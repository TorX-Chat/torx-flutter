// ignore_for_file: constant_identifier_names, non_constant_identifier_names, camel_case_types
import 'dart:async';
import 'dart:ffi';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'colors.dart';
import 'main.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'manual_bindings.dart';
import 'language.dart';
import 'change_notifiers.dart';
import 'scanner.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:photo_view/photo_view.dart';
//import 'package:photo_view/photo_view_gallery.dart';
import 'package:open_filex/open_filex.dart';
import 'stickers.dart';
import 'package:media_scanner/media_scanner.dart';

@pragma("vm:entry-point") // Should be top level / not in class. NOTE: THIS LINE IS ABSOLUTELY necessary by flutter_local_notifications to prevent tree-shaking the code
void response(NotificationResponse notificationResponse) {
/*    if (notificationResponse.actionId == 'reply') {
      printf("there is a reply!");
    }*/
  String? payload = notificationResponse.payload;
  String? input = notificationResponse.input;
  if (payload == null || input == null) {
    printf("Noti fail or user clicked dismiss?");
    return;
  }
  List<String> parts = payload.split(' ');
  int n = int.parse(parts[0]);
  int group_pm = int.parse(parts[1]);
//    printf("Checkpoint notification response: $n $group_pm ${notificationResponse.input}");
  Pointer<Utf8> message = input.toNativeUtf8(); // free'd by calloc.free
  int owner = torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "owner"));
  if (group_pm != 0) {
    torx.message_send(n, ENUM_PROTOCOL_UTF8_TEXT_PRIVATE, message as Pointer<Void>, message.length);
  } else if (owner == ENUM_OWNER_GROUP_CTRL || owner == ENUM_OWNER_GROUP_PEER) {
    int g = torx.set_g(n, nullptr);
    int g_invite_required = torx.getter_group_uint8(g, offsetof("group", "invite_required"));
    int group_n = torx.getter_group_int(g, offsetof("group", "n"));
    if (g_invite_required != 0) {
      // date && sign private group messages
      torx.message_send(group_n, ENUM_PROTOCOL_UTF8_TEXT_DATE_SIGNED, message as Pointer<Void>, message.length);
    } else {
      torx.message_send(group_n, ENUM_PROTOCOL_UTF8_TEXT, message as Pointer<Void>, message.length);
    }
  } else {
    torx.message_send(n, ENUM_PROTOCOL_UTF8_TEXT, message as Pointer<Void>, message.length);
  }
  if (message != nullptr) {
    calloc.free(message);
    message = nullptr;
  }
  //    flutterLocalNotificationsPlugin.cancel(notificationResponse.id!); // Does not work, either due to isolate or unknown other reason
  // GOAT how can these notification IDs be stored in the proper isolate so that they can be individually closed if going to the N's RouteChat? low priority
}

class Noti {
// NOTICE: showsUserInterface: false ---> Response runs in a different isolate. Will not work without interprocess communication. (Neither C nor Dart). 2024/04/15 ALSO DOES NOT WORK WITH INTERPROCESS COMMUNICATION
// Old: Different isolate, C works, Dart everything is initialized. DO NOT READ OR SET GLOBAL VARIABLES INCLUDING t_peer, and ChangeNotifiers don't work. Use print_message_cb() for any UI thread stuff ( ctrl+f "section 9jfj20f0w" ).

  static dynamic initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) {
    var androidInitialize = const AndroidInitializationSettings('ic_notification_foreground'); // NOTE: arg is icon
//      var androidInitialize = const AndroidInitializationSettings('icon_square');
/*var iOSInitialize = IOSInitializationSettings(); */
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
//    onDidReceiveLocalNotification: response(),
    );
    var initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: initializationSettingsDarwin,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: response, onDidReceiveBackgroundNotificationResponse: response);
    flutterLocalNotificationsPlugin.cancelAll(); // perhaps this will kill any hangovers after a detach
  }

  static dynamic showBigTextNotification({var id = 0, required String title, required String body, String? payload, required FlutterLocalNotificationsPlugin fln}) {
    AndroidNotificationDetails
        androidPlatformChannelSpecifics = // GOAT use payload as GroupKey, so that messages are grouped per user (does not work. also changing 'channelId' to payload does not work.)
        AndroidNotificationDetails('jykliDPA9dbXfvX', 'Message Notifier',
            ongoing: false, // true prevents swipe dismiss in android 13/14
            enableLights: true,
            ledOnMs: 2000,
            ledOffMs: 10000,
            ledColor: Colors.pink,
            groupKey: "message", // ( all messages grouped )
            playSound: false,
            enableVibration: false,
            importance: Importance.high,
            priority: Priority.max,
            color: Colors.red,
            actions: [
          // GOAT showsUserInterface resumes the application to the foreground before sending, to run on the main isolate. To disable this, we have to implement a messaging mechanism to communicate with the main isolate.
          if (payload != null)
            AndroidNotificationAction('reply', text.reply,
                /*cancelNotification: cancelAfterReply, titleColor: Colors.green,*/ contextual: false,
                showsUserInterface: true /*DO NOT SET FALSE Interprocess communication does not work, even using ReceivePort*/,
                inputs: [const AndroidNotificationActionInput()]),
          //    AndroidNotificationAction('dismiss', text.dismiss, cancelNotification: true) // does NOT work
        ]);
    fln.show(id, title, body, NotificationDetails(android: androidPlatformChannelSpecifics /*, iOS: IOSNotificationDetails()*/), payload: payload);
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class CustomPopupMenuItem<T> extends PopupMenuItem<T> {
  final Color? color;

  const CustomPopupMenuItem({
    super.key,
    super.value,
    super.enabled,
    super.child,
    WidgetStateProperty<TextStyle?>? labelTextStyle,
    MouseCursor? mouseCursor,
    VoidCallback? onTap,
    EdgeInsets? padding,
    TextStyle? textStyle,
    this.color,
  });

  @override
  _CustomPopupMenuItemState<T> createState() => _CustomPopupMenuItemState<T>();
}

class _CustomPopupMenuItemState<T> extends PopupMenuItemState<T, CustomPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.color,
      child: super.build(context),
    );
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class RoutePopoverList extends StatefulWidget {
  final int type;
  final int g;
  const RoutePopoverList(this.type, this.g, {super.key});

  @override
  State<RoutePopoverList> createState() => _RoutePopoverListState();
}

class _RoutePopoverListState extends State<RoutePopoverList> {
  TextEditingController controllerSearch = TextEditingController();
  String searchText = "";

  double searchWidth = 40;
  Color searchColor = Colors.transparent;
  bool searchOpen = false;
  Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    Pointer<Int> len_p = malloc(8); // free'd by calloc.free // 4 is wide enough, could be 8, should be sizeof, meh.
    Pointer<Utf8> search_p = searchText.toNativeUtf8(); // free'd by calloc.free
    Pointer<Int> arrayFriends;
    if (widget.type == ENUM_OWNER_GROUP_PEER && widget.g > -1) {
      arrayFriends = torx.refined_list(len_p, widget.type, widget.g, search_p);
    } else if (widget.type == ENUM_OWNER_CTRL) {
      arrayFriends = torx.refined_list(len_p, widget.type, ENUM_STATUS_FRIEND, search_p);
    } else {
      error(-1, "Critical coding error in _RoutePopoverListState");
      arrayFriends = nullptr;
    }
    int len = len_p.value;
    calloc.free(search_p);
    search_p = nullptr;
    calloc.free(len_p);
    len_p = nullptr;
    if (searchOpen == true) {
      searchColor = color.search_field_background;
      searchWidth = 180;
      suffixIcon = IconButton(
        icon: Icon(Icons.clear, color: color.search_field_text),
        onPressed: () {
          setState(() {
            searchOpen = false;
          });
        },
      );
    } else {
      controllerSearch.clear();
      searchText = "";
      searchColor = Colors.transparent;
      searchWidth = 40;
      suffixIcon = null;
    }
    return Scaffold(
        backgroundColor: color.right_panel_background,
        appBar: AppBar(
          backgroundColor: color.chat_headerbar,
          title: Text(
            widget.type == ENUM_OWNER_GROUP_PEER ? text.group_peers : text.invite_friend,
            style: TextStyle(color: color.page_title),
          ),
          actions: [
            Container(
              width: searchWidth,
              height: 30,
              decoration: BoxDecoration(color: searchColor, borderRadius: BorderRadius.circular(5)),
              child: Center(
                child: TextField(
                  controller: controllerSearch,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  scribbleEnabled: false,
                  spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                  showCursor: true,
                  onChanged: (content) {
                    setState(() {
                      searchText = content;
                    });
                  },
                  style: TextStyle(color: color.search_field_text),
                  decoration: InputDecoration(
                      suffixIcon: suffixIcon,
                      prefixIcon: IconButton(
                        icon: Icon(Icons.search, color: searchOpen == false ? color.torch_off : color.torch_on),
                        onPressed: () {
                          setState(() {
                            if (searchOpen == true) {
                              searchOpen = false;
                            } else {
                              searchOpen = true;
                            }
                          });
                        },
                      ),
                      hintText: text.placeholder_search,
                      hintStyle: TextStyle(color: color.torch_on),
                      border: InputBorder.none),
                ),
              ),
            )
          ],
        ),
        body: AnimatedBuilder(
            animation: changeNotifierPopoverList,
            builder: (BuildContext context, Widget? snapshot) {
              return ListView.builder(
                itemCount: len,
                prototypeItem: const ListTile(
                  title: Text("This is dummy text used to set height. Can be dropped."),
                ),
                itemBuilder: (context, index) {
                  Color dotColor = ui_statusColor(arrayFriends[index]);
                  Icon dot = Icon(Icons.circle, color: dotColor, size: 20);
                  return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPressStart: (touchDetail) {
                        //    offs = touchDetail.globalPosition; // does not work, throws error jfwoqiefhwoif
                        offs = const Offset(0, 0);
                      },
                      onTap: () {
                        if (widget.type == ENUM_OWNER_GROUP_PEER) {
                          t_peer.edit_n[global_n] = -1;
                          t_peer.edit_i[global_n] = INT_MIN;
                          t_peer.pm_n[global_n] = arrayFriends[index];
                          Navigator.pop(context);
                        } else {
                          int g_invite_required = torx.getter_group_uint8(widget.g, offsetof("group", "invite_required"));
                          int g_peercount = torx.getter_group_uint32(widget.g, offsetof("group", "peercount"));
                          if (g_invite_required == 1 && g_peercount == 0) {
                            torx.message_send(arrayFriends[index], ENUM_PROTOCOL_GROUP_OFFER_FIRST, torx.itovp(widget.g), GROUP_OFFER_FIRST_LEN);
                          } else {
                            torx.message_send(arrayFriends[index], ENUM_PROTOCOL_GROUP_OFFER, torx.itovp(widget.g), GROUP_OFFER_LEN);
                          }
                        }
                      },
                      onLongPress: () {
                        showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, controllerMessage, arrayFriends[index], INT_MIN, -1, -1));
                      },
                      child: ListTile(
                          leading: Badge(
                            isLabelVisible: t_peer.unread[arrayFriends[index]] > 0,
                            label: Text(t_peer.unread[arrayFriends[index]].toString()),
                            child: dot,
                          ),
                          title: Text(
                            getter_string(arrayFriends[index], INT_MIN, -1, offsetof("peer", "peernick")),
                            style: TextStyle(color: color.group_or_user_name, fontWeight: FontWeight.bold),
                          )));
                },
              );
            }));
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class RouteImage extends StatelessWidget {
  final String file_path;

  const RouteImage({super.key, required this.file_path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: PhotoView(
            // DO NOT WRAP IN A HERO, hero is bunk and can be a disaster if image is corrupt
            imageProvider: FileImage(File(file_path)),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class RouteChat extends StatefulWidget {
  final int n;
  const RouteChat(this.n, {super.key});

  @override
  State<RouteChat> createState() => _RouteChatState();
}

class _RouteChatState extends State<RouteChat> {
  ScrollController scrollController = ScrollController();
  TextEditingController controllerNick = TextEditingController(text: global_n > -1 ? getter_string(global_n, INT_MIN, -1, offsetof("peer", "peernick")) : null);
  Widget statusIcon = const Icon(Icons.lock_open);
  String statusText = "";
  Widget loggingIcon = const Icon(Icons.article);
  Widget muteIcon = const Icon(Icons.notifications_off);
  Color loggingColor = color.torch_off;
  Color blockColor = color.torch_off;
  String loggingText = "";
  String muteText = "";
  String blockText = "";
  int owner = 0; // torx.getter_uint8(widget.n, INT_MIN, -1, -1, offsetof("peer", "owner"));
  int g = -1;
  int g_invite_required = 0;
  double msgBorderRadius = 10;

  void setStatusIcon(int n) {
    if (g > -1) {
      statusIcon = SvgPicture.asset(path_logo, color: color.logo, width: 40, height: 40);
      return;
    }
    statusIcon = Icon(Icons.lock, color: ui_statusColor(n), size: 40);
  }

  void setMuteIcon(int n) {
    if (t_peer.mute[n] == 0) {
      muteIcon = Icon(Icons.notifications_active, color: color.torch_on);
      muteText = text.mute_off;
    } else if (t_peer.mute[n] == 1) {
      muteIcon = Icon(Icons.notifications_off, color: color.torch_off);
      muteText = text.mute_on;
    }
  }

  void setBlockIcon(int n) {
    if (torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "status")) == ENUM_STATUS_BLOCKED) {
      blockColor = Colors.red;
      blockText = text.blocked;
    } else {
      blockColor = color.torch_off;
      blockText = text.unblocked;
    }
  }

  void setLoggingIcon(int n) {
    int log_messages = torx.getter_int8(n, INT_MIN, -1, -1, offsetof("peer", "log_messages"));
    int global_log_messages = threadsafe_read_global_Uint8("global_log_messages");
    if (log_messages == -1) {
      loggingText = text.log_never;
      loggingIcon = Icon(Icons.article_outlined, color: color.torch_on);
      loggingColor = color.torch_off;
    } else if (log_messages == 0 && global_log_messages > 0) {
      loggingText = text.log_global_on;
      loggingIcon = Icon(Icons.language, color: color.torch_off);
      loggingColor = color.torch_on;
    } else if (log_messages == 0 && global_log_messages == 0) {
      loggingText = text.log_global_off;
      loggingIcon = Icon(Icons.language, color: color.torch_off);
      loggingColor = color.torch_off;
    } else if (log_messages == 1) {
      loggingText = text.log_always;
      loggingIcon = Icon(Icons.article, color: color.torch_on);
      loggingColor = color.torch_on;
    }
  }

  void toggleLogging(int n) {
    int log_messages = torx.getter_int8(n, INT_MIN, -1, -1, offsetof("peer", "log_messages"));
    if (log_messages == -1 || log_messages == 0) {
      log_messages++;
    } else if (log_messages == 1) {
      log_messages = -1;
    } else {
      return;
    }
    Pointer<Int8> setting = malloc(1); // free'd by calloc.free
    setting.value = log_messages;
    torx.setter(n, INT_MIN, -1, -1, offsetof("peer", "log_messages"), setting as Pointer<Void>, 1);
    calloc.free(setting);
    setting = nullptr;
    int peer_index = torx.getter_int(n, INT_MIN, -1, -1, offsetof("peer", "peer_index"));
    set_setting_string(0, peer_index, "logging", log_messages.toString());
  }

  void toggleKill(int n) {
    torx.kill_code(n, nullptr);
    changeNotifierChatList.callback(integer: n); // might be pointless here
  }

  void toggleDelete(int n) {
    int peer_index = torx.getter_int(n, INT_MIN, -1, -1, offsetof("peer", "peer_index"));
    torx.takedown_onion(peer_index, 1);
    changeNotifierChatList.callback(integer: n);
  }

  void setStatus(int n) {
    int owner = torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "owner"));
    if (owner == ENUM_OWNER_GROUP_CTRL) {
      int g = torx.set_g(n, nullptr);
      int g_peercount = torx.getter_group_uint32(g, offsetof("group", "peercount"));
      statusText = "${text.status_online}: ${torx.group_online(g)} ${text.of} $g_peercount";
      return;
    }

    int sendfd_connected = torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "sendfd_connected"));
    int recvfd_connected = torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "recvfd_connected"));
    if (sendfd_connected == 0 || recvfd_connected == 0) {
      int last_seen = torx.getter_time(n, INT_MIN, -1, -1, offsetof("peer", "last_seen"));
      if (last_seen > 0) {
        // NOTE: integer size is time_t
        statusText = text.status_last_seen + DateFormat('yyyy/MM/dd kk:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(last_seen * 1000, isUtc: false));
      } else {
        statusText = text.status_last_seen + text.status_never;
      }
    } else {
      statusText = text.status_online;
    }
  }

  Widget messageTime(int n, int index) {
    int owner = torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "owner"));
    int stat = torx.getter_uint8(n, index, -1, -1, offsetof("message", "stat"));
    Widget child;
    if (stat == ENUM_MESSAGE_FAIL && owner != ENUM_OWNER_GROUP_CTRL) {
      child = Icon(Icons.cancel, color: color.auth_error, size: 18);
    } else {
      String prefix = "";
      Pointer<Utf8> p = torx.message_time_string(n, index);
      String time_string = p.toDartString();
      torx.torx_free_simple(p as Pointer<Void>);
      p = nullptr;
      if (owner == ENUM_OWNER_GROUP_PEER) {
        prefix = "${getter_string(n, INT_MIN, -1, offsetof("peer", "peernick"))} ";
      }
      child = Padding(
          padding: const EdgeInsets.only(right: 5.0, left: 5.0),
          child: Text(
              textAlign: stat != ENUM_MESSAGE_RECV ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12,
                color: color.message_time,
              ),
              "$prefix$time_string"
              //    ${DateFormat('yyyy/MM/dd kk:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(torx.getter_time(n, index, -1, -1, offsetof("message", "time")) * 1000, isUtc: false))}"
              ));
    }
    return child;
  }

  Color _colorizeBackground(int stat, int group_pm) {
    if (stat == ENUM_MESSAGE_RECV) {
      return group_pm == 0 ? color.message_recv_background : color.message_recv_private_background;
    } else {
      return group_pm == 0 ? color.message_sent_background : color.message_sent_private_background;
    }
  }

  Color _colorizeText(int stat, int group_pm) {
    if (stat == ENUM_MESSAGE_RECV) {
      return group_pm == 0 ? color.message_recv_text : color.message_recv_private_text;
    } else {
      return group_pm == 0 ? color.message_sent_text : color.message_sent_private_text;
    }
  }

  Widget message_bubble(int stat, int group_pm, Widget child) {
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(stat != ENUM_MESSAGE_RECV ? msgBorderRadius : 0),
                topRight: Radius.circular(stat != ENUM_MESSAGE_RECV ? 0 : msgBorderRadius),
                bottomLeft: const Radius.circular(10),
                bottomRight: const Radius.circular(10)),
            color: _colorizeBackground(stat, group_pm)),
        child: Padding(padding: const EdgeInsets.all(8.0), child: child));
  }

  bool is_image_file(int transferred, int size, String file_path) {
    //  final file = File(file_path);
    if (file_path.endsWith(".jpg") ||
        file_path.endsWith(".JPG") ||
        file_path.endsWith(".jpeg") ||
        file_path.endsWith(".JPEG") ||
        file_path.endsWith(".png") ||
        file_path.endsWith(".PNG") ||
        file_path.endsWith(".gif") ||
        file_path.endsWith(".GIF") ||
        file_path.endsWith(".webp") ||
        file_path.endsWith(".WEBP") ||
        file_path.endsWith(".bmp") ||
        file_path.endsWith(".BMP") ||
        file_path.endsWith(".svg") ||
        file_path.endsWith(".SVG")) {
      /*    final imageBytes = file.readAsBytesSync();
      final decodedImage = decodeImage(imageBytes); // requires pub get image // GOAT consider actually checking if valid/existing
      if (decodedImage == null) return false; */ // TODO BAD IDEA, because this runs every rebuild
      return true;
    }
    return false;
  }

  double calculate_percentage(int size, int transferred, int status) {
    return transferred >= size && status != ENUM_FILE_OUTBOUND_PENDING
        ? 1
        : size > 0 && transferred != size
            ? transferred / size
            : 0;
  }

  int ui_load_more_messages(int n) {
    Pointer<Int> count_p = malloc(8); // free'd by calloc.free // 4 is wide enough, could be 8, should be sizeof, meh.
    Pointer<Int> ret = torx.message_load_more(count_p, n);
    torx.torx_free_simple(ret as Pointer<Void>);
    int count = count_p.value;
    malloc.free(count_p);
    return count;
  }

  Widget ui_message_builder(int n, int i) {
    int p_iter = torx.getter_int(n, i, -1, -1, offsetof("message", "p_iter"));
    int group_pm = protocol_int(p_iter, "group_pm");
    int file_offer = protocol_int(p_iter, "file_offer");
    int null_terminated_len = protocol_int(p_iter, "null_terminated_len");
    //  int file_checksum = protocol_int(p_iter, "file_checksum");
    int protocol = protocol_int(p_iter, "protocol");
    int stat = torx.getter_uint8(n, i, -1, -1, offsetof("message", "stat"));
    int message_len = torx.getter_uint32(n, i, -1, -1, offsetof("message", "message_len"));
    /*  int f = -1;

    if (file_checksum > 0) {
      f = torx.set_f_from_i(n, i);
    } */

    if (null_terminated_len > 0) {
      int stat = torx.getter_uint8(n, i, -1, -1, offsetof("message", "stat"));
      return message_bubble(
          stat,
          group_pm,
          GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              onLongPressStart: (touchDetail) {
                offs = touchDetail.globalPosition;
              },
              onLongPress: () {
                showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, controllerMessage, n, i, -1, -1));
              },
              child: Column(
                crossAxisAlignment: stat == ENUM_MESSAGE_RECV ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Text(
                    textAlign: TextAlign.left,
                    // NOTE: this is nonfile message // was formerly SelectableText but we need showMenu
                    getter_string(n, i, -1, offsetof("message", "message")),
                    style: TextStyle(color: _colorizeText(stat, group_pm)),
                  ),
                  messageTime(n, i)
                ],
              )));
    } else if (file_offer > 0) {
      int nnn = handle_stuff(n, i);
      int fff = torx.set_f_from_i(n, i);
      // NOTE: this is SENT OR RECEIVED file offer
      return message_bubble(
          stat,
          group_pm,
          AnimatedBuilder(
              animation: t_peer.t_file[nnn].changeNotifierTransferProgress[fff],
              builder: (BuildContext context, Widget? snapshot) {
                String filename = getter_string(nnn, INT_MIN, fff, offsetof("file", "filename"));
                String file_path = getter_string(nnn, INT_MIN, fff, offsetof("file", "file_path"));
                int size = torx.getter_uint64(nnn, INT_MIN, fff, -1, offsetof("file", "size"));
                int transferred = torx.calculate_transferred(nnn, fff);
                Pointer<Utf8> file_size_text_p = torx.file_progress_string(nnn, fff);
                String file_size_text = file_size_text_p.toDartString();
                torx.torx_free_simple(file_size_text_p as Pointer<Void>);
                int status = torx.getter_uint8(nnn, INT_MIN, fff, -1, offsetof("file", "status"));
                //    printf("Checkpoint file: $transferred $status");
                bool finished_file = size > 0 && size == transferred && size == get_file_size(file_path) ? true : false;
                bool finished_image = false;
                if (finished_file) finished_image = is_image_file(transferred, size, file_path);
                return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      torx.pthread_rwlock_rdlock(torx.mutex_global_variable);
                      Pointer<Utf8> download_dir = torx.download_dir[0];
                      torx.pthread_rwlock_unlock(torx.mutex_global_variable);
                      if ((filename == file_path || file_path == "") && download_dir == nullptr) {
                        String? selectedDirectory = await FilePicker.platform.getDirectoryPath(); // allows user to choose a directory
                        if (selectedDirectory != null && write_test(selectedDirectory)) {
                          String path = "$selectedDirectory/$filename";
                          Pointer<Utf8> file_path_p = path.toNativeUtf8(); // free'd by calloc.free
                          torx.file_set_path(nnn, fff, file_path_p);
                          calloc.free(file_path_p);
                          file_path_p = nullptr;
                          //    printf("Checkpoint accept_file: $path");
                          torx.file_accept(nnn, fff); // NOTE: having this in two places because this function is async
                          //    printf("Checkpoint have accepted file");
                        }
                      } else if (finished_file && finished_image) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) {
                          return RouteImage(file_path: file_path);
                        }));
                      } else if (finished_file) {
                        //      printf("Checkpoint OpenFile $file_path");
                        OpenFilex.open(file_path);
                      } else {
                        //    printf("Checkpoint should pause or start file transfer: $file_path");
                        torx.file_accept(nnn, fff); // NOTE: having this in two places because this function is async
                      }
                    },
                    onLongPressStart: (touchDetail) {
                      offs = touchDetail.globalPosition;
                    },
                    onLongPress: () {
                      showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, controllerMessage, n, i, fff, -1));
                    },
                    child: Column(
                      crossAxisAlignment: stat == ENUM_MESSAGE_RECV ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                      children: [
                        finished_image
                            ? Image.file(File(file_path), height: sticker_size * 2, fit: BoxFit.contain)
                            : Row(
                                // NOTE: this is file message
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: CircularPercentIndicator(
                                        radius: 30.0,
                                        lineWidth: 5.0,
                                        percent: finished_file ? 1 : calculate_percentage(size, transferred, status),
                                        center: Text(
                                          finished_file ? "100%" : "${(calculate_percentage(size, transferred, status) * 100).toStringAsFixed(0)}%",
                                          style: TextStyle(color: _colorizeText(stat, group_pm)),
                                        ),
                                        progressColor: Colors.green),
                                  ),
                                  Flexible(
                                      // THIS FLEXIBLE IS NECESSARY or there is an overflow here because Text widget cannot determine the size of the Row
                                      child: Column(
                                    children: [
                                      Text(
                                        filename, style: TextStyle(color: color.message_recv_text), // File title
                                      ),
                                      Text(
                                        file_size_text,
                                        style: TextStyle(color: _colorizeText(stat, group_pm)),
                                      )
                                    ],
                                  ))
                                ],
                              ),
                        messageTime(n, i)
                      ],
                    ));
              }));
    } else if (protocol == ENUM_PROTOCOL_GROUP_OFFER || protocol == ENUM_PROTOCOL_GROUP_OFFER_FIRST) {
      Pointer<Uint32> untrusted_peercount_p = malloc(4); // free'd by calloc.free
      int local_g = torx.set_g_from_i(untrusted_peercount_p, n, i);
      int untrusted_peercount = untrusted_peercount_p.value;
      calloc.free(untrusted_peercount_p);
      untrusted_peercount_p = nullptr;
      int local_g_invite_required = torx.getter_group_uint8(local_g, offsetof("group", "invite_required"));
      //    printf("Checkpoint group==$local_g $local_g_invite_required");
      int local_group_n = torx.getter_group_int(local_g, offsetof("group", "n"));
      int peercount;
      String group_name;
      String group_type = local_g_invite_required != 0 ? text.group_private : text.group_public;

      if (local_group_n > -1) {
        peercount = torx.getter_group_uint32(local_g, offsetof("group", "peercount"));
        group_name = getter_string(local_group_n, INT_MIN, -1, offsetof("peer", "peernick"));
      } else {
        peercount = untrusted_peercount;
        group_name = getter_group_id(local_g);
      }
      return message_bubble(
          stat,
          group_pm,
          InkWell(
              onTap: () {
                if (stat == ENUM_MESSAGE_RECV) {
                  torx.group_join_from_i(n, i);
                }
              },
              child: Column(
                crossAxisAlignment: stat == ENUM_MESSAGE_RECV ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Padding(padding: const EdgeInsets.only(right: 10.0), child: SvgPicture.asset(path_logo, color: color.logo, width: 40, height: 40)),
                    Flexible(
                      // THIS FLEXIBLE IS NECESSARY or there is an overflow here because Text widget cannot determine the size of the Row
                      child: Text("$group_type\n${text.current_members}$peercount\n$group_name", style: TextStyle(color: _colorizeText(stat, group_pm))),
                    )
                  ]),
                  messageTime(n, i)
                ],
              )));
    } else if (message_len >= CHECKSUM_BIN_LEN &&
        (protocol == ENUM_PROTOCOL_STICKER_HASH || protocol == ENUM_PROTOCOL_STICKER_HASH_PRIVATE || protocol == ENUM_PROTOCOL_STICKER_HASH_DATE_SIGNED)) {
      Image? animated_gif;
      int s = -1;
      return AnimatedBuilder(
          animation: changeNotifierStickerReady,
          builder: (BuildContext context, Widget? snapshot) {
            if (s < 0) {
              Pointer<Utf8> message_local = torx.getter_string(nullptr, n, i, -1, offsetof("message", "message"));
              s = ui_sticker_set(message_local as Pointer<Uint8>);
              torx.torx_free_simple(message_local as Pointer<Void>);
              message_local = nullptr;
            }
            return message_bubble(
                stat,
                group_pm,
                s > -1 && (animated_gif = sticker_generator(s)) != null
                    ? InkWell(
                        onLongPress: () {
                          showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, controllerMessage, n, i, -1, s));
                        },
                        child: Column(
                          crossAxisAlignment: stat == ENUM_MESSAGE_RECV ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                          children: [animated_gif!, messageTime(n, i)],
                        ))
                    : InkWell(
                        onLongPress: () {
                          showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, controllerMessage, n, i, -1, s));
                        },
                        child: Column(
                          crossAxisAlignment: stat == ENUM_MESSAGE_RECV ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                          children: [
                            enable_spinners && stat == ENUM_MESSAGE_RECV
                                ? const CircularProgressIndicator()
                                : SvgPicture.asset(path_logo, color: color.logo, width: sticker_size, height: sticker_size),
                            messageTime(n, i)
                          ],
                        )));
          });
    } else {
      return message_bubble(
          stat,
          group_pm,
          Column(
            crossAxisAlignment: stat == ENUM_MESSAGE_RECV ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [Text("Unrecognized message protocol: $protocol"), messageTime(n, i)],
          ));
    }
  }

  Widget message_builder(int n, int index) {
    int p_iter = torx.getter_int(n, index, -1, -1, offsetof("message", "p_iter"));
    int stat = torx.getter_uint8(n, index, -1, -1, offsetof("message", "stat"));
    if (p_iter < 0 ||
        protocol_int(p_iter, "notifiable") == 0 ||
        (stat == ENUM_MESSAGE_RECV && t_peer.mute[n] == 1 && torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "owner")) == ENUM_OWNER_GROUP_PEER)) {
      return const Padding(padding: EdgeInsets.only(right: 0.0)); // NOTE: invisible widget of zero size, for placeholder / deleted / ignored messages. could still flash something.
    } else {
      return Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(mainAxisAlignment: stat != ENUM_MESSAGE_RECV ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.only(right: 0.0)),
            Flexible(
              // This Flexible is NECESSARY to prevent horizontal overflow. This is the RIGHT location for it.
              child: ui_message_builder(n, index),
            ),
            const Padding(padding: EdgeInsets.only(right: 0.0)),
          ]));
    }
  }

  late Uint8List bytes;
  bool show_keyboard = true;
  bool currently_recording = false;
  final record = AudioRecorder();
  int former_text_len = t_peer.unsent[global_n].length;
  @override
  void dispose() {
    record.dispose(); // says we have to do this
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    owner = torx.getter_uint8(widget.n, INT_MIN, -1, -1, offsetof("peer", "owner"));
    g = owner == ENUM_OWNER_GROUP_CTRL ? torx.set_g(widget.n, nullptr) : -1;
    if (g > -1) {
      g_invite_required = torx.getter_group_uint8(g, offsetof("group", "invite_required"));
    }
    setLoggingIcon(widget.n);
    setBlockIcon(widget.n);
    setMuteIcon(widget.n);
    setStatusIcon(widget.n);
    setStatus(widget.n);
    //  controllerNick.text = Pointer<Utf8>.fromAddress(torx.torx_loo kup(globalCurrentRouteChatN, 8, 0, 0).address).toDartString();
    controllerMessage.text = t_peer.unsent[widget.n];
    SpellCheckConfiguration? ime_enabled_spellCheckConfiguration = const SpellCheckConfiguration.disabled();
    if (keyboard_privacy == false) {
      ime_enabled_spellCheckConfiguration = null;
    }
    return PopScope(
        onPopInvoked: (didPop) {
          scrollController.dispose();
          global_n = -1; // DO NOT PUT ONLY AT onPressed (otherwise it could get skipped)
          changeNotifierChatList.callback(integer: widget.n);
          controllerMessage.clear(); // must be after preceding callback
        },
        child: Scaffold(
          backgroundColor: color.right_panel_background,
          appBar: AppBar(
            backgroundColor: color.chat_headerbar,
            leading: IconButton(
              icon: AnimatedBuilder(
                  animation: changeNotifierOnlineOffline,
                  builder: (BuildContext context, Widget? snapshot) {
                    setStatusIcon(widget.n);
                    return statusIcon;
                  }),
              onPressed: () {
                Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst); // THIS WORKS, but sends us to login page.
                //      await SystemChannels.textInput.invokeMethod('TextInput.hide'); // attempts to close keyboard to work-around a bug. fails without await, or works a single time with await.
                //        Vibration.vibrate();
                //        FocusScope.of(context).unfocus(); // attempts to close keyboard to work-around a bug. fails.
                //        Vibration.vibrate();
                //      Navigator.pop(
                //        context); // FAILS if keyboard is open, on device only. NOTE: this bug is likely due to an issue with how we autoFocus to the message entry. The focus in context is somehow not clear, which is probably also why we have no cursor. When we get a cursor, this bug will probably disappear.
              },
            ),
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//            Text(Pointer<Utf8>.fromAddress(torx.torx_loo kup(globalCurrentRouteChatN, 8, 0, 0).address).toDartString()),
              Focus(
                onFocusChange: (hasFocus) {
                  hasFocus ? null : changeNick(widget.n, controllerNick);
                },
                child: TextField(
                  controller: controllerNick,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  scribbleEnabled: false,
                  spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                  showCursor: true,
                  onEditingComplete: () {
                    changeNick(widget.n, controllerNick);
                  },
                  style: TextStyle(fontSize: 24, color: color.chat_name),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              AnimatedBuilder(
                  animation: changeNotifierOnlineOffline,
                  builder: (BuildContext context, Widget? snapshot) {
                    setStatus(widget.n);
                    return InkWell(
                        onTap: () {
                          if (g > -1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RoutePopoverList(ENUM_OWNER_GROUP_PEER, g)),
                            );
                          }
                        },
                        child: Text(
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                              color: color.last_online,
                            ),
                            statusText));
                  }),
            ]),
            actions: [
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: color.torch_off),
                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                  CustomPopupMenuItem(
                    color: color.chat_headerbar,
                    child: ListTile(
                      leading: loggingIcon,
                      title: Text(
                        loggingText,
                        style: TextStyle(color: color.page_title),
                      ),
                      iconColor: loggingColor,
                      onTap: () {
                        toggleLogging(widget.n);
                        Navigator.pop(context); // pop the menu because set State doesn't update it (we tried)
                      },
                    ),
                  ),
                  CustomPopupMenuItem(
                    color: color.chat_headerbar,
                    child: ListTile(
                      leading: muteIcon,
                      title: Text(
                        muteText,
                        style: TextStyle(color: color.page_title),
                      ),
                      onTap: () {
                        toggleMute(widget.n);
                        Navigator.pop(context); // pop the menu because set State doesn't update it (we tried)
                      },
                    ),
                  ),
                  if (g < 0)
                    CustomPopupMenuItem(
                      color: color.chat_headerbar,
                      child: ListTile(
                        leading: const Icon(Icons.block),
                        title: Text(
                          blockText,
                          style: TextStyle(color: color.page_title),
                        ),
                        iconColor: blockColor,
                        onTap: () {
                          toggleBlock(widget.n);
                          Navigator.pop(context); // pop the menu because set State doesn't update it (we tried)
                        },
                      ),
                    ),
                  if (g > -1)
                    CustomPopupMenuItem(
                      color: color.chat_headerbar,
                      child: ListTile(
                        leading: const Icon(Icons.add),
                        title: Text(
                          text.invite_friend,
                          style: TextStyle(color: color.page_title),
                        ),
                        iconColor: color.torch_off,
                        onTap: () {
                          Navigator.pop(context); // pop the menu
                          torx.getter_group_uint8(g, offsetof("group", "invite_required")) != 0
                              ? Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => RoutePopoverList(ENUM_OWNER_CTRL, g)),
                                )
                              : Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => RouteShowQr(getter_group_id(g))),
                                );
                        },
                      ),
                    ),
                  //      const PopupMenuDivider(), // no color, must replace
                  CustomPopupMenuItem(color: color.chat_headerbar, child: Divider(color: color.page_title)),
                  if (g < 0)
                    CustomPopupMenuItem(
                      color: color.chat_headerbar,
                      child: ListTile(
                        leading: Icon(Icons.fireplace_outlined, color: color.torch_off),
                        title: Text(
                          text.kill,
                          style: TextStyle(color: color.page_title),
                        ),
                        iconColor: color.torch_off,
                        onTap: () {
                          // DO NOT SET STATE HERE because its all zeros. We should popuntil instead
                          toggleKill(widget.n);
                          int count = 0;
                          Navigator.popUntil(context, (route) {
                            return count++ == 2;
                          });
                          //        Navigator.of(context).popUntil(ModalRoute.withName("/RouteChatList"));
                        },
                      ),
                    ),
                  CustomPopupMenuItem(
                    color: color.chat_headerbar,
                    child: ListTile(
                      leading: Icon(Icons.delete, color: color.torch_off),
                      title: Text(
                        text.delete,
                        style: TextStyle(color: color.page_title),
                      ),
                      iconColor: color.torch_off,
                      onTap: () {
                        // DO NOT SET STATE HERE because its all zeros. We should popuntil instead
                        toggleDelete(widget.n);
                        int count = 0;
                        Navigator.popUntil(context, (route) {
                          return count++ == 2;
                        });
                        //      Navigator.of(context).popUntil(ModalRoute.withName("/RouteChatList"));
                      },
                    ),
                  ),
                  CustomPopupMenuItem(
                    color: color.chat_headerbar,
                    child: ListTile(
                      leading: Icon(Icons.delete, color: color.torch_off),
                      title: Text(
                        text.delete_log,
                        style: TextStyle(color: color.page_title),
                      ),
                      iconColor: color.torch_off,
                      onTap: () {
                        torx.delete_log(widget.n);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ), // globalCurrentRouteChatN

          body: Column(
            children: [
              Expanded(
                  child:
                      // This expanded is necessary for listview
                      AnimatedBuilder(
                          // this rebuilds every time but might not be expensive because of shrinkWrap and the reversed SingleChildScrollView
                          // if determined to still be too expensive, add to it dynamically https://googleflutter.com/flutter-add-item-to-listview-dynamically/
                          animation: changeNotifierMessage,
                          builder: (BuildContext context, Widget? snapshot) {
                            int starting_msg_count;
                            if (g > -1) {
                              starting_msg_count = torx.getter_group_uint32(g, offsetof("group", "msg_count"));
                            } else {
                              starting_msg_count = torx.getter_int(widget.n, INT_MIN, -1, -1, offsetof("peer", "max_i")) + 1;
                            }
                            int current_msg_count = starting_msg_count; // UNSURE OF VALUE (if any)
                            return owner == ENUM_OWNER_GROUP_CTRL
                                ? ListView.builder(
                                    reverse: true,
                                    shrinkWrap: true,
                                    controller: scrollController,
                                    //      itemCount: current_msg_count,
                                    itemBuilder: (context, index) {
                                      if (index == current_msg_count - 1) {
                                        current_msg_count += ui_load_more_messages(widget.n);
                                      } else if (index > current_msg_count - 1) {
                                        return null;
                                      }
                                      Pointer<Int> n_p = malloc(8); // free'd by calloc.free
                                      Pointer<Int> i_p = malloc(8); // free'd by calloc.free
                                      torx.group_get_index(n_p, i_p, g, current_msg_count - 1 - index);
                                      int n = n_p.value;
                                      int i = i_p.value;
                                      calloc.free(n_p);
                                      n_p = nullptr;
                                      calloc.free(i_p);
                                      i_p = nullptr;
                                      return message_builder(n, i);
                                    },
                                  )
                                : ListView.builder(
                                    reverse: true,
                                    shrinkWrap: true,
                                    controller: scrollController,
                                    //    itemCount: current_msg_count, // REMOVED PERMANENTLY to support unlimited scroll
                                    itemBuilder: (context, index) {
                                      int i = starting_msg_count - 1 - index;
                                      int min_i = torx.getter_int(widget.n, INT_MIN, -1, -1, offsetof("peer", "min_i"));
                                      if (i == min_i) {
                                        /*current_msg_count += */ ui_load_more_messages(widget.n);
                                      } else if (i < min_i) {
                                        return null;
                                      }
                                      return message_builder(widget.n, i);
                                    },
                                  );
                          })),
              AnimatedBuilder(
                  animation: changeNotifierActivity,
                  builder: (BuildContext context, Widget? snapshot) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (t_peer.pm_n[widget.n] > -1 || t_peer.edit_n[widget.n] > -1)
                          FloatingActionButton.extended(
                              onPressed: () {
                                if (t_peer.edit_n[widget.n] > -1) {
                                  former_text_len = 0;
                                  controllerMessage.clear();
                                }
                                t_peer.pm_n[widget.n] = -1;
                                t_peer.edit_n[widget.n] = -1;
                                t_peer.edit_i[widget.n] = INT_MIN;
                                changeNotifierActivity.callback(integer: 1); // value is arbitrary
                              },
                              label: t_peer.pm_n[widget.n] > -1
                                  ? Text("${text.private_messaging} ${getter_string(t_peer.pm_n[widget.n], INT_MIN, -1, offsetof("peer", "peernick"))}")
                                  : Text(text.cancel_editing))
                      ],
                    );
                  }),
              Row(
                children: [
                  //  const Icon(Icons.emoji_emotions_outlined), //  decide whether to implement a unicode emoji picker (homemade is cleaner/safer) or to rely on keyboards to offer
                  Flexible(
                    child: Container(
                        constraints: const BoxConstraints(
                          maxHeight:
                              381, // was 400. reduced by 19 because fat fingers  GOAT should be sizeof(keyboard)+sizeof(appbar)+ some space, ediaQuery.of(context).size.height - (Scaffold.of(context).appBarMaxHeight! + $keboard + 24)
                        ),
                        margin: const EdgeInsets.only(left: 5.0, bottom: 15.0, top: 8.0), // fat fingers
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: color.write_message_background),
                        child: Padding(
                            padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                            child: AnimatedBuilder(
                                animation: changeNotifierTextOrAudio,
                                builder: (BuildContext context, Widget? snapshot) {
                                  return show_keyboard
                                      ? TextField(
                                          maxLines: null,
                                          controller: controllerMessage,
                                          autocorrect: !keyboard_privacy, // Android + iOS
                                          enableSuggestions: !keyboard_privacy, // Only affects android
                                          enableIMEPersonalizedLearning: false, // Only affects android
                                          scribbleEnabled: false,
                                          spellCheckConfiguration: ime_enabled_spellCheckConfiguration, // const SpellCheckConfiguration.disabled(), // Android + iOS
                                          showCursor: true,
                                          autofocus: autoFocusKeyboard,
                                          onChanged: (value) {
                                            int text_len = controllerMessage.text.length;
                                            if (text_len == 0 || former_text_len == 0) {
                                              changeNotifierSendButton.callback(integer: 1); // value is arbitrary
                                            }
                                            former_text_len = text_len;
                                            //  printf("Checkpoint 1, if after detach, t_peer.unsent may not exist for n=${widget.n}");
                                            t_peer.unsent[widget.n] = controllerMessage.text;
                                          },
                                          style: TextStyle(color: color.write_message_text),
                                        )
                                      : SizedBox(
                                          width: double.infinity,
                                          child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onLongPressDown: (yes) async {
                                                if (await record.hasPermission()) {
                                                  printf("Start recording");
                                                  currently_recording = true;
                                                  changeNotifierTextOrAudio.callback(integer: 1); // arbitrary value
                                                  String path = "$temporaryDir/myFile.m4a";
                                                  //  record.start(const RecordConfig(encoder: AudioEncoder.aacEld, noiseSuppress: true, echoCancel: true), path: path);
                                                  (await record.startStream(const RecordConfig(encoder: AudioEncoder.aacEld, noiseSuppress: true, echoCancel: true))).listen(
                                                    // TODO this doesn't work, but we *used to* have it working
                                                    (data) {
                                                      // ignore: avoid_print
                                                      print(
                                                        record.convertBytesToInt16(Uint8List.fromList(data)),
                                                      );
                                                      printf("Chicken");
                                                      File(path).writeAsBytesSync(data, mode: FileMode.append);
                                                    },
                                                    onDone: () {
                                                      printf('End of stream. File written to $path.');
                                                    },
                                                  );
                                                }
                                              },
                                              onLongPressCancel: () async {
                                                if (currently_recording) {
                                                  printf("Cancel recording. Too short.");
                                                  currently_recording = false;
                                                  changeNotifierTextOrAudio.callback(integer: 1); // arbitrary value
                                                  await record.cancel();
                                                }
                                              },
                                              onLongPressMoveUpdate: (det) async {
                                                if (currently_recording && det.localOffsetFromOrigin.distance > 100) {
                                                  printf("Cancel via drag");
                                                  currently_recording = false;
                                                  changeNotifierTextOrAudio.callback(integer: 1); // arbitrary value
                                                  await record.cancel();
                                                }
                                              },
                                              onLongPressUp: () async {
                                                if (currently_recording) {
                                                  printf("Send audio");
                                                  currently_recording = false;
                                                  changeNotifierTextOrAudio.callback(integer: 1); // arbitrary value
                                                  final path = await record.stop();
                                                  final player = AudioPlayer();
                                                  if (path != null) {
                                                    printf("Playing bytes: $path");
                                                    bytes = await File(path).readAsBytes();
                                                    await player.play(BytesSource(bytes));
                                                  } else {
                                                    await player.play(BytesSource(bytes));
                                                  }
                                                }
                                              },
                                              child: MaterialButton(
                                                  onPressed: () {},
                                                  elevation: 5,
                                                  color: currently_recording ? color.auth_error : color.auth_button_hover,
                                                  child: Text(
                                                    text.hold_to_talk,
                                                    style: TextStyle(color: color.auth_button_text),
                                                  ))));
                                }))),
                  ),
                  AnimatedBuilder(
                      animation: changeNotifierSendButton,
                      builder: (BuildContext context, Widget? snapshot) {
                        return Row(children: [
                          if (controllerMessage.text.isEmpty)
                            IconButton(
                                icon: show_keyboard ? Icon(Icons.mic, color: color.torch_off) : Icon(Icons.keyboard, color: color.torch_off),
                                onPressed: () {
                                  if (show_keyboard) {
                                    show_keyboard = false;
                                  } else {
                                    show_keyboard = true;
                                  }
                                  changeNotifierTextOrAudio.callback(integer: 1); // value is arbitrary
                                  changeNotifierSendButton.callback(integer: 1); // value is arbitrary
                                }),
                          if (controllerMessage.text.isEmpty)
                            IconButton(
                                icon: Icon(Icons.gif_box_outlined, color: color.torch_off),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RouteStickers()),
                                  );
                                }),
                          IconButton(
                            icon: controllerMessage.text.isEmpty ? Icon(Icons.attach_file, color: color.torch_off) : Icon(Icons.send, color: color.torch_off),
                            onPressed: () async {
                              if (controllerMessage.text.isEmpty) {
                                // GOAT file_picker here, allow multiple selections
                                FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
                                if (result != null) {
                                  List<File> files = result.paths.map((path) => File(path!)).toList();
                                  int file_iter = 0;
                                  while (file_iter < files.length) {
                                    //        printf("Checkpoint send_file ${files[file_iter].path}"); // GOAT file_picker caches. we don't want caching. https://github.com/miguelpruivo/flutter_file_picker/issues/40 https://github.com/miguelpruivo/flutter_file_picker/issues/1093
                                    Pointer<Utf8> file_path = files[file_iter].absolute.path.toNativeUtf8(); // free'd by calloc.free
                                    if (t_peer.pm_n[widget.n] > -1) {
                                      torx.file_send(t_peer.pm_n[widget.n], file_path);
                                    } else {
                                      torx.file_send(widget.n, file_path);
                                    }
                                    calloc.free(file_path);
                                    file_path = nullptr;
                                    file_iter++;
                                  }
                                }
                              } else {
                                Pointer<Utf8> message = controllerMessage.text.toNativeUtf8(); // free'd by calloc.free
                                if (t_peer.edit_n[widget.n] > -1 && t_peer.edit_i[widget.n] > INT_MIN) {
                                  torx.message_edit(t_peer.edit_n[widget.n], t_peer.edit_i[widget.n], message);
                                  t_peer.edit_n[widget.n] = -1;
                                  t_peer.edit_i[widget.n] = INT_MIN;
                                } else if (t_peer.edit_n[widget.n] > -1) {
                                  torx.change_nick(t_peer.edit_n[widget.n], message);
                                  setState(() {
                                    t_peer.edit_n[widget.n] = -1;
                                  }); // SLOW-ROUTE need to rebuild NICKNAME (maybe on all messages, if group, so this might be ok)
                                } else if (t_peer.pm_n[widget.n] > -1) {
                                  torx.message_send(t_peer.pm_n[widget.n], ENUM_PROTOCOL_UTF8_TEXT_PRIVATE, message as Pointer<Void>, message.length);
                                } else if (owner == ENUM_OWNER_GROUP_CTRL) {
                                  g = torx.set_g(widget.n, nullptr);
                                  g_invite_required = torx.getter_group_uint8(g, offsetof("group", "invite_required"));
                                  if (owner == ENUM_OWNER_GROUP_CTRL && g_invite_required != 0) {
                                    // date && sign private group messages
                                    torx.message_send(widget.n, ENUM_PROTOCOL_UTF8_TEXT_DATE_SIGNED, message as Pointer<Void>, message.length);
                                  } else {
                                    torx.message_send(widget.n, ENUM_PROTOCOL_UTF8_TEXT, message as Pointer<Void>, message.length);
                                  }
                                } else {
                                  torx.message_send(widget.n, ENUM_PROTOCOL_UTF8_TEXT, message as Pointer<Void>, message.length);
                                }
                                calloc.free(message);
                                message = nullptr;
                                former_text_len = 0;
                                controllerMessage.clear();
                                changeNotifierSendButton.callback(integer: 1); // value is arbitrary
                                //      printf("Checkpoint 2, if after detach, t_peer.unsent may not exist for n=${widget.n}");
                                t_peer.unsent[widget.n] = "";
                              }
                            },
                          ),
                        ]);
                      }),
                ],
              ),
            ],
          ),
        ));
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class RouteChatList extends StatefulWidget {
  const RouteChatList({super.key});

  @override
  State<RouteChatList> createState() => _RouteChatListState();
}

class _RouteChatListState extends State<RouteChatList> with TickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3, initialIndex: current_index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TextEditingController controllerSearch = TextEditingController();
  String searchText = "";
  ListView populatePeerList(int type, String search) {
    Pointer<Int> len_p = malloc(8); // free'd by calloc.free // 4 is wide enough, could be 8, should be sizeof, meh.
    Pointer<Utf8> search_p = search.toNativeUtf8(); // free'd by calloc.free
    Pointer<Int> arrayFriends;
    int owner;
    if (type == ENUM_STATUS_GROUP_CTRL) {
      owner = ENUM_OWNER_GROUP_CTRL;
      arrayFriends = torx.refined_list(len_p, ENUM_OWNER_GROUP_CTRL, ENUM_STATUS_FRIEND, search_p);
    } else {
      owner = ENUM_OWNER_CTRL;
      arrayFriends = torx.refined_list(len_p, ENUM_OWNER_CTRL, type, search_p);
    }
    int len = len_p.value;
    calloc.free(len_p);
    len_p = nullptr;
    calloc.free(search_p);
    search_p = nullptr;
    return ListView.builder(
      itemCount: len,
      prototypeItem: const ListTile(
        title: Text("This is dummy text used to set height. Can be dropped."),
      ),
      itemBuilder: (context, index) {
        Color dotColor = ui_statusColor(arrayFriends[index]);
        Pointer<Int> nn_p = malloc(8); // free'd by calloc.free // 4 is wide enough, could be 8, should be sizeof, meh.
        int i = INT_MIN;
        for (int count_back = 0; (i = torx.set_last_message(nn_p, arrayFriends[index], count_back)) > INT_MIN; count_back++) {
          if (t_peer.mute[nn_p.value] == 1 && torx.getter_uint8(nn_p.value, INT_MIN, -1, -1, offsetof("peer", "owner")) == ENUM_OWNER_GROUP_PEER) {
            continue; // do not print, these are hidden messages from ignored users
          } else {
            break;
          }
        }
        int nn = nn_p.value;
        calloc.free(nn_p);
        nn_p = nullptr;
        String prefix = "";
        String lastMessage = "";
        int p_iter;
        if (i > INT_MIN && (p_iter = torx.getter_int(nn, i, -1, -1, offsetof("message", "p_iter"))) > -1) {
          int max_i = torx.getter_int(nn, INT_MIN, -1, -1, offsetof("peer", "max_i"));
          if (max_i > INT_MIN || t_peer.unsent[nn].isNotEmpty) {
            int protocol = protocol_int(p_iter, "protocol");
            int file_offer = protocol_int(p_iter, "file_offer");
            int null_terminated_len = protocol_int(p_iter, "null_terminated_len");
            int stat = torx.getter_uint8(nn, i, -1, -1, offsetof("message", "stat"));
            if (t_peer.unsent[arrayFriends[index]].isNotEmpty) {
              prefix = text.draft;
            } else if (stat == ENUM_MESSAGE_RECV && t_peer.unread[arrayFriends[index]] > 0) {
              /* no prefix on recv */
            } else if (stat == ENUM_MESSAGE_FAIL && owner != ENUM_OWNER_GROUP_CTRL) {
              prefix = text.queued;
            } else if (stat != ENUM_MESSAGE_RECV) {
              prefix = text.you;
            }
            if (t_peer.unsent[arrayFriends[index]].isNotEmpty) {
              lastMessage = t_peer.unsent[arrayFriends[index]];
            } else if (file_offer > 0) {
              int nnn = nn;
              if (protocol == ENUM_PROTOCOL_FILE_OFFER_GROUP || protocol == ENUM_PROTOCOL_FILE_OFFER_GROUP_DATE_SIGNED) {
                int g = torx.set_g(nn, nullptr);
                nnn = torx.getter_group_int(g, offsetof("group", "n"));
              }
              int f = torx.set_f_from_i(nnn, i);
              f > -1 ? lastMessage = getter_string(nnn, INT_MIN, f, offsetof("file", "filename")) : lastMessage = "Invalid file offer";
            } else if (null_terminated_len > 0) {
              lastMessage = getter_string(nn, i, -1, offsetof("message", "message"));
            } else if (protocol == ENUM_PROTOCOL_GROUP_OFFER || protocol == ENUM_PROTOCOL_GROUP_OFFER_FIRST) {
              lastMessage = text.group_offer;
            } else if (protocol == ENUM_PROTOCOL_STICKER_HASH || protocol == ENUM_PROTOCOL_STICKER_HASH_PRIVATE || protocol == ENUM_PROTOCOL_STICKER_HASH_DATE_SIGNED) {
              lastMessage = text.sticker;
            } else {
              lastMessage = protocol.toString();
            }
          }
        }
        Widget dot = type == ENUM_STATUS_GROUP_CTRL ? SvgPicture.asset(path_logo, color: color.logo, width: 20, height: 20) : Icon(Icons.circle, color: dotColor, size: 20);
        return ListTile(
          leading: Badge(
            isLabelVisible: t_peer.unread[arrayFriends[index]] > 0,
            label: Text(t_peer.unread[arrayFriends[index]].toString()),
            child: dot,
          ),
          title: Text(
            getter_string(arrayFriends[index], INT_MIN, -1, offsetof("peer", "peernick")),
            style: TextStyle(color: color.group_or_user_name, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            //    overflow: TextStyle.overflow,
            //    softWrap: false,
            "$prefix$lastMessage",
            maxLines: 2,
            style: TextStyle(color: color.last_message, fontSize: 12),
          ),
          onTap: () {
            global_n = arrayFriends[index];
            if (t_peer.unread[arrayFriends[index]] > 0) {
              //    printf("Checkpoint unreads to wipe");
              int owner = torx.getter_uint8(arrayFriends[index], INT_MIN, -1, -1, offsetof("peer", "owner"));
              if (owner == ENUM_OWNER_GROUP_CTRL) {
                totalUnreadGroup -= t_peer.unread[arrayFriends[index]];
              } else {
                totalUnreadPeer -= t_peer.unread[arrayFriends[index]];
              }
              t_peer.unread[arrayFriends[index]] = 0;
              changeNotifierTotalUnread.callback(integer: -4);
              changeNotifierChatList.callback(integer: t_peer.unread[arrayFriends[index]]);
              if (launcherBadges) {
                AppBadgePlus.updateBadge(totalUnreadPeer + totalUnreadGroup + totalIncoming);
              }
            }
            //    printf("Checkpoint RouteChat n=${arrayFriends[index]}");
            Navigator.push(context, MaterialPageRoute(builder: (context) => RouteChat(arrayFriends[index])));
          },
        );
      },
    );
  }

  double searchWidth = 40;
  Color searchColor = Colors.transparent;
  bool searchOpen = false;
  Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    if (searchOpen == true) {
      searchColor = color.search_field_background;
      searchWidth = 180;
      suffixIcon = IconButton(
        icon: Icon(Icons.clear, color: color.search_field_text),
        onPressed: () {
          setState(() {
            searchOpen = false;
          });
        },
      );
    } else {
      controllerSearch.clear();
      searchText = "";
      searchColor = Colors.transparent;
      searchWidth = 40;
      suffixIcon = null;
    }

    return PopScope(
        onPopInvoked: (didPop) {},
        child: Scaffold(
          backgroundColor: color.left_panel,
          appBar: AppBar(
            backgroundColor: color.chat_headerbar,
            leading: SvgPicture.asset(path_logo, color: color.logo),
            title: Text(
              text.title,
              style: TextStyle(color: color.page_title),
            ),
            automaticallyImplyLeading: false,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: [
                Tab(
                    child: AnimatedBuilder(
                        animation: changeNotifierTotalUnread,
                        builder: (BuildContext context, Widget? snapshot) {
                          return Badge(isLabelVisible: totalUnreadPeer > 0, offset: const Offset(15, -12), label: Text(totalUnreadPeer.toString()), child: Text(text.peer));
                        })),
                Tab(
                    child: AnimatedBuilder(
                        animation: changeNotifierTotalUnread,
                        builder: (BuildContext context, Widget? snapshot) {
                          return Badge(isLabelVisible: totalUnreadGroup > 0, offset: const Offset(15, -12), label: Text(totalUnreadGroup.toString()), child: Text(text.group));
                        })),
                Tab(text: text.block),
              ],
            ),
            actions: [
              Container(
                width: searchWidth,
                height: 30,
                decoration: BoxDecoration(color: searchColor, borderRadius: BorderRadius.circular(5)),
                child: Center(
                  child: TextField(
                    controller: controllerSearch,
                    autocorrect: false,
                    enableSuggestions: false,
                    enableIMEPersonalizedLearning: false,
                    scribbleEnabled: false,
                    spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                    showCursor: true,
                    onChanged: (content) {
                      setState(() {
                        searchText = content;
                      });
                    },
                    style: TextStyle(color: color.search_field_text),
                    decoration: InputDecoration(
                        suffixIcon: suffixIcon,
                        prefixIcon: IconButton(
                          icon: Icon(Icons.search, color: searchOpen == false ? color.torch_off : color.torch_on),
                          onPressed: () {
                            setState(() {
                              if (searchOpen == true) {
                                searchOpen = false;
                              } else {
                                searchOpen = true;
                              }
                            });
                          },
                        ),
                        hintText: text.placeholder_search,
                        hintStyle: TextStyle(color: color.torch_on),
                        border: InputBorder.none),
                  ),
                ),
              )
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              Center(
                  child: AnimatedBuilder(
                      animation: changeNotifierChatList,
                      builder: (BuildContext context, Widget? snapshot) {
                        current_index = 0;
                        return populatePeerList(ENUM_STATUS_FRIEND, searchText);
                      })),
              Center(
                  child: AnimatedBuilder(
                      animation: changeNotifierChatList,
                      builder: (BuildContext context, Widget? snapshot) {
                        current_index = 1;
                        return populatePeerList(ENUM_STATUS_GROUP_CTRL, searchText);
                      })),
              Center(
                  child: AnimatedBuilder(
                      animation: changeNotifierChatList,
                      builder: (BuildContext context, Widget? snapshot) {
                        current_index = 2;
                        return populatePeerList(ENUM_STATUS_BLOCKED, searchText);
                      })),
            ],
          ),
        ));
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class RouteLogTor extends StatefulWidget {
  const RouteLogTor({super.key});

  @override
  State<RouteLogTor> createState() => _RouteLogTorState();
}

class _RouteLogTorState extends State<RouteLogTor> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom(scrollcontroller_log_tor));
    return Scaffold(
      backgroundColor: color.right_panel_background,
      appBar: AppBar(
          backgroundColor: color.chat_headerbar,
          title: Text(
            text.tor_log,
            style: TextStyle(color: color.page_title),
          )),
      body: SingleChildScrollView(
          controller: scrollcontroller_log_tor,
          child: AnimatedBuilder(
              animation: changeNotifierTorLog,
              builder: (BuildContext context, Widget? snapshot) {
                return SelectableText(
                  torLogBuffer,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 12,
                    color: color.right_panel_text,
                  ),
                );
              })),
      bottomNavigationBar: BottomAppBar(
        color: color.right_panel_background,
        child: MaterialButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: torLogBuffer));
          },
          height: 20,
          minWidth: 20,
          elevation: 5,
          color: color.button_background,
          child: Text(
            text.copy_all,
            style: TextStyle(color: color.button_text),
          ),
        ),
      ),
    );
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class RouteLogTorX extends StatefulWidget {
  const RouteLogTorX({super.key});

  @override
  State<RouteLogTorX> createState() => _RouteLogTorXState();
}

class _RouteLogTorXState extends State<RouteLogTorX> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom(scrollcontroller_log_torx));
    return Scaffold(
      backgroundColor: color.right_panel_background,
      appBar: AppBar(
          backgroundColor: color.chat_headerbar,
          title: Text(
            text.torx_log,
            style: TextStyle(color: color.page_title),
          ),
          actions: [
            Align(
              alignment: Alignment.center,
              child: Text(
                "${text.debug_level} ${torx.torx_debug_level(-1).toString()}",
                style: TextStyle(color: color.page_title),
              ),
            ),
            IconButton(
                onPressed: () {
                  int level = torx.torx_debug_level(-1);
                  if (level < 5) {
                    setState(() {
                      torx.torx_debug_level(++level);
                    });
                  }
                },
                icon: Icon(Icons.add, color: color.torch_off)),
            IconButton(
                onPressed: () {
                  int level = torx.torx_debug_level(-1);
                  if (level > 0) {
                    setState(() {
                      torx.torx_debug_level(--level);
                    });
                  }
                },
                icon: Icon(Icons.remove, color: color.torch_off)),
          ]),
      body: SingleChildScrollView(
          controller: scrollcontroller_log_torx,
          child: AnimatedBuilder(
              animation: changeNotifierError,
              builder: (BuildContext context, Widget? snapshot) {
                return SelectableText(
                  torxLogBuffer,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 12,
                    color: color.right_panel_text,
                  ),
                );
              })),
      bottomNavigationBar: BottomAppBar(
        color: color.right_panel_background,
        child: MaterialButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: torxLogBuffer));
          },
          height: 20,
          minWidth: 20,
          elevation: 5,
          color: color.button_background,
          child: Text(
            text.copy_all,
            style: TextStyle(color: color.button_text),
          ),
        ),
      ),
    );
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
/*
Future<ByteData?>? genQr(String arg) {
  final qrValidationResult = QrValidator.validate(
    data: arg,
    version: QrVersions.auto,
    //  errorCorrectionLevel: QrErrorCorrectLevel.L,
  );
  if (qrValidationResult.status == QrValidationStatus.valid) {
    final painter = QrPainter.withQr(
      qr: qrValidationResult.qrCode!,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
      embeddedImageStyle: null,
      embeddedImage: null,
    );
    return painter.toImageData(2048, format: ui.ImageByteFormat.png);
  } else {
    error(0, "Flutter UI QR generation failed3: ${qrValidationResult.error.toString()}");
    return null;
  }
} */
class RouteShowQr extends StatefulWidget {
  final String data;
  const RouteShowQr(this.data, {super.key});

  @override
  State<RouteShowQr> createState() => _RouteShowQr();
}

Future<void> saveQr(String data) async {
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath(); // allows user to choose a directory
  if (selectedDirectory != null && write_test(selectedDirectory)) {
    //  printf("Selected dir: $selectedDirectory");
    int datetime = (DateTime.now()).millisecondsSinceEpoch; // seconds since epoch is safe because it has no timezone attached
    Pointer<Utf8> data_p = data.toNativeUtf8(); // free'd by calloc.free
    Pointer<Size_t> size_p = malloc(8); // free'd by calloc.free // 4 is wide enough, could be 8, should be sizeof, meh.
    Pointer<Void> qr_raw = torx.qr_bool(data_p, 8); // free'd by torx_free
    Pointer<Void> png = torx.return_png(size_p, qr_raw); // free'd by torx_free
    String path = "$selectedDirectory/qr$datetime.png";
    Pointer<Utf8> destination = path.toNativeUtf8(); // free'd by calloc.free
    torx.write_bytes(destination, png, size_p.value);
    MediaScanner.loadMedia(path: path);
    torx.torx_free_simple(qr_raw);
    qr_raw = nullptr;
    torx.torx_free_simple(png);
    png = nullptr;
    calloc.free(data_p);
    data_p = nullptr;
    calloc.free(size_p);
    size_p = nullptr;
    calloc.free(destination);
    destination = nullptr;
  }
}

class _RouteShowQr extends State<RouteShowQr> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: color.right_panel_background,
        appBar: AppBar(
            backgroundColor: color.chat_headerbar,
            title: Text(
              text.show_qr,
              style: TextStyle(color: color.page_title),
            )),
        body: SingleChildScrollView(
          child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                generate_qr(widget.data),
                SelectableText(
                  widget.data,
                  style: TextStyle(color: color.page_subtitle, fontSize: 12),
                ),
                MaterialButton(
                  onPressed: () async {
                    // final ts = DateTime.now().millisecondsSinceEpoch.toString();
                    String path =
                        '$temporaryDir/qr.png'; // might want to make this name unique if sending them in rapid succession causes corruption. depends on how OS handles sharing. if so, use above line
                    Pointer<Size_t> size_p = malloc(8); // free'd by calloc.free // 4 is wide enough, could be 8, should be sizeof, meh.
                    Pointer<Utf8> data_p = widget.data.toNativeUtf8(); // free'd by calloc.free
                    Pointer<Void> qr_raw = torx.qr_bool(data_p, 8); // free'd by torx_free
                    Pointer<Void> png = torx.return_png(size_p, qr_raw); // free'd by torx_free
                    Pointer<Utf8> destination = path.toNativeUtf8(); // free'd by calloc.free
                    torx.write_bytes(destination, png, size_p.value);
                    torx.torx_free_simple(qr_raw);
                    qr_raw = nullptr;
                    torx.torx_free_simple(png);
                    png = nullptr;
                    calloc.free(size_p);
                    size_p = nullptr;
                    calloc.free(data_p);
                    data_p = nullptr;
                    calloc.free(destination);
                    destination = nullptr;
                    Share.shareXFiles(
                      [XFile(path)],
                    );
                    // GOAT delete getTemporaryDirectory().path/qr.png on program startup and shutdown
                  },
                  height: 30,
                  minWidth: 60,
                  elevation: 5,
                  color: color.button_background,
                  child: Text(
                    text.share_qr,
                    style: TextStyle(color: color.button_text),
                  ),
                ),
                MaterialButton(
                  onPressed: () {
                    saveQr(widget.data);
                  },
                  height: 20,
                  minWidth: 20,
                  elevation: 5,
                  color: color.button_background,
                  child: Text(
                    text.save_qr,
                    style: TextStyle(color: color.button_text),
                  ),
                ),
                // If the share button doesn't allow saving and it is desirable, we might need https://pub.dev/packages/image_gallery_saver which is based on https://pub.dev/packages/gallery_saver
              ])),
        ));
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class RouteGlobalKill extends StatefulWidget {
  const RouteGlobalKill({super.key});

  @override
  State<RouteGlobalKill> createState() => _RouteGlobalKillState();
}

class _RouteGlobalKillState extends State<RouteGlobalKill> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: color.right_panel_background,
        appBar: AppBar(
            backgroundColor: color.chat_headerbar,
            title: Text(
              text.global_kill,
              style: TextStyle(color: color.page_title),
            )),
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      text.warning,
                      style: TextStyle(color: color.page_subtitle, fontSize: 18),
                    ),
                    Text(
                      text.global_kill_warning,
                      style: TextStyle(color: color.right_panel_text),
                    ),
                    MaterialButton(
                      onPressed: () {
                        torx.kill_code(-1, nullptr);
                      },
                      height: 20,
                      minWidth: 20,
                      elevation: 5,
                      color: color.button_background,
                      child: Text(
                        text.emit_global_kill,
                        style: TextStyle(color: color.button_text),
                      ),
                    ),
                  ],
                ))));
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class RouteHome extends StatefulWidget {
  const RouteHome({super.key});

  @override
  State<RouteHome> createState() => _RouteHomeState();
}

class _RouteHomeState extends State<RouteHome> {
  int currentRowN = -1;
  int dtCurrentType = ENUM_OWNER_CTRL;
  int shorten_torxids = threadsafe_read_global_Uint8("shorten_torxids");

  DataTable currentDataTable(int owner) {
    String idName;
    String lookup;
    if (shorten_torxids == 1) {
      idName = text.torxid;
      lookup = "torxid";
    } else {
      idName = text.onionid;
      lookup = "onion";
    }
    Pointer<Int> len_p = malloc(8); // 4 is wide enough, could be 8, should be sizeof, meh.
    Pointer<Int> arrayN = torx.refined_list(len_p, owner, ENUM_STATUS_PENDING, nullptr);
    int len = len_p.value;
    calloc.free(len_p);
    List<TextEditingController> controller = [];
    for (int i = 0; i < len; i++) {
      controller.add(TextEditingController());
      controller[i].text = getter_string(arrayN[i], INT_MIN, -1, offsetof("peer", "peernick")); // 8
    }

    List<DataCell> currentCells(int i) {
      List<DataCell> currentCells;
      bool enabled = false; // only relevant to Sing and Mult
      if (torx.getter_uint8(arrayN[i], INT_MIN, -1, -1, offsetof("peer", "status")) == ENUM_STATUS_FRIEND) {
        enabled = true;
      }
      if (owner == ENUM_OWNER_CTRL || owner == ENUM_OWNER_PEER) {
        currentCells = [
          DataCell(Focus(
            onFocusChange: (hasFocus) {
              hasFocus ? null : changeNick(arrayN[i], controller[i]);
            },
            child: TextField(
              controller: controller[i],
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              scribbleEnabled: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              showCursor: true,
              onEditingComplete: () {
                changeNick(arrayN[i], controller[i]);
              },
              style: TextStyle(color: color.page_subtitle),
            ),
          )),
          DataCell(Text(
            getter_string(arrayN[i], INT_MIN, -1, offsetof("peer", lookup)),
            style: TextStyle(color: color.page_subtitle),
          )),
        ];
      } else /*if (owner == owners.ENUM_OWNER_MULT.index || owner == owners.ENUM_OWNER_SING.index) */ {
        currentCells = [
          DataCell(Switch(
              value: enabled,
              activeColor: const Color(0xFF6200EE),
              onChanged: (value) {
                torx.block_peer(arrayN[i]);
                setState(() {
                  enabled = value; // really we should not assume this but check the struct. thats more lines though.
                });
              })),
          DataCell(Focus(
            onFocusChange: (hasFocus) {
              hasFocus ? null : changeNick(arrayN[i], controller[i]);
            },
            child: TextField(
              controller: controller[i],
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              scribbleEnabled: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              showCursor: true,
              onEditingComplete: () {
                changeNick(arrayN[i], controller[i]);
              },
              style: TextStyle(color: color.page_subtitle),
            ),
          )),
          DataCell(Text(
            getter_string(arrayN[i], INT_MIN, -1, offsetof("peer", lookup)),
            style: TextStyle(color: color.page_subtitle),
          )),
        ];
      }
      return currentCells;
    }

    List<DataRow> rows = [];
    for (int i = 0; i < len; i++) {
      rows.add(DataRow(
        selected: currentRowN == arrayN[i] ? true : false,
        color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return color.selected_row; //
          } else {
            return null; // else Use the default value, ie transparent
          }
        }),
        onSelectChanged: (value) {
          if (value == true) {
            setState(() {
              currentRowN = arrayN[i];
            });
            //    printf("selected $currentRowN");
          } else {
            setState(() {
              currentRowN = -1;
            });
            //    printf("unselected $currentRowN");
          }
        },
        cells: currentCells(i),
      ));
    }

    DataTable dtCurrent;
    if (owner == ENUM_OWNER_CTRL || owner == ENUM_OWNER_PEER) {
      dtCurrent = DataTable(
        showCheckboxColumn: false,
        columns: [
          DataColumn(
              label: Text(
            text.identifier,
            style: TextStyle(color: color.page_subtitle),
          )),
          DataColumn(
              label: Text(
            idName,
            style: TextStyle(color: color.page_subtitle),
          )), // NOTE: for pending, this is rather meaningless and probably is being shown for no reason at all. This is our onion.
        ],
        rows: rows,
      );
    } else /* if (owner == owners.ENUM_OWNER_MULT.index || owner == owners.ENUM_OWNER_SING.index) */ {
      dtCurrent = DataTable(
        showCheckboxColumn: false,
        columns: [
          DataColumn(
              label: Text(
            text.active,
            style: TextStyle(color: color.page_subtitle),
          )),
          DataColumn(
              label: Text(
            text.identifier,
            style: TextStyle(color: color.page_subtitle),
          )),
          DataColumn(
              label: Text(
            idName,
            style: TextStyle(color: color.page_subtitle),
          )),
        ],
        rows: rows,
      );
    }
    return dtCurrent;
  }

  String buttonTextDelete = "";

  @override
  Widget build(BuildContext context) {
    if (dtCurrentType == ENUM_OWNER_CTRL) {
      buttonTextDelete = text.reject;
    } else {
      buttonTextDelete = text.delete;
    }
    return PopScope(
        onPopInvoked: (didPop) {},
        child: Scaffold(
          backgroundColor: color.right_panel_background,
          appBar: AppBar(
            backgroundColor: color.chat_headerbar,
            title: Text(
              text.home,
              style: TextStyle(color: color.page_title),
            ),
            automaticallyImplyLeading: false,
            actions: [
              MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RouteLogTor()),
                  );
                },
                height: 20,
                minWidth: 20,
                elevation: 5,
                color: color.button_background,
                child: Text(
                  text.tor_log,
                  style: TextStyle(color: color.button_text),
                ),
              ),
              MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RouteLogTorX()),
                  );
                },
                height: 20,
                minWidth: 20,
                elevation: 5,
                color: color.button_background,
                child: Text(
                  text.torx_log,
                  style: TextStyle(color: color.button_text),
                ),
              ),
              MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RouteGlobalKill()),
                  );
                },
                height: 20,
                minWidth: 20,
                elevation: 5,
                color: color.button_background,
                child: Text(
                  text.vertical_emit_global_kill,
                  style: TextStyle(color: color.button_text),
                ),
              ),
            ],
          ),
          body:
              // GOAT Incredibly low priority: this route doesn't use a S.C.S.V and therefore is unusable in horizontal mode. To remedy, it needs to be redesigned like RouteChat.
              SingleChildScrollView(
                  child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MaterialButton(
                  onPressed: () {
                    setState(() {
                      currentRowN = -1;
                      dtCurrentType = ENUM_OWNER_CTRL;
                    });
                  },
                  height: 40,
                  minWidth: 300,
                  elevation: 5,
                  color: dtCurrentType == ENUM_OWNER_CTRL ? color.selected_row : color.button_background,
                  child: Text(
                    text.incoming,
                    style: TextStyle(color: color.button_text),
                  ),
                ),
                MaterialButton(
                  onPressed: () {
                    setState(() {
                      currentRowN = -1;
                      dtCurrentType = ENUM_OWNER_PEER;
                    });
                  },
                  height: 40,
                  minWidth: 300,
                  elevation: 5,
                  color: dtCurrentType == ENUM_OWNER_PEER ? color.selected_row : color.button_background,
                  child: Text(
                    text.outgoing,
                    style: TextStyle(color: color.button_text),
                  ),
                ),
                MaterialButton(
                  onPressed: () {
                    setState(() {
                      currentRowN = -1;
                      dtCurrentType = ENUM_OWNER_MULT;
                    });
                  },
                  height: 40,
                  minWidth: 300,
                  elevation: 5,
                  color: dtCurrentType == ENUM_OWNER_MULT ? color.selected_row : color.button_background,
                  child: Text(
                    text.active_mult,
                    style: TextStyle(color: color.button_text),
                  ),
                ),
                MaterialButton(
                  onPressed: () {
                    setState(() {
                      currentRowN = -1;
                      dtCurrentType = ENUM_OWNER_SING;
                    });
                  },
                  height: 40,
                  minWidth: 300,
                  elevation: 5,
                  color: dtCurrentType == ENUM_OWNER_SING ? color.selected_row : color.button_background,
                  child: Text(
                    text.active_sing,
                    style: TextStyle(color: color.button_text),
                  ),
                ),
                /*  Expanded(
                  child:*/
                SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: AnimatedBuilder(
                          animation: changeNotifierDataTables,
                          builder: (BuildContext context, Widget? snapshot) {
                            return currentDataTable(dtCurrentType);
                          }),
                    )),
                //    )
              ],
            ),
          )),
          persistentFooterButtons: [
            if (currentRowN > -1 && dtCurrentType == ENUM_OWNER_CTRL)
              MaterialButton(
                onPressed: () {
                  torx.peer_accept(currentRowN);
                  changeNotifierDataTables.callback(integer: currentRowN);
                  totalIncoming--;
                  changeNotifierTotalIncoming.callback(integer: totalIncoming);
                  if (launcherBadges) {
                    AppBadgePlus.updateBadge(totalUnreadPeer + totalUnreadGroup + totalIncoming);
                  }
                },
                height: 20,
                minWidth: 60,
                elevation: 5,
                color: color.button_background,
                child: Text(
                  text.accept,
                  style: TextStyle(color: color.button_text),
                ),
              ),
            if (currentRowN > -1)
              MaterialButton(
                onPressed: () {
                  int former_owner = torx.getter_uint8(currentRowN, INT_MIN, -1, -1, offsetof("peer", "owner"));
                  int peer_index = torx.getter_int(currentRowN, INT_MIN, -1, -1, offsetof("peer", "peer_index"));
                  torx.takedown_onion(peer_index, 1); // currentRowN
                  if (dtCurrentType == ENUM_OWNER_CTRL) {
                    totalIncoming--;
                    changeNotifierTotalIncoming.callback(integer: totalIncoming);
                    if (launcherBadges) {
                      AppBadgePlus.updateBadge(totalUnreadPeer + totalUnreadGroup + totalIncoming);
                    }
                  }
                  setState(() {
                    currentRowN = -1;
                    currentDataTable(former_owner); // could also use dtCurrentType
                  });
                },
                height: 20,
                minWidth: 60,
                elevation: 5,
                color: color.button_background,
                child: Text(
                  buttonTextDelete,
                  style: TextStyle(color: color.button_text),
                ),
              ),
            if (currentRowN > -1 && dtCurrentType != ENUM_OWNER_CTRL)
              MaterialButton(
                onPressed: () {
                  if (shorten_torxids == 1) {
                    Clipboard.setData(ClipboardData(text: getter_string(currentRowN, INT_MIN, -1, offsetof("peer", "torxid"))));
                  } else {
                    Clipboard.setData(ClipboardData(text: getter_string(currentRowN, INT_MIN, -1, offsetof("peer", "onion"))));
                  }
                },
                height: 20,
                minWidth: 60,
                elevation: 5,
                color: color.button_background,
                child: Text(
                  text.copy,
                  style: TextStyle(color: color.button_text),
                ),
              ),
            if (currentRowN > -1 && (dtCurrentType == ENUM_OWNER_SING || dtCurrentType == ENUM_OWNER_MULT))
              MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RouteShowQr(getter_string(currentRowN, INT_MIN, -1, offsetof("peer", "torxid")))),
                  );
                },
                height: 20,
                minWidth: 60,
                elevation: 5,
                color: color.button_background,
                child: Text(
                  text.show_qr,
                  style: TextStyle(color: color.button_text),
                ),
              ),
          ],
        ));
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

/*
GOAT:
  Scan with https://pub.dev/packages/mobile_scanner
*/
class widget_route_generate extends StatefulWidget {
  final bool group;

  const widget_route_generate({super.key, required this.group});

  @override
  _widget_route_generateState createState() => _widget_route_generateState();
}

class _widget_route_generateState extends State<widget_route_generate> {
  TextEditingController entryAddPeernickController = TextEditingController(); // added
  TextEditingController entryAddGenerateGroupOutputController = TextEditingController();

  bool bool_fill_peeronion = false;

  @override
  Widget build(BuildContext context) {
    bool group = widget.group;
    int g = -1;
    String group_id = "";
    Pointer<Utf8> group_id_p = nullptr;
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
            //      child: SizedBox(
            //              height: MediaQuery.of(context).size.height,
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              group ? text.add_group_by : text.add_peer_by,
              style: TextStyle(color: color.page_subtitle),
            ),
            TextField(
              controller: entryAddPeernickController,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              scribbleEnabled: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              showCursor: true,
              textAlign: TextAlign.left,
              style: TextStyle(color: color.write_message_text),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: group ? text.placeholder_add_group_identifier : text.placeholder_add_identifier,
                hintStyle: TextStyle(color: color.right_panel_text),
              ),
            ),
            TextField(
              controller: entryAddPeeronionController,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              scribbleEnabled: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              showCursor: true,
              textAlign: TextAlign.left,
              style: TextStyle(color: color.write_message_text),
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: group ? text.placeholder_add_group_id : text.placeholder_add_onion,
                  hintStyle: TextStyle(color: color.right_panel_text),
                  filled: bool_fill_peeronion,
                  fillColor: color.auth_error // for errors
                  ),
            ),
            MaterialButton(
              onPressed: () {
                int ret = 0;
                group
                    ? g = ui_group_join_public(entryAddPeernickController.text, entryAddPeeronionController.text)
                    : ret = ui_add_peer(entryAddPeernickController.text, entryAddPeeronionController.text);
                if ((group && g < 0) || (!group && ret != 0)) {
                  setState(() {
                    bool_fill_peeronion = true; // indicates error / required field not filled
                  });
                } else {
                  entryAddPeeronionController.clear();
                  entryAddPeernickController.clear();
                }
              },
              height: 30,
              minWidth: 60,
              elevation: 5,
              color: color.button_background,
              child: Text(
                group ? text.button_join : text.button_add,
                style: TextStyle(color: color.button_text),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              group ? text.generate_group_for : text.generate_for,
              style: TextStyle(color: color.page_subtitle),
            ),
            TextField(
              controller: entryAddGeneratePeernickController,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              scribbleEnabled: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              showCursor: true,
              textAlign: TextAlign.left,
              style: TextStyle(color: color.write_message_text),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: group ? text.placeholder_add_group_identifier : text.placeholder_add_identifier,
                hintStyle: TextStyle(color: color.right_panel_text),
              ),
            ),
            MaterialButton(
              onPressed: () {
                group ? g = ui_group_generate(1, entryAddGeneratePeernickController.text) : ui_generate_onion(ENUM_OWNER_SING, entryAddGeneratePeernickController.text);
                if (group) {
                  entryAddGenerateGroupOutputController.text = g > -1 ? text.successfully_created_group : text.error_creating_group;
                  if (g > -1) {
                    entryAddGeneratePeernickController.clear();
                  }
                  g = -1; // do not display QR, do not display ID
                  changeNotifierGroupReady.callback(integer: 1);
                  if (group_id_p != nullptr) {
                    calloc.free(group_id_p);
                    group_id_p = nullptr;
                  }
                }
              },
              height: 30,
              minWidth: 60,
              elevation: 5,
              color: color.button_background,
              child: Text(
                group ? text.button_generate_invite : text.button_sing,
                style: TextStyle(color: color.button_text),
              ),
            ),
            MaterialButton(
              onPressed: () {
                group ? g = ui_group_generate(0, entryAddGeneratePeernickController.text) : ui_generate_onion(ENUM_OWNER_MULT, entryAddGeneratePeernickController.text);
                if (g > -1) {
                  group_id = getter_group_id(g);
                  entryAddGenerateGroupOutputController.text = group_id;
                  if (group_id_p != nullptr) {
                    calloc.free(group_id_p);
                    group_id_p = nullptr;
                  }
                  group_id_p = group_id.toNativeUtf8();
                  changeNotifierGroupReady.callback(integer: 1);
                  entryAddGeneratePeernickController.clear();
                }
              },
              height: 30,
              minWidth: 60,
              elevation: 5,
              color: color.button_background,
              child: Text(
                group ? text.button_generate_public : text.button_mult,
                style: TextStyle(color: color.button_text),
              ),
            ),
            TextField(
              readOnly: true,
              controller: group ? entryAddGenerateGroupOutputController : entryAddGenerateOutputController,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              scribbleEnabled: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              showCursor: false,
              textAlign: TextAlign.center,
              style: TextStyle(color: color.write_message_text),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            AnimatedBuilder(
                animation: group ? changeNotifierGroupReady : changeNotifierOnionReady,
                builder: (BuildContext context, Widget? snapshot) {
                  Pointer<Utf8> generated = nullptr;
                  generated_n = changeNotifierOnionReady.section.integer;
                  if ((!group && changeNotifierOnionReady.section.integer > -1) || (group && g > -1)) {
                    generated =
                        group ? group_id_p : torx.getter_string(nullptr, changeNotifierOnionReady.section.integer, INT_MIN, -1, offsetof("peer", "torxid")); // GOAT somehow free???
                  }
                  //    printf("Group g: $group $g");
                  bool deleted = false;
                  if (generated != nullptr && generated.toDartString().startsWith('000000')) {
                    deleted = true;
                    group ? entryAddGenerateGroupOutputController.clear() : entryAddGenerateOutputController.clear();
                  }
                  return Column(children: [
                    if (((!group && changeNotifierOnionReady.section.integer > -1) || (group && g > -1)) && !deleted && generated != nullptr) generate_qr(generated.toDartString()),
                    if (((!group && changeNotifierOnionReady.section.integer > -1) || (group && g > -1)) && !deleted && generated != nullptr)
                      MaterialButton(
                        onPressed: () async {
                          // final ts = DateTime.now().millisecondsSinceEpoch.toString();
                          String path =
                              '$temporaryDir/qr.png'; // might want to make this name unique if sending them in rapid succession causes corruption. depends on how OS handles sharing. if so, use above line
                          Pointer<Size_t> size_p = malloc(8); // free'd by calloc.free // 4 is wide enough, could be 8, should be sizeof, meh.
                          Pointer<Void> qr_raw = torx.qr_bool(generated, 8); // free'd by torx_free
                          Pointer<Void> png = torx.return_png(size_p, qr_raw); // free'd by torx_free
                          Pointer<Utf8> destination = path.toNativeUtf8(); // free'd by calloc.free
                          torx.write_bytes(destination, png, size_p.value);
                          torx.torx_free_simple(qr_raw);
                          qr_raw = nullptr;
                          torx.torx_free_simple(png);
                          png = nullptr;
                          calloc.free(size_p);
                          size_p = nullptr;
                          calloc.free(destination);
                          destination = nullptr;
                          Share.shareXFiles(
                            [XFile(path)],
                          );
                          // GOAT delete getTemporaryDirectory().path/qr.png on program startup and shutdown
                        },
                        height: 30,
                        minWidth: 60,
                        elevation: 5,
                        color: color.button_background,
                        child: Text(
                          text.share_qr,
                          style: TextStyle(color: color.button_text),
                        ),
                      ),
                    if (((!group && changeNotifierOnionReady.section.integer > -1) || (group && g > -1)) && !deleted && generated != nullptr)
                      MaterialButton(
                        onPressed: () {
                          saveQr(generated.toDartString());
                        },
                        height: 20,
                        minWidth: 20,
                        elevation: 5,
                        color: color.button_background,
                        child: Text(
                          text.save_qr,
                          style: TextStyle(color: color.button_text),
                        ),
                      ),
                  ]);
                }),
            // If the share button doesn't allow saving and it is desirable, we might need https://pub.dev/packages/image_gallery_saver which is based on https://pub.dev/packages/gallery_saver
          ],
        )));
  }
}

class RouteAdd extends StatefulWidget {
  const RouteAdd({super.key});

  @override
  State<RouteAdd> createState() => _RouteAddState();
}

class _RouteAddState extends State<RouteAdd> with TickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TextEditingController entryAddPeernickController = TextEditingController(); // added
  TextEditingController entryAddGeneratePeernickController = TextEditingController();
  bool bool_fill_peeronion = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
        onPopInvoked: (didPop) {},
        child: Scaffold(
          backgroundColor: color.right_panel_background,
          appBar: AppBar(
            backgroundColor: color.chat_headerbar,
            title: Text(
              text.add_generate,
              style: TextStyle(color: color.page_title),
            ),
            automaticallyImplyLeading: false,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: text.peer),
                Tab(text: text.group),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RouteScan()),
                  );
                },
                icon: Icon(Icons.qr_code_2, color: color.torch_off), // qr_code_2 is more attractive looking, but qr_code_scanner is more appropriate
                iconSize: size_large_icon,
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              AnimatedBuilder(
                  animation: changeNotifierChatList,
                  builder: (BuildContext context, Widget? snapshot) {
                    return const widget_route_generate(group: false);
                  }),
              AnimatedBuilder(
                  animation: changeNotifierChatList,
                  builder: (BuildContext context, Widget? snapshot) {
                    return const widget_route_generate(group: true);
                  }),
            ],
          ),
        ));
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class RouteEditTorrc extends StatefulWidget {
  const RouteEditTorrc({super.key});

  @override
  State<RouteEditTorrc> createState() => _RouteEditTorrcState();
}

class _RouteEditTorrcState extends State<RouteEditTorrc> {
  TextEditingController controllerTorrc = TextEditingController(text: threadsafe_read_global_string("torrc_content"));

  int _verify_config(String content) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner(); // remove existing, if any
    Pointer<Utf8> p = content.toNativeUtf8(); // free'd by calloc.free
    Pointer<Utf8> torrc_errors = torx.torrc_verify(p); // free'd by torx_free
    calloc.free(p);
    p = nullptr;
    if (torrc_errors == nullptr) {
      set_torrc(content);
      return 0;
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(torrc_errors.toDartString()),
          action: SnackBarAction(
            label: text.override,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              set_torrc(content);
            },
          ),
        ),
      );
      torx.torx_free_simple(torrc_errors as Pointer<Void>);
      torrc_errors = nullptr;
      return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        onPopInvoked: (didPop) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
        child: Scaffold(
            backgroundColor: color.right_panel_background,
            appBar: AppBar(
                backgroundColor: color.chat_headerbar,
                title: Text(
                  text.edit_torrc,
                  style: TextStyle(color: color.page_title),
                ),
                actions: [
                  MaterialButton(
                    onPressed: () {
                      if (_verify_config(controllerTorrc.text) == 0) Navigator.pop(context);
                    },
                    height: 20,
                    minWidth: 60,
                    elevation: 5,
                    color: color.button_background,
                    child: Text(
                      text.save_torrc,
                      style: TextStyle(color: color.button_text),
                    ),
                  ),
                ]),
            body: SingleChildScrollView(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: controllerTorrc,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                scribbleEnabled: false,
                spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                showCursor: true,
                maxLines: null,
                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14, color: color.right_panel_text),
              ),
            ))));
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class RouteChangePassword extends StatefulWidget {
  const RouteChangePassword({super.key});

  @override
  State<RouteChangePassword> createState() => _RouteChangePasswordState();
}

String buttonChangePasswordText = text.change_password;
TextEditingController controllerPassOld = TextEditingController();
TextEditingController controllerPassNew = TextEditingController();
TextEditingController controllerPassVerify = TextEditingController();

class _RouteChangePasswordState extends State<RouteChangePassword> {
  void _submitChangePassword() {
    setState(() {
      buttonChangePasswordText = text.wait;
    });
    Pointer<Utf8> password_old = controllerPassOld.text.toNativeUtf8(); // free'd by calloc.free
    Pointer<Utf8> password_new = controllerPassNew.text.toNativeUtf8(); // free'd by calloc.free
    Pointer<Utf8> password_verify = controllerPassVerify.text.toNativeUtf8(); // free'd by calloc.free
    torx.change_password_start(password_old, password_new, password_verify);
    calloc.free(password_old);
    password_old = nullptr;
    calloc.free(password_new);
    password_new = nullptr;
    calloc.free(password_verify);
    password_verify = nullptr;
  }

  bool obscureText1 = true;
  bool obscureText2 = true;
  bool obscureText3 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: color.right_panel_background,
        appBar: AppBar(
            backgroundColor: color.chat_headerbar,
            title: Text(
              text.change_password,
              style: TextStyle(color: color.page_title),
            )),
        body: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            Text(
              text.old_password,
              style: TextStyle(color: color.page_subtitle),
            ),
            TextField(
              controller: controllerPassOld,
              obscureText: obscureText1,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              scribbleEnabled: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              showCursor: true,
              textAlign: TextAlign.center,
              style: TextStyle(color: color.write_message_text),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureText1 ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureText1 = !obscureText1;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              text.new_password,
              style: TextStyle(color: color.page_subtitle),
            ),
            TextField(
              controller: controllerPassNew,
              obscureText: obscureText2,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              scribbleEnabled: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              textAlign: TextAlign.center,
              style: TextStyle(color: color.write_message_text),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureText2 ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureText2 = !obscureText2;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              text.new_password_again,
              style: TextStyle(color: color.page_subtitle),
            ),
            TextField(
              controller: controllerPassVerify,
              obscureText: obscureText3,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              scribbleEnabled: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              showCursor: true,
              textAlign: TextAlign.center,
              style: TextStyle(color: color.write_message_text),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureText3 ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureText3 = !obscureText3;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MaterialButton(
                    onPressed: _submitChangePassword,
                    height: 20,
                    minWidth: 60,
                    elevation: 5,
                    color: color.button_background,
                    child: AnimatedBuilder(
                        animation: changeNotifierChangePassword,
                        builder: (BuildContext context, Widget? snapshot) {
                          return Text(
                            buttonChangePasswordText,
                            style: TextStyle(color: color.button_text),
                          );
                        })),
              ],
            )
          ]),
        )));
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class RouteSettings extends StatefulWidget {
  const RouteSettings({super.key});

  @override
  State<RouteSettings> createState() => _RouteSettingsState();
}

class _RouteSettingsState extends State<RouteSettings> {
  // GOAT implement a Focus() on any textfield (see what we did in RouteHome() with datacells, or in chat title?) so that saves occur when focus is lost not just when submit is pressed
  final List<String> _languages = [
    "English",
  ];
  final List<String> _themes = [text.dark, text.light];
  final List<String> _idTypes = [text.generate_onionid, text.generate_torxid];

  final _cpuThreads = List<String>.generate(threadsafe_read_global_Uint32("threads_max"), (int index) => '${index + 1}');

  final _suffixLength = List<String>.generate(10, (int index) => '$index');

  String? _selectedLanguage;
  String? _selectedTheme;
  String? _selectedIdType;
  bool _selectedGlobalLogging = false;
  bool _selectedAutoResumeInbound = false;
  String? _selectedCpuThreads;
  String? _selectedSuffixLength;
  bool _selectedAutoMult = true;
  TextEditingController controllerSingDays = TextEditingController(text: torx.sing_expiration_days.value.toString());
  TextEditingController controllerMultDays = TextEditingController(text: torx.mult_expiration_days.value.toString());
  TextEditingController controllerCustomInputPrivkey = TextEditingController();
  TextEditingController controllerCustomInputIdentifier = TextEditingController();
  bool wrongLength = false;
  bool validExternal = false;
  Color inputColor = Colors.transparent;

  void _saveIntSetting(Pointer<Int> p, String name, TextEditingController tec) {
    torx.pthread_rwlock_rdlock(torx.mutex_global_variable);
    int original_value = p.value;
    torx.pthread_rwlock_unlock(torx.mutex_global_variable);
    if (tec.text.isNotEmpty && int.parse(tec.text) != original_value) {
      // might need a max here and in GTK? itoa should handle it?
      torx.pthread_rwlock_wrlock(torx.mutex_global_variable);
      p.value = int.parse(tec.text);
      torx.pthread_rwlock_unlock(torx.mutex_global_variable);
      set_setting_string(0, -1, name, tec.text);
    } else {
      // invalid, empty, or unchanged --> reset
      tec.text = original_value.toString();
    }
  }

  int shorten_torxids = threadsafe_read_global_Uint8("shorten_torxids");
  int global_log_messages = threadsafe_read_global_Uint8("global_log_messages");
  int auto_resume_inbound = threadsafe_read_global_Uint8("auto_resume_inbound");
  int threads_max = threadsafe_read_global_Uint32("threads_max");
  int suffix_length = threadsafe_read_global_Uint8("suffix_length");
  int auto_accept_mult = threadsafe_read_global_Uint8("auto_accept_mult");
  int global_threads = threadsafe_read_global_Uint32("global_threads");

  @override
  Widget build(BuildContext context) {
    if (language == "en_US") {
      _selectedLanguage = "English";
    }

    if (theme == enum_theme.DARK_THEME.index) {
      _selectedTheme = text.dark;
    } else if (theme == enum_theme.LIGHT_THEME.index) {
      _selectedTheme = text.light;
    }

    if (shorten_torxids == 0) {
      _selectedIdType = text.generate_onionid;
    } else if (shorten_torxids == 1) {
      _selectedIdType = text.generate_torxid;
    }

    if (global_log_messages == 0) {
      _selectedGlobalLogging = false;
    } else if (global_log_messages == 1) {
      _selectedGlobalLogging = true;
    } else {
      error(0, "Unexpected log_messages value: ${global_log_messages.toString()}");
    }

    if (auto_resume_inbound == 0) {
      _selectedAutoResumeInbound = false;
    } else if (auto_resume_inbound == 1) {
      _selectedAutoResumeInbound = true;
    }

    if (global_threads <= threads_max) {
      _selectedCpuThreads = _cpuThreads.elementAt(global_threads - 1);
    } else {
      _selectedCpuThreads = _cpuThreads.elementAt(threads_max - 1);
    }

    if (suffix_length < 10) {
      _selectedSuffixLength = suffix_length.toString();
    } else {
      error(0, "Suffix length invalid: ${torx.suffix_length.value.toString()}");
    }

    if (auto_accept_mult == 0) {
      _selectedAutoMult = false;
    } else if (auto_accept_mult == 1) {
      _selectedAutoMult = true;
    }

    return PopScope(
        onPopInvoked: (didPop) {},
        child: Scaffold(
          backgroundColor: color.right_panel_background,
          appBar: AppBar(
            backgroundColor: color.chat_headerbar,
            title: Text(
              text.settings,
              style: TextStyle(color: color.page_title),
            ),
            automaticallyImplyLeading: false,
            actions: [
              MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RouteEditTorrc()),
                  );
                },
                height: 20,
                minWidth: 20,
                elevation: 5,
                color: color.button_background,
                child: Text(
                  text.edit_torrc,
                  style: TextStyle(color: color.button_text),
                ),
              ),
              MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RouteChangePassword()),
                  );
                },
                height: 20,
                minWidth: 20,
                elevation: 5,
                color: color.button_background,
                child: Text(
                  text.vertical_change_password,
                  style: TextStyle(color: color.button_text),
                ),
              ),
              MaterialButton(
                onPressed: () {
                  flutterLocalNotificationsPlugin.cancelAll();
                  writeUnread();
                  torx.cleanup_lib(0);
                  //Process.killPid(); // can kill stuff if we need to
                  exit(0);
                },
                height: 20,
                minWidth: 20,
                elevation: 5,
                color: color.button_background,
                child: Text(
                  text.quit,
                  style: TextStyle(color: color.button_text),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(
                    text.set_select_language,
                    style: TextStyle(color: color.page_subtitle),
                  ),
                  DropdownButton(
                      dropdownColor: color.chat_headerbar,
                      value: _selectedLanguage,
                      items: _languages
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    e,
                                    style: TextStyle(fontSize: 18, color: color.page_title),
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == "English" && language == "en_US") {
                          return; // compensating for flutter triggering when there is no change
                        }
                        if (value == "English") {
                          language = "en_US";
                        } else {
                          error(0, "Invalid language selected: $value");
                        }
                        set_setting_string(1, -1, "language", language);
                        setState(() {
                          _selectedLanguage = value;
                        });
                      }),
                ]),
                const SizedBox(height: 5),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(
                    text.set_select_theme,
                    style: TextStyle(color: color.page_subtitle),
                  ),
                  DropdownButton(
                      dropdownColor: color.chat_headerbar,
                      value: _selectedTheme,
                      items: _themes
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    e,
                                    style: TextStyle(fontSize: 18, color: color.page_title),
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == text.dark && theme == enum_theme.DARK_THEME.index) {
                          return; // compensating for flutter triggering when there is no change
                        } else if (value == text.light && theme == enum_theme.LIGHT_THEME.index) {
                          return; // compensating for flutter triggering when there is no change
                        }
                        if (value == text.dark) {
                          theme = enum_theme.DARK_THEME.index;
                        } else if (value == text.light) {
                          theme = enum_theme.LIGHT_THEME.index;
                        }
                        set_setting_string(1, -1, "theme", theme.toString());
                        setState(() {
                          _selectedTheme = value;
                          initialize_theme(context);
                        });
                        changeNotifierTheme.callback(integer: 0); // to force rebuild of RouteBottom
                      }),
                ]),
                const SizedBox(height: 5),
                Row(children: [
                  Text(
                    text.set_onionid_or_torxid,
                    style: TextStyle(color: color.page_subtitle),
                  ),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  DropdownButton(
                      dropdownColor: color.chat_headerbar,
                      value: _selectedIdType,
                      items: _idTypes
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    e,
                                    style: TextStyle(fontSize: 18, color: color.page_title),
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == text.generate_onionid && shorten_torxids == 0) {
                          return; // compensating for flutter triggering when there is no change
                        } else if (value == text.generate_torxid && shorten_torxids == 1) {
                          return; // compensating for flutter triggering when there is no change
                        }
                        if (value == text.generate_onionid) {
                          shorten_torxids = 0;
                        } else if (value == text.generate_torxid) {
                          shorten_torxids = 1;
                        }
                        torx.pthread_rwlock_wrlock(torx.mutex_global_variable);
                        torx.shorten_torxids.value = shorten_torxids;
                        torx.pthread_rwlock_unlock(torx.mutex_global_variable);
                        set_setting_string(0, -1, "shorten_torxids", shorten_torxids.toString());
                        setState(() {
                          _selectedIdType = value;
                        });
                      }),
                ]),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      text.set_global_log,
                      style: TextStyle(color: color.page_subtitle),
                    )
                  ],
                ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Switch(
                    value: _selectedGlobalLogging,
                    activeColor: const Color(0xFF6200EE),
                    onChanged: (value) {
                      if (value == false) {
                        global_log_messages = 0;
                      } else if (value == true) {
                        global_log_messages = 1;
                      }
                      torx.pthread_rwlock_wrlock(torx.mutex_global_variable);
                      torx.global_log_messages.value = global_log_messages;
                      torx.pthread_rwlock_unlock(torx.mutex_global_variable);
                      set_setting_string(0, -1, "global_log_messages", global_log_messages.toString());
                      setState(() {
                        _selectedGlobalLogging = value;
                      });
                    },
                  ),
                ]),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      text.set_auto_resume_inbound,
                      style: TextStyle(color: color.page_subtitle),
                    )
                  ],
                ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Switch(
                    value: _selectedAutoResumeInbound,
                    activeColor: const Color(0xFF6200EE),
                    onChanged: (value) {
                      if (value == false) {
                        auto_resume_inbound = 0;
                      } else if (value == true) {
                        auto_resume_inbound = 1;
                      }
                      torx.pthread_rwlock_wrlock(torx.mutex_global_variable);
                      torx.auto_resume_inbound.value = auto_resume_inbound;
                      torx.pthread_rwlock_unlock(torx.mutex_global_variable);
                      set_setting_string(0, -1, "auto_resume_inbound", auto_resume_inbound.toString());
                      setState(() {
                        _selectedAutoResumeInbound = value;
                      });
                    },
                  ),
                ]),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      text.set_save_all_stickers,
                      style: TextStyle(color: color.page_subtitle),
                    )
                  ],
                ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Switch(
                    value: save_all_stickers,
                    activeColor: const Color(0xFF6200EE),
                    onChanged: (value) {
                      if (value == false) {
                        set_setting_string(0, -1, "save_all_stickers", "0");
                      } else if (value == true) {
                        set_setting_string(0, -1, "save_all_stickers", "1");
                      }
                      setState(() {
                        save_all_stickers = value;
                      });
                    },
                  ),
                ]),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      text.keyboard_privacy,
                      style: TextStyle(color: color.page_subtitle),
                    )
                  ],
                ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Switch(
                    value: keyboard_privacy,
                    activeColor: const Color(0xFF6200EE),
                    onChanged: (value) {
                      if (value == false) {
                        set_setting_string(0, -1, "keyboard_privacy", "0");
                      } else if (value == true) {
                        set_setting_string(0, -1, "keyboard_privacy", "1");
                      }
                      setState(() {
                        keyboard_privacy = value;
                      });
                    },
                  ),
                ]),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      text.set_download_directory,
                      style: TextStyle(color: color.page_subtitle),
                    )
                  ],
                ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  MaterialButton(
                    onPressed: () async {
                      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(); // allows user to choose a directory
                      Pointer<Utf8> name = "download_dir".toNativeUtf8();
                      if (selectedDirectory != null) {
                        if (write_test(selectedDirectory) == false) {
                          calloc.free(name);
                          name = nullptr;
                          return; // not writable
                        }
                        Pointer<Utf8> directory = selectedDirectory.toNativeUtf8();
                        Pointer<Void> allocation = torx.torx_secure_malloc(selectedDirectory.length + 1);
                        torx.memcpy(allocation, directory as Pointer<Void>, selectedDirectory.length + 1);
                        torx.pthread_rwlock_wrlock(torx.mutex_global_variable);
                        torx.torx_free_simple(torx.download_dir[0] as Pointer<Void>);
                        torx.download_dir[0] = allocation as Pointer<Utf8>;
                        torx.pthread_rwlock_unlock(torx.mutex_global_variable);
                        set_setting_string(0, -1, "download_dir", selectedDirectory);
                        calloc.free(directory);
                        directory = nullptr;
                      } else {
                        torx.pthread_rwlock_wrlock(torx.mutex_global_variable);
                        if (torx.download_dir[0] != nullptr) {
                          torx.torx_free_simple(torx.download_dir[0] as Pointer<Void>);
                          torx.download_dir[0] = nullptr;
                        }
                        torx.pthread_rwlock_unlock(torx.mutex_global_variable);
                        torx.sql_delete_setting(0, -1, name);
                      }
                      calloc.free(name);
                      name = nullptr;
                      setState(() {}); // torx.download_dir[0] changed
                    },
                    height: 20,
                    minWidth: 20,
                    elevation: 5,
                    color: color.button_background,
                    child: Text(
                      threadsafe_read_global_string("download_dir"),
                      style: TextStyle(color: color.button_text),
                    ),
                  ),
                ]),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      text.set_cpu,
                      style: TextStyle(color: color.page_subtitle),
                    )
                  ],
                ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  DropdownButton(
                      dropdownColor: color.chat_headerbar,
                      value: _selectedCpuThreads,
                      items: _cpuThreads
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    e,
                                    style: TextStyle(fontSize: 18, color: color.page_title),
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (global_threads == int.parse(value!)) {
                          return; // compensating for flutter triggering when there is no change
                        }
                        global_threads = int.parse(value);
                        torx.pthread_rwlock_wrlock(torx.mutex_global_variable);
                        torx.global_threads.value = global_threads;
                        torx.pthread_rwlock_unlock(torx.mutex_global_variable);
                        set_setting_string(0, -1, "global_threads", global_threads.toString());
                        setState(() {
                          _selectedCpuThreads = value;
                        });
                      }),
                ]),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      text.set_suffix,
                      style: TextStyle(color: color.page_subtitle),
                    )
                  ],
                ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  DropdownButton(
                      dropdownColor: color.chat_headerbar,
                      value: _selectedSuffixLength,
                      items: _suffixLength
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    e,
                                    style: TextStyle(fontSize: 18, color: color.page_title),
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (suffix_length == int.parse(value!)) {
                          return; // compensating for flutter triggering when there is no change
                        }
                        suffix_length = int.parse(value);
                        torx.pthread_rwlock_wrlock(torx.mutex_global_variable);
                        torx.suffix_length.value = suffix_length;
                        torx.pthread_rwlock_unlock(torx.mutex_global_variable);
                        set_setting_string(0, -1, "suffix_length", suffix_length.toString());
                        setState(() {
                          _selectedSuffixLength = value;
                        });
                      }),
                ]),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      text.set_validity_sing,
                      style: TextStyle(color: color.page_subtitle),
                    )
                  ],
                ),
                Focus(
                    onFocusChange: (hasFocus) {
                      hasFocus ? null : _saveIntSetting(torx.sing_expiration_days as Pointer<Int>, "sing_expiration_days", controllerSingDays);
                    },
                    child: TextField(
                      controller: controllerSingDays,
                      autocorrect: false,
                      enableSuggestions: false,
                      enableIMEPersonalizedLearning: false,
                      scribbleEnabled: false,
                      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                      showCursor: true,
                      keyboardType: TextInputType.number,
                      onEditingComplete: () {
                        _saveIntSetting(torx.sing_expiration_days as Pointer<Int>, "sing_expiration_days", controllerSingDays);
                      },
                      textAlign: TextAlign.center,
                      style: TextStyle(color: color.write_message_text),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    )),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      text.set_validity_mult,
                      style: TextStyle(color: color.page_subtitle),
                    )
                  ],
                ),
                Focus(
                    onFocusChange: (hasFocus) {
                      hasFocus ? null : _saveIntSetting(torx.mult_expiration_days as Pointer<Int>, "mult_expiration_days", controllerMultDays);
                    },
                    child: TextField(
                      controller: controllerMultDays,
                      autocorrect: false,
                      enableSuggestions: false,
                      enableIMEPersonalizedLearning: false,
                      scribbleEnabled: false,
                      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                      showCursor: true,
                      keyboardType: TextInputType.number,
                      onEditingComplete: () {
                        _saveIntSetting(torx.mult_expiration_days as Pointer<Int>, "mult_expiration_days", controllerMultDays);
                      },
                      textAlign: TextAlign.center,
                      style: TextStyle(color: color.write_message_text),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    )),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      text.set_automatic_mult,
                      style: TextStyle(color: color.page_subtitle),
                    )
                  ],
                ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Switch(
                    value: _selectedAutoMult,
                    activeColor: const Color(0xFF6200EE),
                    onChanged: (value) {
                      if (value == false) {
                        auto_accept_mult = 0;
                      } else if (value == true) {
                        auto_accept_mult = 1;
                      }
                      torx.pthread_rwlock_wrlock(torx.mutex_global_variable);
                      torx.auto_accept_mult.value = auto_accept_mult;
                      torx.pthread_rwlock_unlock(torx.mutex_global_variable);
                      set_setting_string(0, -1, "auto_accept_mult", auto_accept_mult.toString());
                      setState(() {
                        _selectedAutoMult = value;
                      });
                    },
                  ),
                ]),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      text.set_externally_generated,
                      style: TextStyle(color: color.page_subtitle),
                    )
                  ], // GOAT put placeholder text saying base64 priv key, and put a filepicker
                ),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      if (value.length == 88) {
                        wrongLength = false;
                        Pointer<Utf8> p = value.toNativeUtf8(); // free'd by calloc.free
                        if (torx.b64_decoded_size(p) == 64) {
                          inputColor = Colors.green;
                          validExternal = true;
                        } else {
                          inputColor = color.auth_error;
                          validExternal = false;
                        }
                        calloc.free(p);
                        p = nullptr;
                      } else {
                        wrongLength = true;
                        if (value.isEmpty) {
                          inputColor = Colors.transparent;
                        } else {
                          inputColor = Colors.orange;
                        }
                        validExternal = false;
                      }
                    });
                  },
                  controller: controllerCustomInputPrivkey,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  scribbleEnabled: false,
                  spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                  showCursor: true,
                  textAlign: TextAlign.start,
                  style: TextStyle(color: color.write_message_text),
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: text.placeholder_privkey_flutter,
                      hintStyle: TextStyle(color: color.right_panel_text),
                      filled: wrongLength,
                      fillColor: inputColor),
                ),
                Visibility(
                  visible: validExternal,
                  child: TextField(
                    controller: controllerCustomInputIdentifier,
                    autocorrect: false,
                    enableSuggestions: false,
                    enableIMEPersonalizedLearning: false,
                    scribbleEnabled: false,
                    spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                    showCursor: true,
                    textAlign: TextAlign.start,
                    style: TextStyle(color: color.write_message_text),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: text.placeholder_identifier,
                      hintStyle: TextStyle(color: color.right_panel_text),
                    ),
                  ),
                ),
                Visibility(
                  visible: validExternal,
                  child: MaterialButton(
                    onPressed: () {
                      Pointer<Utf8> identifier = controllerCustomInputIdentifier.text.toNativeUtf8(); // free'd by calloc.free
                      Pointer<Utf8> privkey = controllerCustomInputPrivkey.text.toNativeUtf8(); // free'd by calloc.free
                      torx.custom_input(ENUM_OWNER_SING, identifier, privkey);
                      calloc.free(identifier);
                      identifier = nullptr;
                      calloc.free(privkey);
                      privkey = nullptr;
                      controllerCustomInputPrivkey.clear();
                      controllerCustomInputIdentifier.clear();
                      setState(() {
                        validExternal = false;
                      });
                    },
                    height: 20,
                    minWidth: 60,
                    elevation: 5,
                    color: color.button_background,
                    child: Text(
                      text.save_sing,
                      style: TextStyle(color: color.button_text),
                    ),
                  ),
                ),
                Visibility(
                  visible: validExternal,
                  child: MaterialButton(
                    onPressed: () {
                      Pointer<Utf8> identifier = controllerCustomInputIdentifier.text.toNativeUtf8();
                      Pointer<Utf8> privkey = controllerCustomInputPrivkey.text.toNativeUtf8();
                      torx.custom_input(ENUM_OWNER_MULT, identifier, privkey);
                      calloc.free(identifier);
                      identifier = nullptr;
                      calloc.free(privkey);
                      privkey = nullptr;
                      controllerCustomInputPrivkey.clear();
                      controllerCustomInputIdentifier.clear();
                      setState(() {
                        validExternal = false;
                      });
                    },
                    height: 20,
                    minWidth: 60,
                    elevation: 5,
                    color: color.button_background,
                    child: Text(
                      text.save_mult,
                      style: TextStyle(color: color.button_text),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ));
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class RouteBottom extends StatefulWidget {
  const RouteBottom({super.key});

  @override
  State<RouteBottom> createState() => _RouteBottomState();
}

class _RouteBottomState extends State<RouteBottom> {
  int _selectedIndex = bottom_index;

  void _onItemTapped(int index) {
    current_index = 0;
    setState(() {
      _selectedIndex = index;
    });
  }

  static final List<Widget> _widgetOptions = <Widget>[
    // Put pages here
    const RouteChatList(),
    const RouteAdd(),
    const RouteHome(),
    const RouteSettings()
  ];

  @override
  Widget build(BuildContext context) {
//    displayNotification();
/* NOTE: This works fine. Do not delete it. It is a drop-in replacement for didChangeAppLifecycleState(). Enabling it will directly replace calls to didChangeAppLifecycleState(), even without removing didChangeAppLifecycleState(). However, this requires <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS", so we are deleting it
  SystemChannels.lifecycle.setMessageHandler((msg) async {
    debugPrintf('SystemChannels> $msg');
    if (msg == AppLifecycleState.resumed.toString()) {
      printf("Systemchannels says application resumed");
        printf("Checkpoint AppLifecycleState.resumed");
    } else if (msg == AppLifecycleState.inactive.toString()) {
      printf("Systemchannels says application inactive");
    } else if (msg == AppLifecycleState.paused.toString()) {
      printf("Systemchannels says application paused");
        _start_foreground_task(); // restart to update the text
    } else if (msg == AppLifecycleState.detached.toString()) {
      printf("Systemchannels says application detached");
        FlutterForegroundTask.stopService(); // NOTE: this will probably NOT occur and an abandoned foreground service could occur... however torx runs in background so its ok/good
        printf("Checkpoint AppLifecycleState.detached");
    }
    return msg;
  }); */
    if (color.logo == const Color.fromRGBO(255, 255, 255, 0)) {
      // check theme initialization
      initialize_theme(context);
    }
//    globalCurrentRouteChatN = -1; // BAD BAD DO NOT PUT HERE
    return AnimatedBuilder(
        animation: changeNotifierTheme,
        builder: (BuildContext context, Widget? snapshot) {
          return Scaffold(
            body: _widgetOptions[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                showSelectedLabels: true,
                showUnselectedLabels: false,
                selectedItemColor: color.torch_on,
                unselectedItemColor: color.torch_off,
                items: [
                  BottomNavigationBarItem(
                      backgroundColor: color.chat_headerbar,
                      icon: AnimatedBuilder(
                          animation: changeNotifierTotalUnread,
                          builder: (BuildContext context, Widget? snapshot) {
                            return Badge(
                                isLabelVisible: totalUnreadPeer + totalUnreadGroup > 0,
                                label: Text((totalUnreadPeer + totalUnreadGroup).toString()),
                                child: const Icon(Icons.chat_outlined));
                          }),
                      activeIcon: AnimatedBuilder(
                          animation: changeNotifierTotalUnread,
                          builder: (BuildContext context, Widget? snapshot) {
                            return Badge(
                              isLabelVisible: totalUnreadPeer + totalUnreadGroup > 0,
                              label: Text((totalUnreadPeer + totalUnreadGroup).toString()),
                              child: const Icon(Icons.chat),
                            );
                          }),
                      label: text.chats),
                  //  BottomNavigationBarItem(icon: Icon(Icons.ac_unit),label: "Groups"),
                  BottomNavigationBarItem(backgroundColor: color.chat_headerbar, icon: const Icon(Icons.add), label: text.add_generate_bottom),
                  BottomNavigationBarItem(
                      backgroundColor: color.chat_headerbar,
                      icon: AnimatedBuilder(
                          animation: changeNotifierTotalIncoming,
                          builder: (BuildContext context, Widget? snapshot) {
                            return Badge(isLabelVisible: totalIncoming > 0, label: Text(totalIncoming.toString()), child: const Icon(Icons.home));
                          }),
                      label: text.home),
                  BottomNavigationBarItem(backgroundColor: color.chat_headerbar, icon: const Icon(Icons.settings), label: text.settings)
                ]),
          );
        });
  }
}
