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
// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:ffi/ffi.dart';
import 'change_notifiers.dart';
import 'colors.dart';
import 'language.dart';
import 'main.dart';
import 'manual_bindings.dart';
import 'routes.dart';
import 'stickers.dart';
import 'package:media_scanner/media_scanner.dart';

/*
Future.microtask(() {
  // Non-UI code only
});

WidgetsBinding.instance.addPostFrameCallback((_) {
  // UI code here
});
*/

class Callbacks {
  // Singleton instance
  Callbacks._privateConstructor();

  static final Callbacks _instance = Callbacks._privateConstructor();

  factory Callbacks() {
    return _instance;
  }

  int build_times = 0;

  void initialize_n_cb_ui(int n) {
    t_peer.unsent[n] = "";
    t_peer.mute[n] = 0;
    t_peer.unread[n] = 0;
    t_peer.pm_n[n] = -1;
    t_peer.edit_n[n] = -1;
    t_peer.edit_i[n] = INT_MIN;
    t_peer.t_message[n] = t_message_class();
    t_peer.t_file[n] = t_file_class();
    t_peer.stickers_requested[n] = [];
    t_peer.t_call[n] = t_call_class();
  }

  void initialize_i_cb_ui(int n, int i) {
    t_peer.t_message[n].unheard[i - t_peer.t_message[n].offset] = 1;
  }

  void initialize_f_cb_ui(int n, int f) {
    t_peer.t_file[n].changeNotifierTransferProgress[f] = ChangeNotifierTransferProgress();
    t_peer.t_file[n].previously_completed[f] = 0;
  }

  void initialize_g_cb_ui(int g) {
    /* currently null */
  }

  void shrinkage_cb_ui(int n, int shrinkage) {
    if (shrinkage != 0) {
      List<int> tmp = [];
      for (int iter = 0; iter < t_peer.t_message[n].unheard.length - shrinkage.abs(); iter++) {
        if (shrinkage > 0) {
          // We shift everything forward
          tmp.add(t_peer.t_message[n].unheard[iter + shrinkage]);
        } else {
          tmp.add(t_peer.t_message[n].unheard[iter]);
        }
      }
      t_peer.t_message[n].unheard.clear();
      t_peer.t_message[n].unheard = tmp;
      if (shrinkage > 0) {
        // We shift everything forward
        t_peer.t_message[n].offset + shrinkage;
      }
    }
  }

  void expand_file_struc_cb_ui(int n, int f) {
    for (int i = 0; i < 10; i++) {
      t_peer.t_file[n].changeNotifierTransferProgress.add(ChangeNotifierTransferProgress());
      t_peer.t_file[n].previously_completed.add(0);
    }
  }

  void expand_message_struc_cb_ui(int n, int i) {
    if (i > -1) {
      for (int ii = 0; ii < 10; ii++) {
        t_peer.t_message[n].unheard.add(1);
      }
    } else {
      t_peer.t_message[n].offset -= 10;
      t_peer.t_message[n].unheard.insertAll(0, List.filled(10, 1));
    }
  }

  void expand_peer_struc_cb_ui(int n) {
    for (int i = 0; i < 10; i++) {
      t_peer.unsent.add("");
      t_peer.mute.add(0);
      t_peer.unread.add(0);
      t_peer.pm_n.add(0);
      t_peer.edit_n.add(0);
      t_peer.edit_i.add(0);
      t_peer.t_message.add(t_message_class());
      t_peer.t_file.add(t_file_class());
      t_peer.stickers_requested.add([]);
      t_peer.t_call.add(t_call_class());
    }
  }

  void expand_group_struc_cb_ui(int g) {
    /* currently null */
  }

  void transfer_progress_cb_ui(int n, int f, int transferred) {
    int size = torx.getter_uint64(n, INT_MIN, f, offsetof("file", "size"));
    int file_status = torx.file_status_get(n, f);
    if (t_peer.t_file[n].previously_completed[f] == 0 && (file_status == ENUM_FILE_INACTIVE_COMPLETE || transferred == size)) {
      String file_path = getter_string(n, INT_MIN, f, offsetof("file", "file_path"));
      if (size == get_file_size(file_path)) {
        t_peer.t_file[n].previously_completed[f] = 1;
        MediaScanner.loadMedia(path: file_path);
      }
    }
    t_peer.t_file[n].changeNotifierTransferProgress[f].callback();
  }

  void change_password_cb_ui(int value) {
    if (value == 0 || value == -1) {
      controllerPassOld.clear();
      controllerPassNew.clear();
      controllerPassVerify.clear();
    } else if (value == 1) {
      controllerPassOld.clear();
    } else if (value == 2) {
      controllerPassNew.clear();
      controllerPassVerify.clear();
    }
    buttonChangePasswordText = text.change_password;
    changeNotifierChangePassword.callback(integer: value);
  }

  void incoming_friend_request_cb_ui(int n) {
    totalIncoming++;
    if (launcherBadges) {
      AppBadgePlus.updateBadge(totalUnreadPeer + totalUnreadGroup + totalIncoming);
    }
    changeNotifierTotalIncoming.callback(integer: -1);
    changeNotifierDataTables.callback(integer: n);
    String peernick = getter_string(n, INT_MIN, -1, offsetof("peer", "peernick")); // 8
    if (peernick.isEmpty) {
      error(0, "nullptr in cb_type 8a");
      return;
    }
    Noti.showBigTextNotification(
        id: n, title: getter_string(n, INT_MIN, -1, offsetof("peer", "peernick")), body: text.new_friend, payload: "friend_request $n", flnp: flutterLocalNotificationsPlugin);
  }

  void onion_deleted_cb_ui(int owner, int n) {
    initialize_n_cb_ui(n);
    changeNotifierDataTables.callback(integer: owner);
    // GOAT check if ctrl before updating chatlist
    changeNotifierChatList.callback(integer: owner);
    Noti.cancel(n, flutterLocalNotificationsPlugin); // cancel all related notifications, whether PEER (friend_request) or CTRL (message).
    if (generated_n == n) {
      generated_n = -1;
      changeNotifierOnionReady.callback(integer: -1);
      entryAddGenerateOutputController.clear();
    }
    if (n == global_n) {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  void peer_online_cb_ui(int n) {
    int owner = torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "owner"));
    if (n == global_n || owner == ENUM_OWNER_GROUP_PEER) {
      changeNotifierOnlineOffline.callback(integer: n);
    }
    changeNotifierChatList.callback(integer: n);
  }

  void peer_offline_cb_ui(int n) {
    int sendfd_connected = torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "sendfd_connected"));
    int recvfd_connected = torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "recvfd_connected"));
    int online = recvfd_connected + sendfd_connected;
    if (online == 0) {
      // Peer is completely offline
      call_peer_leaving_all_except(n, -1, -1);
    }
    peer_online_cb_ui(n);
  }

  void peer_loaded_cb_ui(int n) {
    int owner = torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "owner"));
    if (owner == ENUM_OWNER_CTRL) {
      int status = torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "status"));
      if (status == ENUM_STATUS_PENDING) {
        totalIncoming++;
        if (launcherBadges) {
          AppBadgePlus.updateBadge(totalUnreadPeer + totalUnreadGroup + totalIncoming);
        }
        changeNotifierTotalIncoming.callback(integer: totalIncoming);
        changeNotifierDataTables.callback(integer: n);
      }
    }
    peer_online_cb_ui(n);
  }

  void peer_new_cb_ui(int n) {
    changeNotifierOnlineOffline.callback(integer: n); // especially for groups
    changeNotifierChatList.callback(integer: n);
    changeNotifierDataTables.callback(integer: n);
  }

  void onion_ready_cb_ui(int n) {
    String onion = getter_string(n, INT_MIN, -1, offsetof("peer", "onion"));
    String torxid = getter_string(n, INT_MIN, -1, offsetof("peer", "torxid"));
    if (torxid.isEmpty || onion.isEmpty) {
      return;
    }
    int shorten_torxids = threadsafe_read_global_Uint8("shorten_torxids");
    entryAddGeneratePeernickController.clear();
    if (shorten_torxids == 0) {
      entryAddGenerateOutputController.text = onion; // GOAT this onion is for some reason invalid when torxid is enabled??? wtf 2022/11/09
    } else if (shorten_torxids == 1) {
      entryAddGenerateOutputController.text = torxid;
    }
    changeNotifierOnionReady.callback(integer: n);
    changeNotifierDataTables.callback(integer: n);
  }

  void cleanup_cb_ui(int sig_num) {
    cleanup_idle(sig_num);
  }

  void tor_log_cb_ui(Pointer<Utf8> message) {
    if (message == nullptr) {
      return;
    }
    torLogBuffer = torLogBuffer + message.toDartString();
    changeNotifierTorLog.callback(string: message.toDartString());
    if (scrollcontroller_log_tor.hasClients &&
        scrollcontroller_log_tor.positions.isNotEmpty &&
        scrollcontroller_log_tor.position.pixels == scrollcontroller_log_tor.position.maxScrollExtent) {
      scrollIfBottom(scrollcontroller_log_tor);
    }
    torx.torx_free_simple(message);
    message = nullptr;
  }

  void error_cb_ui(Pointer<Utf8> error_message) {
    if (error_message == nullptr) {
      return;
    }
    String message_string = error_message.toDartString();
    printf(message_string);
    torxLogBuffer = torxLogBuffer + message_string;
    changeNotifierError.callback(string: message_string);
    if (scrollcontroller_log_torx.hasClients &&
        scrollcontroller_log_torx.positions.isNotEmpty &&
        scrollcontroller_log_torx.position.pixels == scrollcontroller_log_torx.position.maxScrollExtent) {
      scrollIfBottom(scrollcontroller_log_torx);
    }
    torx.torx_free_simple(error_message);
    error_message = nullptr;
  }

  void fatal_cb_ui(Pointer<Utf8> error_message) {
    error_cb_ui(error_message);
  }

  void custom_setting_cb_ui(int n, Pointer<Utf8> setting_name, Pointer<Utf8> setting_value, int setting_value_len, int plaintext) {
    if (setting_name == nullptr || setting_value == nullptr) {
      return;
    }
    String name = setting_name.toDartString();
    if (plaintext == 0) {
      // Only considering encrypted/non-cleartext
      if (name == "mute") {
        t_peer.mute[n] = int.parse(setting_value.toDartString());
      } else if (name == "unread") {
        if (log_unread) {
          int owner = torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "owner"));
          t_peer.unread[n] = int.parse(setting_value.toDartString());
          if (t_peer.unread[n] > 0) {
            if (owner == ENUM_OWNER_GROUP_CTRL) {
              totalUnreadGroup += t_peer.unread[n];
            } else {
              totalUnreadPeer += t_peer.unread[n];
            }
          }
          if (launcherBadges) {
            AppBadgePlus.updateBadge(totalUnreadPeer + totalUnreadGroup + totalIncoming);
          }
          changeNotifierTotalUnread.callback(integer: -3);
        }
      } else if (name == "keyboard_privacy") {
        if (int.parse(setting_value.toDartString()) == 0) {
          keyboard_privacy = false;
        } else if (int.parse(setting_value.toDartString()) == 1) {
          keyboard_privacy = true;
        } else {
          error(0, "Bad keyboard_privacy setting read from storage. Coding error. Report this.");
        }
      } else if (name == "save_all_stickers") {
        if (int.parse(setting_value.toDartString()) == 0) {
          save_all_stickers = false;
        } else if (int.parse(setting_value.toDartString()) == 1) {
          save_all_stickers = true;
        } else {
          error(0, "Bad save_all_stickers setting read from storage. Coding error. Report this.");
        }
      } else if (name.startsWith("sticker-gif-")) {
        int s = ui_sticker_register(setting_value as Pointer<Uint8>, setting_value_len);
        stickers[s].saved = true;
      } else {
        error(0, "Unrecognized encrypted config setting: $name");
      }
    } else if (plaintext == 1) {
      if (name == "theme") {
        theme = int.parse(setting_value.toDartString());
        initialize_theme(null);
      } else if (name == "language") {
        language = setting_value.toDartString();
        initialize_language();
      } else {
        error(0, "Unrecognized unencrypted config setting: $name");
      }
    }
    torx.torx_free_simple(setting_name);
    setting_name = nullptr;
    torx.torx_free_simple(setting_value);
    setting_value = nullptr;
  }

  void message_new_cb_ui(int n, int i) {
    print_message(n, i, 1);
  }

  void message_modified_cb_ui(int n, int i) {
    print_message(n, i, 2);
  }

  void message_deleted_cb_ui(int n, int i) {
    // XXX WARNING: DO NOT ACCESS .message STRUCT due to shrinkage possibly having occurred
    changeNotifierMessage.callback(n: n, i: i, scroll: 3);
    int max_i = torx.getter_int(n, INT_MIN, -1, offsetof("peer", "max_i"));
    if (i == max_i + 1) {
      changeNotifierChatList.callback(integer: n); // for the last_message
    }
  }

  void stream_cb_ui(int n, int p_iter, Pointer<Utf8> data, int data_len) {
    if (data == nullptr || data_len == 0 || n < 0 || p_iter < 0) {
      torx.torx_free_simple(data);
      data = nullptr;
      error(0, "Sanity check fail in stream_cb_ui. Possibly due to recursion? $n $p_iter $data_len ${data == nullptr ? "is null" : "is not null"}");
      return;
    }
    int protocol = protocol_int(p_iter, "protocol");
    int owner = torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "owner"));
    int status = torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "status"));
    if ((owner == ENUM_OWNER_GROUP_PEER && t_peer.mute[n] != 0) || status == ENUM_STATUS_BLOCKED) {
      torx.torx_free_simple(data);
      data = nullptr;
      error(0, "Error 2 in stream_cb_ui");
      return;
    }
    printf("Checkpoint stream_cb_ui protocol: $protocol size: $data_len");
    if (data_len >= CHECKSUM_BIN_LEN && protocol == ENUM_PROTOCOL_STICKER_DATA_GIF) {
      int s_check = ui_sticker_set(data as Pointer<Uint8>);
      if (s_check > -1) {
        // Old sticker data, do not print or register (such as re-opening peer route)
        error(0, "We already have this sticker data, do not register or print again.");
      } else {
        Pointer<Uint8> checksum = torx.torx_secure_malloc(CHECKSUM_BIN_LEN) as Pointer<Uint8>; // free'd by torx_free
        if (torx.b3sum_bin(checksum, nullptr, data as Pointer<Uint8>, CHECKSUM_BIN_LEN, data_len - CHECKSUM_BIN_LEN) != data_len - CHECKSUM_BIN_LEN ||
            torx.memcmp(checksum, data, CHECKSUM_BIN_LEN) != 0) {
          error(0, "Received bunk sticker data from peer. Checksum failed. Disgarding sticker.");
        } else {
          // Fresh sticker data. Save it and print it
          Pointer<Uint8> data_unsigned = data as Pointer<Uint8>;
          int s = ui_sticker_register(data_unsigned + CHECKSUM_BIN_LEN, data_len - CHECKSUM_BIN_LEN); // this is pointer arithmetic
          if (save_all_stickers) {
            ui_sticker_save(s);
          }
          changeNotifierStickerReady.callback(integer: s);
        }
        int y = 0;
        while (y < t_peer.stickers_requested[n].length && torx.memcmp(t_peer.stickers_requested[n][y], checksum, CHECKSUM_BIN_LEN) != 0) {
          y++;
        }
        if (y < t_peer.stickers_requested[n].length) {
          // Remove the sticker request
          torx.torx_free_simple(t_peer.stickers_requested[n][y]);
          t_peer.stickers_requested[n][y] = nullptr;
          t_peer.stickers_requested[n].removeAt(y);
        }
        torx.torx_free_simple(checksum);
        checksum = nullptr;
      }
    } else if (data_len >= 8 &&
        (protocol == ENUM_PROTOCOL_AAC_AUDIO_STREAM_DATA_DATE ||
            protocol == ENUM_PROTOCOL_AAC_AUDIO_STREAM_JOIN ||
            protocol == ENUM_PROTOCOL_AAC_AUDIO_STREAM_JOIN_PRIVATE ||
            protocol == ENUM_PROTOCOL_AAC_AUDIO_STREAM_LEAVE)) {
      Uint8List typecast = (data as Pointer<Uint8>).asTypedList(8);
      int time = be32toh(typecast);
      int nstime = be32toh(typecast.sublist(4));
      printf("Checkpoint received host: $time $nstime");
      int call_n = n;
      int call_c = -1;
      int group_n = -1; // WARNING: ensure initialization
      for (int c = 0; c < t_peer.t_call[call_n].joined.length; c++) {
        if (t_peer.t_call[call_n].start_time[c] == time && t_peer.t_call[call_n].start_nstime[c] == nstime) call_c = c;
      }
      if (call_c == -1 && owner == ENUM_OWNER_GROUP_PEER) {
        // Try group_n instead
        int g = torx.set_g(n, nullptr);
        group_n = torx.getter_group_int(g, offsetof("group", "n"));
        call_n = group_n;
        for (int c = 0; c < t_peer.t_call[call_n].joined.length; c++) {
          if (t_peer.t_call[call_n].start_time[c] == time && t_peer.t_call[call_n].start_nstime[c] == nstime) call_c = c;
        }
      }
      if (call_c == -1 && (protocol == ENUM_PROTOCOL_AAC_AUDIO_STREAM_JOIN || protocol == ENUM_PROTOCOL_AAC_AUDIO_STREAM_JOIN_PRIVATE)) {
        // Received offer to join a new call
        if (protocol == ENUM_PROTOCOL_AAC_AUDIO_STREAM_JOIN_PRIVATE) call_n = n;
        call_c = set_c(call_n, time, nstime); // reserve
        t_peer.t_call[call_n].waiting[call_c] = true;
        call_peer_joining(call_n, call_c, n);
        if ((owner != ENUM_OWNER_GROUP_PEER || t_peer.mute[group_n] == 0) && t_peer.mute[call_n] == 0) {
          t_peer.t_call[call_n].notification_id[call_c] = Random().nextInt(99999999) + 10000; // minimum 10,000 to not conflict with n values
          Noti.showBigTextNotification(
              id: t_peer.t_call[call_n].notification_id[call_c],
              title: text.incoming_call,
              body: getter_string(call_n, INT_MIN, -1, offsetof("peer", "peernick")),
              payload: "call $call_n $call_c",
              flnp: flutterLocalNotificationsPlugin);
          ring_start();
        }
      } else if (call_c > -1) {
        if (protocol == ENUM_PROTOCOL_AAC_AUDIO_STREAM_DATA_DATE) {
          printf("Checkpoint stream_cb_ui AAC_AUDIO_STREAM_DATA_DATE time=$time:$nstime data_len=$data_len"); // TODO PLAY IT
        } else if (protocol == ENUM_PROTOCOL_AAC_AUDIO_STREAM_LEAVE) {
          call_peer_leaving(call_n, call_c, n);
        } else // if(protocol == ENUM_PROTOCOL_AAC_AUDIO_STREAM_JOIN || protocol == ENUM_PROTOCOL_AAC_AUDIO_STREAM_JOIN_PRIVATE)
        {
          call_peer_joining(call_n, call_c, n);
        }
      } else {
        error(0, "Received a audio stream related message for an unknown call: $time $nstime"); // If DATA, consider sending _LEAVE once. Otherwise it is _LEAVE, so ignore.
      }
    } else {
      error(0, "Unknown stream data received: protocol=$protocol data_len=$data_len");
    }
    torx.torx_free_simple(data);
    data = nullptr;
  }

  void message_extra_cb_ui(int n, int i, Pointer<Utf8> data, int data_len) {
    int p_iter = torx.getter_int(n, i, -1, offsetof("message", "p_iter"));
    if (p_iter < 0) {
      error(0, "message_extra_cb_ui hit a negative p_iter. Coding error. Report this.");
      return;
    }
    int protocol = protocol_int(p_iter, "protocol");
    if (protocol == ENUM_PROTOCOL_AAC_AUDIO_MSG || protocol == ENUM_PROTOCOL_AAC_AUDIO_MSG_PRIVATE || protocol == ENUM_PROTOCOL_AAC_AUDIO_MSG_DATE_SIGNED) {
      t_peer.t_message[n].unheard[i - t_peer.t_message[n].offset] = (data as Pointer<Uint8>).value;
    } else {
      error(0, "message_extra_cb received $data_len unknown bytes on protocol $protocol");
    }
    torx.torx_free_simple(data);
    data = nullptr;
  }

  void message_more_cb_ui(int loaded, Pointer<Int> loaded_array_n, Pointer<Int> loaded_array_i) {
    //  printf("Checkpoint message_more_cb_ui is currently non-op. See around call to message_load_more.");
  }

  void login_cb_ui(int value) {
    login_failed = true;
    changeNotifierLogin.callback(integer: value);
  }
}
