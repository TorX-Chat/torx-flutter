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
// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'callbacks.dart';
import 'main.dart';

/*
  // Use GOAT instead of T O D O
  // Note: Theme.of(context).colorScheme.primary <-- this is actually a usable color

  // To set an error
    error(0, "this is 34 long including newline");

  // To set an int
    torx.mult_expiration_days.value = 758;

  // To read an int
    printf(torx.mult_expiration_days.value);

  // To print a returned char*
    printf(torx.itoa(3).toDartString());

  // To debug any SCUDO errors, https://source.android.google.cn/docs/security/test/scudo?hl=en

  // Linking in Android and IOS (MUST USE)
    https://www.raywenderlich.com/21512310-calling-native-libraries-in-flutter-with-dart-ffi

  // Other stuff, old:
    https://asim.ihsan.io/flutter-ffi-libsodium/
    https://dart.dev/guides/libraries/c-interop
    https://blog.logrocket.com/dart-ffi-native-libraries-flutter/#generating-the-ffi-binding-code
    https://stackoverflow.com/questions/65551415/failed-to-load-dynamic-library-in-flutter-app

*/

const int ENUM_OWNER_PEER = 1;
const int ENUM_OWNER_SING = 2;
const int ENUM_OWNER_MULT = 3;
const int ENUM_OWNER_CTRL = 4;
const int ENUM_OWNER_GROUP_PEER = 5;
const int ENUM_OWNER_GROUP_CTRL = 6;

const int ENUM_STATUS_BLOCKED = 1; // includes disabled for SING/MULT
const int ENUM_STATUS_FRIEND = 2;
const int ENUM_STATUS_PENDING = 3;
const int ENUM_STATUS_GROUP_CTRL = 4; // only for populatePeerList

const int ENUM_MESSAGE_RECV = 1;
const int ENUM_MESSAGE_FAIL = 2;
const int ENUM_MESSAGE_SENT = 3;

const int ENUM_FILE_INACTIVE_AWAITING_ACCEPTANCE_INBOUND = 0;
const int ENUM_FILE_ACTIVE_OUT = 1;
const int ENUM_FILE_ACTIVE_IN = 2;
const int ENUM_FILE_ACTIVE_IN_OUT = 3;
const int ENUM_FILE_INACTIVE_ACCEPTED = 4;
const int ENUM_FILE_INACTIVE_CANCELLED = 5;
const int ENUM_FILE_INACTIVE_COMPLETE = 6;

// UI Protocols
const int ENUM_PROTOCOL_AAC_AUDIO_MSG = 43474; // uint32_t duration (milliseconds, big endian) + data
const int ENUM_PROTOCOL_AAC_AUDIO_MSG_PRIVATE = 29304; // uint32_t duration (milliseconds, big endian) + data
const int ENUM_PROTOCOL_AAC_AUDIO_MSG_DATE_SIGNED = 47904; // uint32_t duration (milliseconds, big endian) + data

/*
const int ENUM_PROTOCOL_AUDIO_WAV = 14433;
  const int ENUM_PROTOCOL_AUDIO_WAV_DATE_SIGNED = 5392;
  const int ENUM_PROTOCOL_FILE_PREVIEW_PNG = 32343;
  const int ENUM_PROTOCOL_FILE_PREVIEW_PNG_DATE_SIGNED = 17878;
  const int ENUM_PROTOCOL_FILE_PREVIEW_GIF = 54526;
  const int ENUM_PROTOCOL_FILE_PREVIEW_GIF_DATE_SIGNED = 47334; */

// Library protocols
const int ENUM_PROTOCOL_UTF8_TEXT = 32896;
const int ENUM_PROTOCOL_FILE_OFFER = 44443;
const int ENUM_PROTOCOL_FILE_OFFER_PRIVATE = 62747;
const int ENUM_PROTOCOL_FILE_OFFER_GROUP = 32918;
const int ENUM_PROTOCOL_FILE_OFFER_GROUP_DATE_SIGNED = 2125;
const int ENUM_PROTOCOL_FILE_OFFER_PARTIAL = 64736;
const int ENUM_PROTOCOL_FILE_INFO_REQUEST = 63599;
const int ENUM_PROTOCOL_FILE_PARTIAL_REQUEST = 52469;
const int ENUM_PROTOCOL_FILE_PIECE = 7795;
const int ENUM_PROTOCOL_FILE_REQUEST = 27493;
const int ENUM_PROTOCOL_FILE_PAUSE = 38490;
const int ENUM_PROTOCOL_FILE_CANCEL = 22461;
const int ENUM_PROTOCOL_PROPOSE_UPGRADE = 57382;
const int ENUM_PROTOCOL_KILL_CODE = 41342;
const int ENUM_PROTOCOL_UTF8_TEXT_DATE_SIGNED = 47208;
const int ENUM_PROTOCOL_UTF8_TEXT_PRIVATE = 24326;
const int ENUM_PROTOCOL_GROUP_BROADCAST = 13854;
const int ENUM_PROTOCOL_GROUP_OFFER_FIRST = 11919;
const int ENUM_PROTOCOL_GROUP_OFFER_ACCEPT_FIRST = 48942;
const int ENUM_PROTOCOL_GROUP_OFFER = 23579;
const int ENUM_PROTOCOL_GROUP_OFFER_ACCEPT = 10652;
const int ENUM_PROTOCOL_GROUP_OFFER_ACCEPT_REPLY = 59142;
const int ENUM_PROTOCOL_GROUP_PUBLIC_ENTRY_REQUEST = 24335;
const int ENUM_PROTOCOL_GROUP_PRIVATE_ENTRY_REQUEST = 13196;
const int ENUM_PROTOCOL_GROUP_REQUEST_PEERLIST = 62797;
const int ENUM_PROTOCOL_GROUP_PEERLIST = 39970;
const int ENUM_PROTOCOL_PIPE_AUTH = 25078;
const int ENUM_PROTOCOL_AUDIO_STREAM_JOIN = 65303; // Start Time + nstime // This is also offer
const int ENUM_PROTOCOL_AUDIO_STREAM_JOIN_PRIVATE = 33037; // Start Time + nstime // This is also offer
const int ENUM_PROTOCOL_AUDIO_STREAM_PEERS = 16343; // Start Time + nstime + 56*participating
const int ENUM_PROTOCOL_AUDIO_STREAM_LEAVE = 23602; // Start Time + nstime
const int ENUM_PROTOCOL_AUDIO_STREAM_DATA_DATE_AAC = 54254; // Start Time + nstime + data (AAC)
const int ENUM_PROTOCOL_STICKER_HASH = 29812;
const int ENUM_PROTOCOL_STICKER_HASH_PRIVATE = 40505;
const int ENUM_PROTOCOL_STICKER_HASH_DATE_SIGNED = 1891;
const int ENUM_PROTOCOL_STICKER_REQUEST = 24931;
const int ENUM_PROTOCOL_STICKER_DATA_GIF = 46093;

typedef Size_t = Size;
typedef Time_t = Long; // GOAT WARNING: *should* be ok? Could use Size?? TODO
int INT_MIN = -(1 << 31); // -2147483648;

const int crypto_box_SEEDBYTES = 32;
const int crypto_sign_BYTES = 64;
const int crypto_sign_PUBLICKEYBYTES = 32;
const int CHECKSUM_BIN_LEN = 32;
const int GROUP_ID_SIZE = crypto_box_SEEDBYTES;
const int GROUP_OFFER_LEN = GROUP_ID_SIZE + 4 + 1;
const int GROUP_OFFER_FIRST_LEN = GROUP_ID_SIZE + 4 + 1 + 56 + crypto_sign_PUBLICKEYBYTES;

const int ENUM_EXCLUSIVE_NONE = 0;
const int ENUM_EXCLUSIVE_GROUP_PM = 1;
const int ENUM_EXCLUSIVE_GROUP_MSG = 2;
const int ENUM_EXCLUSIVE_GROUP_MECHANICS = 3;

const int ENUM_NON_STREAM = 0;
const int ENUM_STREAM_DISCARDABLE = 1;
const int ENUM_STREAM_NON_DISCARDABLE = 2;

typedef FnCinitialize_n_cb = Void Function(Int);
typedef FnDARTinitialize_n_cb = void Function(int);

typedef FnCinitialize_i_cb = Void Function(Int, Int);
typedef FnDARTinitialize_i_cb = void Function(int, int);

typedef FnCinitialize_f_cb = Void Function(Int, Int);
typedef FnDARTinitialize_f_cb = void Function(int, int);

typedef FnCinitialize_g_cb = Void Function(Int);
typedef FnDARTinitialize_g_cb = void Function(int);

typedef FnCshrinkage_cb = Void Function(Int, Int);
typedef FnDARTshrinkage_cb = void Function(int, int);

typedef FnCexpand_file_struc_cb = Void Function(Int, Int);
typedef FnDARTexpand_file_struc_cb = void Function(int, int);

typedef FnCexpand_message_struc_cb = Void Function(Int, Int);
typedef FnDARTexpand_message_struc_cb = void Function(int, int);

typedef FnCexpand_peer_struc_cb = Void Function(Int);
typedef FnDARTexpand_peer_struc_cb = void Function(int);

typedef FnCexpand_group_struc_cb = Void Function(Int);
typedef FnDARTexpand_group_struc_cb = void Function(int);

typedef FnCtransfer_progress_cb = Void Function(Int, Int, Uint64);
typedef FnDARTtransfer_progress_cb = void Function(int, int, int);

typedef FnCchange_password_cb = Void Function(Int);
typedef FnDARTchange_password_cb = void Function(int);

typedef FnCincoming_friend_request_cb = Void Function(Int);
typedef FnDARTincoming_friend_request_cb = void Function(int);

typedef FnConion_deleted_cb = Void Function(Uint8, Int);
typedef FnDARTonion_deleted_cb = void Function(int, int);

typedef FnCpeer_online_cb = Void Function(Int);
typedef FnDARTpeer_online_cb = void Function(int);

typedef FnCpeer_offline_cb = Void Function(Int);
typedef FnDARTpeer_offline_cb = void Function(int);

typedef FnCpeer_new_cb = Void Function(Int);
typedef FnDARTpeer_new_cb = void Function(int);

typedef FnConion_ready_cb = Void Function(Int);
typedef FnDARTonion_ready_cb = void Function(int);

typedef FnCtor_log_cb = Void Function(Pointer<Utf8>);
typedef FnDARTtor_log_cb = void Function(Pointer<Utf8>);

typedef FnCerror_cb = Void Function(Pointer<Utf8>);
typedef FnDARTerror_cb = void Function(Pointer<Utf8>);

typedef FnCfatal_cb = Void Function(Pointer<Utf8>);
typedef FnDARTfatal_cb = void Function(Pointer<Utf8>);

typedef FnCcustom_setting_cb = Void Function(Int, Pointer<Utf8>, Pointer<Utf8>, Size_t, Int);
typedef FnDARTcustom_setting_cb = void Function(int, Pointer<Utf8>, Pointer<Utf8>, int, int);

typedef FnCmessage_new_cb = Void Function(Int, Int);
typedef FnDARTmessage_new_cb = void Function(int, int);

typedef FnCmessage_modified_cb = Void Function(Int, Int);
typedef FnDARTmessage_modified_cb = void Function(int, int);

typedef FnCmessage_deleted_cb = Void Function(Int, Int);
typedef FnDARTmessage_deleted_cb = void Function(int, int);

typedef FnCmessage_extra_cb = Void Function(Int, Int, Pointer<Utf8>, Uint32);
typedef FnDARTmessage_extra_cb = void Function(int, int, Pointer<Utf8>, int);

typedef FnCmessage_more_cb = Void Function(Int, Pointer<Int>, Pointer<Int>);
typedef FnDARTmessage_more_cb = void Function(int, Pointer<Int>, Pointer<Int>);

typedef FnClogin_cb = Void Function(Int);
typedef FnDARTlogin_cb = void Function(int);

typedef FnCpeer_loaded_cb = Void Function(Int);
typedef FnDARTpeer_loaded_cb = void Function(int);

typedef FnCcleanup_cb = Void Function(Int);
typedef FnDARTcleanup_cb = void Function(int);

typedef FnCstream_cb = Void Function(Int, Int, Pointer<Utf8>, Uint32);
typedef FnDARTstream_cb = void Function(int, int, Pointer<Utf8>, int);

typedef FnCinitialize_peer_call_cb = Void Function(Int, Int);
typedef FnDARTinitialize_peer_call_cb = void Function(int, int);

typedef FnCexpand_call_struc_cb = Void Function(Int, Int);
typedef FnDARTexpand_call_struc_cb = void Function(int, int);

typedef FnCcall_update_cb = Void Function(Int, Int);
typedef FnDARTcall_update_cb = void Function(int, int);

typedef FnCaudio_cache_add_cb = Void Function(Int);
typedef FnDARTaudio_cache_add_cb = void Function(int);

/* NOTE FOR THE FOLLOWING SETTERS: pointer must be the same across both */
typedef FnCinitialize_n_setter = Void Function(Pointer<NativeFunction<FnCinitialize_n_cb>>);
typedef FnDARTinitialize_n_setter = void Function(Pointer<NativeFunction<FnCinitialize_n_cb>>);

typedef FnCinitialize_i_setter = Void Function(Pointer<NativeFunction<FnCinitialize_i_cb>>);
typedef FnDARTinitialize_i_setter = void Function(Pointer<NativeFunction<FnCinitialize_i_cb>>);

typedef FnCinitialize_f_setter = Void Function(Pointer<NativeFunction<FnCinitialize_f_cb>>);
typedef FnDARTinitialize_f_setter = void Function(Pointer<NativeFunction<FnCinitialize_f_cb>>);

typedef FnCinitialize_g_setter = Void Function(Pointer<NativeFunction<FnCinitialize_g_cb>>);
typedef FnDARTinitialize_g_setter = void Function(Pointer<NativeFunction<FnCinitialize_g_cb>>);

typedef FnCshrinkage_setter = Void Function(Pointer<NativeFunction<FnCshrinkage_cb>>);
typedef FnDARTshrinkage_setter = void Function(Pointer<NativeFunction<FnCshrinkage_cb>>);

typedef FnCexpand_file_struc_setter = Void Function(Pointer<NativeFunction<FnCexpand_file_struc_cb>>);
typedef FnDARTexpand_file_struc_setter = void Function(Pointer<NativeFunction<FnCexpand_file_struc_cb>>);

typedef FnCexpand_message_struc_setter = Void Function(Pointer<NativeFunction<FnCexpand_message_struc_cb>>);
typedef FnDARTexpand_message_struc_setter = void Function(Pointer<NativeFunction<FnCexpand_message_struc_cb>>);

typedef FnCexpand_peer_struc_setter = Void Function(Pointer<NativeFunction<FnCexpand_peer_struc_cb>>);
typedef FnDARTexpand_peer_struc_setter = void Function(Pointer<NativeFunction<FnCexpand_peer_struc_cb>>);

typedef FnCexpand_group_struc_setter = Void Function(Pointer<NativeFunction<FnCexpand_group_struc_cb>>);
typedef FnDARTexpand_group_struc_setter = void Function(Pointer<NativeFunction<FnCexpand_group_struc_cb>>);

typedef FnCtransfer_progress_setter = Void Function(Pointer<NativeFunction<FnCtransfer_progress_cb>>);
typedef FnDARTtransfer_progress_setter = void Function(Pointer<NativeFunction<FnCtransfer_progress_cb>>);

typedef FnCchange_password_setter = Void Function(Pointer<NativeFunction<FnCchange_password_cb>>);
typedef FnDARTchange_password_setter = void Function(Pointer<NativeFunction<FnCchange_password_cb>>);

typedef FnCincoming_friend_request_setter = Void Function(Pointer<NativeFunction<FnCincoming_friend_request_cb>>);
typedef FnDARTincoming_friend_request_setter = void Function(Pointer<NativeFunction<FnCincoming_friend_request_cb>>);

typedef FnConion_deleted_setter = Void Function(Pointer<NativeFunction<FnConion_deleted_cb>>);
typedef FnDARTonion_deleted_setter = void Function(Pointer<NativeFunction<FnConion_deleted_cb>>);

typedef FnCpeer_online_setter = Void Function(Pointer<NativeFunction<FnCpeer_online_cb>>);
typedef FnDARTpeer_online_setter = void Function(Pointer<NativeFunction<FnCpeer_online_cb>>);

typedef FnCpeer_offline_setter = Void Function(Pointer<NativeFunction<FnCpeer_offline_cb>>);
typedef FnDARTpeer_offline_setter = void Function(Pointer<NativeFunction<FnCpeer_offline_cb>>);

typedef FnCpeer_new_setter = Void Function(Pointer<NativeFunction<FnCpeer_new_cb>>);
typedef FnDARTpeer_new_setter = void Function(Pointer<NativeFunction<FnCpeer_new_cb>>);

typedef FnConion_ready_setter = Void Function(Pointer<NativeFunction<FnConion_ready_cb>>);
typedef FnDARTonion_ready_setter = void Function(Pointer<NativeFunction<FnConion_ready_cb>>);

typedef FnCtor_log_setter = Void Function(Pointer<NativeFunction<FnCtor_log_cb>>);
typedef FnDARTtor_log_setter = void Function(Pointer<NativeFunction<FnCtor_log_cb>>);

typedef FnCerror_setter = Void Function(Pointer<NativeFunction<FnCerror_cb>>);
typedef FnDARTerror_setter = void Function(Pointer<NativeFunction<FnCerror_cb>>);

typedef FnCfatal_setter = Void Function(Pointer<NativeFunction<FnCfatal_cb>>);
typedef FnDARTfatal_setter = void Function(Pointer<NativeFunction<FnCfatal_cb>>);

typedef FnCcustom_setting_setter = Void Function(Pointer<NativeFunction<FnCcustom_setting_cb>>);
typedef FnDARTcustom_setting_setter = void Function(Pointer<NativeFunction<FnCcustom_setting_cb>>);

typedef FnCmessage_new_setter = Void Function(Pointer<NativeFunction<FnCmessage_new_cb>>);
typedef FnDARTmessage_new_setter = void Function(Pointer<NativeFunction<FnCmessage_new_cb>>);

typedef FnCmessage_modified_setter = Void Function(Pointer<NativeFunction<FnCmessage_modified_cb>>);
typedef FnDARTmessage_modified_setter = void Function(Pointer<NativeFunction<FnCmessage_modified_cb>>);

typedef FnCmessage_deleted_setter = Void Function(Pointer<NativeFunction<FnCmessage_deleted_cb>>);
typedef FnDARTmessage_deleted_setter = void Function(Pointer<NativeFunction<FnCmessage_deleted_cb>>);

typedef FnCmessage_extra_setter = Void Function(Pointer<NativeFunction<FnCmessage_extra_cb>>);
typedef FnDARTmessage_extra_setter = void Function(Pointer<NativeFunction<FnCmessage_extra_cb>>);

typedef FnCmessage_more_setter = Void Function(Pointer<NativeFunction<FnCmessage_more_cb>>);
typedef FnDARTmessage_more_setter = void Function(Pointer<NativeFunction<FnCmessage_more_cb>>);

typedef FnClogin_setter = Void Function(Pointer<NativeFunction<FnClogin_cb>>);
typedef FnDARTlogin_setter = void Function(Pointer<NativeFunction<FnClogin_cb>>);

typedef FnCpeer_loaded_setter = Void Function(Pointer<NativeFunction<FnCpeer_loaded_cb>>);
typedef FnDARTpeer_loaded_setter = void Function(Pointer<NativeFunction<FnCpeer_loaded_cb>>);

typedef FnCcleanup_setter = Void Function(Pointer<NativeFunction<FnCcleanup_cb>>);
typedef FnDARTcleanup_setter = void Function(Pointer<NativeFunction<FnCcleanup_cb>>);

typedef FnCstream_setter = Void Function(Pointer<NativeFunction<FnCstream_cb>>);
typedef FnDARTstream_setter = void Function(Pointer<NativeFunction<FnCstream_cb>>);

typedef FnCinitialize_peer_call_setter = Void Function(Pointer<NativeFunction<FnCinitialize_peer_call_cb>>);
typedef FnDARTinitialize_peer_call_setter = void Function(Pointer<NativeFunction<FnCinitialize_peer_call_cb>>);

typedef FnCexpand_call_struc_setter = Void Function(Pointer<NativeFunction<FnCexpand_call_struc_cb>>);
typedef FnDARTexpand_call_struc_setter = void Function(Pointer<NativeFunction<FnCexpand_call_struc_cb>>);

typedef FnCcall_update_setter = Void Function(Pointer<NativeFunction<FnCcall_update_cb>>);
typedef FnDARTcall_update_setter = void Function(Pointer<NativeFunction<FnCcall_update_cb>>);

typedef FnCaudio_cache_add_setter = Void Function(Pointer<NativeFunction<FnCaudio_cache_add_cb>>);
typedef FnDARTaudio_cache_add_setter = void Function(Pointer<NativeFunction<FnCaudio_cache_add_cb>>);

/* End of setter block */
typedef FnCpthread_rwlock_rdlock = Int Function(Pointer<NativeType>);
typedef FnDARTpthread_rwlock_rdlock = int Function(Pointer<NativeType>);

typedef FnCpthread_rwlock_wrlock = Int Function(Pointer<NativeType>);
typedef FnDARTpthread_rwlock_wrlock = int Function(Pointer<NativeType>);

typedef FnCpthread_rwlock_unlock = Int Function(Pointer<NativeType>);
typedef FnDARTpthread_rwlock_unlock = int Function(Pointer<NativeType>);

typedef FnCmemcpy = Pointer<Void> Function(Pointer<NativeType>, Pointer<NativeType>, Size_t);
typedef FnDARTmemcpy = Pointer<Void> Function(Pointer<NativeType>, Pointer<NativeType>, int);

typedef FnCmemcmp = Int Function(Pointer<NativeType>, Pointer<NativeType>, Size_t);
typedef FnDARTmemcmp = int Function(Pointer<NativeType>, Pointer<NativeType>, int);

typedef FnCsodium_memzero = Pointer<Void> Function(Pointer<NativeType>, Size_t);
typedef FnDARTsodium_memzero = Pointer<Void> Function(Pointer<NativeType>, int);

typedef FnCtorx_fn_read = Void Function(Int);
typedef FnDARTtorx_fn_read = void Function(int);

typedef FnCtorx_fn_write = Void Function(Int);
typedef FnDARTtorx_fn_write = void Function(int);

typedef FnCtorx_fn_unlock = Void Function(Int);
typedef FnDARTtorx_fn_unlock = void Function(int);

typedef FnCerror_simple = Void Function(Int, Pointer<Utf8>);
typedef FnDARTerror_simple = void Function(int, Pointer<Utf8>);

typedef FnCgetter_length = Uint32 Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_length = int Function(int, int, int, int);

typedef FnCgetter_string = Pointer<Utf8> Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_string = Pointer<Utf8> Function(int, int, int, int);

typedef FnCgetter_group_id = Pointer<Uint8> Function(Int);
typedef FnDARTgetter_group_id = Pointer<Uint8> Function(int);

typedef FnCgroup_access = Pointer<Void> Function(Int, Size_t);
typedef FnDARTgroup_access = Pointer<Void> Function(int, int);

typedef FnCgroup_get_next = Pointer<Void> Function(Pointer<Int>, Pointer<Int>, Pointer<NativeType>);
typedef FnDARTgroup_get_next = Pointer<Void> Function(Pointer<Int>, Pointer<Int>, Pointer<NativeType>);

typedef FnCgroup_get_prior = Pointer<Void> Function(Pointer<Int>, Pointer<Int>, Pointer<NativeType>);
typedef FnDARTgroup_get_prior = Pointer<Void> Function(Pointer<Int>, Pointer<Int>, Pointer<NativeType>);

typedef FnCgroup_get_index = Void Function(Pointer<Int>, Pointer<Int>, Int, Uint32);
typedef FnDARTgroup_get_index = void Function(Pointer<Int>, Pointer<Int>, int, int);

typedef FnCprotocol_access = Pointer<Void> Function(Int, Size_t);
typedef FnDARTprotocol_access = Pointer<Void> Function(int, int);

typedef FnCgetter_offset = Size_t Function(Pointer<Utf8>, Pointer<Utf8>);
typedef FnDARTgetter_offset = int Function(Pointer<Utf8>, Pointer<Utf8>);

typedef FnCgetter_size = Size_t Function(Pointer<Utf8>, Pointer<Utf8>);
typedef FnDARTgetter_size = int Function(Pointer<Utf8>, Pointer<Utf8>);

typedef FnCsetter = Void Function(Int, Int, Int, Size_t, Pointer<NativeType>, Size_t);
typedef FnDARTsetter = void Function(int, int, int, int, Pointer<NativeType>, int);

typedef FnCgetter_byte = UnsignedChar Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_byte = int Function(int, int, int, int);

typedef FnCgetter_array = Void Function(Pointer<NativeType>, Size_t, Int, Int, Int, Size_t);
typedef FnDARTgetter_array = void Function(Pointer<NativeType>, int, int, int, int, int);

typedef FnCgetter_int8 = Int8 Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_int8 = int Function(int, int, int, int);

typedef FnCgetter_int16 = Int16 Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_int16 = int Function(int, int, int, int);

typedef FnCgetter_int32 = Int32 Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_int32 = int Function(int, int, int, int);

typedef FnCgetter_int64 = Int64 Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_int64 = int Function(int, int, int, int);

typedef FnCgetter_uint8 = Uint8 Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_uint8 = int Function(int, int, int, int);

typedef FnCgetter_uint16 = Uint16 Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_uint16 = int Function(int, int, int, int);

typedef FnCgetter_uint32 = Uint32 Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_uint32 = int Function(int, int, int, int);

typedef FnCgetter_uint64 = Uint64 Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_uint64 = int Function(int, int, int, int);

typedef FnCgetter_int = Int Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_int = int Function(int, int, int, int);

typedef FnCgetter_time = Time_t Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_time = int Function(int, int, int, int);

typedef FnCsetter_group = Void Function(Int, Size_t, Pointer<NativeType>, Size_t);
typedef FnDARTsetter_group = void Function(int, int, Pointer<NativeType>, int);

typedef FnCgetter_group_int8 = Int8 Function(Int, Size_t);
typedef FnDARTgetter_group_int8 = int Function(int, int);

typedef FnCgetter_group_int16 = Int16 Function(Int, Size_t);
typedef FnDARTgetter_group_int16 = int Function(int, int);

typedef FnCgetter_group_int32 = Int32 Function(Int, Size_t);
typedef FnDARTgetter_group_int32 = int Function(int, int);

typedef FnCgetter_group_int64 = Int64 Function(Int, Size_t);
typedef FnDARTgetter_group_int64 = int Function(int, int);

typedef FnCgetter_group_uint8 = Uint8 Function(Int, Size_t);
typedef FnDARTgetter_group_uint8 = int Function(int, int);

typedef FnCgetter_group_uint16 = Uint16 Function(Int, Size_t);
typedef FnDARTgetter_group_uint16 = int Function(int, int);

typedef FnCgetter_group_uint32 = Uint32 Function(Int, Size_t);
typedef FnDARTgetter_group_uint32 = int Function(int, int);

typedef FnCgetter_group_uint64 = Uint64 Function(Int, Size_t);
typedef FnDARTgetter_group_uint64 = int Function(int, int);

typedef FnCgetter_group_int = Int Function(Int, Size_t);
typedef FnDARTgetter_group_int = int Function(int, int);

typedef FnCthreadsafe_write = Void Function(Pointer<NativeType>, Pointer<NativeType>, Pointer<NativeType>, Size_t);
typedef FnDARTthreadsafe_write = void Function(Pointer<NativeType>, Pointer<NativeType>, Pointer<NativeType>, int);

typedef FnCthreadsafe_read_int8 = Int8 Function(Pointer<NativeType>, Pointer<Int8>);
typedef FnDARTthreadsafe_read_int8 = int Function(Pointer<NativeType>, Pointer<Int8>);

typedef FnCthreadsafe_read_int16 = Int16 Function(Pointer<NativeType>, Pointer<Int16>);
typedef FnDARTthreadsafe_read_int16 = int Function(Pointer<NativeType>, Pointer<Int16>);

typedef FnCthreadsafe_read_int32 = Int32 Function(Pointer<NativeType>, Pointer<Int32>);
typedef FnDARTthreadsafe_read_int32 = int Function(Pointer<NativeType>, Pointer<Int32>);

typedef FnCthreadsafe_read_int64 = Int64 Function(Pointer<NativeType>, Pointer<Int64>);
typedef FnDARTthreadsafe_read_int64 = int Function(Pointer<NativeType>, Pointer<Int64>);

typedef FnCthreadsafe_read_uint8 = Uint8 Function(Pointer<NativeType>, Pointer<Uint8>);
typedef FnDARTthreadsafe_read_uint8 = int Function(Pointer<NativeType>, Pointer<Uint8>);

typedef FnCthreadsafe_read_uint16 = Uint16 Function(Pointer<NativeType>, Pointer<Uint16>);
typedef FnDARTthreadsafe_read_uint16 = int Function(Pointer<NativeType>, Pointer<Uint16>);

typedef FnCthreadsafe_read_uint32 = Uint32 Function(Pointer<NativeType>, Pointer<Uint32>);
typedef FnDARTthreadsafe_read_uint32 = int Function(Pointer<NativeType>, Pointer<Uint32>);

typedef FnCthreadsafe_read_uint64 = Uint64 Function(Pointer<NativeType>, Pointer<Uint64>);
typedef FnDARTthreadsafe_read_uint64 = int Function(Pointer<NativeType>, Pointer<Uint64>);

typedef FnCprotocol_lookup = Int Function(Uint16);
typedef FnDARTprotocol_lookup = int Function(int);

typedef FnCprotocol_registration = Int Function(Int16, Pointer<Utf8>, Pointer<Utf8>, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8);
typedef FnDARTprotocol_registration = int Function(int, Pointer<Utf8>, Pointer<Utf8>, int, int, int, int, int, int, int, int, int, int, int);

typedef FnCread_bytes = Pointer<Uint8> Function(Pointer<Size_t>, Pointer<Utf8>);
typedef FnDARTread_bytes = Pointer<Uint8> Function(Pointer<Size_t>, Pointer<Utf8>);

typedef FnCzero_pthread = Void Function(Pointer<NativeType>);
typedef FnDARTzero_pthread = void Function(Pointer<NativeType>);

typedef FnCsetcanceltype = Void Function(Int, Pointer<Int>);
typedef FnDARTsetcanceltype = void Function(int, Pointer<Int>);

typedef FnCtorx_debug_level = Int8 Function(Int8);
typedef FnDARTtorx_debug_level = int Function(int);

typedef FnCalign_uint16 = Uint16 Function(Pointer<NativeType>);
typedef FnDARTalign_uint16 = int Function(Pointer<NativeType>);

typedef FnCalign_uint32 = Uint32 Function(Pointer<NativeType>);
typedef FnDARTalign_uint32 = int Function(Pointer<NativeType>);

typedef FnCalign_uint64 = Uint64 Function(Pointer<NativeType>);
typedef FnDARTalign_uint64 = int Function(Pointer<NativeType>);

typedef FnCis_null = Int Function(Pointer<NativeType>, Size_t);
typedef FnDARTis_null = int Function(Pointer<NativeType>, int);

typedef FnCtorx_insecure_malloc = Pointer<Void> Function(Size_t);
typedef FnDARTtorx_insecure_malloc = Pointer<Void> Function(int);

typedef FnCtorx_free_simple = Void Function(Pointer<NativeType>);
typedef FnDARTtorx_free_simple = void Function(Pointer<NativeType>);

typedef FnCtorx_free = Void Function(Pointer<Pointer<NativeType>>);
typedef FnDARTtorx_free = void Function(Pointer<Pointer<NativeType>>);

typedef FnCtorx_secure_malloc = Pointer<Void> Function(Size_t);
typedef FnDARTtorx_secure_malloc = Pointer<Void> Function(int);

typedef FnCmessage_load_more = Int Function(Int);
typedef FnDARTmessage_load_more = int Function(int);

typedef FnCset_time = Void Function(Pointer<Time_t>, Pointer<Time_t>);
typedef FnDARTset_time = void Function(Pointer<Time_t>, Pointer<Time_t>);

typedef FnCmessage_time_string = Pointer<Utf8> Function(Int, Int);
typedef FnDARTmessage_time_string = Pointer<Utf8> Function(int, int);

typedef FnCfile_progress_string = Pointer<Utf8> Function(Int, Int);
typedef FnDARTfile_progress_string = Pointer<Utf8> Function(int, int);

typedef FnCcalculate_transferred = Uint64 Function(Int, Int);
typedef FnDARTcalculate_transferred = int Function(int, int);

typedef FnCvptoi = Int Function(Pointer<NativeType>);
typedef FnDARTvptoi = int Function(Pointer<NativeType>);

typedef FnCitovp = Pointer<Void> Function(Int);
typedef FnDARTitovp = Pointer<Void> Function(int);

typedef FnCset_n = Int Function(Int, Pointer<Utf8>);
typedef FnDARTset_n = int Function(int, Pointer<Utf8>);

typedef FnCset_g = Int Function(Int, Pointer<NativeType>);
typedef FnDARTset_g = int Function(int, Pointer<NativeType>);

typedef FnCset_f = Int Function(Int, Pointer<Utf8>, Size_t);
typedef FnDARTset_f = int Function(int, Pointer<Utf8>, int);

typedef FnCset_g_from_i = Int Function(Pointer<Uint32>, Int, Int);
typedef FnDARTset_g_from_i = int Function(Pointer<Uint32>, int, int);

typedef FnCset_f_from_i = Int Function(Pointer<Int>, Int, Int);
typedef FnDARTset_f_from_i = int Function(Pointer<Int>, int, int);

typedef FnCset_o = Int Function(Int, Int, Int);
typedef FnDARTset_o = int Function(int, int, int);

typedef FnCset_r = Int Function(Int, Int, Int);
typedef FnDARTset_r = int Function(int, int, int);

typedef FnCrandom_string = Void Function(Pointer<Utf8>, Size_t);
typedef FnDARTrandom_string = void Function(Pointer<Utf8>, int);

typedef FnCtorrc_verify = Pointer<Utf8> Function(Pointer<Utf8>);
typedef FnDARTtorrc_verify = Pointer<Utf8> Function(Pointer<Utf8>);

typedef FnCtorrc_save = Void Function(Pointer<Utf8>);
typedef FnDARTtorrc_save = void Function(Pointer<Utf8>);

typedef FnCwhich = Pointer<Utf8> Function(Pointer<Utf8>);
typedef FnDARTwhich = Pointer<Utf8> Function(Pointer<Utf8>);

typedef FnCtorx_allocation_len = Uint32 Function(Pointer<NativeType>);
typedef FnDARTtorx_allocation_len = int Function(Pointer<NativeType>);

typedef FnCtorx_realloc = Pointer<Void> Function(Pointer<NativeType>, Size_t);
typedef FnDARTtorx_realloc = Pointer<Void> Function(Pointer<NativeType>, int);

typedef FnCrefined_list = Pointer<Int> Function(Pointer<Int>, Uint8, Int, Pointer<Utf8>); // free required
typedef FnDARTrefined_list = Pointer<Int> Function(Pointer<Int>, int, int, Pointer<Utf8>);

typedef FnCrandport = Uint16 Function(Uint16);
typedef FnDARTrandport = int Function(int);

typedef FnCstart_tor = Void Function();
typedef FnDARTstart_tor = void Function();

typedef FnCb64_decoded_size = Size_t Function(Pointer<Utf8>);
typedef FnDARTb64_decoded_size = int Function(Pointer<Utf8>);

typedef FnCb64_decode = Size_t Function(Pointer<Uint8>, Size_t, Pointer<Utf8>); // caller must allocate space
typedef FnDARTb64_decode = int Function(Pointer<Uint8>, int, Pointer<Utf8>);

typedef FnCb64_encode = Pointer<Utf8> Function(Pointer<NativeType>, Size_t); // torx_free required
typedef FnDARTb64_encode = Pointer<Utf8> Function(Pointer<NativeType>, int);

typedef FnCinitial_keyed = Void Function();
typedef FnDARTinitial_keyed = void Function();

typedef FnCre_expand_callbacks = Void Function();
typedef FnDARTre_expand_callbacks = void Function();

typedef FnCset_last_message = Int Function(Pointer<Int>, Int, Int);
typedef FnDARTset_last_message = int Function(Pointer<Int>, int, int);

typedef FnCgroup_online = Int Function(Int);
typedef FnDARTgroup_online = int Function(int);

typedef FnCgroup_check_sig = Int Function(Int, Pointer<Utf8>, Uint32, Uint16, Pointer<Uint8>, Pointer<Utf8>);
typedef FnDARTgroup_check_sig = int Function(int, Pointer<Utf8>, int, int, Pointer<Uint8>, Pointer<Utf8>);

typedef FnCbroadcast_prep = Void Function(Pointer<Uint8>, Int);
typedef FnDARTbroadcast_prep = void Function(Pointer<Uint8>, int);

typedef FnCgroup_join = Int Function(Int, Pointer<Uint8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Uint8>);
typedef FnDARTgroup_join = int Function(int, Pointer<Uint8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Uint8>);

typedef FnCgroup_join_from_i = Int Function(Int, Int);
typedef FnDARTgroup_join_from_i = int Function(int, int);

typedef FnCgroup_generate = Int Function(Uint8, Pointer<Utf8>);
typedef FnDARTgroup_generate = int Function(int, Pointer<Utf8>);

typedef FnCinitial = Void Function();
typedef FnDARTinitial = void Function();

typedef FnCchange_password_start = Void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef FnDARTchange_password_start = void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);

typedef FnClogin_start = Void Function(Pointer<Utf8>);
typedef FnDARTlogin_start = void Function(Pointer<Utf8>);

typedef FnCcleanup_lib = Void Function(Int);
typedef FnDARTcleanup_lib = void Function(int);

typedef FnCtor_call = Pointer<Utf8> Function(Pointer<Utf8>);
typedef FnDARTtor_call = Pointer<Utf8> Function(Pointer<Utf8>);

typedef FnCtor_call_async = Void Function(Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>, Pointer<Utf8>);
typedef FnDARTtor_call_async = void Function(Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>, Pointer<Utf8>);

typedef FnConion_from_privkey = Pointer<Utf8> Function(Pointer<Utf8>);
typedef FnDARTonion_from_privkey = Pointer<Utf8> Function(Pointer<Utf8>);

typedef FnCtorxid_from_onion = Pointer<Utf8> Function(Pointer<Utf8>);
typedef FnDARTtorxid_from_onion = Pointer<Utf8> Function(Pointer<Utf8>);

typedef FnConion_from_torxid = Pointer<Utf8> Function(Pointer<Utf8>);
typedef FnDARTonion_from_torxid = Pointer<Utf8> Function(Pointer<Utf8>);

typedef FnCcustom_input = Int Function(Uint8, Pointer<Utf8>, Pointer<Utf8>);
typedef FnDARTcustom_input = int Function(int, Pointer<Utf8>, Pointer<Utf8>);

typedef FnCdelete_log = Void Function(Int);
typedef FnDARTdelete_log = void Function(int);

typedef FnCmessage_edit = Int Function(Int, Int, Pointer<Utf8>);
typedef FnDARTmessage_edit = int Function(int, int, Pointer<Utf8>);

typedef FnCsql_setting = Int Function(Int, Int, Pointer<Utf8>, Pointer<Utf8>, Size_t);
typedef FnDARTsql_setting = int Function(int, int, Pointer<Utf8>, Pointer<Utf8>, int);

typedef FnCsql_populate_setting = Void Function(Int);
typedef FnDARTsql_populate_setting = void Function(int);

typedef FnCsql_delete_setting = Int Function(Int, Int, Pointer<Utf8>);
typedef FnDARTsql_delete_setting = int Function(int, int, Pointer<Utf8>);

typedef FnCfile_is_active = Int Function(Int, Int);
typedef FnDARTfile_is_active = int Function(int, int);

typedef FnCfile_is_cancelled = Int Function(Int, Int);
typedef FnDARTfile_is_cancelled = int Function(int, int);

typedef FnCfile_is_complete = Int Function(Int, Int);
typedef FnDARTfile_is_complete = int Function(int, int);

typedef FnCfile_status_get = Int Function(Int, Int);
typedef FnDARTfile_status_get = int Function(int, int);

typedef FnCpeer_save = Int Function(Pointer<Utf8>, Pointer<Utf8>);
typedef FnDARTpeer_save = int Function(Pointer<Utf8>, Pointer<Utf8>);

typedef FnCpeer_accept = Void Function(Int);
typedef FnDARTpeer_accept = void Function(int);

typedef FnCchange_nick = Void Function(Int, Pointer<Utf8>);
typedef FnDARTchange_nick = void Function(int, Pointer<Utf8>);

typedef FnCget_file_size = Uint64 Function(Pointer<Utf8>);
typedef FnDARTget_file_size = int Function(Pointer<Utf8>);

typedef FnCdestroy_file = Void Function(Pointer<Utf8>);
typedef FnDARTdestroy_file = void Function(Pointer<Utf8>);

typedef FnCcustom_input_file = Pointer<Utf8> Function(Pointer<Utf8>);
typedef FnDARTcustom_input_file = Pointer<Utf8> Function(Pointer<Utf8>);

typedef FnCtakedown_onion = Void Function(Int, Int);
typedef FnDARTtakedown_onion = void Function(int, int);

typedef FnCblock_peer = Void Function(Int);
typedef FnDARTblock_peer = void Function(int);

typedef FnCmessage_resend = Int Function(Int, Int);
typedef FnDARTmessage_resend = int Function(int, int);

typedef FnCmessage_send_select = Int Function(Uint32, Pointer<Int>, Uint16, Pointer<NativeType>, Uint32);
typedef FnDARTmessage_send_select = int Function(int, Pointer<Int>, int, Pointer<NativeType>, int);

typedef FnCmessage_send = Int Function(Int, Uint16, Pointer<NativeType>, Uint32);
typedef FnDARTmessage_send = int Function(int, int, Pointer<NativeType>, int);

typedef FnCmessage_extra = Void Function(Int, Int, Pointer<NativeType>, Uint32);
typedef FnDARTmessage_extra = void Function(int, int, Pointer<NativeType>, int);

typedef FnCkill_code = Void Function(Int, Pointer<Utf8>);
typedef FnDARTkill_code = void Function(int, Pointer<Utf8>);

typedef FnCfile_set_path = Void Function(Int, Int, Pointer<Utf8>);
typedef FnDARTfile_set_path = void Function(int, int, Pointer<Utf8>);

typedef FnCfile_accept = Void Function(Int, Int);
typedef FnDARTfile_accept = void Function(int, int);

typedef FnCfile_cancel = Void Function(Int, Int);
typedef FnDARTfile_cancel = void Function(int, int);

typedef FnCfile_send = Int Function(Int, Pointer<Utf8>);
typedef FnDARTfile_send = int Function(int, Pointer<Utf8>);

typedef FnCtorx_events = Pointer<Void> Function(Pointer<NativeType>);
typedef FnDARTtorx_events = Pointer<Void> Function(Pointer<NativeType>);

typedef FnCgenerate_onion = Int Function(Uint8, Pointer<Utf8>, Pointer<Utf8>);
typedef FnDARTgenerate_onion = int Function(int, Pointer<Utf8>, Pointer<Utf8>);

typedef FnCcpucount = Int Function();
typedef FnDARTcpucount = int Function();

typedef FnCutf8_valid = Uint8 Function(Pointer<NativeType>, Size_t);
typedef FnDARTutf8_valid = int Function(Pointer<NativeType>, int);

typedef FnCbase32_encode = Size_t Function(Pointer<Uint8>, Pointer<Uint8>, Size_t);
typedef FnDARTbase32_encode = int Function(Pointer<Uint8>, Pointer<Uint8>, int);

typedef FnCbase32_decode = Pointer<Uint8> Function(Pointer<Utf8>, Size_t, Pointer<NativeType>);
typedef FnDARTbase32_decode = Pointer<Uint8> Function(Pointer<Utf8>, int, Pointer<NativeType>);

typedef FnCqr_bool = Pointer<Void> Function(Pointer<Utf8>, Size_t); // returns struct qr_data *
typedef FnDARTqr_bool = Pointer<Void> Function(Pointer<Utf8>, int); // returns struct qr_data *

typedef FnCqr_utf8 = Pointer<Utf8> Function(Pointer<NativeType>);
typedef FnDARTqr_utf8 = Pointer<Utf8> Function(Pointer<NativeType>);

typedef FnCreturn_png = Pointer<Void> Function(Pointer<Size_t>, Pointer<NativeType>);
typedef FnDARTreturn_png = Pointer<Void> Function(Pointer<Size_t>, Pointer<NativeType>);

typedef FnCwrite_bytes = Size_t Function(Pointer<Utf8>, Pointer<NativeType>, Size_t);
typedef FnDARTwrite_bytes = int Function(Pointer<Utf8>, Pointer<NativeType>, int);
/*
typedef FnCgetter_call_union = types Function(Int, Int, Int, Size_t, Size_t);
typedef FnDARTgetter_call_union = types Function(int, int, int, int, int);

final class types extends Union {
  @Int()
  external int Int;

  @Time_t()
  external int time;

  @Size()
  external int size;

  @Uint8()
  external int uint8;

  @Uint16()
  external int uint16;

  @Uint32()
  external int uint32;

  @Uint64()
  external int uint64;

  @Int8()
  external int int8;

  @Int16()
  external int int16;

  @Int32()
  external int int32;

  @Int64()
  external int int64;
}
  static final getter_call_union = dynamicLibrary.lookupFunction<FnCgetter_call_union, FnDARTgetter_call_union>('getter_call_union');
*/

typedef FnCgetter_call_uint8 = Uint8 Function(Int, Int, Int, Size_t);
typedef FnDARTgetter_call_uint8 = int Function(int, int, int, int);

typedef FnCgetter_call_time = Time_t Function(Int, Int, Int, Size);
typedef FnDARTgetter_call_time = int Function(int, int, int, int);

typedef FnCcall_recipient_list = Pointer<Int> Function(Pointer<Uint32>, Int, Int);
typedef FnDARTcall_recipient_list = Pointer<Int> Function(Pointer<Uint32>, int, int);

typedef FnCcall_participant_list = Pointer<Int> Function(Pointer<Uint32>, Int, Int);
typedef FnDARTcall_participant_list = Pointer<Int> Function(Pointer<Uint32>, int, int);

typedef FnCcall_participant_count = Int Function(Int, Int);
typedef FnDARTcall_participant_count = int Function(int, int);

typedef FnCcall_start = Int Function(Int);
typedef FnDARTcall_start = int Function(int);

typedef FnCcall_toggle_mic = Void Function(Int, Int, Int);
typedef FnDARTcall_toggle_mic = void Function(int, int, int);

typedef FnCcall_toggle_speaker = Void Function(Int, Int, Int);
typedef FnDARTcall_toggle_speaker = void Function(int, int, int);

typedef FnCcall_join = Void Function(Int, Int);
typedef FnDARTcall_join = void Function(int, int);

typedef FnCcall_ignore = Void Function(Int, Int);
typedef FnDARTcall_ignore = void Function(int, int);

typedef FnCcall_leave = Void Function(Int, Int);
typedef FnDARTcall_leave = void Function(int, int);

typedef FnCcall_leave_all_except = Void Function(Int, Int);
typedef FnDARTcall_leave_all_except = void Function(int, int);

typedef FnCcall_mute_all_except = Void Function(Int, Int);
typedef FnDARTcall_mute_all_except = void Function(int, int);

typedef FnCaudio_cache_retrieve = Pointer<Uint8> Function(Pointer<Time_t>, Pointer<Time_t>, Pointer<Uint32>, Int);
typedef FnDARTaudio_cache_retrieve = Pointer<Uint8> Function(Pointer<Time_t>, Pointer<Time_t>, Pointer<Uint32>, int);

typedef FnCrecord_cache_clear = Int Function(Int);
typedef FnDARTrecord_cache_clear = int Function(int);

typedef FnCrecord_cache_add = Int Function(Int, Int, Uint32, Uint32, Pointer<Uint8>, Uint32);
typedef FnDARTrecord_cache_add = int Function(int, int, int, int, Pointer<Uint8>, int);

typedef FnCset_s = Int Function(Pointer<Uint8>);
typedef FnDARTset_s = int Function(Pointer<Uint8>);

typedef FnCsticker_save = Void Function(Int);
typedef FnDARTsticker_save = void Function(int);

typedef FnCsticker_delete = Void Function(Int);
typedef FnDARTsticker_delete = void Function(int);

typedef FnCsticker_register = Int Function(Pointer<Uint8>, Size);
typedef FnDARTsticker_register = int Function(Pointer<Uint8>, int);

typedef FnCsticker_retrieve_saved = Uint8 Function(Int);
typedef FnDARTsticker_retrieve_saved = int Function(int);

typedef FnCsticker_retrieve_checksum = Pointer<Uint8> Function(Int);
typedef FnDARTsticker_retrieve_checksum = Pointer<Uint8> Function(int);

typedef FnCsticker_retrieve_data = Pointer<Uint8> Function(Pointer<Size>, Int);
typedef FnDARTsticker_retrieve_data = Pointer<Uint8> Function(Pointer<Size>, int);

typedef FnCsticker_retrieve_count = Uint32 Function();
typedef FnDARTsticker_retrieve_count = int Function();

typedef FnCsticker_offload = Void Function(Int);
typedef FnDARTsticker_offload = void Function(int);

typedef FnCsticker_offload_saved = Void Function();
typedef FnDARTsticker_offload_saved = void Function();

void register_callbacks() {
  // WARNING: DO NOT USE ERROR MESSAGES HERE. Only print/printf.
  if (callbacks_registered) {
    return;
  }
  callbacks_registered = true;
  printf("SINGLETON CHECKER -------> ${Callbacks().hashCode} ${Callbacks().initialize_n_cb_ui.hashCode}"); // Should be the same across lifecycle, which it is not
  torx.initialize_n_setter(NativeCallable<FnCinitialize_n_cb>.listener(Callbacks().initialize_n_cb_ui).nativeFunction);
  torx.initialize_i_setter(NativeCallable<FnCinitialize_i_cb>.listener(Callbacks().initialize_i_cb_ui).nativeFunction);
  torx.initialize_f_setter(NativeCallable<FnCinitialize_f_cb>.listener(Callbacks().initialize_f_cb_ui).nativeFunction);
  torx.initialize_g_setter(NativeCallable<FnCinitialize_g_cb>.listener(Callbacks().initialize_g_cb_ui).nativeFunction);
  torx.shrinkage_setter(NativeCallable<FnCshrinkage_cb>.listener(Callbacks().shrinkage_cb_ui).nativeFunction);
  torx.expand_file_struc_setter(NativeCallable<FnCexpand_file_struc_cb>.listener(Callbacks().expand_file_struc_cb_ui).nativeFunction);
  torx.expand_message_struc_setter(NativeCallable<FnCexpand_message_struc_cb>.listener(Callbacks().expand_message_struc_cb_ui).nativeFunction);
  torx.expand_peer_struc_setter(NativeCallable<FnCexpand_peer_struc_cb>.listener(Callbacks().expand_peer_struc_cb_ui).nativeFunction);
  torx.expand_group_struc_setter(NativeCallable<FnCexpand_group_struc_cb>.listener(Callbacks().expand_group_struc_cb_ui).nativeFunction);
  torx.transfer_progress_setter(NativeCallable<FnCtransfer_progress_cb>.listener(Callbacks().transfer_progress_cb_ui).nativeFunction);
  torx.change_password_setter(NativeCallable<FnCchange_password_cb>.listener(Callbacks().change_password_cb_ui).nativeFunction);
  torx.incoming_friend_request_setter(NativeCallable<FnCincoming_friend_request_cb>.listener(Callbacks().incoming_friend_request_cb_ui).nativeFunction);
  torx.onion_deleted_setter(NativeCallable<FnConion_deleted_cb>.listener(Callbacks().onion_deleted_cb_ui).nativeFunction);
  torx.peer_online_setter(NativeCallable<FnCpeer_online_cb>.listener(Callbacks().peer_online_cb_ui).nativeFunction);
  torx.peer_offline_setter(NativeCallable<FnCpeer_offline_cb>.listener(Callbacks().peer_offline_cb_ui).nativeFunction);
  torx.peer_new_setter(NativeCallable<FnCpeer_new_cb>.listener(Callbacks().peer_new_cb_ui).nativeFunction);
  torx.onion_ready_setter(NativeCallable<FnConion_ready_cb>.listener(Callbacks().onion_ready_cb_ui).nativeFunction);
  torx.tor_log_setter(NativeCallable<FnCtor_log_cb>.listener(Callbacks().tor_log_cb_ui).nativeFunction);
  torx.error_setter(NativeCallable<FnCerror_cb>.listener(Callbacks().error_cb_ui).nativeFunction);
  torx.fatal_setter(NativeCallable<FnCfatal_cb>.listener(Callbacks().fatal_cb_ui).nativeFunction);
  torx.custom_setting_setter(NativeCallable<FnCcustom_setting_cb>.listener(Callbacks().custom_setting_cb_ui).nativeFunction);
  torx.message_new_setter(NativeCallable<FnCmessage_new_cb>.listener(Callbacks().message_new_cb_ui).nativeFunction);
  torx.message_modified_setter(NativeCallable<FnCmessage_modified_cb>.listener(Callbacks().message_modified_cb_ui).nativeFunction);
  torx.message_deleted_setter(NativeCallable<FnCmessage_deleted_cb>.listener(Callbacks().message_deleted_cb_ui).nativeFunction);
  torx.message_extra_setter(NativeCallable<FnCmessage_extra_cb>.listener(Callbacks().message_extra_cb_ui).nativeFunction);
  torx.message_more_setter(NativeCallable<FnCmessage_more_cb>.listener(Callbacks().message_more_cb_ui).nativeFunction);
  torx.login_setter(NativeCallable<FnClogin_cb>.listener(Callbacks().login_cb_ui).nativeFunction);
  torx.peer_loaded_setter(NativeCallable<FnCpeer_loaded_cb>.listener(Callbacks().peer_loaded_cb_ui).nativeFunction);
  torx.cleanup_setter(NativeCallable<FnCcleanup_cb>.listener(Callbacks().cleanup_cb_ui).nativeFunction);
  torx.stream_setter(NativeCallable<FnCstream_cb>.listener(Callbacks().stream_cb_ui).nativeFunction);
  torx.initialize_peer_call_setter(NativeCallable<FnCinitialize_peer_call_cb>.listener(Callbacks().initialize_peer_call_cb_ui).nativeFunction);
  torx.expand_call_struc_setter(NativeCallable<FnCexpand_call_struc_cb>.listener(Callbacks().expand_call_struc_cb_ui).nativeFunction);
  torx.call_update_setter(NativeCallable<FnCcall_update_cb>.listener(Callbacks().call_update_cb_ui).nativeFunction);
  torx.audio_cache_add_setter(NativeCallable<FnCaudio_cache_add_cb>.listener(Callbacks().audio_cache_add_cb_ui).nativeFunction);
}

String getPath() {
//  var currentDir = Directory.current.absolute.path;
  var libTorxPath = 'libtorx.so'; // CMakeLists.txt is appending a d here for unknown reason. Might indicate debug symbols.
  if (Platform.isWindows) {
    libTorxPath = 'libtorx.dll';
  } else if (Platform.isMacOS) {
    libTorxPath = 'libtorx.dylib';
  }
  return libTorxPath;
//  return currentDir+libTorxPath;
}

void set_setting_string(int force_cleartext, int peer_index, String name, String value) {
  Pointer<Utf8> setting_name = name.toNativeUtf8(); // free'd by calloc.free
  Pointer<Utf8> setting_value = value.toNativeUtf8(); // free'd by calloc.free
  torx.sql_setting(force_cleartext, peer_index, setting_name, setting_value, setting_value.length);
  calloc.free(setting_name);
  setting_name = nullptr;
  calloc.free(setting_value);
  setting_value = nullptr;
}

void set_torrc(String contents) {
  Pointer<Utf8> contents_p = contents.toNativeUtf8(); // free'd by calloc.free // 10.0.2.2 is alias for emulator's host OS 127.0.0.1
  torx.torrc_save(contents_p);
  calloc.free(contents_p);
  contents_p = nullptr;
}

int offsetof(String list, String member) {
  Pointer<Utf8> list_p = list.toNativeUtf8(); // free'd by calloc.free
  Pointer<Utf8> member_p = member.toNativeUtf8(); // free'd by calloc.free
  int offset = torx.getter_offset(list_p, member_p);
  calloc.free(list_p);
  list_p = nullptr;
  calloc.free(member_p);
  member_p = nullptr;
//  printf("Offset: $list $member $offset");
  return offset;
}

Uint8List getter_array(int size, int n, int i, int f, int offset) {
  // WARNING: This function lacks safety checks
  Pointer<Uint8> array = torx.torx_secure_malloc(size) as Pointer<Uint8>; // free'd by torx_free
  torx.getter_array(array, size, n, i, f, offset);
  Uint8List list = array.asTypedList(size).sublist(0);
  torx.torx_free_simple(array);
  array = nullptr;
  return list;
}

Uint8List getter_bytes(int n, int i, int f, int offset) {
  Pointer<Uint8> pointer = torx.getter_string(n, i, f, offset) as Pointer<Uint8>; // free'd by torx_free
  int len = torx.torx_allocation_len(pointer);
  if (pointer != nullptr) {
    Uint8List list = pointer.asTypedList(len).sublist(0);
    torx.torx_free_simple(pointer);
    pointer = nullptr;
    return list;
  }
  return Uint8List(0);
}

Uint8List getter_audio(int n, int i) {
  int p_iter = torx.getter_int(n, i, -1, offsetof("message", "p_iter"));
  if (p_iter < 0) return Uint8List(0);
  Pointer<Uint8> pointer = torx.getter_string(n, i, -1, offsetof("message", "message")) as Pointer<Uint8>; // free'd by torx_free
  if (pointer != nullptr) {
    int null_terminated_len = protocol_int(p_iter, "null_terminated_len");
    int date_len = protocol_int(p_iter, "date_len");
    int signature_len = protocol_int(p_iter, "signature_len");
    int audio_len = torx.torx_allocation_len(pointer) - 4 - (null_terminated_len + date_len + signature_len);
    Uint8List list = pointer.asTypedList(4 + audio_len).sublist(4, audio_len + 4);
    torx.torx_free_simple(pointer);
    pointer = nullptr;
    return list;
  }
  return Uint8List(0);
}

String getter_string(int n, int i, int f, int offset) {
  String ret = "";
//  printf("Getter_string: $n $i $f $offset");
  Pointer<Utf8> pointer = torx.getter_string(n, i, f, offset); // free'd by torx_free
  if (pointer != nullptr) {
    ret = pointer.toDartString();
    torx.torx_free_simple(pointer);
    pointer = nullptr;
  }
  return ret;
}

List<int> refined_list(int owner, int peer_status, String search) {
  Pointer<Int> len_p = torx.torx_insecure_malloc(8) as Pointer<Int>; // free'd by torx_free // 4 is wide enough, could be 8, should be sizeof, meh.
  Pointer<Utf8> search_p = nullptr;
  if (search.isNotEmpty) search_p = search.toNativeUtf8(); // free'd by calloc.free
  Pointer<Int> arrayN = torx.refined_list(len_p, owner, peer_status, search_p); // free'd by torx_free
  if (search_p != nullptr) {
    calloc.free(search_p);
    search_p = nullptr;
  }
  int len = len_p.value;
  torx.torx_free_simple(len_p);
  len_p = nullptr;
  List<int> list = [];
  for (int iter = 0; iter < len; iter++) {
    list.add(arrayN[iter]);
  }
  torx.torx_free_simple(arrayN);
  arrayN = nullptr;
  return list;
}

List<int> call_recipient_list(int call_n, int call_c) {
  Pointer<Uint32> len_p = torx.torx_insecure_malloc(4) as Pointer<Uint32>; // free'd by torx_free
  Pointer<Int> pointer = torx.call_recipient_list(len_p, call_n, call_c);
  List<int> list = [];
  if (pointer != nullptr) {
    for (int iter = 0; iter < len_p.value; iter++) {
      list.add(pointer[iter]);
    }
    torx.torx_free_simple(pointer);
    pointer = nullptr;
  }
  torx.torx_free_simple(len_p);
  len_p = nullptr;
  return list;
}

List<int> call_participant_list(int call_n, int call_c) {
  Pointer<Uint32> len_p = torx.torx_insecure_malloc(4) as Pointer<Uint32>; // free'd by torx_free
  Pointer<Int> pointer = torx.call_participant_list(len_p, call_n, call_c);
  List<int> list = [];
  if (pointer != nullptr) {
    for (int iter = 0; iter < len_p.value; iter++) {
      list.add(pointer[iter]);
    }
    torx.torx_free_simple(pointer);
    pointer = nullptr;
  }
  torx.torx_free_simple(len_p);
  len_p = nullptr;
  return list;
}

Uint8List audio_cache_retrieve(int participant_n) {
  Pointer<Uint32> len_p = torx.torx_insecure_malloc(4) as Pointer<Uint32>; // free'd by torx_free
  Pointer<Uint8> pointer = torx.audio_cache_retrieve(nullptr, nullptr, len_p, participant_n);
  int len = len_p.value;
  torx.torx_free_simple(len_p);
  len_p = nullptr;
  if (pointer != nullptr) {
    Uint8List list = pointer.asTypedList(len).sublist(0);
    torx.torx_free_simple(pointer);
    pointer = nullptr;
    return list;
  }
  return Uint8List(0);
}

int get_file_size(String file_path) {
  Pointer<Utf8> file_path_p = file_path.toNativeUtf8();
  int size = torx.get_file_size(file_path_p);
  calloc.free(file_path_p);
  file_path_p = nullptr;
  return size;
}

String protocol_string(int p_iter, int offset) {
  if (p_iter < 0) {
    error(0, "Negative p_iter passed to protocol_string. Coding error. Report to UI devs.");
    return "";
  }
  String ret;
  torx.pthread_rwlock_rdlock(torx.mutex_protocols); // 🟧
  Pointer<Utf8> pointer = torx.protocol_access(p_iter, offset) as Pointer<Utf8>; // DO NOT FREE
  if (pointer != nullptr) {
    ret = pointer.toDartString();
  } else {
    ret = "";
  }
  torx.pthread_rwlock_unlock(torx.mutex_protocols); // 🟩
  return ret;
}

int protocol_int(int p_iter, String member) {
  // Returns a member value from the specific p_iter. Note: Cannot return an error if p_iter is -1. Just have to let the program die in protocol_access.
  Pointer<Utf8> parent_p = "protocols".toNativeUtf8(); // free'd by calloc.free
  Pointer<Utf8> member_p = member.toNativeUtf8(); // free'd by calloc.free
  int offset = torx.getter_offset(parent_p, member_p);
  int size = torx.getter_size(parent_p, member_p);
  calloc.free(parent_p);
  parent_p = nullptr;
  calloc.free(member_p);
  member_p = nullptr;
  int value = 0;
  if (size == 1) {
    torx.pthread_rwlock_rdlock(torx.mutex_protocols); // 🟧
    Pointer<Uint8> pointer = torx.protocol_access(p_iter, offset) as Pointer<Uint8>; // DO NOT FREE
    value = pointer.value;
    torx.pthread_rwlock_unlock(torx.mutex_protocols); // 🟩
  } else if (size == 2) {
    torx.pthread_rwlock_rdlock(torx.mutex_protocols); // 🟧
    Pointer<Uint16> pointer = torx.protocol_access(p_iter, offset) as Pointer<Uint16>; // DO NOT FREE
    value = pointer.value;
    torx.pthread_rwlock_unlock(torx.mutex_protocols); // 🟩
  } else if (size == 4) {
    torx.pthread_rwlock_rdlock(torx.mutex_protocols); // 🟧
    Pointer<Uint32> pointer = torx.protocol_access(p_iter, offset) as Pointer<Uint32>; // DO NOT FREE
    value = pointer.value;
    torx.pthread_rwlock_unlock(torx.mutex_protocols); // 🟩
  } else {
    error(-1, "Bad times in protocol_int. Coding error. Report this.");
  }
  return value;
}

void error(int level, String message) {
  Pointer<Utf8> pointer = message.toNativeUtf8(); // free'd by calloc.free
  torx.error_simple(level, pointer);
  calloc.free(pointer);
  pointer = nullptr;
}

int protocol_registration(int protocol, String name, String description, int null_terminate, int date, int signature, int logged, int notifiable, int file_checksum, int file_offer,
    int exclusive_type, int utf8, int socket_swappable, int stream) {
  Pointer<Utf8> name_p = name.toNativeUtf8(); // free'd by calloc.free
  Pointer<Utf8> description_p = description.toNativeUtf8(); // free'd by calloc.free
  int ret = torx.protocol_registration(
      protocol, name_p, description_p, null_terminate, date, signature, logged, notifiable, file_checksum, file_offer, exclusive_type, utf8, socket_swappable, stream);
  calloc.free(name_p);
  name_p = nullptr;
  calloc.free(description_p);
  description_p = nullptr;
  return ret;
}

void destroy_file(String path) {
  Pointer<Utf8> pointer = path.toNativeUtf8();
  torx.destroy_file(pointer);
  calloc.free(pointer);
  pointer = nullptr;
}

class torx {
  // Functions
  static final initialize_n_setter = dynamicLibrary.lookupFunction<FnCinitialize_n_setter, FnDARTinitialize_n_setter>('initialize_n_setter');

  static final initialize_i_setter = dynamicLibrary.lookupFunction<FnCinitialize_i_setter, FnDARTinitialize_i_setter>('initialize_i_setter');

  static final initialize_f_setter = dynamicLibrary.lookupFunction<FnCinitialize_f_setter, FnDARTinitialize_f_setter>('initialize_f_setter');

  static final initialize_g_setter = dynamicLibrary.lookupFunction<FnCinitialize_g_setter, FnDARTinitialize_g_setter>('initialize_g_setter');

  static final shrinkage_setter = dynamicLibrary.lookupFunction<FnCshrinkage_setter, FnDARTshrinkage_setter>('shrinkage_setter');

  static final expand_file_struc_setter = dynamicLibrary.lookupFunction<FnCexpand_file_struc_setter, FnDARTexpand_file_struc_setter>('expand_file_struc_setter');

  static final expand_message_struc_setter = dynamicLibrary.lookupFunction<FnCexpand_message_struc_setter, FnDARTexpand_message_struc_setter>('expand_message_struc_setter');

  static final expand_peer_struc_setter = dynamicLibrary.lookupFunction<FnCexpand_peer_struc_setter, FnDARTexpand_peer_struc_setter>('expand_peer_struc_setter');

  static final expand_group_struc_setter = dynamicLibrary.lookupFunction<FnCexpand_group_struc_setter, FnDARTexpand_group_struc_setter>('expand_group_struc_setter');

  static final transfer_progress_setter = dynamicLibrary.lookupFunction<FnCtransfer_progress_setter, FnDARTtransfer_progress_setter>('transfer_progress_setter');

  static final change_password_setter = dynamicLibrary.lookupFunction<FnCchange_password_setter, FnDARTchange_password_setter>('change_password_setter');

  static final incoming_friend_request_setter =
      dynamicLibrary.lookupFunction<FnCincoming_friend_request_setter, FnDARTincoming_friend_request_setter>('incoming_friend_request_setter');

  static final onion_deleted_setter = dynamicLibrary.lookupFunction<FnConion_deleted_setter, FnDARTonion_deleted_setter>('onion_deleted_setter');

  static final peer_online_setter = dynamicLibrary.lookupFunction<FnCpeer_online_setter, FnDARTpeer_online_setter>('peer_online_setter');

  static final peer_offline_setter = dynamicLibrary.lookupFunction<FnCpeer_offline_setter, FnDARTpeer_offline_setter>('peer_offline_setter');

  static final peer_new_setter = dynamicLibrary.lookupFunction<FnCpeer_new_setter, FnDARTpeer_new_setter>('peer_new_setter');

  static final onion_ready_setter = dynamicLibrary.lookupFunction<FnConion_ready_setter, FnDARTonion_ready_setter>('onion_ready_setter');

  static final tor_log_setter = dynamicLibrary.lookupFunction<FnCtor_log_setter, FnDARTtor_log_setter>('tor_log_setter');

  static final error_setter = dynamicLibrary.lookupFunction<FnCerror_setter, FnDARTerror_setter>('error_setter');

  static final fatal_setter = dynamicLibrary.lookupFunction<FnCfatal_setter, FnDARTfatal_setter>('fatal_setter');

  static final custom_setting_setter = dynamicLibrary.lookupFunction<FnCcustom_setting_setter, FnDARTcustom_setting_setter>('custom_setting_setter');

  static final message_new_setter = dynamicLibrary.lookupFunction<FnCmessage_new_setter, FnDARTmessage_new_setter>('message_new_setter');

  static final message_modified_setter = dynamicLibrary.lookupFunction<FnCmessage_modified_setter, FnDARTmessage_modified_setter>('message_modified_setter');

  static final message_deleted_setter = dynamicLibrary.lookupFunction<FnCmessage_deleted_setter, FnDARTmessage_deleted_setter>('message_deleted_setter');

  static final message_extra_setter = dynamicLibrary.lookupFunction<FnCmessage_extra_setter, FnDARTmessage_extra_setter>('message_extra_setter');

  static final message_more_setter = dynamicLibrary.lookupFunction<FnCmessage_more_setter, FnDARTmessage_more_setter>('message_more_setter');

  static final login_setter = dynamicLibrary.lookupFunction<FnClogin_setter, FnDARTlogin_setter>('login_setter');

  static final peer_loaded_setter = dynamicLibrary.lookupFunction<FnCpeer_loaded_setter, FnDARTpeer_loaded_setter>('peer_loaded_setter');

  static final cleanup_setter = dynamicLibrary.lookupFunction<FnCcleanup_setter, FnDARTcleanup_setter>('cleanup_setter');

  static final stream_setter = dynamicLibrary.lookupFunction<FnCstream_setter, FnDARTstream_setter>('stream_setter');

  static final initialize_peer_call_setter = dynamicLibrary.lookupFunction<FnCinitialize_peer_call_setter, FnDARTinitialize_peer_call_setter>('initialize_peer_call_setter');

  static final expand_call_struc_setter = dynamicLibrary.lookupFunction<FnCexpand_call_struc_setter, FnDARTexpand_call_struc_setter>('expand_call_struc_setter');

  static final call_update_setter = dynamicLibrary.lookupFunction<FnCcall_update_setter, FnDARTcall_update_setter>('call_update_setter');

  static final audio_cache_add_setter = dynamicLibrary.lookupFunction<FnCaudio_cache_add_setter, FnDARTaudio_cache_add_setter>('audio_cache_add_setter');

  static final pthread_rwlock_rdlock = dynamicLibrary.lookupFunction<FnCpthread_rwlock_rdlock, FnDARTpthread_rwlock_rdlock>('pthread_rwlock_rdlock');

  static final pthread_rwlock_wrlock = dynamicLibrary.lookupFunction<FnCpthread_rwlock_wrlock, FnDARTpthread_rwlock_wrlock>('pthread_rwlock_wrlock');

  static final pthread_rwlock_unlock = dynamicLibrary.lookupFunction<FnCpthread_rwlock_unlock, FnDARTpthread_rwlock_unlock>('pthread_rwlock_unlock');

  static final memcpy = dynamicLibrary.lookupFunction<FnCmemcpy, FnDARTmemcpy>('memcpy');

  static final memcmp = dynamicLibrary.lookupFunction<FnCmemcmp, FnDARTmemcmp>('memcmp');

  static final sodium_memzero = dynamicLibrary.lookupFunction<FnCsodium_memzero, FnDARTsodium_memzero>('sodium_memzero');

  static final torx_fn_read = dynamicLibrary.lookupFunction<FnCtorx_fn_read, FnDARTtorx_fn_read>('torx_fn_read');

  static final torx_fn_write = dynamicLibrary.lookupFunction<FnCtorx_fn_write, FnDARTtorx_fn_write>('torx_fn_write');

  static final torx_fn_unlock = dynamicLibrary.lookupFunction<FnCtorx_fn_unlock, FnDARTtorx_fn_unlock>('torx_fn_unlock');

  static final error_simple = dynamicLibrary.lookupFunction<FnCerror_simple, FnDARTerror_simple>('error_simple');

  static final getter_length = dynamicLibrary.lookupFunction<FnCgetter_length, FnDARTgetter_length>('getter_length');

  static final getter_string = dynamicLibrary.lookupFunction<FnCgetter_string, FnDARTgetter_string>('getter_string');

  static final getter_group_id = dynamicLibrary.lookupFunction<FnCgetter_group_id, FnDARTgetter_group_id>('getter_group_id');

  static final group_access = dynamicLibrary.lookupFunction<FnCgroup_access, FnDARTgroup_access>('group_access');

  static final group_get_next = dynamicLibrary.lookupFunction<FnCgroup_get_next, FnDARTgroup_get_next>('group_get_next');

  static final group_get_prior = dynamicLibrary.lookupFunction<FnCgroup_get_prior, FnDARTgroup_get_prior>('group_get_prior');

  static final group_get_index = dynamicLibrary.lookupFunction<FnCgroup_get_index, FnDARTgroup_get_index>('group_get_index');

  static final protocol_access = dynamicLibrary.lookupFunction<FnCprotocol_access, FnDARTprotocol_access>('protocol_access');

  static final getter_offset = dynamicLibrary.lookupFunction<FnCgetter_offset, FnDARTgetter_offset>('getter_offset');

  static final getter_size = dynamicLibrary.lookupFunction<FnCgetter_size, FnDARTgetter_size>('getter_size');

  static final setter = dynamicLibrary.lookupFunction<FnCsetter, FnDARTsetter>('setter');

  static final getter_byte = dynamicLibrary.lookupFunction<FnCgetter_byte, FnDARTgetter_byte>('getter_byte');

  static final getter_array = dynamicLibrary.lookupFunction<FnCgetter_array, FnDARTgetter_array>('getter_array');

  static final getter_int8 = dynamicLibrary.lookupFunction<FnCgetter_int8, FnDARTgetter_int8>('getter_int8');

  static final getter_int16 = dynamicLibrary.lookupFunction<FnCgetter_int16, FnDARTgetter_int16>('getter_int16');

  static final getter_int32 = dynamicLibrary.lookupFunction<FnCgetter_int32, FnDARTgetter_int32>('getter_int32');

  static final getter_int64 = dynamicLibrary.lookupFunction<FnCgetter_int64, FnDARTgetter_int64>('getter_int64');

  static final getter_uint8 = dynamicLibrary.lookupFunction<FnCgetter_uint8, FnDARTgetter_uint8>('getter_uint8');

  static final getter_uint16 = dynamicLibrary.lookupFunction<FnCgetter_uint16, FnDARTgetter_uint16>('getter_uint16');

  static final getter_uint32 = dynamicLibrary.lookupFunction<FnCgetter_uint32, FnDARTgetter_uint32>('getter_uint32');

  static final getter_uint64 = dynamicLibrary.lookupFunction<FnCgetter_uint64, FnDARTgetter_uint64>('getter_uint64');

  static final getter_int = dynamicLibrary.lookupFunction<FnCgetter_int, FnDARTgetter_int>('getter_int');

  static final getter_time = dynamicLibrary.lookupFunction<FnCgetter_time, FnDARTgetter_time>('getter_time');

  static final setter_group = dynamicLibrary.lookupFunction<FnCsetter_group, FnDARTsetter_group>('setter_group');

  static final getter_group_int8 = dynamicLibrary.lookupFunction<FnCgetter_group_int8, FnDARTgetter_group_int8>('getter_group_int8');

  static final getter_group_int16 = dynamicLibrary.lookupFunction<FnCgetter_group_int16, FnDARTgetter_group_int16>('getter_group_int16');

  static final getter_group_int32 = dynamicLibrary.lookupFunction<FnCgetter_group_int32, FnDARTgetter_group_int32>('getter_group_int32');

  static final getter_group_int64 = dynamicLibrary.lookupFunction<FnCgetter_group_int64, FnDARTgetter_group_int64>('getter_group_int64');

  static final getter_group_uint8 = dynamicLibrary.lookupFunction<FnCgetter_group_uint8, FnDARTgetter_group_uint8>('getter_group_uint8');

  static final getter_group_uint16 = dynamicLibrary.lookupFunction<FnCgetter_group_uint16, FnDARTgetter_group_uint16>('getter_group_uint16');

  static final getter_group_uint32 = dynamicLibrary.lookupFunction<FnCgetter_group_uint32, FnDARTgetter_group_uint32>('getter_group_uint32');

  static final getter_group_uint64 = dynamicLibrary.lookupFunction<FnCgetter_group_uint64, FnDARTgetter_group_uint64>('getter_group_uint64');

  static final getter_group_int = dynamicLibrary.lookupFunction<FnCgetter_group_int, FnDARTgetter_group_int>('getter_group_int');

  static final threadsafe_write = dynamicLibrary.lookupFunction<FnCthreadsafe_write, FnDARTthreadsafe_write>('threadsafe_write');

  static final threadsafe_read_int8 = dynamicLibrary.lookupFunction<FnCthreadsafe_read_int8, FnDARTthreadsafe_read_int8>('threadsafe_read_int8');

  static final threadsafe_read_int16 = dynamicLibrary.lookupFunction<FnCthreadsafe_read_int16, FnDARTthreadsafe_read_int16>('threadsafe_read_int16');

  static final threadsafe_read_int32 = dynamicLibrary.lookupFunction<FnCthreadsafe_read_int32, FnDARTthreadsafe_read_int32>('threadsafe_read_int32');

  static final threadsafe_read_int64 = dynamicLibrary.lookupFunction<FnCthreadsafe_read_int64, FnDARTthreadsafe_read_int64>('threadsafe_read_int64');

  static final threadsafe_read_uint8 = dynamicLibrary.lookupFunction<FnCthreadsafe_read_uint8, FnDARTthreadsafe_read_uint8>('threadsafe_read_uint8');

  static final threadsafe_read_uint16 = dynamicLibrary.lookupFunction<FnCthreadsafe_read_uint16, FnDARTthreadsafe_read_uint16>('threadsafe_read_uint16');

  static final threadsafe_read_uint32 = dynamicLibrary.lookupFunction<FnCthreadsafe_read_uint32, FnDARTthreadsafe_read_uint32>('threadsafe_read_uint32');

  static final threadsafe_read_uint64 = dynamicLibrary.lookupFunction<FnCthreadsafe_read_uint64, FnDARTthreadsafe_read_uint64>('threadsafe_read_uint64');

  static final protocol_lookup = dynamicLibrary.lookupFunction<FnCprotocol_lookup, FnDARTprotocol_lookup>('protocol_lookup');

  static final protocol_registration = dynamicLibrary.lookupFunction<FnCprotocol_registration, FnDARTprotocol_registration>('protocol_registration');

  static final read_bytes = dynamicLibrary.lookupFunction<FnCread_bytes, FnDARTread_bytes>('read_bytes');

  static final zero_pthread = dynamicLibrary.lookupFunction<FnCzero_pthread, FnDARTzero_pthread>('zero_pthread');

  static final setcanceltype = dynamicLibrary.lookupFunction<FnCsetcanceltype, FnDARTsetcanceltype>('setcanceltype');

  static final torx_debug_level = dynamicLibrary.lookupFunction<FnCtorx_debug_level, FnDARTtorx_debug_level>('torx_debug_level');

  static final align_uint16 = dynamicLibrary.lookupFunction<FnCalign_uint16, FnDARTalign_uint16>('align_uint16');

  static final align_uint32 = dynamicLibrary.lookupFunction<FnCalign_uint32, FnDARTalign_uint32>('align_uint32');

  static final align_uint64 = dynamicLibrary.lookupFunction<FnCalign_uint64, FnDARTalign_uint64>('align_uint64');

  static final is_null = dynamicLibrary.lookupFunction<FnCis_null, FnDARTis_null>('is_null');

  static final torx_insecure_malloc = dynamicLibrary.lookupFunction<FnCtorx_insecure_malloc, FnDARTtorx_insecure_malloc>('torx_insecure_malloc');

  static final torx_free_simple = dynamicLibrary.lookupFunction<FnCtorx_free_simple, FnDARTtorx_free_simple>('torx_free_simple');

  static final torx_free = dynamicLibrary.lookupFunction<FnCtorx_free, FnDARTtorx_free>('torx_free');

  static final torx_secure_malloc = dynamicLibrary.lookupFunction<FnCtorx_secure_malloc, FnDARTtorx_secure_malloc>('torx_secure_malloc');

  static final message_load_more = dynamicLibrary.lookupFunction<FnCmessage_load_more, FnDARTmessage_load_more>('message_load_more');

  static final set_time = dynamicLibrary.lookupFunction<FnCset_time, FnDARTset_time>('set_time');

  static final message_time_string = dynamicLibrary.lookupFunction<FnCmessage_time_string, FnDARTmessage_time_string>('message_time_string');

  static final file_progress_string = dynamicLibrary.lookupFunction<FnCfile_progress_string, FnDARTfile_progress_string>('file_progress_string');

  static final calculate_transferred = dynamicLibrary.lookupFunction<FnCcalculate_transferred, FnDARTcalculate_transferred>('calculate_transferred');

  static final vptoi = dynamicLibrary.lookupFunction<FnCvptoi, FnDARTvptoi>('vptoi');

  static final itovp = dynamicLibrary.lookupFunction<FnCitovp, FnDARTitovp>('itovp');

  static final set_n = dynamicLibrary.lookupFunction<FnCset_n, FnDARTset_n>('set_n');

  static final set_g = dynamicLibrary.lookupFunction<FnCset_g, FnDARTset_g>('set_g');

  static final set_f = dynamicLibrary.lookupFunction<FnCset_f, FnDARTset_f>('set_f');

  static final set_g_from_i = dynamicLibrary.lookupFunction<FnCset_g_from_i, FnDARTset_g_from_i>('set_g_from_i');

  static final set_f_from_i = dynamicLibrary.lookupFunction<FnCset_f_from_i, FnDARTset_f_from_i>('set_f_from_i');

  static final set_o = dynamicLibrary.lookupFunction<FnCset_o, FnDARTset_o>('set_o');

  static final set_r = dynamicLibrary.lookupFunction<FnCset_r, FnDARTset_r>('set_r');

  static final random_string = dynamicLibrary.lookupFunction<FnCrandom_string, FnDARTrandom_string>('random_string');

  static final torrc_verify = dynamicLibrary.lookupFunction<FnCtorrc_verify, FnDARTtorrc_verify>('torrc_verify');

  static final torrc_save = dynamicLibrary.lookupFunction<FnCtorrc_save, FnDARTtorrc_save>('torrc_save');

  static final which = dynamicLibrary.lookupFunction<FnCwhich, FnDARTwhich>('which');

  static final torx_allocation_len = dynamicLibrary.lookupFunction<FnCtorx_allocation_len, FnDARTtorx_allocation_len>('torx_allocation_len');

  static final torx_realloc = dynamicLibrary.lookupFunction<FnCtorx_realloc, FnDARTtorx_realloc>('torx_realloc');

  static final refined_list = dynamicLibrary.lookupFunction<FnCrefined_list, FnDARTrefined_list>('refined_list');

  static final randport = dynamicLibrary.lookupFunction<FnCrandport, FnDARTrandport>('randport');

  static final start_tor = dynamicLibrary.lookupFunction<FnCstart_tor, FnDARTstart_tor>('start_tor');

  static final b64_decoded_size = dynamicLibrary.lookupFunction<FnCb64_decoded_size, FnDARTb64_decoded_size>('b64_decoded_size');

  static final b64_decode = dynamicLibrary.lookupFunction<FnCb64_decode, FnDARTb64_decode>('b64_decode');

  static final b64_encode = dynamicLibrary.lookupFunction<FnCb64_encode, FnDARTb64_encode>('b64_encode');

  static final initial_keyed = dynamicLibrary.lookupFunction<FnCinitial_keyed, FnDARTinitial_keyed>('initial_keyed');

  static final re_expand_callbacks = dynamicLibrary.lookupFunction<FnCre_expand_callbacks, FnDARTre_expand_callbacks>('re_expand_callbacks');

  static final set_last_message = dynamicLibrary.lookupFunction<FnCset_last_message, FnDARTset_last_message>('set_last_message');

  static final group_online = dynamicLibrary.lookupFunction<FnCgroup_online, FnDARTgroup_online>('group_online');

  static final group_check_sig = dynamicLibrary.lookupFunction<FnCgroup_check_sig, FnDARTgroup_check_sig>('group_check_sig');

  static final broadcast_prep = dynamicLibrary.lookupFunction<FnCbroadcast_prep, FnDARTbroadcast_prep>('broadcast_prep');

  static final group_join = dynamicLibrary.lookupFunction<FnCgroup_join, FnDARTgroup_join>('group_join');

  static final group_join_from_i = dynamicLibrary.lookupFunction<FnCgroup_join_from_i, FnDARTgroup_join_from_i>('group_join_from_i');

  static final group_generate = dynamicLibrary.lookupFunction<FnCgroup_generate, FnDARTgroup_generate>('group_generate');

  static final initial = dynamicLibrary.lookupFunction<FnCinitial, FnDARTinitial>('initial');

  static final change_password_start = dynamicLibrary.lookupFunction<FnCchange_password_start, FnDARTchange_password_start>('change_password_start');

  static final login_start = dynamicLibrary.lookupFunction<FnClogin_start, FnDARTlogin_start>('login_start');

  static final cleanup_lib = dynamicLibrary.lookupFunction<FnCcleanup_lib, FnDARTcleanup_lib>('cleanup_lib');

  static final tor_call = dynamicLibrary.lookupFunction<FnCtor_call, FnDARTtor_call>('tor_call');

  static final tor_call_async = dynamicLibrary.lookupFunction<FnCtor_call_async, FnDARTtor_call_async>('tor_call_async');

  static final onion_from_privkey = dynamicLibrary.lookupFunction<FnConion_from_privkey, FnDARTonion_from_privkey>('onion_from_privkey');

  static final torxid_from_onion = dynamicLibrary.lookupFunction<FnCtorxid_from_onion, FnDARTtorxid_from_onion>('torxid_from_onion');

  static final onion_from_torxid = dynamicLibrary.lookupFunction<FnConion_from_torxid, FnDARTonion_from_torxid>('onion_from_torxid');

  static final custom_input = dynamicLibrary.lookupFunction<FnCcustom_input, FnDARTcustom_input>('custom_input');

  static final delete_log = dynamicLibrary.lookupFunction<FnCdelete_log, FnDARTdelete_log>('delete_log');

  static final message_edit = dynamicLibrary.lookupFunction<FnCmessage_edit, FnDARTmessage_edit>('message_edit');

  static final sql_setting = dynamicLibrary.lookupFunction<FnCsql_setting, FnDARTsql_setting>('sql_setting');

  static final sql_populate_setting = dynamicLibrary.lookupFunction<FnCsql_populate_setting, FnDARTsql_populate_setting>('sql_populate_setting');

  static final sql_delete_setting = dynamicLibrary.lookupFunction<FnCsql_delete_setting, FnDARTsql_delete_setting>('sql_delete_setting');

  static final file_is_active = dynamicLibrary.lookupFunction<FnCfile_is_active, FnDARTfile_is_active>('file_is_active');

  static final file_is_cancelled = dynamicLibrary.lookupFunction<FnCfile_is_cancelled, FnDARTfile_is_cancelled>('file_is_cancelled');

  static final file_is_complete = dynamicLibrary.lookupFunction<FnCfile_is_complete, FnDARTfile_is_complete>('file_is_complete');

  static final file_status_get = dynamicLibrary.lookupFunction<FnCfile_status_get, FnDARTfile_status_get>('file_status_get');

  static final peer_save = dynamicLibrary.lookupFunction<FnCpeer_save, FnDARTpeer_save>('peer_save');

  static final peer_accept = dynamicLibrary.lookupFunction<FnCpeer_accept, FnDARTpeer_accept>('peer_accept');

  static final change_nick = dynamicLibrary.lookupFunction<FnCchange_nick, FnDARTchange_nick>('change_nick');

  static final get_file_size = dynamicLibrary.lookupFunction<FnCget_file_size, FnDARTget_file_size>('get_file_size');

  static final destroy_file = dynamicLibrary.lookupFunction<FnCdestroy_file, FnDARTdestroy_file>('destroy_file');

  static final custom_input_file = dynamicLibrary.lookupFunction<FnCcustom_input_file, FnDARTcustom_input_file>('custom_input_file');

  static final takedown_onion = dynamicLibrary.lookupFunction<FnCtakedown_onion, FnDARTtakedown_onion>('takedown_onion');

  static final block_peer = dynamicLibrary.lookupFunction<FnCblock_peer, FnDARTblock_peer>('block_peer');

  static final message_resend = dynamicLibrary.lookupFunction<FnCmessage_resend, FnDARTmessage_resend>('message_resend');

  static final message_send_select = dynamicLibrary.lookupFunction<FnCmessage_send_select, FnDARTmessage_send_select>('message_send_select');

  static final message_send = dynamicLibrary.lookupFunction<FnCmessage_send, FnDARTmessage_send>('message_send');

  static final message_extra = dynamicLibrary.lookupFunction<FnCmessage_extra, FnDARTmessage_extra>('message_extra');

  static final kill_code = dynamicLibrary.lookupFunction<FnCkill_code, FnDARTkill_code>('kill_code');

  static final file_set_path = dynamicLibrary.lookupFunction<FnCfile_set_path, FnDARTfile_set_path>('file_set_path');

  static final file_accept = dynamicLibrary.lookupFunction<FnCfile_accept, FnDARTfile_accept>('file_accept');

  static final file_cancel = dynamicLibrary.lookupFunction<FnCfile_cancel, FnDARTfile_cancel>('file_cancel');

  static final file_send = dynamicLibrary.lookupFunction<FnCfile_send, FnDARTfile_send>('file_send');

  static final torx_events = dynamicLibrary.lookupFunction<FnCtorx_events, FnDARTtorx_events>('torx_events');

  static final generate_onion = dynamicLibrary.lookupFunction<FnCgenerate_onion, FnDARTgenerate_onion>('generate_onion');

  static final cpucount = dynamicLibrary.lookupFunction<FnCcpucount, FnDARTcpucount>('cpucount');

  static final utf8_valid = dynamicLibrary.lookupFunction<FnCutf8_valid, FnDARTutf8_valid>('utf8_valid');

  static final base32_encode = dynamicLibrary.lookupFunction<FnCbase32_encode, FnDARTbase32_encode>('base32_encode');

  static final base32_decode = dynamicLibrary.lookupFunction<FnCbase32_decode, FnDARTbase32_decode>('base32_decode');

  static final qr_bool = dynamicLibrary.lookupFunction<FnCqr_bool, FnDARTqr_bool>('qr_bool');

  static final qr_utf8 = dynamicLibrary.lookupFunction<FnCqr_utf8, FnDARTqr_utf8>('qr_utf8');

  static final return_png = dynamicLibrary.lookupFunction<FnCreturn_png, FnDARTreturn_png>('return_png');

  static final write_bytes = dynamicLibrary.lookupFunction<FnCwrite_bytes, FnDARTwrite_bytes>('write_bytes');

  static final getter_call_uint8 = dynamicLibrary.lookupFunction<FnCgetter_call_uint8, FnDARTgetter_call_uint8>('getter_call_uint8');

  static final getter_call_time = dynamicLibrary.lookupFunction<FnCgetter_call_time, FnDARTgetter_call_time>('getter_call_time');

  static final call_recipient_list = dynamicLibrary.lookupFunction<FnCcall_recipient_list, FnDARTcall_recipient_list>('call_recipient_list');

  static final call_participant_list = dynamicLibrary.lookupFunction<FnCcall_participant_list, FnDARTcall_participant_list>('call_participant_list');

  static final call_participant_count = dynamicLibrary.lookupFunction<FnCcall_participant_count, FnDARTcall_participant_count>('call_participant_count');

  static final call_start = dynamicLibrary.lookupFunction<FnCcall_start, FnDARTcall_start>('call_start');

  static final call_toggle_mic = dynamicLibrary.lookupFunction<FnCcall_toggle_mic, FnDARTcall_toggle_mic>('call_toggle_mic');

  static final call_toggle_speaker = dynamicLibrary.lookupFunction<FnCcall_toggle_speaker, FnDARTcall_toggle_speaker>('call_toggle_speaker');

  static final call_join = dynamicLibrary.lookupFunction<FnCcall_join, FnDARTcall_join>('call_join');

  static final call_ignore = dynamicLibrary.lookupFunction<FnCcall_ignore, FnDARTcall_ignore>('call_ignore');

  static final call_leave = dynamicLibrary.lookupFunction<FnCcall_leave, FnDARTcall_leave>('call_leave');

  static final call_leave_all_except = dynamicLibrary.lookupFunction<FnCcall_leave_all_except, FnDARTcall_leave_all_except>('call_leave_all_except');

  static final call_mute_all_except = dynamicLibrary.lookupFunction<FnCcall_mute_all_except, FnDARTcall_mute_all_except>('call_mute_all_except');

  static final audio_cache_retrieve = dynamicLibrary.lookupFunction<FnCaudio_cache_retrieve, FnDARTaudio_cache_retrieve>('audio_cache_retrieve');

  static final record_cache_clear = dynamicLibrary.lookupFunction<FnCrecord_cache_clear, FnDARTrecord_cache_clear>('record_cache_clear');

  static final record_cache_add = dynamicLibrary.lookupFunction<FnCrecord_cache_add, FnDARTrecord_cache_add>('record_cache_add');

  static final set_s = dynamicLibrary.lookupFunction<FnCset_s, FnDARTset_s>('set_s');

  static final sticker_save = dynamicLibrary.lookupFunction<FnCsticker_save, FnDARTsticker_save>('sticker_save');

  static final sticker_delete = dynamicLibrary.lookupFunction<FnCsticker_delete, FnDARTsticker_delete>('sticker_delete');

  static final sticker_register = dynamicLibrary.lookupFunction<FnCsticker_register, FnDARTsticker_register>('sticker_register');

  static final sticker_retrieve_saved = dynamicLibrary.lookupFunction<FnCsticker_retrieve_saved, FnDARTsticker_retrieve_saved>('sticker_retrieve_saved');

  static final sticker_retrieve_checksum = dynamicLibrary.lookupFunction<FnCsticker_retrieve_checksum, FnDARTsticker_retrieve_checksum>('sticker_retrieve_checksum');

  static final sticker_retrieve_data = dynamicLibrary.lookupFunction<FnCsticker_retrieve_data, FnDARTsticker_retrieve_data>('sticker_retrieve_data');

  static final sticker_retrieve_count = dynamicLibrary.lookupFunction<FnCsticker_retrieve_count, FnDARTsticker_retrieve_count>('sticker_retrieve_count');

  static final sticker_offload = dynamicLibrary.lookupFunction<FnCsticker_offload, FnDARTsticker_offload>('sticker_offload');

  static final sticker_offload_saved = dynamicLibrary.lookupFunction<FnCsticker_offload_saved, FnDARTsticker_offload_saved>('sticker_offload_saved');

/* Pointers */
  // These are ONLY FOR SETTING. and require mutex wrapper. For reading, use threadsafe_read_global_
  static Pointer<Pointer<Utf8>> download_dir = dynamicLibrary.lookup('download_dir'); // utilized
  static Pointer<Pointer<Utf8>> tor_data_directory = dynamicLibrary.lookup('tor_data_directory'); // utilized
  static Pointer<Pointer<Utf8>> tor_location = dynamicLibrary.lookup('tor_location'); // utilized
  static Pointer<Pointer<Utf8>> snowflake_location = dynamicLibrary.lookup('snowflake_location'); // utilized
  static Pointer<Pointer<Utf8>> lyrebird_location = dynamicLibrary.lookup('lyrebird_location'); // utilized
  static Pointer<Pointer<Utf8>> conjure_location = dynamicLibrary.lookup('conjure_location'); // utilized
  static Pointer<Pointer<Utf8>> native_library_directory = dynamicLibrary.lookup('native_library_directory'); // utilized
  static Pointer<Pointer<Utf8>> working_dir = dynamicLibrary.lookup('working_dir'); // utilized

  /* Arrays */
  // These are ONLY FOR SETTING. and require mutex wrapper. For reading, use threadsafe_read_global_

  static Pointer<Uint8> stickers_save_all = dynamicLibrary.lookup('stickers_save_all'); // utilized
  static Pointer<Uint8> reduced_memory = dynamicLibrary.lookup('reduced_memory'); // utilized
  static Pointer<Uint8> global_log_messages = dynamicLibrary.lookup('global_log_messages'); // utilized
  static Pointer<Uint8> auto_resume_inbound = dynamicLibrary.lookup('auto_resume_inbound'); // utilized
  static Pointer<Uint8> auto_accept_mult = dynamicLibrary.lookup('auto_accept_mult'); // utilized
  static Pointer<Uint8> censored_region = dynamicLibrary.lookup('censored_region'); // utilized
  static Pointer<Uint8> shorten_torxids = dynamicLibrary.lookup('shorten_torxids'); // utilized
  static Pointer<Uint8> suffix_length = dynamicLibrary.lookup('suffix_length'); // utilized

  static Pointer<Uint32> sing_expiration_days = dynamicLibrary.lookup('sing_expiration_days'); // utilized
  static Pointer<Uint32> mult_expiration_days = dynamicLibrary.lookup('mult_expiration_days'); // utilized
  static Pointer<Uint32> global_threads = dynamicLibrary.lookup('global_threads'); // utilized
  static Pointer<Uint32> show_log_messages = dynamicLibrary.lookup('show_log_messages');

  // Confirmed to work. Pass directly to torx.pthread_rwlock_rdlock(mutex);
  static Pointer<Void> mutex_global_variable = dynamicLibrary.lookup('mutex_global_variable'); // utilized
  static Pointer<Void> mutex_protocols = dynamicLibrary.lookup('mutex_protocols'); // utilized

  // Store any data here and access it without mutex locks
  static Pointer<Pointer<Void>> ui_data = dynamicLibrary.lookup('ui_data');
}

/* // The following work (mutex confirmed working by not unlocking), do not delete, even if not using. Good examples. */
String threadsafe_read_global_string(String symbolName) {
  Pointer<Pointer<Utf8>> symbol = dynamicLibrary.lookup(symbolName);
  torx.pthread_rwlock_rdlock(torx.mutex_global_variable); // 🟧
  String ret;
  if (symbol[0] == nullptr) {
    ret = "";
  } else {
    ret = symbol[0].toDartString();
  }
  torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
  return ret;
}

int threadsafe_read_global_Uint8(String symbolName) {
  Pointer<Uint8> symbol = dynamicLibrary.lookup(symbolName);
  torx.pthread_rwlock_rdlock(torx.mutex_global_variable); // 🟧
  int ret = symbol.value;
  torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
  return ret;
}

int threadsafe_read_global_Uint16(String symbolName) {
  Pointer<Uint16> symbol = dynamicLibrary.lookup(symbolName);
  torx.pthread_rwlock_rdlock(torx.mutex_global_variable); // 🟧
  int ret = symbol.value;
  torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
  return ret;
}

int threadsafe_read_global_Uint32(String symbolName) {
  Pointer<Uint32> symbol = dynamicLibrary.lookup(symbolName);
  torx.pthread_rwlock_rdlock(torx.mutex_global_variable); // 🟧
  int ret = symbol.value;
  torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
  return ret;
}

int threadsafe_read_global_Int(String symbolName) {
  Pointer<Int> symbol = dynamicLibrary.lookup(symbolName);
  torx.pthread_rwlock_rdlock(torx.mutex_global_variable); // 🟧
  int ret = symbol.value;
  torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
  return ret;
}
//*/
