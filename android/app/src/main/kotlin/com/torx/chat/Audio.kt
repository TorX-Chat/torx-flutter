/*
TorX: Metadata-safe Tor Chat Library
Copyright (C) 2024 TorX

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3 as published by the Free
Software Foundation.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <https://www.gnu.org/licenses/>.

Appendix:

Section 7 Exceptions:

1) Modified versions of the material and resulting works must be clearly titled
in the following manner: "Unofficial TorX by Financier", where the word
Financier is replaced by the financier of the modifications. Where there is no
financier, the word Financier shall be replaced by the organization or
individual who is primarily responsible for causing the modifications. Example:
"Unofficial TorX by The United States Department of Defense". This amended
full-title must replace the word "TorX" in all source code files and all
resulting works. Where utilizing spaces is not possible, underscores may be
utilized. Example: "Unofficial_TorX_by_The_United_States_Department_of_Defense".
The title must not be replaced by an acronym or short title in any form of
distribution.

2) Modified versions of the material and resulting works must be distributed
with alternate logos and imagery that is substantially different from the
original TorX logo and imagery, especially the 7-headed snake logo. Modified
material and resulting works, where distributed with a logo or imagery, should
choose and distribute a logo or imagery that reflects the Financier,
organization, or individual primarily responsible for causing modifications and
must not cause any user to note similarities with any of the original TorX
imagery. Example: Modifications or works financed by The United States
Department of Defense should choose a logo and imagery similar to existing logos
and imagery utilized by The United States Department of Defense.

3) Those who modify, distribute, or finance the modification or distribution of
modified versions of the material or resulting works, shall not avail themselves
of any disclaimers of liability, such as those laid out by the original TorX
author in sections 15 and 16 of the License.

4) Those who modify, distribute, or finance the modification or distribution of
modified versions of the material or resulting works, shall jointly and
severally indemnify the original TorX author against any claims of damages
incurred and any costs arising from litigation related to any changes they are
have made, caused to be made, or financed. 

5) The original author of TorX may issue explicit exemptions from some or all of
the above requirements (1-4), but such exemptions should be interpreted in the
narrowest possible scope and to only grant limited rights within the narrowest
possible scope to those who explicitly receive the exemption and not those who
receive the material or resulting works from the exemptee.

6) The original author of TorX grants no exceptions from trademark protection in
any form.

7) Each aspect of these exemptions are to be considered independent and
severable if found in contradiction with the License or applicable law.
*/
package com.torx.chat

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.MediaCodec
import android.media.MediaFormat
import android.util.Log
import java.nio.ByteBuffer
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

private const val LOG_TAG = "torx"
private const val AUDIO_PLAYOUT_DELAY_MS = 50 // Depth of the receive side jitter buffer. Costs exactly this much added latency. (Recommended: 50ms to 300ms)
private const val AUDIO_HEADROOM_MS = 500 // Track buffer beyond the playout delay, and so the slack a burst can be written into before WRITE_BLOCKING throttles the decoder. Bounds the track, not the backlog, which is MAX_PENDING_FRAMES.
private const val AAC_FRAME_SAMPLES = 1024 // Fixed by AAC-LC, not a tunable.
private const val MAX_PENDING_FRAMES = 512 // A call's queue depth. Clips do not use the queue. XXX Shortening this to shed the backlog was tried and reverted: see AUDIO-BACKLOG-PLAN.md.

private val ADTS_SAMPLE_RATES = intArrayOf(96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050, 16000, 12000, 11025, 8000, 7350)
private val ADTS_CHANNEL_COUNTS = intArrayOf(0, 1, 2, 3, 4, 5, 6, 8)

private fun adtsSynced(data: ByteArray, offset: Int): Boolean {
	return offset + 7 <= data.size && (data[offset].toInt() and 0xFF) == 0xFF && (data[offset + 1].toInt() and 0xF0) == 0xF0
}

private fun adtsSampleRate(data: ByteArray, offset: Int): Int {
	val index = (data[offset + 2].toInt() and 0x3C) shr 2
	return if (index < ADTS_SAMPLE_RATES.size) ADTS_SAMPLE_RATES[index] else -1
}

private fun adtsChannelCount(data: ByteArray, offset: Int): Int {
	val index = ((data[offset + 2].toInt() and 0x01) shl 2) or ((data[offset + 3].toInt() and 0xC0) shr 6)
	return if (index > 0 && index < ADTS_CHANNEL_COUNTS.size) ADTS_CHANNEL_COUNTS[index] else -1
}

private fun adtsFrameLength(data: ByteArray, offset: Int): Int {
	return ((data[offset + 3].toInt() and 0x03) shl 11) or ((data[offset + 4].toInt() and 0xFF) shl 3) or ((data[offset + 5].toInt() and 0xE0) shr 5)
}

private fun adtsCodecSpecificData(data: ByteArray, offset: Int): ByteArray {
	val objectType = ((data[offset + 2].toInt() and 0xC0) shr 6) + 1
	val frequency = (data[offset + 2].toInt() and 0x3C) shr 2
	val channels = ((data[offset + 2].toInt() and 0x01) shl 2) or ((data[offset + 3].toInt() and 0xC0) shr 6)
	return byteArrayOf((((objectType shl 3) or (frequency shr 1)) and 0xFF).toByte(), ((((frequency and 0x01) shl 7) or (channels shl 3)) and 0xFF).toByte())
}

private class Frame(val data: ByteArray, val offset: Int, val length: Int, val presentationTimeUs: Long) // References its message in place. Neither a stream's message nor a clip is reused after it is handed over, so nothing is copied.

object Audio {
	private val streams = HashMap<Int, Stream>()
	private var clip: Stream? = null // Voice message playback. One at a time, and separate from streams because a call and a voice message may legitimately sound at once.

	@Synchronized fun push(n: Int, data: ByteArray, time: Long, nstime: Long) {
		if (n < 0 || data.isEmpty()) {
			return
		}
		if (!adtsSynced(data, 0)) { // The library concatenates whole chunks with no framing of its own, so the codec being self-delimiting is what makes the concatenation decodable.
			Log.e(LOG_TAG, "Audio from n=$n is not ADTS framed. Discarding it.")
			return
		}
		val sampleRate = adtsSampleRate(data, 0)
		val channelCount = adtsChannelCount(data, 0)
		if (sampleRate < 1 || channelCount < 1 || channelCount > 2) {
			Log.e(LOG_TAG, "Unsupported ADTS header from n=$n rate=$sampleRate channels=$channelCount. Discarding it.")
			return
		}
		var stream = streams[n]
		if (stream != null && !stream.isRunning()) { // Its decoder died. The next arrival builds a fresh one, as it would on a first arrival.
			streams.remove(n)
			stream = null
		}
		if (stream != null && !stream.matches(sampleRate, channelCount)) { // XXX A peer need not be recording at our rate or channel count. Every ADTS header carries both, so rebuild rather than pinning either.
		//	Log.i(LOG_TAG, "Audio format from n=$n changed to rate=$sampleRate channels=$channelCount. Rebuilding.")
			stream.stop()
			streams.remove(n)
			stream = null
		}
		if (stream == null) {
			stream = Stream(n, sampleRate, channelCount, adtsCodecSpecificData(data, 0))
			if (!stream.start()) {
				return
			}
			streams[n] = stream
		}
		stream.push(data, time, nstime)
	}

	@Synchronized fun stop(n: Int) {
		streams.remove(n)?.stop()
	}

	@Synchronized fun stopAll() {
		for (stream in streams.values) {
			stream.stop()
		}
		streams.clear()
		clipStop()
	}

	@Synchronized fun clipPlay(data: ByteArray) { // Voice messages. n = -1 selects one shot playback, as it does in torx-gtk4's playback_start.
		clipStop()
		if (data.isEmpty() || !adtsSynced(data, 0)) {
			Log.e(LOG_TAG, "Voice message is not ADTS framed. Discarding it.")
			return
		}
		val sampleRate = adtsSampleRate(data, 0)
		val channelCount = adtsChannelCount(data, 0)
		if (sampleRate < 1 || channelCount < 1 || channelCount > 2) {
			Log.e(LOG_TAG, "Unsupported ADTS header in a voice message rate=$sampleRate channels=$channelCount. Discarding it.")
			return
		}
		val stream = Stream(-1, sampleRate, channelCount, adtsCodecSpecificData(data, 0), data) // XXX The clip must arrive at construction: start() launches the worker, and a worker that finds no data declares itself ended.
		if (!stream.start()) {
			return
		}
		clip = stream
	}

	@Synchronized fun clipStop(): Boolean { // Returns whether a clip was still playing, which is what the caller's play/stop toggle needs
		val stream = clip ?: return false
		clip = null
		val playing = stream.isRunning()
		stream.stop()
		return playing
	}
}

private class Stream(private val n: Int, private val sampleRate: Int, private val channelCount: Int, private val csd: ByteArray, private val clipData: ByteArray? = null) : Runnable {
	private val streaming = n > -1 // XXX As in torx-gtk4's playback_start: n > -1 is a call, n == -1 is a one shot voice message. Must agree with clipData == null.
	private val queue = LinkedBlockingQueue<Frame>(MAX_PENDING_FRAMES) // Streams only. A clip is read in place by the worker, so its length is bounded by nothing.
	@Volatile private var running = false
	@Volatile private var ended = false // Clips only. No more input is coming.
	@Volatile private var anchored = false
	@Volatile private var anchorNs = 0L
	private var thread: Thread? = null
	private var codec: MediaCodec? = null
	@Volatile private var track: AudioTrack? = null
	private var trackRate = 0
	private var frameBytes = 0
	private var delayFrames = 0L
	private var framesWritten = 0L
	private var timelineOrigin = 0L
	private var reported = 0
	private var silence = ByteArray(0)
	private var clipOffset = 0 // Clips only. Worker owned, so it needs no synchronisation.
	private var clipIndex = 0

	fun isRunning(): Boolean {
		return running
	}

	fun matches(rate: Int, channels: Int): Boolean {
		return rate == sampleRate && channels == channelCount
	}

	fun start(): Boolean {
		try {
			val format = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, sampleRate, channelCount)
			format.setInteger(MediaFormat.KEY_IS_ADTS, 1)
			format.setByteBuffer("csd-0", ByteBuffer.wrap(csd)) // Some decoders will not configure themselves from the ADTS header alone.
			val codec = MediaCodec.createDecoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
			codec.configure(format, null, null, 0)
			codec.start()
			this.codec = codec
		} catch (e: Exception) {
			Log.e(LOG_TAG, "Failed to start audio decoder for n=$n: $e")
			return false
		}
		running = true
		val thread = Thread(this, if (streaming) "torx-audio-$n" else "torx-audio-clip")
		this.thread = thread
		thread.start()
	//	Log.i(LOG_TAG, "Checkpoint audio_stream_start n=$n rate=$sampleRate channels=$channelCount")
		return true
	}

	fun stop() {
		running = false
		queue.clear()
		try { // Unblocks a worker that is blocked in write(). The worker releases the codec and track itself, in run()'s finally.
			track?.pause()
			track?.flush()
		} catch (e: Exception) {
		}
		thread?.interrupt()
		thread = null
	}

	private fun nextClipFrame(): Frame? { // Clips only. Walks the message in place. Any failure ends the clip rather than spinning on it.
		val data = clipData
		if (data == null || clipOffset >= data.size) {
			ended = true
			return null
		}
		if (!adtsSynced(data, clipOffset)) {
			Log.e(LOG_TAG, "Lost ADTS sync in a voice message. Discarding the remainder.")
			ended = true
			return null
		}
		val length = adtsFrameLength(data, clipOffset)
		if (length < 7 || clipOffset + length > data.size) {
			Log.e(LOG_TAG, "Bad ADTS frame length in a voice message. Discarding the remainder.")
			ended = true
			return null
		}
		val frame = Frame(data, clipOffset, length, clipIndex.toLong() * AAC_FRAME_SAMPLES * 1000000L / sampleRate) // A clip has no sender timeline to anchor against, so its frames are simply consecutive.
		clipOffset += length
		clipIndex++
		return frame
	}

	fun push(data: ByteArray, time: Long, nstime: Long) {
		val messageNs = time * 1000000000L + nstime
		if (!anchored) { // XXX The timeline must follow the SENDER's clock, not ours. Audio arrives clumped, so placing it by arrival puts a message on top of its predecessor, and a transport gap longer than the playout buffer then desynchronises playback permanently instead of resynchronising on the next message.
			anchorNs = messageNs
			anchored = true
		}
		var offset = 0
		var index = 0
		while (offset < data.size) { // One message is N whole ADTS frames concatenated. The decoder wants one access unit per input buffer, so they must be split.
			if (!adtsSynced(data, offset)) {
				Log.e(LOG_TAG, "Lost ADTS sync in audio from n=$n. Discarding remainder of message.")
				return
			}
			val length = adtsFrameLength(data, offset)
			if (length < 7 || offset + length > data.size) {
				Log.e(LOG_TAG, "Bad ADTS frame length in audio from n=$n. Discarding remainder of message.")
				return
			}
			var presentationTimeUs = (messageNs - anchorNs) / 1000L + index.toLong() * AAC_FRAME_SAMPLES * 1000000L / sampleRate
			if (presentationTimeUs < 0L) {
				presentationTimeUs = 0L
			}
			if (!queue.offer(Frame(data, offset, length, presentationTimeUs))) {
				Log.e(LOG_TAG, "Audio decoder for n=$n is not keeping up. Dropping a frame.")
			}
			offset += length
			index++
		}
	}

	override fun run() {
		try {
			decode()
		} catch (e: Exception) {
			Log.e(LOG_TAG, "Audio playback for n=$n failed: $e")
		} finally {
			release()
		}
	}

	private fun decode() {
		val codec = this.codec ?: return
		val info = MediaCodec.BufferInfo()
		var pending: Frame? = null
		var signalled = false // Input end of stream has been queued. Clips only.
		while (running) {
			if (pending == null) {
				pending = if (streaming) {
					try {
						queue.poll(5, TimeUnit.MILLISECONDS)
					} catch (e: InterruptedException) {
						return
					}
				} else {
					nextClipFrame()
				}
			}
			if (pending == null && ended && !signalled) { // XXX A decoder holds its final frames until it is told the input ended, so a clip would lose its tail without this.
				val index = codec.dequeueInputBuffer(5000L)
				if (index >= 0) {
					codec.queueInputBuffer(index, 0, 0, 0L, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
					signalled = true
				}
			}
			if (pending != null) {
				val index = codec.dequeueInputBuffer(5000L)
				if (index >= 0) {
					val buffer = codec.getInputBuffer(index)
					if (buffer != null) {
						buffer.clear()
						buffer.put(pending.data, pending.offset, pending.length)
						codec.queueInputBuffer(index, 0, pending.length, pending.presentationTimeUs, 0)
					}
					pending = null
				}
			}
			while (running) {
				val index = codec.dequeueOutputBuffer(info, 5000L)
				if (index >= 0) {
					val buffer = codec.getOutputBuffer(index)
					if (buffer != null && info.size > 0 && (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) == 0) {
						val pcm = ByteArray(info.size)
						buffer.position(info.offset)
						buffer.get(pcm, 0, info.size)
						render(pcm, info.presentationTimeUs)
					}
					codec.releaseOutputBuffer(index, false)
					if ((info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
						drain()
						return
					}
				} else if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
					openTrack(codec.outputFormat)
				} else {
					break
				}
			}
		}
	}

	private fun openTrack(format: MediaFormat) {
		if (track != null) {
			return
		}
		val rate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
		val channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
		if (channels < 1 || channels > 2) {
			Log.e(LOG_TAG, "Audio decoder for n=$n produced $channels channels, which is unsupported.")
			running = false
			return
		}
		val mask = if (channels == 1) AudioFormat.CHANNEL_OUT_MONO else AudioFormat.CHANNEL_OUT_STEREO
		trackRate = rate
		frameBytes = channels * 2
		delayFrames = if (streaming) rate.toLong() * AUDIO_PLAYOUT_DELAY_MS / 1000L else 0L // A clip has already arrived in full, so there is no transport left to buffer against.
		silence = ByteArray(frameBytes * (rate / 20)) // 50ms of padding per write
		val minimum = AudioTrack.getMinBufferSize(rate, mask, AudioFormat.ENCODING_PCM_16BIT)
		var wanted = ((delayFrames + rate.toLong() * AUDIO_HEADROOM_MS / 1000L) * frameBytes).toInt()
		if (wanted < minimum * 2) {
			wanted = minimum * 2
		}
		val opened = AudioTrack.Builder()
			.setAudioAttributes(AudioAttributes.Builder()
				.setUsage(AudioAttributes.USAGE_MEDIA)
				.setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
				.build())
			.setAudioFormat(AudioFormat.Builder()
				.setEncoding(AudioFormat.ENCODING_PCM_16BIT)
				.setSampleRate(rate)
				.setChannelMask(mask)
				.build())
			.setBufferSizeInBytes(wanted)
			.setTransferMode(AudioTrack.MODE_STREAM)
			.build()
		track = opened
		opened.play() // XXX Must precede the first write. A track that has not been started does not consume, so the write blocks or returns nothing once its buffer fills.
	//	Log.i(LOG_TAG, "Checkpoint audio_stream_track n=$n rate=$rate channels=$channels buffer_frames=${opened.bufferSizeInFrames} state=${opened.state} play_state=${opened.playState}")
		framesWritten = writeSilence(opened, (delayFrames * frameBytes).toInt()) // XXX THIS is the playout delay: the track is started on silence, so the play head trails the write head by exactly this much.
		timelineOrigin = framesWritten
	}

	private fun render(pcm: ByteArray, presentationTimeUs: Long) {
		val track = this.track ?: return
		if (reported < 8) { // Reports whether the decoder is producing audible samples and whether the track is consuming them. Silent PCM and a stalled play head look identical from outside.
			var peak = 0
			var iter = 0
			while (iter + 1 < pcm.size) {
				var sample = (((pcm[iter + 1].toInt() and 0xFF) shl 8) or (pcm[iter].toInt() and 0xFF)).toShort().toInt()
				if (sample < 0) {
					sample = -sample
				}
				if (sample > peak) {
					peak = sample
				}
				iter += 2
			}
		//	Log.i(LOG_TAG, "Checkpoint audio_stream_pcm n=$n bytes=${pcm.size} peak=$peak head=${track.playbackHeadPosition} written=$framesWritten play_state=${track.playState}")
			reported++
		}
		if (streaming) { // A clip's frames are contiguous, so it has no gaps to preserve and no delay to preserve them across.
			var padding = timelineOrigin + presentationTimeUs * trackRate / 1000000L - framesWritten
			if (padding > delayFrames) { // A gap longer than the delay is not worth padding in full, and the origin must absorb the remainder or every later message would owe it too.
				timelineOrigin -= padding - delayFrames
				padding = delayFrames
			}
			if (padding > 0L) { // Gaps in the capture timeline are real: the sender suppresses silence, and padding them is what preserves the playout delay across them.
				framesWritten += writeSilence(track, (padding * frameBytes).toInt())
			}
		}
		framesWritten += write(track, pcm, 0, pcm.size)
	}

	private fun drain() { // Clips only
		val track = this.track ?: return
		try {
			track.stop() // XXX Not pause(): in MODE_STREAM stop() plays out what is already buffered, where pause() would cut the tail off.
			var guard = 0
			while (running && guard < 500 && track.playbackHeadPosition.toLong() < framesWritten) { // stop() returns immediately, so releasing here would truncate. Bounded because blocking writes leave at most a track buffer to play out.
				Thread.sleep(20L)
				guard++
			}
		} catch (e: Exception) {
		}
	}

	private fun writeSilence(track: AudioTrack, bytes: Int): Long {
		var written = 0L
		while (written < bytes && running) {
			val remaining = bytes - written
			val chunk = if (remaining > silence.size) silence.size else remaining.toInt()
			val ret = write(track, silence, 0, chunk)
			if (ret < 1L) {
				break
			}
			written += ret * frameBytes
		}
		return written / frameBytes
	}

	private fun write(track: AudioTrack, data: ByteArray, offset: Int, bytes: Int): Long {
		var written = 0
		while (written < bytes && running) {
			val ret = track.write(data, offset + written, bytes - written, AudioTrack.WRITE_BLOCKING)
			if (ret < 1) {
				break
			}
			written += ret
		}
		return (written / frameBytes).toLong()
	}

	private fun release() {
		running = false // XXX Must be here and not only in stop(), otherwise a worker that died of an exception still reports itself as running and keeps being fed.
		try {
			codec?.stop()
			codec?.release()
		} catch (e: Exception) {
		}
		codec = null
		try {
			track?.pause()
			track?.flush()
			track?.release()
		} catch (e: Exception) {
		}
		track = null
	//	Log.i(LOG_TAG, "Checkpoint audio_stream_stop n=$n")
	}
}
