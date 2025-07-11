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
// ignore_for_file: constant_identifier_names, non_constant_identifier_names, camel_case_types
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

@pragma("vm:entry-point") // Should be top level / not in class. NOTE: THIS LINE IS ABSOLUTELY necessary by flutter_local_notifications to prevent tree-shaking the code
void response(NotificationResponse notificationResponse) {
/*    if (notificationResponse.actionId == 'reply') {
      printf("there is a reply!");
    }*/
  String? payload = notificationResponse.payload;
  String? input = notificationResponse.input;
  if (payload == null) {
    printf("Noti fail. UI Coding error. Report this");
    return;
  }
  List<String> parts = payload.split(' ');
  if (parts[0] == "message" && input != null) {
    int n = int.parse(parts[1]);
    int group_pm = int.parse(parts[2]);
//    printf("Checkpoint notification response: $n $group_pm ${notificationResponse.input}");
    Pointer<Utf8> message = input.toNativeUtf8(); // free'd by calloc.free
    int owner = torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "owner"));
    if (group_pm != 0) {
      torx.message_send(n, ENUM_PROTOCOL_UTF8_TEXT_PRIVATE, message, message.length);
    } else if (owner == ENUM_OWNER_GROUP_CTRL || owner == ENUM_OWNER_GROUP_PEER) {
      int g = torx.set_g(n, nullptr);
      int g_invite_required = torx.getter_group_uint8(g, offsetof("group", "invite_required"));
      int group_n = torx.getter_group_int(g, offsetof("group", "n"));
      if (g_invite_required != 0) {
        // date && sign private group messages
        torx.message_send(group_n, ENUM_PROTOCOL_UTF8_TEXT_DATE_SIGNED, message, message.length);
      } else {
        torx.message_send(group_n, ENUM_PROTOCOL_UTF8_TEXT, message, message.length);
      }
    } else {
      torx.message_send(n, ENUM_PROTOCOL_UTF8_TEXT, message, message.length);
    }
    if (message != nullptr) {
      calloc.free(message);
      message = nullptr;
    }
    /*  if (notificationResponse.id != null) {
      printf("Checkpoint closing ${notificationResponse.id}");
      Noti.cancel(notificationResponse.id!, flutterLocalNotificationsPlugin); // Does not work. Cannot close after a reply is sent for unknown reason.
    } */
  } else if (parts[0] == "call" && notificationResponse.actionId != null) {
    String response = notificationResponse.actionId!;
    int call_n = int.parse(parts[1]);
    int call_c = int.parse(parts[2]);
    if (response == "accept") {
      call_join(call_n, call_c);
    } else if (response == "reject") {
      call_leave(call_n, call_c);
    } else if (response == "ignore") {
      call_ignore(call_n, call_c);
    }
    changeNotifierDrag.callback(integer: -1);
  } else if (parts[0] == "friend_request" && notificationResponse.actionId != null) {
    String response = notificationResponse.actionId!;
    int peer_n = int.parse(parts[1]);
    if (response == "accept") {
      totalIncoming--;
      torx.peer_accept(peer_n);
    } else if (response == "reject") {
      totalIncoming--;
      int peer_index = torx.getter_int(peer_n, INT_MIN, -1, offsetof("peer", "peer_index"));
      torx.takedown_onion(peer_index, 1);
    }
    changeNotifierTotalIncoming.callback(integer: totalIncoming);
    changeNotifierDataTables.callback(integer: peer_n);
  } else {
    error(0, "UI response function has unexpected args: ${parts[0]} + ${notificationResponse.actionId}. Coding error. Report this.");
  }
}

class Noti {
// NOTICE: showsUserInterface: false ---> Response runs in a different isolate. Will not work without interprocess communication. (Neither C nor Dart). 2024/04/15 ALSO DOES NOT WORK WITH INTERPROCESS COMMUNICATION
// Old: Different isolate, C works, Dart everything is initialized. DO NOT READ OR SET GLOBAL VARIABLES INCLUDING t_peer, and ChangeNotifiers don't work. Use print_message_cb() for any UI thread stuff ( ctrl+f "section 9jfj20f0w" ).
  static bool notificationsInitialized = false; // NOTE: Globally defined variable, accessible as Noti.notificationsInitialized

  static dynamic initialize(FlutterLocalNotificationsPlugin flnp) {
    if (!notificationsInitialized) {
      notificationsInitialized = true;
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
      flnp.initialize(initializationSettings, onDidReceiveNotificationResponse: response, onDidReceiveBackgroundNotificationResponse: response);
      flnp.cancelAll(); // perhaps this will kill any hangovers after a detach (doubt it)
    } else {
      printf("Noti already initialized. Not re-initializing.");
    }
  }

  static dynamic showBigTextNotification({var id = 0, required String title, required String body, required String payload, required FlutterLocalNotificationsPlugin flnp}) {
    List<String> parts = payload.split(' ');
    if (notificationsInitialized) {
      AndroidNotificationDetails
          androidPlatformChannelSpecifics = // GOAT use payload as GroupKey, so that messages are grouped per user (does not work. also changing 'channelId' to payload does not work.)
          AndroidNotificationDetails('jykliDPA9dbXfvX', 'Message Notifier',
              ongoing: /*parts[0] == "call" ? true :*/ false, // true prevents swipe dismiss in android 13/14, also causes other issues
              enableLights: true,
              ledOnMs: 2000,
              ledOffMs: 10000,
              ledColor: Colors.pink,
              groupKey: "message $id", // ( all messages grouped by...) NOTE: Calls are set with a random ID, will not be grouped.
              playSound: false,
              enableVibration: false,
              importance: Importance.high,
              priority: Priority.max,
              color: Colors.red,
              actions: [
            // GOAT showsUserInterface resumes the application to the foreground before sending, to run on the main isolate. To disable this, we have to implement a messaging mechanism to communicate with the main isolate.
            if (parts[0] == "message")
              AndroidNotificationAction('reply', text.reply,
                  /*cancelNotification: cancelAfterReply, titleColor: Colors.green,*/ contextual: false,
                  showsUserInterface: true /*DO NOT SET FALSE Interprocess communication does not work, even using ReceivePort*/,
                  inputs: [const AndroidNotificationActionInput()]),
            //    AndroidNotificationAction('dismiss', text.dismiss, cancelNotification: true) // does NOT work
            if (parts[0] == "call" || parts[0] == "friend_request") AndroidNotificationAction('accept', text.accept, contextual: false, showsUserInterface: true, inputs: []),
            if (parts[0] == "call" || parts[0] == "friend_request") AndroidNotificationAction('reject', text.reject, contextual: false, showsUserInterface: true, inputs: []),
            if (parts[0] == "call") AndroidNotificationAction('ignore', text.ignore, contextual: false, showsUserInterface: true, inputs: []),
          ]);
      flnp.show(id, title, body, NotificationDetails(android: androidPlatformChannelSpecifics /*, iOS: IOSNotificationDetails()*/), payload: payload);
    } else {
      printf("Noti not yet initialized. Initializing.1");
      Noti.initialize(flnp);
    }
  }

  static void cancel(int id, FlutterLocalNotificationsPlugin flnp, {String? tag}) {
    if (notificationsInitialized && tag != null) {
      flnp.cancel(id, tag: tag);
    } else if (notificationsInitialized) {
      flnp.cancel(id);
    }
  }

  static void cancelAll(FlutterLocalNotificationsPlugin flnp) {
    if (notificationsInitialized) flnp.cancelAll();
  }

  static Future<void> startForegroundService(FlutterLocalNotificationsPlugin flnp) async {
    if (notificationsInitialized && threadsafe_read_global_Uint8("keyed") > 0) {
      // Documentation: https://github.com/MaikuB/flutter_local_notifications/blob/5375645b01c845998606b58a3d97b278c5b2cefa/flutter_local_notifications/lib/src/platform_flutter_local_notifications.dart#L208
      // And: https://github.com/MaikuB/flutter_local_notifications/blob/5375645b01c845998606b58a3d97b278c5b2cefa/flutter_local_notifications/example/android/app/src/main/AndroidManifest.xml
      // The notification of the foreground service can be updated by method multiple times.
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'TorX Foreground Service',
        'TorX Foreground Service',
        channelDescription: 'Allows TorX to operate in the background',
        importance: Importance.none,
        priority: Priority.min,
        visibility: NotificationVisibility.secret,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: false,
        showWhen: false,
        icon: 'ic_notification_foreground',
        color: Colors.red,
        colorized: false,
        enableVibration: false, // NOTE: Cannot be changed without changing channel name
        playSound: false, // NOTE: Cannot be changed without changing channel name
        silent: true,
      );
      AndroidFlutterLocalNotificationsPlugin? platformSpecific = flnp.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (platformSpecific != null) {
        await platformSpecific.startForegroundService(1, text.title, "", notificationDetails: androidPlatformChannelSpecifics, payload: 'item x');
      }
    } else {
      printf("Noti not yet initialized. Initializing.2");
      Noti.initialize(flnp);
    }
  }

  static void stopForegroundService(FlutterLocalNotificationsPlugin flnp) {
    if (notificationsInitialized) {
      AndroidFlutterLocalNotificationsPlugin? platformSpecific = flnp.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (platformSpecific != null) {
        platformSpecific.stopForegroundService();
      }
    } else {
      printf("Noti not yet initialized. Initializing.3");
      Noti.initialize(flnp);
    }
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

class RoutePopoverGroupList extends StatefulWidget {
  final int type;
  final int g;
  const RoutePopoverGroupList(this.type, this.g, {super.key});

  @override
  State<RoutePopoverGroupList> createState() => _RoutePopoverGroupListState();
}

class _RoutePopoverGroupListState extends State<RoutePopoverGroupList> {
  TextEditingController controllerSearch = TextEditingController();
  String searchText = "";

  double searchWidth = 40;
  Color searchColor = Colors.transparent;
  bool searchOpen = false;
  Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: color.right_panel_background,
        appBar: AppBar(
          backgroundColor: color.chat_headerbar,
          title: Text(
            widget.type == ENUM_OWNER_GROUP_PEER ? text.group_peers : text.invite_friend,
            style: TextStyle(color: color.page_title),
          ),
          actions: [
            AnimatedBuilder(
                animation: changeNotifierPopoverList,
                builder: (BuildContext context, Widget? snapshot) {
                  if (searchOpen == true) {
                    searchColor = color.search_field_background;
                    searchWidth = 180;
                    suffixIcon = IconButton(
                      icon: Icon(Icons.clear, color: color.search_field_text),
                      onPressed: () {
                        searchOpen = false;
                        changeNotifierPopoverList.callback(integer: -1);
                      },
                    );
                  } else {
                    controllerSearch.clear();
                    searchText = "";
                    searchColor = Colors.transparent;
                    searchWidth = 40;
                    suffixIcon = null;
                  }
                  return Container(
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
                          searchText = content;
                          changeNotifierPopoverList.callback(integer: -1);
                        },
                        style: TextStyle(color: color.search_field_text),
                        decoration: InputDecoration(
                            suffixIcon: suffixIcon,
                            prefixIcon: IconButton(
                              icon: Icon(Icons.search, color: searchOpen == false ? color.torch_off : color.torch_on),
                              onPressed: () {
                                if (searchOpen == true) {
                                  searchOpen = false;
                                } else {
                                  searchOpen = true;
                                }
                                changeNotifierPopoverList.callback(integer: -1);
                              },
                            ),
                            hintText: text.placeholder_search,
                            hintStyle: TextStyle(color: color.torch_on),
                            border: InputBorder.none),
                      ),
                    ),
                  );
                })
          ],
        ),
        body: AnimatedBuilder(
            animation: changeNotifierPopoverList,
            builder: (BuildContext context, Widget? snapshot) {
              List<int> list;
              if (widget.type == ENUM_OWNER_GROUP_PEER && widget.g > -1) {
                list = refined_list(widget.type, widget.g, searchText);
              } else if (widget.type == ENUM_OWNER_CTRL) {
                list = refined_list(widget.type, ENUM_STATUS_FRIEND, searchText);
              } else {
                error(-1, "Critical coding error in _RoutePopoverListState");
                list = [];
              }
              return ListView.builder(
                itemCount: list.length,
                prototypeItem: const ListTile(
                  title: Text("This is dummy text used to set height. Can be dropped."),
                ),
                itemBuilder: (context, index) {
                  Color dotColor = ui_statusColor(list[index]);
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
                          t_peer.pm_n[global_n] = list[index];
                          Navigator.pop(context);
                        } else {
                          int g_invite_required = torx.getter_group_uint8(widget.g, offsetof("group", "invite_required"));
                          int g_peercount = torx.getter_group_uint32(widget.g, offsetof("group", "peercount"));
                          if (g_invite_required == 1 && g_peercount == 0) {
                            torx.message_send(list[index], ENUM_PROTOCOL_GROUP_OFFER_FIRST, torx.itovp(widget.g), GROUP_OFFER_FIRST_LEN);
                          } else {
                            torx.message_send(list[index], ENUM_PROTOCOL_GROUP_OFFER, torx.itovp(widget.g), GROUP_OFFER_LEN);
                          }
                        }
                      },
                      onLongPress: () {
                        showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, controllerMessage, list[index], INT_MIN, -1));
                      },
                      child: ListTile(
                          leading: Badge(
                            isLabelVisible: t_peer.unread[list[index]] > 0,
                            label: Text(t_peer.unread[list[index]].toString()),
                            child: dot,
                          ),
                          title: Text(
                            getter_string(list[index], INT_MIN, -1, offsetof("peer", "peernick")),
                            style: TextStyle(color: color.group_or_user_name, fontWeight: FontWeight.bold),
                          )));
                },
              );
            }));
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class RoutePopoverParticipantList extends StatefulWidget {
  final int call_n;
  final int call_c;
  const RoutePopoverParticipantList(this.call_n, this.call_c, {super.key});

  @override
  State<RoutePopoverParticipantList> createState() => _RoutePopoverParticipantListState();
}

class _RoutePopoverParticipantListState extends State<RoutePopoverParticipantList> {
  TextEditingController controllerSearch = TextEditingController();
  String searchText = "";

  double searchWidth = 40;
  Color searchColor = Colors.transparent;
  bool searchOpen = false;
  Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: color.right_panel_background,
        appBar: AppBar(
          backgroundColor: color.chat_headerbar,
          title: Text(
            text.participants,
            style: TextStyle(color: color.page_title),
          ),
        ),
        body: AnimatedBuilder(
            animation: changeNotifierPopoverList,
            builder: (BuildContext context, Widget? snapshot) {
              return ListView.builder(
                itemCount: t_peer.t_call[widget.call_n].participating[widget.call_c].length,
                prototypeItem: const ListTile(
                  title: Text("This is dummy text used to set height. Can be dropped."),
                ),
                itemBuilder: (context, index) {
                  Color dotColor = ui_statusColor(t_peer.t_call[widget.call_n].participating[widget.call_c][index]);
                  Icon dot = Icon(Icons.circle, color: dotColor, size: 20);
                  return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPressStart: (touchDetail) {
                        //    offs = touchDetail.globalPosition; // does not work, throws error jfwoqiefhwoif
                        offs = const Offset(0, 0);
                      },
                      onTap: () {
                        printf("Not doing anything here.");
                      },
                      onLongPress: () {
                        showMenu(
                            context: context,
                            position: getPosition(context),
                            items: generate_message_menu(context, controllerMessage, t_peer.t_call[widget.call_n].participating[widget.call_c][index], INT_MIN, -1));
                      },
                      child: ListTile(
                        leading: Badge(
                          isLabelVisible: true, // TODO have this determined by whether they are currently speaking
                          child: dot,
                        ),
                        title: Text(
                          getter_string(t_peer.t_call[widget.call_n].participating[widget.call_c][index], INT_MIN, -1, offsetof("peer", "peernick")),
                          style: TextStyle(color: color.group_or_user_name, fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min, // Makes the row wrap tightly around the children
                          children: [
                            IconButton(
                              icon: t_peer.t_call[widget.call_n].participant_mic[widget.call_c][index]
                                  ? Icon(Icons.mic_off, color: color.torch_off)
                                  : Icon(Icons.mic, color: color.torch_off),
                              onPressed: () {
                                // toggle_mic
                                if (t_peer.t_call[widget.call_n].participant_mic[widget.call_c][index]) {
                                  t_peer.t_call[widget.call_n].participant_mic[widget.call_c][index] = false;
                                  record_stop();
                                } else {
                                  t_peer.t_call[widget.call_n].participant_mic[widget.call_c][index] = true;
                                }
                                changeNotifierPopoverList.callback(integer: -1);
                                // TODO consider whether to call_update?
                              },
                            ),
                            IconButton(
                              icon: t_peer.t_call[widget.call_n].participant_speaker[widget.call_c][index]
                                  ? Icon(Icons.volume_off, color: color.torch_off)
                                  : Icon(Icons.volume_up, color: color.torch_off),
                              onPressed: () {
                                // toggle_speaker
                                if (t_peer.t_call[widget.call_n].participant_speaker[widget.call_c][index]) {
                                  t_peer.t_call[widget.call_n].participant_speaker[widget.call_c][index] = false;
                                } else {
                                  t_peer.t_call[widget.call_n].participant_speaker[widget.call_c][index] = true;
                                }
                                changeNotifierPopoverList.callback(integer: -1);
                                // TODO consider whether to call_update?
                              },
                            ),
                          ],
                        ),
                      ));
                },
              );
            }));
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

class RouteImage extends StatefulWidget {
  final String file_path;
  const RouteImage(this.file_path, {super.key});

  @override
  State<RouteImage> createState() => _RouteImageState();
}

class _RouteImageState extends State<RouteImage> {
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
            imageProvider: FileImage(File(widget.file_path)),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            minScale: PhotoViewComputedScale.contained,
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
  Widget statusIcon = const Icon(Icons.lock_open); // TODO use lock_open_right
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
  AudioPlayer player = AudioPlayer();

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
    if (torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "status")) == ENUM_STATUS_BLOCKED) {
      blockColor = Colors.red;
      blockText = text.blocked;
    } else {
      blockColor = color.torch_off;
      blockText = text.unblocked;
    }
  }

  void setLoggingIcon(int n) {
    int log_messages = torx.getter_int8(n, INT_MIN, -1, offsetof("peer", "log_messages"));
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
    int log_messages = torx.getter_int8(n, INT_MIN, -1, offsetof("peer", "log_messages"));
    if (log_messages == -1 || log_messages == 0) {
      log_messages++;
    } else if (log_messages == 1) {
      log_messages = -1;
    } else {
      return;
    }
    Pointer<Int8> setting = torx.torx_insecure_malloc(1) as Pointer<Int8>; // free'd by torx_free
    setting.value = log_messages;
    torx.setter(n, INT_MIN, -1, offsetof("peer", "log_messages"), setting, 1);
    torx.torx_free_simple(setting);
    setting = nullptr;
    int peer_index = torx.getter_int(n, INT_MIN, -1, offsetof("peer", "peer_index"));
    set_setting_string(0, peer_index, "logging", log_messages.toString());
  }

  void toggleKill(int n) {
    torx.kill_code(n, nullptr);
    changeNotifierChatList.callback(integer: n); // might be pointless here
  }

  void toggleDelete(int n) {
    int peer_index = torx.getter_int(n, INT_MIN, -1, offsetof("peer", "peer_index"));
    torx.takedown_onion(peer_index, 1);
    changeNotifierChatList.callback(integer: n);
  }

  void setStatus(int n) {
    int owner = torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "owner"));
    if (owner == ENUM_OWNER_GROUP_CTRL) {
      int g = torx.set_g(n, nullptr);
      int g_peercount = torx.getter_group_uint32(g, offsetof("group", "peercount"));
      statusText = "${text.status_online}: ${torx.group_online(g)} ${text.of} $g_peercount";
      return;
    }

    int sendfd_connected = torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "sendfd_connected"));
    int recvfd_connected = torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "recvfd_connected"));
    if (sendfd_connected == 0 || recvfd_connected == 0) {
      int last_seen = torx.getter_time(n, INT_MIN, -1, offsetof("peer", "last_seen"));
      if (last_seen > 0) {
        // NOTE: integer size is time_t
        statusText = "${text.status_last_seen}: ${DateFormat('yyyy/MM/dd kk:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(last_seen * 1000, isUtc: false))}";
      } else {
        statusText = "${text.status_last_seen}: ${text.status_never}";
      }
    } else {
      statusText = text.status_online;
    }
  }

  Widget messageTime(int n, int index) {
    int owner = torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "owner"));
    int stat = torx.getter_uint8(n, index, -1, offsetof("message", "stat"));
    Widget child;
    if (stat == ENUM_MESSAGE_FAIL && owner != ENUM_OWNER_GROUP_CTRL) {
      child = Icon(Icons.cancel, color: color.auth_error, size: 18);
    } else {
      String prefix = "";
      Pointer<Utf8> p = torx.message_time_string(n, index); // free'd by torx_free
      String time_string = p.toDartString();
      torx.torx_free_simple(p);
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

  Widget ui_message_builder(int n, int i) {
    int p_iter = torx.getter_int(n, i, -1, offsetof("message", "p_iter"));
    if (p_iter < 0) {
      return const Text("Negative p_iter in ui_message_builder. Coding error. Report this to UI Devs.");
    }
    int group_pm = protocol_int(p_iter, "group_pm");
    int file_offer = protocol_int(p_iter, "file_offer");
    int null_terminated_len = protocol_int(p_iter, "null_terminated_len");
    //  int file_checksum = protocol_int(p_iter, "file_checksum");
    int protocol = protocol_int(p_iter, "protocol");
    int stat = torx.getter_uint8(n, i, -1, offsetof("message", "stat"));
    int message_len = torx.getter_length(n, i, -1, offsetof("message", "message"));

    if (null_terminated_len > 0) {
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
                showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, controllerMessage, n, i, -1));
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
      Pointer<Int> file_n_p = torx.torx_insecure_malloc(8) as Pointer<Int>; // free'd by torx_free // 4 is wide enough, could be 8, should be sizeof, meh.
      int f = torx.set_f_from_i(file_n_p, n, i);
      int file_n = file_n_p.value;
      torx.torx_free_simple(file_n_p);
      file_n_p = nullptr;
      if (f < 0) {
        return const Text("Negative f from set_f_from_i. Coding error. Report this to UI Devs.");
      }
      // NOTE: this is SENT OR RECEIVED file offer
      return message_bubble(
          stat,
          group_pm,
          AnimatedBuilder(
              animation: t_peer.t_file[file_n].changeNotifierTransferProgress[f],
              builder: (BuildContext context, Widget? snapshot) {
                String filename = getter_string(file_n, INT_MIN, f, offsetof("file", "filename"));
                String file_path = getter_string(file_n, INT_MIN, f, offsetof("file", "file_path"));
                int size = torx.getter_uint64(file_n, INT_MIN, f, offsetof("file", "size"));
                int transferred = torx.calculate_transferred(file_n, f);
                Pointer<Utf8> file_size_text_p = torx.file_progress_string(file_n, f); // free'd by torx_free
                String file_size_text = file_size_text_p.toDartString();
                torx.torx_free_simple(file_size_text_p);
                file_size_text_p = nullptr;
                bool finished_image = false;
                if (t_peer.t_file[file_n].previously_completed[f] == 1 || torx.file_is_complete(file_n, f) == 1) {
                  t_peer.t_file[file_n].previously_completed[f] = 1;
                  finished_image = is_image_file(transferred, size, file_path);
                }
                double fraction = 0;
                if (transferred == 0 && t_peer.t_file[file_n].previously_completed[f] == 1) {
                  fraction = 1;
                } else if (size > 0) {
                  fraction = transferred / size;
                }
                return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      torx.pthread_rwlock_rdlock(torx.mutex_global_variable); // 🟧
                      Pointer<Utf8> download_dir = torx.download_dir[0];
                      torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
                      if ((filename == file_path || file_path == "") && download_dir == nullptr) {
                        String? selectedDirectory = await FilePicker.platform.getDirectoryPath(); // allows user to choose a directory
                        if (selectedDirectory != null && write_test(selectedDirectory)) {
                          String path = "$selectedDirectory/$filename";
                          Pointer<Utf8> file_path_p = path.toNativeUtf8(); // free'd by calloc.free
                          torx.file_set_path(file_n, f, file_path_p);
                          calloc.free(file_path_p);
                          file_path_p = nullptr;
                          //    printf("Checkpoint accept_file: $path");
                          torx.file_accept(file_n, f); // NOTE: having this in two places because this function is async
                          //    printf("Checkpoint have accepted file");
                        }
                      } else if (finished_image) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RouteImage(file_path)),
                        );
                      } else if (t_peer.t_file[file_n].previously_completed[f] == 1) {
                        //      printf("Checkpoint OpenFile $file_path");
                        OpenFilex.open(file_path);
                      } else {
                        //    printf("Checkpoint should pause or start file transfer: $file_path");
                        torx.file_accept(file_n, f); // NOTE: having this in two places because this function is async
                      }
                    },
                    onLongPressStart: (touchDetail) {
                      offs = touchDetail.globalPosition;
                    },
                    onLongPress: () {
                      showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, controllerMessage, n, i, -1));
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
                                        percent: fraction,
                                        center: Text(
                                          fraction == 1 ? "100%" : "${(fraction * 100).toStringAsFixed(0)}%",
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
      Pointer<Uint32> untrusted_peercount_p = torx.torx_insecure_malloc(4) as Pointer<Uint32>; // free'd by torx_free
      int local_g = torx.set_g_from_i(untrusted_peercount_p, n, i);
      int untrusted_peercount = untrusted_peercount_p.value;
      torx.torx_free_simple(untrusted_peercount_p);
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
              onLongPress: () {
                showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, controllerMessage, n, i, -1));
              },
              child: Column(
                crossAxisAlignment: stat == ENUM_MESSAGE_RECV ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Padding(padding: const EdgeInsets.only(right: 10.0), child: SvgPicture.asset(path_logo, color: color.logo, width: 40, height: 40)),
                    Flexible(
                      // THIS FLEXIBLE IS NECESSARY or there is an overflow here because Text widget cannot determine the size of the Row
                      child: Text("$group_type\n${text.current_members}: $peercount\n$group_name", style: TextStyle(color: _colorizeText(stat, group_pm))),
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
              Pointer<Utf8> message_local = torx.getter_string(nullptr, n, i, -1, offsetof("message", "message")); // free'd by torx_free
              s = ui_sticker_set(message_local as Pointer<Uint8>);
              torx.torx_free_simple(message_local);
              message_local = nullptr;
            }
            return message_bubble(
                stat,
                group_pm,
                s > -1 && (animated_gif = sticker_generator(s)) != null
                    ? InkWell(
                        onLongPress: () {
                          showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, controllerMessage, n, i, s));
                        },
                        child: Column(
                          crossAxisAlignment: stat == ENUM_MESSAGE_RECV ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                          children: [animated_gif!, messageTime(n, i)],
                        ))
                    : InkWell(
                        onLongPress: () {
                          showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, controllerMessage, n, i, s));
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
    } else if (protocol == ENUM_PROTOCOL_AAC_AUDIO_MSG || protocol == ENUM_PROTOCOL_AAC_AUDIO_MSG_PRIVATE || protocol == ENUM_PROTOCOL_AAC_AUDIO_MSG_DATE_SIGNED) {
      int duration = be32toh(getter_array(4, n, i, -1, offsetof("message", "message")));
      return message_bubble(
          stat,
          group_pm,
          InkWell(
              onTap: () async {
                if (player.state == PlayerState.playing) {
                  await player.stop();
                  if (last_played_n == n && last_played_i == i) {
                    return;
                  }
                }
                last_played_n = n;
                last_played_i = i;
                Uint8List bytes = getter_bytes(n, i, -1, offsetof("message", "message"));
                await player.play(BytesSource(bytes.sublist(4) /*, mimeType: "audio/L16"*/));
                if (t_peer.t_message[n].unheard[i - t_peer.t_message[n].offset] == 1 && torx.getter_uint8(n, i, -1, offsetof("message", "stat")) == ENUM_MESSAGE_RECV) {
                  t_peer.t_message[n].unheard[i - t_peer.t_message[n].offset] = 0;
                  Pointer<Uint8> val = torx.torx_insecure_malloc(1) as Pointer<Uint8>; // free'd by torx_free
                  val.value = 0;
                  torx.message_extra(n, i, val, 1);
                  print_message(n, i, 2);
                  torx.torx_free_simple(val);
                  val = nullptr;
                }
              },
              onLongPress: () {
                showMenu(context: context, position: getPosition(context), items: generate_message_menu(context, controllerMessage, n, i, -1));
              },
              child: Column(
                crossAxisAlignment: stat == ENUM_MESSAGE_RECV ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Padding(padding: const EdgeInsets.only(right: 10.0), child: SvgPicture.asset(path_logo, color: color.logo, width: 20, height: 20)),
                    Flexible(
                      // THIS FLEXIBLE IS NECESSARY or there is an overflow here because Text widget cannot determine the size of the Row
                      child: Text(" ${(duration / 1000).round()}\" ", style: TextStyle(color: _colorizeText(stat, group_pm))),
                    ),
                    if (stat == ENUM_MESSAGE_RECV && t_peer.t_message[n].unheard[i - t_peer.t_message[n].offset] == 1) Icon(Icons.circle, color: color.auth_error, size: 18)
                  ]),
                  messageTime(n, i)
                ],
              )));
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
    int p_iter = torx.getter_int(n, index, -1, offsetof("message", "p_iter"));
    int stat = torx.getter_uint8(n, index, -1, offsetof("message", "stat"));
    if (p_iter < 0 ||
        protocol_int(p_iter, "notifiable") == 0 ||
        (stat == ENUM_MESSAGE_RECV && t_peer.mute[n] == 1 && torx.getter_uint8(n, INT_MIN, -1, offsetof("peer", "owner")) == ENUM_OWNER_GROUP_PEER)) {
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

//  int call_n = -1; // should be List<int> because there could be multiple concurrent calls/offers in a group chat TODO
//  int call_c = -1; // should be List<int> because there could be multiple concurrent calls/offers in a group chat TODO

  Widget CallWaiting(int call_n, int call_c) {
    Color dragColor = Colors.grey;
    double dragPosition = -1; // Will be set. Must initialize < 0.
    double dragWidth = size_large_icon * 1.4;
    double dragThresholdAccept = 0; // WILL BE SET by CallWaiting
    double dragThresholdDecline = 0; // WILL BE SET by CallWaiting
    double dragCenter = 0; // WILL BE SET by CallWaiting
    void onDragUpdate(details) {
      double maxWidth = MediaQuery.of(context).size.width - dragWidth / 2;
      if (details.globalPosition.dx > maxWidth) {
        dragPosition = MediaQuery.of(context).size.width - dragWidth;
      } else if (details.globalPosition.dx < dragWidth / 2) {
        dragPosition = 0;
      } else {
        dragPosition = details.globalPosition.dx - dragWidth / 2;
      }
      if (dragPosition >= dragThresholdAccept) {
        dragColor = Colors.green;
      } else if (dragPosition <= dragThresholdDecline) {
        dragColor = Colors.red;
      } else {
        dragColor = Colors.grey;
      }
      changeNotifierDrag.callback(integer: -1);
    }

    void onDragEnd(int call_n, int call_c) {
      if (dragPosition >= dragThresholdAccept) {
        call_join(call_n, call_c);
      } else if (dragPosition <= dragThresholdDecline) {
        call_leave(call_n, call_c);
      }
      dragPosition = dragCenter;
      changeNotifierDrag.callback(integer: -1);
    }

    dragCenter = (MediaQuery.of(context).size.width - dragWidth) / 2;
    dragThresholdAccept = dragCenter + dragCenter * 0.8;
    dragThresholdDecline = dragCenter - dragCenter * 0.8;
    if (dragPosition == -1) dragPosition = dragCenter;
    dragColor = Colors.grey;
    return AnimatedBuilder(
        animation: changeNotifierDrag,
        builder: (BuildContext context, Widget? snapshot) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: size_large_icon,
                decoration: BoxDecoration(
                  color: Colors.blue.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              // This is the draggable button/slider
              Positioned(
                left: dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: onDragUpdate,
                  onHorizontalDragEnd: (details) => onDragEnd(call_n, call_c),
                  child: Container(
                    width: dragWidth,
                    height: size_large_icon,
                    decoration: BoxDecoration(
                      color: dragColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Icon(Icons.phone_callback, color: color.torch_off),
                    ),
                  ),
                ),
              ),
            ],
          );
        });
  }

  Widget CallAccepted(int call_n, int call_c) {
    int call_n_owner = torx.getter_uint8(call_n, INT_MIN, -1, offsetof("peer", "owner"));
    return Row(
      spacing: size_medium_icon,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (t_peer.t_call[call_n].participating[call_c].isNotEmpty)
          IconButton(
            icon: t_peer.t_call[call_n].mic_on[call_c] ? Icon(Icons.mic_off, color: color.torch_off) : Icon(Icons.mic, color: color.torch_off),
            iconSize: size_medium_icon,
            onPressed: () {
              // toggle_mic
              if (t_peer.t_call[call_n].mic_on[call_c]) {
                t_peer.t_call[call_n].mic_on[call_c] = false;
                record_stop();
              } else {
                t_peer.t_call[call_n].mic_on[call_c] = true;
              }
              call_update(call_n, call_c);
            },
          ),
        if (t_peer.t_call[call_n].participating[call_c].isNotEmpty)
          IconButton(
            icon: t_peer.t_call[call_n].speaker_on[call_c] ? Icon(Icons.volume_off, color: color.torch_off) : Icon(Icons.volume_up, color: color.torch_off),
            iconSize: size_medium_icon,
            onPressed: () {
              // toggle_speaker
              if (t_peer.t_call[call_n].speaker_on[call_c]) {
                t_peer.t_call[call_n].speaker_on[call_c] = false;
              } else {
                t_peer.t_call[call_n].speaker_on[call_c] = true;
              }
              call_update(call_n, call_c);
            },
          ),
        if (t_peer.t_call[call_n].participating[call_c].isNotEmpty && call_n_owner == ENUM_OWNER_GROUP_CTRL) // must be call_n_owner
          IconButton(
            icon: Icon(Icons.group, color: color.torch_off),
            iconSize: size_large_icon,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RoutePopoverParticipantList(call_n, call_c)),
              );
            },
          ),
        IconButton(
          icon: Icon(Icons.call_end, color: color.torch_off),
          iconSize: size_medium_icon,
          onPressed: () {
            call_leave(call_n, call_c);
          },
        ),
      ],
    );
  }

  Widget? CallColumn(int call_n, int call_c) {
    Widget? row;
    if (t_peer.t_call[call_n].waiting[call_c]) {
      row = CallWaiting(call_n, call_c);
    } else if (t_peer.t_call[call_n].joined[call_c]) {
      row = CallAccepted(call_n, call_c);
    }
    if (row != null) {
      int call_n_owner = torx.getter_uint8(call_n, INT_MIN, -1, offsetof("peer", "owner"));
      if (call_n_owner == ENUM_OWNER_GROUP_PEER) {
        String peernick = getter_string(call_n, INT_MIN, -1, offsetof("peer", "peernick"));
        return Column(
          children: [Text(style: TextStyle(color: color.page_title), peernick), row],
        );
      } else {
        return Column(
          children: [row],
        );
      }
    } else {
      return null;
    }
  }

  Uint8List bytes = Uint8List(0);
  bool show_keyboard = true;
//  AudioRecorder record = AudioRecorder();
  int former_text_len = t_peer.unsent[global_n].length;
  int start_time = 0;

  @override
  void dispose() {
    //  record.dispose(); // says we have to do this
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    owner = torx.getter_uint8(widget.n, INT_MIN, -1, offsetof("peer", "owner"));
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
          reset_unread(widget.n);
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
                              MaterialPageRoute(builder: (context) => RoutePopoverGroupList(ENUM_OWNER_GROUP_PEER, g)),
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
                        Navigator.pop(context); // Alternative: utilize changeNotifierSettingChange
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
                        Navigator.pop(context); // Alternative: utilize changeNotifierSettingChange
                      },
                    ),
                  ),
                  CustomPopupMenuItem(
                    color: color.chat_headerbar,
                    child: ListTile(
                      leading: const Icon(Icons.call),
                      title: Text(
                        text.audio_call,
                        style: TextStyle(color: color.page_title),
                      ),
                      iconColor: color.torch_off,
                      onTap: () {
                        int call_n;
                        if (t_peer.pm_n[global_n] > -1) {
                          call_n = t_peer.pm_n[global_n];
                        } else {
                          call_n = global_n;
                        }
                        call_start(call_n);
                        Navigator.pop(context); // Alternative: utilize changeNotifierSettingChange
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
                          Navigator.pop(context); // Alternative: utilize changeNotifierSettingChange
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
                                  MaterialPageRoute(builder: (context) => RoutePopoverGroupList(ENUM_OWNER_CTRL, g)),
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
                        leading: Icon(Icons.local_fire_department, color: color.torch_off),
                        title: Text(
                          text.kill,
                          style: TextStyle(color: color.page_title),
                        ),
                        iconColor: color.torch_off,
                        onTap: () {
                          // DO NOT SET STATE HERE because its all zeros. We should popuntil instead
                          toggleKill(widget.n);
                          /*    int count = 0;
                                Navigator.popUntil(context, (route) {
                                  return count++ == 2;
                                }); */
                          //        Navigator.of(context).popUntil(ModalRoute.withName("/RouteChatList"));
                        },
                      ),
                    ),
                  CustomPopupMenuItem(
                    color: color.chat_headerbar,
                    child: ListTile(
                      leading: Icon(Icons.delete_forever, color: color.torch_off),
                      title: Text(
                        text.delete,
                        style: TextStyle(color: color.page_title),
                      ),
                      iconColor: color.torch_off,
                      onTap: () {
                        // DO NOT SET STATE HERE because its all zeros. We should popuntil instead
                        toggleDelete(widget.n);
                        /*    int count = 0;
                              Navigator.popUntil(context, (route) {
                                return count++ == 2;
                              }); */
                        //      Navigator.of(context).popUntil(ModalRoute.withName("/RouteChatList"));
                      },
                    ),
                  ),
                  CustomPopupMenuItem(
                    color: color.chat_headerbar,
                    child: ListTile(
                      leading: Icon(Icons.clear_all, color: color.torch_off),
                      title: Text(
                        text.delete_log,
                        style: TextStyle(color: color.page_title),
                      ),
                      iconColor: color.torch_off,
                      onTap: () {
                        torx.delete_log(widget.n);
                        Navigator.pop(context); // pop the menu (and in the process rebuild)
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
                            printf(
                                "Checkpoint expensive changeNotifierMessage n=${changeNotifierMessage.section.n} i=${changeNotifierMessage.section.i} scroll=${changeNotifierMessage.section.scroll}");
                            int starting_msg_count;
                            if (g > -1) {
                              starting_msg_count = torx.getter_group_uint32(g, offsetof("group", "msg_count"));
                            } else {
                              starting_msg_count = torx.getter_int(widget.n, INT_MIN, -1, offsetof("peer", "max_i")) + 1;
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
                                        current_msg_count += torx.message_load_more(widget.n);
                                      } else if (index > current_msg_count - 1) {
                                        return null;
                                      }
                                      Pointer<Int> n_p = torx.torx_insecure_malloc(8) as Pointer<Int>; // free'd by torx_free
                                      Pointer<Int> i_p = torx.torx_insecure_malloc(8) as Pointer<Int>; // free'd by torx_free
                                      torx.group_get_index(n_p, i_p, g, current_msg_count - 1 - index);
                                      int n = n_p.value;
                                      int i = i_p.value;
                                      torx.torx_free_simple(n_p);
                                      n_p = nullptr;
                                      torx.torx_free_simple(i_p);
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
                                      int min_i = torx.getter_int(widget.n, INT_MIN, -1, offsetof("peer", "min_i"));
                                      if (i == min_i) {
                                        /*current_msg_count += */ torx.message_load_more(widget.n);
                                      } else if (i < min_i) {
                                        return null;
                                      }
                                      return message_builder(widget.n, i);
                                    },
                                  );
                          })),
              AnimatedBuilder(
                  animation: changeNotifierCallUpdate,
                  builder: (BuildContext context, Widget? snapshot) {
                    List<Widget> call_rows = [];
                    for (int c = 0; c < t_peer.t_call[widget.n].joined.length; c++) {
                      Widget? column = CallColumn(widget.n, c);
                      if (column != null) call_rows.add(column);
                      record_start(widget.n, c);
                    }
                    if (owner == ENUM_OWNER_GROUP_CTRL) {
                      // Iterate through all group peers and add their rows too
                      g = torx.set_g(widget.n, nullptr);
                      List<int> list = refined_list(ENUM_OWNER_GROUP_PEER, g, "");
                      for (int nn = 0; nn < list.length; nn++) {
                        int peer_n = list[nn];
                        for (int c = 0; c < t_peer.t_call[peer_n].joined.length; c++) {
                          Widget? column = CallColumn(peer_n, c);
                          if (column != null) call_rows.add(column);
                          record_start(peer_n, c);
                        }
                      }
                    }
                    return Column(
                      children: call_rows,
                    );
                  }),
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
                                  changeNotifierSendButton.callback(integer: 1); // value is arbitrary
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
                                                if (await current_recording.hasPermission()) {
                                                  printf("Checkpoint starting recording");
                                                  if (currently_recording) {
                                                    record_stop();
                                                    call_mute_all_except(-1, -1);
                                                  }

                                                  currently_recording = true;
                                                  changeNotifierTextOrAudio.callback(integer: 1); // arbitrary value
                                                  start_time = DateTime.now().millisecondsSinceEpoch;

                                                  /*  DEPRECIATED now that streaming works:
                                                  String path = "$temporaryDir/myFile.m4a";
                                                  File(path).writeAsBytesSync([]);
                                                   record.start(
                                                      const RecordConfig(encoder: AudioEncoder.aacEld, sampleRate: 16000, numChannels: 1, noiseSuppress: true, echoCancel: true),
                                                      path: path); */

                                                  final List<Uint8List> recordedDataChunks = [];
                                                  final stream = await current_recording.startStream(const RecordConfig(
                                                      encoder: AudioEncoder.aacLc,
                                                      sampleRate: 16000,
                                                      numChannels: 2 /* 2 is much louder than 1 */,
                                                      noiseSuppress: true,
                                                      echoCancel: true));
                                                  stream.listen(
                                                    (data) {
                                                      recordedDataChunks.add(data);
                                                    },
                                                    onDone: () {
                                                      bytes = Uint8List.fromList(recordedDataChunks.expand((x) => x).toList()); // chatgpt says this is simple concat
                                                    },
                                                    onError: (error) {
                                                      error(0, "Recording error: $error");
                                                    },
                                                  );
                                                } else {
                                                  error(0, "No permission to record, or already recording (in a call?)");
                                                }
                                              },
                                              onLongPressCancel: () async {
                                                if (currently_recording) {
                                                  printf("Cancel recording. Too short.");
                                                  currently_recording = false;
                                                  changeNotifierTextOrAudio.callback(integer: 1); // arbitrary value
                                                  await current_recording.cancel();
                                                }
                                              },
                                              onLongPressMoveUpdate: (det) async {
                                                if (currently_recording && det.localOffsetFromOrigin.distance > 100) {
                                                  printf("Cancel via drag");
                                                  currently_recording = false;
                                                  changeNotifierTextOrAudio.callback(integer: 1); // arbitrary value
                                                  await current_recording.cancel();
                                                }
                                              },
                                              onLongPressUp: () async {
                                                if (currently_recording) {
                                                  currently_recording = false;
                                                  changeNotifierTextOrAudio.callback(integer: 1); // arbitrary value
                                                  int duration = DateTime.now().millisecondsSinceEpoch - start_time;
                                                  //  printf("Checkpoint duration: ${DateTime.now().millisecondsSinceEpoch} - $start_time = $duration milliseconds");
                                                  final path = await current_recording
                                                      .stop(); // NOTE: Path usage is depreciated, but it is not harmful to leave this check and functionality
                                                  if (path != null || bytes.isNotEmpty) {
                                                    if (path != null && bytes.isEmpty) {
                                                      bytes = await File(path).readAsBytes();
                                                      destroy_file(path);
                                                    }
                                                    final Pointer<Uint8> ptr = malloc(4 + bytes.length);
                                                    ptr.asTypedList(4).setAll(0, htobe32(duration));
                                                    (ptr + 4).asTypedList(bytes.length).setAll(0, bytes);
                                                    if (t_peer.edit_n[widget.n] > -1 && t_peer.edit_i[widget.n] > INT_MIN) {
                                                      error(0,
                                                          "Currently no support for modifying an audio message to another audio message. Replace it with text instead, or modify message_edit() to facilitate.");
                                                    } else if (t_peer.edit_n[widget.n] > -1) {
                                                      error(0, "Cannot modify peernick to an audio message.");
                                                    } else if (t_peer.pm_n[widget.n] > -1) {
                                                      torx.message_send(t_peer.pm_n[widget.n], ENUM_PROTOCOL_AAC_AUDIO_MSG_PRIVATE, ptr, 4 + bytes.length);
                                                    } else if (owner == ENUM_OWNER_GROUP_CTRL) {
                                                      g = torx.set_g(widget.n, nullptr);
                                                      g_invite_required = torx.getter_group_uint8(g, offsetof("group", "invite_required"));
                                                      if (owner == ENUM_OWNER_GROUP_CTRL && g_invite_required != 0) {
                                                        // date && sign private group messages
                                                        torx.message_send(widget.n, ENUM_PROTOCOL_AAC_AUDIO_MSG_DATE_SIGNED, ptr, 4 + bytes.length);
                                                      } else {
                                                        torx.message_send(widget.n, ENUM_PROTOCOL_AAC_AUDIO_MSG, ptr, 4 + bytes.length);
                                                      }
                                                    } else {
                                                      torx.message_send(widget.n, ENUM_PROTOCOL_AAC_AUDIO_MSG, ptr, 4 + bytes.length);
                                                    }
                                                    malloc.free(ptr);
                                                  } else {
                                                    error(0, "Final stream data length is zero. Coding error. Report this to UI Devs.");
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
                                  changeNotifierActivity.callback(integer: 1); // value is arbitrary
                                } else if (t_peer.edit_n[widget.n] > -1) {
                                  torx.change_nick(t_peer.edit_n[widget.n], message);
                                  t_peer.edit_n[widget.n] = -1;
                                  changeNotifierActivity.callback(integer: 1); // value is arbitrary
                                  changeNotifierMessage.callback(
                                      n: -1, i: -1, scroll: -1); // SLOW-ROUTE need to rebuild NICKNAME (maybe on all messages, if group, so this might be ok)
                                } else if (t_peer.pm_n[widget.n] > -1) {
                                  torx.message_send(t_peer.pm_n[widget.n], ENUM_PROTOCOL_UTF8_TEXT_PRIVATE, message, message.length);
                                } else if (owner == ENUM_OWNER_GROUP_CTRL) {
                                  g = torx.set_g(widget.n, nullptr);
                                  g_invite_required = torx.getter_group_uint8(g, offsetof("group", "invite_required"));
                                  if (owner == ENUM_OWNER_GROUP_CTRL && g_invite_required != 0) {
                                    // date && sign private group messages
                                    torx.message_send(widget.n, ENUM_PROTOCOL_UTF8_TEXT_DATE_SIGNED, message, message.length);
                                  } else {
                                    torx.message_send(widget.n, ENUM_PROTOCOL_UTF8_TEXT, message, message.length);
                                  }
                                } else {
                                  torx.message_send(widget.n, ENUM_PROTOCOL_UTF8_TEXT, message, message.length);
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
    List<int> list;
    int owner;
    if (type == ENUM_STATUS_GROUP_CTRL) {
      owner = ENUM_OWNER_GROUP_CTRL;
      list = refined_list(ENUM_OWNER_GROUP_CTRL, ENUM_STATUS_FRIEND, search);
    } else {
      owner = ENUM_OWNER_CTRL;
      list = refined_list(ENUM_OWNER_CTRL, type, search);
    }
    return ListView.builder(
      itemCount: list.length,
      prototypeItem: const ListTile(
        title: Text("This is dummy text used to set height. Can be dropped."),
      ),
      itemBuilder: (context, index) {
        Color dotColor = ui_statusColor(list[index]);
        Pointer<Int> last_message_n_p = torx.torx_insecure_malloc(8) as Pointer<Int>; // free'd by torx_free // 4 is wide enough, could be 8, should be sizeof, meh.
        int i = INT_MIN;
        for (int count_back = 0; (i = torx.set_last_message(last_message_n_p, list[index], count_back)) > INT_MIN; count_back++) {
          if (t_peer.mute[last_message_n_p.value] == 1 && torx.getter_uint8(last_message_n_p.value, INT_MIN, -1, offsetof("peer", "owner")) == ENUM_OWNER_GROUP_PEER) {
            continue; // do not print, these are hidden messages from ignored users
          } else {
            break;
          }
        }
        int last_message_n = last_message_n_p.value;
        torx.torx_free_simple(last_message_n_p);
        last_message_n_p = nullptr;
        String prefix = "";
        String lastMessage = "";
        int p_iter;
        if (i > INT_MIN && (p_iter = torx.getter_int(last_message_n, i, -1, offsetof("message", "p_iter"))) > -1) {
          int max_i = torx.getter_int(last_message_n, INT_MIN, -1, offsetof("peer", "max_i"));
          if (max_i > INT_MIN || t_peer.unsent[last_message_n].isNotEmpty) {
            int protocol = protocol_int(p_iter, "protocol");
            int file_offer = protocol_int(p_iter, "file_offer");
            int null_terminated_len = protocol_int(p_iter, "null_terminated_len");
            int stat = torx.getter_uint8(last_message_n, i, -1, offsetof("message", "stat"));
            if (t_peer.unsent[list[index]].isNotEmpty) {
              prefix = "${text.draft}: ";
            } else if (stat == ENUM_MESSAGE_RECV && t_peer.unread[list[index]] > 0) {
              /* no prefix on recv */
            } else if (stat == ENUM_MESSAGE_FAIL && owner != ENUM_OWNER_GROUP_CTRL) {
              prefix = "${text.queued}: ";
            } else if (stat != ENUM_MESSAGE_RECV) {
              prefix = "${text.you}: ";
            }
            if (t_peer.unsent[list[index]].isNotEmpty) {
              lastMessage = t_peer.unsent[list[index]];
            } else if (file_offer > 0) {
              Pointer<Int> file_n_p = torx.torx_insecure_malloc(8) as Pointer<Int>; // free'd by torx_free // 4 is wide enough, could be 8, should be sizeof, meh.
              int f = torx.set_f_from_i(file_n_p, last_message_n, i);
              int file_n = file_n_p.value;
              torx.torx_free_simple(file_n_p);
              file_n_p = nullptr;
              f > -1 ? lastMessage = getter_string(file_n, INT_MIN, f, offsetof("file", "filename")) : lastMessage = "Invalid file offer";
            } else if (null_terminated_len > 0) {
              lastMessage = getter_string(last_message_n, i, -1, offsetof("message", "message"));
            } else if (protocol == ENUM_PROTOCOL_GROUP_OFFER || protocol == ENUM_PROTOCOL_GROUP_OFFER_FIRST) {
              lastMessage = text.group_offer;
            } else if (protocol == ENUM_PROTOCOL_AAC_AUDIO_MSG || protocol == ENUM_PROTOCOL_AAC_AUDIO_MSG_PRIVATE || protocol == ENUM_PROTOCOL_AAC_AUDIO_MSG_DATE_SIGNED) {
              lastMessage = text.audio_message;
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
            isLabelVisible: t_peer.unread[list[index]] > 0,
            label: Text(t_peer.unread[list[index]].toString()),
            child: dot,
          ),
          title: Text(
            getter_string(list[index], INT_MIN, -1, offsetof("peer", "peernick")),
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
            global_n = list[index];
            Noti.cancel(list[index], flutterLocalNotificationsPlugin);
            reset_unread(list[index]);
            //    printf("Checkpoint RouteChat n=${arrayFriends[index]}");
            Navigator.push(context, MaterialPageRoute(builder: (context) => RouteChat(list[index])));
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
              AnimatedBuilder(
                  animation: changeNotifierChatList,
                  builder: (BuildContext context, Widget? snapshot) {
                    if (searchOpen == true) {
                      searchColor = color.search_field_background;
                      searchWidth = 180;
                      suffixIcon = IconButton(
                        icon: Icon(Icons.clear, color: color.search_field_text),
                        onPressed: () {
                          searchOpen = false;
                          changeNotifierChatList.callback(integer: -1);
                        },
                      );
                    } else {
                      controllerSearch.clear();
                      searchText = "";
                      searchColor = Colors.transparent;
                      searchWidth = 40;
                      suffixIcon = null;
                    }
                    return Container(
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
                            searchText = content;
                            changeNotifierChatList.callback(integer: -1);
                          },
                          style: TextStyle(color: color.search_field_text),
                          decoration: InputDecoration(
                              suffixIcon: suffixIcon,
                              prefixIcon: IconButton(
                                icon: Icon(Icons.search, color: searchOpen == false ? color.torch_off : color.torch_on),
                                onPressed: () {
                                  if (searchOpen == true) {
                                    searchOpen = false;
                                  } else {
                                    searchOpen = true;
                                  }
                                  changeNotifierChatList.callback(integer: -1);
                                },
                              ),
                              hintText: text.placeholder_search,
                              hintStyle: TextStyle(color: color.torch_on),
                              border: InputBorder.none),
                        ),
                      ),
                    );
                  })
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
                child: AnimatedBuilder(
                    animation: changeNotifierDebugLevel,
                    builder: (BuildContext context, Widget? snapshot) {
                      return Text(
                        "${text.debug_level} ${torx.torx_debug_level(-1).toString()}",
                        style: TextStyle(color: color.page_title),
                      );
                    })),
            IconButton(
                onPressed: () {
                  int level = torx.torx_debug_level(-1);
                  if (level < 5) {
                    torx.torx_debug_level(++level);
                    changeNotifierDebugLevel.callback(integer: level);
                  }
                },
                icon: Icon(Icons.add, color: color.torch_off)),
            IconButton(
                onPressed: () {
                  int level = torx.torx_debug_level(-1);
                  if (level > 0) {
                    torx.torx_debug_level(--level);
                    changeNotifierDebugLevel.callback(integer: level);
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
                  onPressed: () {
                    shareQr(widget.data);
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
    List<int> list = refined_list(owner, ENUM_STATUS_PENDING, "");
    List<TextEditingController> controller = [];
    for (int nn = 0; nn < list.length; nn++) {
      controller.add(TextEditingController());
      controller[nn].text = getter_string(list[nn], INT_MIN, -1, offsetof("peer", "peernick")); // 8
    }

    List<DataCell> currentCells(int nn) {
      List<DataCell> currentCells;
      bool enabled = false; // only relevant to Sing and Mult
      if (torx.getter_uint8(list[nn], INT_MIN, -1, offsetof("peer", "status")) == ENUM_STATUS_FRIEND) {
        enabled = true;
      }
      if (owner == ENUM_OWNER_CTRL || owner == ENUM_OWNER_PEER) {
        currentCells = [
          DataCell(Focus(
            onFocusChange: (hasFocus) {
              hasFocus ? null : changeNick(list[nn], controller[nn]);
            },
            child: TextField(
              controller: controller[nn],
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              scribbleEnabled: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              showCursor: true,
              onEditingComplete: () {
                changeNick(list[nn], controller[nn]);
              },
              style: TextStyle(color: color.page_subtitle),
            ),
          )),
          DataCell(Text(
            getter_string(list[nn], INT_MIN, -1, offsetof("peer", lookup)),
            style: TextStyle(color: color.page_subtitle),
          )),
        ];
      } else /*if (owner == owners.ENUM_OWNER_MULT.index || owner == owners.ENUM_OWNER_SING.index) */ {
        currentCells = [
          DataCell(Switch(
              value: enabled,
              activeColor: const Color(0xFF6200EE),
              onChanged: (value) {
                torx.block_peer(list[nn]);
                enabled = value; // really we should not assume this but check the struct. thats more lines though.
                changeNotifierDataTables.callback(integer: currentRowN);
              })),
          DataCell(Focus(
            onFocusChange: (hasFocus) {
              hasFocus ? null : changeNick(list[nn], controller[nn]);
            },
            child: TextField(
              controller: controller[nn],
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              scribbleEnabled: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              showCursor: true,
              onEditingComplete: () {
                changeNick(list[nn], controller[nn]);
              },
              style: TextStyle(color: color.page_subtitle),
            ),
          )),
          DataCell(Text(
            getter_string(list[nn], INT_MIN, -1, offsetof("peer", lookup)),
            style: TextStyle(color: color.page_subtitle),
          )),
        ];
      }
      return currentCells;
    }

    List<DataRow> rows = [];
    for (int nn = 0; nn < list.length; nn++) {
      rows.add(DataRow(
        selected: currentRowN == list[nn] ? true : false,
        color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return color.selected_row; //
          } else {
            return null; // else Use the default value, ie transparent
          }
        }),
        onSelectChanged: (value) {
          if (value == true) {
            currentRowN = list[nn];
            changeNotifierDataTables.callback(integer: currentRowN);
          } else {
            currentRowN = -1;
            changeNotifierDataTables.callback(integer: currentRowN);
          }
        },
        cells: currentCells(nn),
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
    return PopScope(
        onPopInvoked: (didPop) {},
        child: AnimatedBuilder(
            animation: changeNotifierDataTables,
            builder: (BuildContext context, Widget? snapshot) {
              if (dtCurrentType == ENUM_OWNER_CTRL) {
                buttonTextDelete = text.reject;
              } else {
                buttonTextDelete = text.delete;
              }
              return Scaffold(
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
                          currentRowN = -1;
                          dtCurrentType = ENUM_OWNER_CTRL;
                          changeNotifierDataTables.callback(integer: currentRowN);
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
                          currentRowN = -1;
                          dtCurrentType = ENUM_OWNER_PEER;
                          changeNotifierDataTables.callback(integer: currentRowN);
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
                          currentRowN = -1;
                          dtCurrentType = ENUM_OWNER_MULT;
                          changeNotifierDataTables.callback(integer: currentRowN);
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
                          currentRowN = -1;
                          dtCurrentType = ENUM_OWNER_SING;
                          changeNotifierDataTables.callback(integer: currentRowN);
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
                            child: currentDataTable(dtCurrentType),
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
                        int peer_index = torx.getter_int(currentRowN, INT_MIN, -1, offsetof("peer", "peer_index"));
                        torx.takedown_onion(peer_index, 1); // currentRowN
                        currentRowN = -1;
                        if (dtCurrentType == ENUM_OWNER_CTRL) {
                          totalIncoming--;
                          changeNotifierTotalIncoming.callback(integer: totalIncoming);
                          if (launcherBadges) {
                            AppBadgePlus.updateBadge(totalUnreadPeer + totalUnreadGroup + totalIncoming);
                          }
                        }
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
              );
            }));
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

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
    String group_id_p = "";
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
            AnimatedBuilder(
                animation: changeNotifierInvalidEntry,
                builder: (BuildContext context, Widget? snapshot) {
                  return TextField(
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
                  );
                }),
            MaterialButton(
              onPressed: () {
                int ret = 0;
                group
                    ? g = ui_group_join_public(entryAddPeernickController.text, entryAddPeeronionController.text)
                    : ret = ui_add_peer(entryAddPeernickController.text, entryAddPeeronionController.text);
                if ((group && g < 0) || (!group && ret != 0)) {
                  bool_fill_peeronion = true; // indicates error / required field not filled
                  changeNotifierInvalidEntry.callback(integer: -1);
                } else {
                  if (bool_fill_peeronion) {
                    bool_fill_peeronion = false;
                    changeNotifierInvalidEntry.callback(integer: -1); // necessary, even with .clear
                  }
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
                  group_id_p = group_id;
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
                  String generated = "";
                  generated_n = changeNotifierOnionReady.section.integer;
                  if ((!group && changeNotifierOnionReady.section.integer > -1) || (group && g > -1)) {
                    generated = group ? group_id_p : getter_string(changeNotifierOnionReady.section.integer, INT_MIN, -1, offsetof("peer", "torxid"));
                  }
                  //    printf("Group g: $group $g");
                  bool deleted = false;
                  if (generated.isNotEmpty && generated.startsWith('000000')) {
                    deleted = true;
                    group ? entryAddGenerateGroupOutputController.clear() : entryAddGenerateOutputController.clear();
                  }
                  return Column(children: [
                    if (((!group && changeNotifierOnionReady.section.integer > -1) || (group && g > -1)) && !deleted && generated.isNotEmpty) generate_qr(generated),
                    if (((!group && changeNotifierOnionReady.section.integer > -1) || (group && g > -1)) && !deleted && generated.isNotEmpty)
                      MaterialButton(
                        onPressed: () {
                          shareQr(generated);
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
                          saveQr(generated);
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
      torx.torx_free_simple(torrc_errors);
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
    buttonChangePasswordText = text.wait;
    changeNotifierChangePassword.callback(integer: 500); // value is arbitrary

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
            AnimatedBuilder(
                animation: changeNotifierObscureText,
                builder: (BuildContext context, Widget? snapshot) {
                  return TextField(
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
                          obscureText1 = !obscureText1;
                          changeNotifierObscureText.callback(integer: -1);
                        },
                      ),
                    ),
                  );
                }),
            const SizedBox(height: 5),
            Text(
              text.new_password,
              style: TextStyle(color: color.page_subtitle),
            ),
            AnimatedBuilder(
                animation: changeNotifierObscureText,
                builder: (BuildContext context, Widget? snapshot) {
                  return TextField(
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
                          obscureText2 = !obscureText2;
                          changeNotifierObscureText.callback(integer: -1);
                        },
                      ),
                    ),
                  );
                }),
            const SizedBox(height: 5),
            Text(
              text.new_password_again,
              style: TextStyle(color: color.page_subtitle),
            ),
            AnimatedBuilder(
                animation: changeNotifierObscureText,
                builder: (BuildContext context, Widget? snapshot) {
                  return TextField(
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
                          obscureText3 = !obscureText3;
                          changeNotifierObscureText.callback(integer: -1);
                        },
                      ),
                    ),
                  );
                }),
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
  final List<String> languages_available_name = ["English", "中文"];
  final List<String> languages_available_code = ["en_US", "zh_CN"];
  final List<String> languages_available_code_short = ["en", "zh"];
  List<String> _themes = []; // do not set here because it can change based on language
  List<String> _idTypes = []; // do not set here because it can change based on language

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
    torx.pthread_rwlock_rdlock(torx.mutex_global_variable); // 🟧
    int original_value = p.value;
    torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
    if (tec.text.isNotEmpty && int.parse(tec.text) != original_value) {
      // might need a max here and in GTK? itoa should handle it?
      torx.pthread_rwlock_wrlock(torx.mutex_global_variable); // 🟥
      p.value = int.parse(tec.text);
      torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
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
    return PopScope(
        onPopInvoked: (didPop) {},
        child: AnimatedBuilder(
            animation: changeNotifierThemeChange,
            builder: (BuildContext context, Widget? snapshot) {
              return Scaffold(
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
                        cleanup_idle(0);
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
                        child: AnimatedBuilder(
                            animation: changeNotifierSettingChange,
                            builder: (BuildContext context, Widget? snapshot) {
                              _themes = [text.dark, text.light];
                              _idTypes = [text.generate_onionid, text.generate_torxid];
                              if (language == languages_available_code_short[0] || language == languages_available_code[0]) {
                                _selectedLanguage = languages_available_name[0];
                              } else if (language == languages_available_code_short[1] || language == languages_available_code[1]) {
                                _selectedLanguage = languages_available_name[1];
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
                              return Column(
                                children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Text(
                                      text.set_select_language,
                                      style: TextStyle(color: color.page_subtitle),
                                    ),
                                    DropdownButton(
                                        dropdownColor: color.chat_headerbar,
                                        value: _selectedLanguage,
                                        items: languages_available_name
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
                                          if (_selectedLanguage == value) {
                                            return; // compensating for flutter triggering when there is no change
                                          }
                                          if (value == languages_available_name[0]) {
                                            language = languages_available_code[0];
                                          } else if (value == languages_available_name[1]) {
                                            language = languages_available_code[1];
                                          } else {
                                            error(0, "Invalid language selected: $value");
                                          }
                                          set_setting_string(1, -1, "language", language);
                                          _selectedLanguage = value;
                                          initialize_language();
                                          //  changeNotifierSettingChange.callback(integer: -1);
                                          changeNotifierThemeChange.callback(integer: -1);
                                          changeNotifierBottom.callback(integer: -1);
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
                                          _selectedTheme = value;
                                          initialize_theme(context);
                                          //  changeNotifierSettingChange.callback(integer: -1);
                                          changeNotifierThemeChange.callback(integer: -1);
                                          changeNotifierBottom.callback(integer: -1);
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
                                          torx.pthread_rwlock_wrlock(torx.mutex_global_variable); // 🟥
                                          torx.shorten_torxids.value = shorten_torxids;
                                          torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
                                          set_setting_string(0, -1, "shorten_torxids", shorten_torxids.toString());
                                          _selectedIdType = value;
                                          changeNotifierSettingChange.callback(integer: -1);
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
                                        torx.pthread_rwlock_wrlock(torx.mutex_global_variable); // 🟥
                                        torx.global_log_messages.value = global_log_messages;
                                        torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
                                        set_setting_string(0, -1, "global_log_messages", global_log_messages.toString());
                                        _selectedGlobalLogging = value;
                                        changeNotifierSettingChange.callback(integer: -1);
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
                                        torx.pthread_rwlock_wrlock(torx.mutex_global_variable); // 🟥
                                        torx.auto_resume_inbound.value = auto_resume_inbound;
                                        torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
                                        set_setting_string(0, -1, "auto_resume_inbound", auto_resume_inbound.toString());
                                        _selectedAutoResumeInbound = value;
                                        changeNotifierSettingChange.callback(integer: -1);
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
                                        save_all_stickers = value;
                                        changeNotifierSettingChange.callback(integer: -1);
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
                                        keyboard_privacy = value;
                                        changeNotifierSettingChange.callback(integer: -1);
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
                                        Pointer<Utf8> name = "download_dir".toNativeUtf8(); // free'd by calloc.free
                                        if (selectedDirectory != null) {
                                          if (write_test(selectedDirectory) == false) {
                                            calloc.free(name);
                                            name = nullptr;
                                            return; // not writable
                                          }
                                          Pointer<Utf8> directory = selectedDirectory.toNativeUtf8(); // free'd by calloc.free
                                          Pointer<Void> allocation = torx.torx_secure_malloc(selectedDirectory.length + 1);
                                          torx.memcpy(allocation, directory, selectedDirectory.length + 1);
                                          torx.pthread_rwlock_wrlock(torx.mutex_global_variable); // 🟥
                                          torx.torx_free_simple(torx.download_dir[0]);
                                          torx.download_dir[0] = allocation as Pointer<Utf8>;
                                          torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
                                          set_setting_string(0, -1, "download_dir", selectedDirectory);
                                          calloc.free(directory);
                                          directory = nullptr;
                                        } else {
                                          torx.pthread_rwlock_wrlock(torx.mutex_global_variable); // 🟥
                                          if (torx.download_dir[0] != nullptr) {
                                            torx.torx_free_simple(torx.download_dir[0]);
                                            torx.download_dir[0] = nullptr;
                                          }
                                          torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
                                          torx.sql_delete_setting(0, -1, name);
                                        }
                                        calloc.free(name);
                                        name = nullptr;
                                        changeNotifierSettingChange.callback(integer: -1); // torx.download_dir[0] changed
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
                                          torx.pthread_rwlock_wrlock(torx.mutex_global_variable); // 🟥
                                          torx.global_threads.value = global_threads;
                                          torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
                                          set_setting_string(0, -1, "global_threads", global_threads.toString());
                                          _selectedCpuThreads = value;
                                          changeNotifierSettingChange.callback(integer: -1);
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
                                          torx.pthread_rwlock_wrlock(torx.mutex_global_variable); // 🟥
                                          torx.suffix_length.value = suffix_length;
                                          torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
                                          set_setting_string(0, -1, "suffix_length", suffix_length.toString());
                                          _selectedSuffixLength = value;
                                          changeNotifierSettingChange.callback(integer: -1);
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
                                        text.set_auto_mult,
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
                                        torx.pthread_rwlock_wrlock(torx.mutex_global_variable); // 🟥
                                        torx.auto_accept_mult.value = auto_accept_mult;
                                        torx.pthread_rwlock_unlock(torx.mutex_global_variable); // 🟩
                                        set_setting_string(0, -1, "auto_accept_mult", auto_accept_mult.toString());
                                        _selectedAutoMult = value;
                                        changeNotifierSettingChange.callback(integer: -1);
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
                                      changeNotifierSettingChange.callback(integer: -1);
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
                                        validExternal = false;
                                        changeNotifierSettingChange.callback(integer: -1);
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
                                        Pointer<Utf8> identifier = controllerCustomInputIdentifier.text.toNativeUtf8(); // free'd by calloc.free
                                        Pointer<Utf8> privkey = controllerCustomInputPrivkey.text.toNativeUtf8(); // free'd by calloc.free
                                        torx.custom_input(ENUM_OWNER_MULT, identifier, privkey);
                                        calloc.free(identifier);
                                        identifier = nullptr;
                                        calloc.free(privkey);
                                        privkey = nullptr;
                                        controllerCustomInputPrivkey.clear();
                                        controllerCustomInputIdentifier.clear();
                                        validExternal = false;
                                        changeNotifierSettingChange.callback(integer: -1);
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
                              );
                            }))),
              );
            }));
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
    _selectedIndex = index;
    changeNotifierBottom.callback(integer: _selectedIndex);
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
        animation: changeNotifierBottom,
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
