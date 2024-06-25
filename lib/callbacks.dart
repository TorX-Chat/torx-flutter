// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'change_notifiers.dart';
import 'language.dart';
import 'main.dart';
import 'manual_bindings.dart';
import 'routes.dart';
import 'stickers.dart';

/*
Future.microtask(() {
  // Non-UI code only
});

WidgetsBinding.instance.addPostFrameCallback((_) {
  // UI code here
});
*/
void initialize_n_cb_ui(int n) {
  t_peer.unsent[n] = "";
  t_peer.mute[n] = 0;
  t_peer.unread[n] = 0;
  t_peer.pm_n[n] = -1;
  t_peer.edit_n[n] = -1;
  t_peer.edit_i[n] = -1;
  t_peer.t_file[n] = t_file_class();
}

void initialize_i_cb_ui(int n, int i) {
  /* currently null */
}

void initialize_f_cb_ui(int n, int f) {
  t_peer.t_file[n].changeNotifierTransferProgress[f] = ChangeNotifierTransferProgress();
}

void initialize_g_cb_ui(int g) {
  /* currently null */
}

void expand_file_struc_cb_ui(int n, int f) {
  for (int i = 0; i < 10; i++) {
    t_peer.t_file[n].changeNotifierTransferProgress.add(ChangeNotifierTransferProgress());
  }
}

void expand_messages_struc_cb_ui(int n, int i) {
  /* currently null */
}

void expand_peer_struc_cb_ui(int n) {
  for (int i = 0; i < 10; i++) {
    t_peer.unsent.add("");
    t_peer.mute.add(0);
    t_peer.unread.add(0);
    t_peer.pm_n.add(0);
    t_peer.edit_n.add(0);
    t_peer.edit_i.add(0);
    t_peer.t_file.add(t_file_class());
  }
}

void expand_group_struc_cb_ui(int g) {
  /* currently null */
}

void transfer_progress_cb_ui(int n, int f, int transferred) {
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
    FlutterAppBadger.updateBadgeCount(totalUnreadPeer + totalUnreadGroup + totalIncoming);
  }
  changeNotifierTotalIncoming.callback(integer: -1);
  changeNotifierDataTables.callback(integer: n);
  String peernick = getter_string(n, -1, -1, offsetof("peer", "peernick")); // 8
  if (peernick.isEmpty) {
    error(0, "nullptr in cb_type 8a");
    return;
  }
  // GOAT does this banner even work? could probably give a notification here instead, with Accept/Reject options
  MaterialBanner(
    content: Text("$peernick\n${text.new_friend}"),
    actions: [
      IconButton(
        icon: const Icon(Icons.thumb_up),
        onPressed: () {
          torx.peer_accept(n);
        },
      ),
      IconButton(
        icon: const Icon(Icons.thumb_down),
        onPressed: () {
          int peer_index = torx.getter_int(n, -1, -1, -1, offsetof("peer", "peer_index"));
          torx.takedown_onion(peer_index, 1);
        },
      ),
    ],
  );
}

void onion_deleted_cb_ui(int owner, int n) {
  initialize_n_cb_ui(n);
  changeNotifierDataTables.callback(integer: owner);
  // GOAT check if ctrl before updating chatlist
  changeNotifierChatList.callback(integer: owner);
  if (generated_n > -1) {
    String generated = getter_string(generated_n, -1, -1, offsetof("peer", "onion"));
    if (generated.startsWith('000000')) {
      changeNotifierOnionReady.callback(integer: -1);
      entryAddGenerateOutputController.clear();
    }
  }
}

void peer_online_cb_ui(int n) {
  int owner = torx.getter_uint8(n, -1, -1, -1, offsetof("peer", "owner"));
  if (n == global_n || owner == ENUM_OWNER_GROUP_PEER) {
    changeNotifierOnlineOffline.callback(integer: n);
  }
  changeNotifierChatList.callback(integer: n);
}

void peer_offline_cb_ui(int n) {
  int owner = torx.getter_uint8(n, -1, -1, -1, offsetof("peer", "owner"));
  if (n == global_n || owner == ENUM_OWNER_GROUP_PEER) {
    changeNotifierOnlineOffline.callback(integer: n);
  }
  changeNotifierChatList.callback(integer: n);
}

void peer_new_cb_ui(int n) {
  changeNotifierOnlineOffline.callback(integer: n); // especially for groups
  changeNotifierChatList.callback(integer: n);
  changeNotifierDataTables.callback(integer: n);
}

void print_log_cb_ui(int n, int actual) {
  /* currently null */
}

void onion_ready_cb_ui(int n) {
  String onion = getter_string(n, -1, -1, offsetof("peer", "onion"));
  String torxid = getter_string(n, -1, -1, offsetof("peer", "torxid"));
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
  writeUnread();
  torx.cleanup_lib(sig_num); // do last before calling exit
  SystemNavigator.pop(); // proper alternative to exit(sig_num); but it will be ignored in iOS
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
  torx.torx_free_simple(message as Pointer<Void>);
  message = nullptr;
}

void error_cb_ui(Pointer<Utf8> error_message) {
  if (error_message == nullptr) {
    return;
  }
  printf(error_message.toDartString());
  torxLogBuffer = torxLogBuffer + error_message.toDartString();
  changeNotifierError.callback(string: error_message.toDartString());
  if (scrollcontroller_log_torx.hasClients &&
      scrollcontroller_log_torx.positions.isNotEmpty &&
      scrollcontroller_log_torx.position.pixels == scrollcontroller_log_torx.position.maxScrollExtent) {
    scrollIfBottom(scrollcontroller_log_torx);
  }
  torx.torx_free_simple(error_message as Pointer<Void>);
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
        int owner = torx.getter_uint8(n, -1, -1, -1, offsetof("peer", "owner"));
        t_peer.unread[n] = int.parse(setting_value.toDartString());
        if (t_peer.unread[n] > 0) {
          if (owner == ENUM_OWNER_GROUP_CTRL) {
            totalUnreadGroup += t_peer.unread[n];
          } else {
            totalUnreadPeer += t_peer.unread[n];
          }
        }
        if (launcherBadges) {
          FlutterAppBadger.updateBadgeCount(totalUnreadPeer + totalUnreadGroup + totalIncoming);
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
    } else if (name.startsWith("sticker-gif-")) {
      int s = ui_sticker_register(setting_value as Pointer<Uint8>, setting_value_len);
      stickers[s].saved = true;
    } else {
      error(0, "Unrecognized encrypted config setting: $name");
    }
  } else if (plaintext == 1) {
    if (name == "theme") {
      theme = int.parse(setting_value.toDartString());
    } else if (name == "language") {
      language = setting_value.toDartString();
    } else {
      error(0, "Unrecognized unencrypted config setting: $name");
    }
  }
  torx.torx_free_simple(setting_name as Pointer<Void>);
  setting_name = nullptr;
  torx.torx_free_simple(setting_value as Pointer<Void>);
  setting_value = nullptr;
}

void print_message_cb_ui(int n, int i, int scroll) {
  if (n < 0 || i < 0 || scroll < 0) {
    error(0, "Sanity checkfailed in print_message_cb_ui");
    return;
  }
  int stat = torx.getter_uint8(n, i, -1, -1, offsetof("message", "stat"));
  if (stat == ENUM_MESSAGE_RECV && scroll == 1) {
    int p_iter = torx.getter_int(n, i, -1, -1, offsetof("message", "p_iter"));
    int notifiable = protocol_int(p_iter, "notifiable");
    if (notifiable == 0) {
      return;
    }
    int owner = torx.getter_uint8(n, -1, -1, -1, offsetof("peer", "owner"));
    int nn = n;
    if (owner == ENUM_OWNER_GROUP_PEER) {
      int g = torx.set_g(n, nullptr);
      nn = torx.getter_group_int(g, offsetof("group", "n"));
      owner = ENUM_OWNER_GROUP_CTRL;
    }
    int null_terminated_len = protocol_int(p_iter, "null_terminated_len");
    if (nn != global_n || globalAppLifecycleState != AppLifecycleState.resumed) {
      if (t_peer.mute[n] == 0 && t_peer.mute[nn] == 0) {
        int group_pm = protocol_int(p_iter, "group_pm");
        Noti.showBigTextNotification(
            title: getter_string(n, -1, -1, offsetof("peer", "peernick")),
            body: null_terminated_len != 0 ? getter_string(n, i, -1, offsetof("message", "message")) : protocol_string(p_iter, offsetof("protocols", "name")),
            payload: "$n $group_pm",
            fln: flutterLocalNotificationsPlugin);
        Vibration.vibrate(); // Vibrate regardless of mute setting, if current chat not open or application is not in the foreground
        FlutterRingtonePlayer.play(looping: false, fromAsset: "lib/other/beep.wav"); // Make sound if not muted
      }
      t_peer.unread[nn]++;
      if (owner == ENUM_OWNER_GROUP_CTRL) {
        totalUnreadGroup++;
      } else {
        totalUnreadPeer++;
      }
      if (launcherBadges) {
        FlutterAppBadger.updateBadgeCount(totalUnreadPeer + totalUnreadGroup + totalIncoming);
      }
      changeNotifierTotalUnread.callback(integer: -2);
    }
    /*         FlutterRingtonePlayer.play(
          android: AndroidSounds.notification,
          ios: IosSounds.glass,
          looping: false, // Android only - API >= 28
//        volume: 0.1, // Android only - API >= 28
          asAlarm: false, // Android only - all APIs
        ); */
  } else if (stat != ENUM_MESSAGE_RECV && scroll == 1) {
    // "section 9jfj20f0w" this appears to be for clearing notifications after responding via notification
    int owner = torx.getter_uint8(n, -1, -1, -1, offsetof("peer", "owner"));
    int nn = n;
    if (owner == ENUM_OWNER_GROUP_PEER) {
      int g = torx.set_g(n, nullptr);
      nn = torx.getter_group_int(g, offsetof("group", "n"));
      owner = ENUM_OWNER_GROUP_CTRL;
    }
    if (t_peer.unread[nn] > 0) {
      if (owner == ENUM_OWNER_GROUP_CTRL) {
        totalUnreadGroup -= t_peer.unread[nn];
      } else {
        totalUnreadPeer -= t_peer.unread[nn];
      }

      t_peer.unread[nn] = 0;
      if (launcherBadges) {
        FlutterAppBadger.updateBadgeCount(totalUnreadPeer + totalUnreadGroup + totalIncoming);
      }
      changeNotifierChatList.callback(integer: -1);
      changeNotifierTotalUnread.callback(integer: -1);
    }
  }
  changeNotifierMessage.callback(n: n, i: i, scroll: scroll);
  if (scroll == 1 || scroll == 2) {
    changeNotifierChatList.callback(integer: n); // for the last_message
  }
}

void stream_cb_ui(int n, int p_iter, Pointer<Utf8> data, int data_len) {
  if (data == nullptr || data_len == 0 || n < 0 || p_iter < 0) {
    torx.torx_free_simple(data as Pointer<Void>);
    data = nullptr;
    error(0, "Sanity check fail in stream_cb_ui. Possibly due to recursion? $n $p_iter $data_len ${data == nullptr ? "is null" : "is not null"}");
    return;
  }
  int protocol = protocol_int(p_iter, "protocol");
  int owner = torx.getter_uint8(n, -1, -1, -1, offsetof("peer", "owner"));
  int status = torx.getter_uint8(n, -1, -1, -1, offsetof("peer", "status"));
  if ((owner == ENUM_OWNER_GROUP_PEER && t_peer.mute[n] != 0) || status == ENUM_STATUS_BLOCKED) {
    torx.torx_free_simple(data as Pointer<Void>);
    data = nullptr;
    error(0, "Error 2 in stream_cb_ui");
    return;
  }
  printf("Checkpoint stream_cb_ui protocol: $protocol size: $data_len");
  if (data_len >= CHECKSUM_BIN_LEN && protocol == ENUM_PROTOCOL_STICKER_REQUEST) {
    if (send_sticker_data == false) {
      torx.torx_free_simple(data as Pointer<Void>);
      data = nullptr;
      error(0, "Error 3 in stream_cb_ui");
      return;
    }
    int s = ui_sticker_set(data as Pointer<Uint8>);
    int relevant_n = n; // TODO for groups, this should be group_n
    int iter = 0;
    while (iter < stickers[s].peers.length && stickers[s].peers[iter] != relevant_n && stickers[s].peers[iter] > -1) {
      iter++;
    }
    if (relevant_n != stickers[s].peers[iter]) {
      //	printf("Checkpoint TRYING s=%d owner=%u\n",s,owner); // FINGERPRINTING
      if (owner == ENUM_OWNER_GROUP_PEER) {
        // if not on peer_n(pm), try group_n (public)
        int g = torx.set_g(n, nullptr);
        relevant_n = torx.getter_group_int(g, offsetof("group", "n"));
        owner = torx.getter_uint8(relevant_n, -1, -1, -1, offsetof("peer", "owner"));
        stream_cb_ui(n, p_iter, data, data_len); // recurse
      } else {
        error(0, "Peer requested a sticker they dont have access to (either they are buggy or malicious, or our MAX_PEERS is too small). Report this.");
      }
    } else if (s > -1) {
      // Peer requested a sticker we have
      Pointer<Uint8> message = torx.torx_secure_malloc(CHECKSUM_BIN_LEN + stickers[s].data_len) as Pointer<Uint8>;
      torx.memcpy(message as Pointer<Void>, stickers[s].checksum as Pointer<Void>, CHECKSUM_BIN_LEN);
      torx.memcpy((message + CHECKSUM_BIN_LEN) as Pointer<Void>, stickers[s].data as Pointer<Void>, stickers[s].data_len);
      torx.message_send(n, ENUM_PROTOCOL_STICKER_DATA_GIF, message as Pointer<Void>, CHECKSUM_BIN_LEN + stickers[s].data_len);
      torx.torx_free_simple(message as Pointer<Void>);
      message = nullptr;
    } else {
      error(0, "Peer requested sticker we do not have. Maybe we deleted it.");
    }
  } else if (data_len >= CHECKSUM_BIN_LEN && protocol == ENUM_PROTOCOL_STICKER_DATA_GIF) {
    int s_check = ui_sticker_set(data as Pointer<Uint8>);
    if (s_check > -1) {
      // Old sticker data, do not print or register (such as re-opening peer route)
      error(0, "We already have this sticker data, do not register or print again.");
    } else {
      // Fresh sticker data. Save it and print it
      Pointer<Uint8> data_unsigned = data as Pointer<Uint8>;
      int s = ui_sticker_register(data_unsigned + CHECKSUM_BIN_LEN, data_len - CHECKSUM_BIN_LEN); // this is pointer arithmetic
      if (save_all_stickers) {
        ui_sticker_save(s);
      }
      changeNotifierStickerReady.callback(integer: s);
    }
  } else {
    error(0, "Unknown stream data received: protocol=$protocol data_len=$data_len");
  }
  torx.torx_free_simple(data as Pointer<Void>);
  data = nullptr;
}

void login_cb_ui(int value) {
  printf("Checkpoint login: $value");
  login_failed = true;
  changeNotifierLogin.callback(integer: value);
}
