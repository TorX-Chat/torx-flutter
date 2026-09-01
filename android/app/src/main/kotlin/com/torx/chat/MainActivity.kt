/*
TorX: Metadata-safe Tor Chat Library 
Copyright (C) 2024 TorX

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 3 as
published by the Free Software Foundation.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

Appendix:

Section 7 Exceptions:
1) Modified versions of the material and resulting works must be clearly titled in the following manner: "Unofficial TorX by Financier", where the word Financier is replaced by the financier of the modifications. Where there is no financier, the word Financier shall be replaced by the organization or individual who is primarily responsible for causing the modifications. Example: "Unofficial TorX by The United States Department of Defense". This amended full-title must replace the word "TorX" in all source code files and all resulting works. Where utilizing spaces is not possible, underscores may be utilized. Example: "Unofficial_TorX_by_The_United_States_Department_of_Defense". The title must not be replaced by an acronym or short title in any form of distribution.

2) Modified versions of the material and resulting works must be distributed with alternate logos and imagery that is substantially different from the original TorX logo and imagery, especially the 7-headed snake logo. Modified material and resulting works, where distributed with a logo or imagery, should choose and distribute a logo or imagery that reflects the Financier, organization, or individual primarily responsible for causing modifications and must not cause any user to note similarities with any of the original TorX imagery. Example: Modifications or works financed by The United States Department of Defense should choose a logo and imagery similar to existing logos and imagery utilized by The United States Department of Defense.

3) Those who modify, distribute, or finance the modification or distribution of the material or resulting works, shall not avail themselves of any disclaimers of liability, such as those laid out by the original TorX author in sections 15 and 16 of the License.

4) Those who modify, distribute, or finance the modification or distribution of the material or resulting works, shall jointly and severally indemnify the original TorX author against any claims of damages incurred and any costs arising from litigation related to any changes they are have made, caused to be made, or financed. 

5) The original author of TorX may issue explicit exemptions from the above requirements (Such as, for example, necessary changes for package maintenance in official Debian repositories), but such exemptions should be interpretted in the narrowest possible scope and to only grant limited rights within the narrowest possible scope to those who explicitly receive the exemption and not those who receive the material or resulting works from the exemptee.

6) The original author of TorX grants no exceptions from trademark protection in any form.

7) Each aspect of these exemptions are to be considered independent and severable if found in contradiction with the License or applicable law.
*/
package com.torx.chat

import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
	private val CHANNEL_TAG = "com.torx.chat/android"

	override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		Audio.stopAll() // XXX Any stream still held belongs to a destroyed engine, so nothing will ever stop it. A live call rebuilds within a message. Do NOT do this on pause/resume, which does not rebuild the engine and would interrupt a backgrounded call.
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_TAG).setMethodCallHandler {
			call, result ->
			if (call.method == "getNativeLibraryPath") {
				result.success(getContext().getApplicationInfo().nativeLibraryDir);
			} else if (call.method == "audio_stream_push") {
				val n = call.argument<Number>("n")
				val data = call.argument<ByteArray>("data")
				val time = call.argument<Number>("time")
				val nstime = call.argument<Number>("nstime")
				if (n == null || data == null || time == null || nstime == null) {
					result.error("sanity", "audio_stream_push requires n, data, time, nstime", null)
				} else {
					Audio.push(n.toInt(), data, time.toLong(), nstime.toLong())
					result.success(null)
				}
			} else if (call.method == "audio_stream_stop") {
				val n = call.argument<Number>("n")
				if (n == null) {
					result.error("sanity", "audio_stream_stop requires n", null)
				} else {
					Audio.stop(n.toInt())
					result.success(null)
				}
			} else if (call.method == "audio_clip_play") {
				val data = call.argument<ByteArray>("data")
				if (data == null) {
					result.error("sanity", "audio_clip_play requires data", null)
				} else {
					Audio.clipPlay(data)
					result.success(null)
				}
			} else if (call.method == "audio_clip_stop") {
				result.success(Audio.clipStop())
			} else {
				result.notImplemented();
			}
		}
	}
}