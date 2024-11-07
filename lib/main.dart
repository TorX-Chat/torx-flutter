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
// ignore_for_file: avoid_print, non_constant_identifier_names, camel_case_types, constant_identifier_names
import 'dart:async';
import 'dart:ffi';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:chat/callbacks.dart';
import 'package:chat/stickers.dart';
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'colors.dart';
import 'routes.dart';
import 'route_login.dart';
import 'manual_bindings.dart';
import 'language.dart';
import 'change_notifiers.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';

/* Global Variables */
int current_index = 0;
int global_n = -1; // for current RouteChat
final dynamicLibrary = DynamicLibrary.open(getPath());
String language = "";
int theme = -1; // DO NOT set a default here. Setting it at 0 allows everything to initialized properly after the system theme is checked.
int bottom_index = 1; // default is add/generate page
int notificationCount = 0;
bool keyboard_privacy = true; // disable IME by default
bool log_unread = true;
bool autoFocusKeyboard = true; // GOAT If there are segfaults on pop, this being TRUE is probably why. Other chats we tested don't use it anyway (but it would be nice)
bool preventScreenshots = true;
bool autoRunOnBoot = false; // GOAT whether or not to start foreground service on boot (currently useless because our application doesn't start with it) TODO
const String path_logo = 'lib/other/svg/logo_torx.svg';
// bool cancelAfterReply = true; // cancel notifications after replying (DOES NOT WORK, not important)

int generated_n = -1;
int last_played_n = -1;
int last_played_i = INT_MIN;
int totalUnreadPeer = 0;
int totalUnreadGroup = 0;
int totalIncoming = 0; // incoming peer requests, ++'d from incoming_friend_request_cb_ui
bool login_failed = false;
bool callbacks_registered = false;
bool launcherBadges = true;
String torLogBuffer = ""; // global
String torxLogBuffer = "";
String? temporaryDir; // WARNING: Use String? instead of Directory? because Directory interpolates incorrectly to String (it adds a bunk prefix)
String? nativeLibraryDir;
String? applicationDocumentsDir;
bool initialized = false; // initialization_functions() only

const double size_large_icon = 50;
const double size_medium_icon = 32;

ScrollController scrollcontroller_log_tor = ScrollController();
ScrollController scrollcontroller_log_torx = ScrollController();
TextEditingController entryAddPeeronionController = TextEditingController();
TextEditingController entryAddGeneratePeernickController = TextEditingController();
TextEditingController entryAddGenerateOutputController = TextEditingController();
TextEditingController controllerMessage = TextEditingController();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class t_file_class {
  // NOTE: if adding things, be sure to handle them in expand_file_struc_cb() and initialize_f_cb()
  List<ChangeNotifierTransferProgress> changeNotifierTransferProgress = [
    ChangeNotifierTransferProgress(),
    ChangeNotifierTransferProgress(),
    ChangeNotifierTransferProgress(),
    ChangeNotifierTransferProgress(),
    ChangeNotifierTransferProgress(),
    ChangeNotifierTransferProgress(),
    ChangeNotifierTransferProgress(),
    ChangeNotifierTransferProgress(),
    ChangeNotifierTransferProgress(),
    ChangeNotifierTransferProgress(),
    ChangeNotifierTransferProgress(),
  ]; // 11
//  List<int> time_left = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]; //11
}

class t_message_class {
  // NOTE: if adding things, be sure to handle them in expand_message_struc_cb() and initialize_i_cb()
  List<int> unheard = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; //11
}

class t_peer {
  // NOTE: if adding things, be sure to handle them in expand_peer_struc_cb() and initialize_n_cb()
  // WARNING: These have to be intialized to the proper value (ie, -1 not 0) because the settings can be re-initialized in flutter by lifecycle changes
  static List<String> unsent = ["", "", "", "", "", "", "", "", "", "", ""]; //11
  static List<int> mute = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; //11
  static List<int> unread = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; //11
  static List<int> pm_n = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]; //11
  static List<int> edit_n = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]; //11
  static List<int> edit_i = [INT_MIN, INT_MIN, INT_MIN, INT_MIN, INT_MIN, INT_MIN, INT_MIN, INT_MIN, INT_MIN, INT_MIN, INT_MIN]; //11
  static List<t_file_class> t_file = [
    t_file_class(),
    t_file_class(),
    t_file_class(),
    t_file_class(),
    t_file_class(),
    t_file_class(),
    t_file_class(),
    t_file_class(),
    t_file_class(),
    t_file_class(),
    t_file_class(),
  ]; // 11
  static List<t_message_class> t_message = [
    t_message_class(),
    t_message_class(),
    t_message_class(),
    t_message_class(),
    t_message_class(),
    t_message_class(),
    t_message_class(),
    t_message_class(),
    t_message_class(),
    t_message_class(),
    t_message_class(),
  ]; // 11
  static List<List<Pointer<Uint8>>> stickers_requested = [[], [], [], [], [], [], [], [], [], [], []]; // 11
}

AppLifecycleState globalAppLifecycleState = AppLifecycleState.resumed; // This is the appropriate default Enum values below
/*
AppLifecycleState.detached; // ??? ded ???
AppLifecycleState.resumed; // foreground
AppLifecycleState.inactive; // paused by system, seems to be transitory between resumed and paused (fraction of second of 'pausing')
AppLifecycleState.paused; // background
*/

void resumptionTasks() {
  // This is called on startup (by main), on .resume after .pause, and when resuming after .detach (by main, not .resume)
  // Any UI held values will be defaults if this has occured after .detach. This means things like .unread will be zero'd.
  // Find a way to set "resuming from detach" bool that can re-set or re-fetch certain things, like .unread counts and such
  flutterLocalNotificationsPlugin.cancelAll();
  _stopForegroundService();
  if (threadsafe_read_global_Uint8("keyed") > 0) {
    if (!callbacks_registered) {
      register_callbacks(); // NECESSARY to call again, in case .detach occured
      torx.re_expand_callbacks();
      torx.sql_populate_setting(1); // re-load plaintext settings to get UI settings
      torx.sql_populate_setting(0); // re-load settings to get UI settings and stickers, etc
    }
    if (totalUnreadPeer > 0 || totalUnreadGroup > 0) {
      changeNotifierTotalUnread.callback(integer: -5);
      changeNotifierChatList.callback(integer: 0);
    }
    if (totalIncoming > 0) {
      changeNotifierTotalIncoming.callback(integer: 0);
    }
    if (launcherBadges && totalIncoming > 0 || totalUnreadPeer > 0 || totalUnreadGroup > 0) {
      AppBadgePlus.updateBadge(totalUnreadPeer + totalUnreadGroup + totalIncoming);
    }
  }
}

Future<void> _startForegroundService() async {
  // Documentation: https://github.com/MaikuB/flutter_local_notifications/blob/5375645b01c845998606b58a3d97b278c5b2cefa/flutter_local_notifications/lib/src/platform_flutter_local_notifications.dart#L208
  // And: https://github.com/MaikuB/flutter_local_notifications/blob/5375645b01c845998606b58a3d97b278c5b2cefa/flutter_local_notifications/example/android/app/src/main/AndroidManifest.xml
  // The notification of the foreground service can be updated by method multiple times.
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'Foreground service channel2',
    'Foreground service channel2',
    channelDescription: 'Foreground service channel description',
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
  AndroidFlutterLocalNotificationsPlugin? flnp = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (flnp != null) {
    await flnp.startForegroundService(1, text.title, "", notificationDetails: androidPlatformChannelSpecifics, payload: 'item x');
  }
}

void _stopForegroundService() {
  AndroidFlutterLocalNotificationsPlugin? flnp = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (flnp != null) {
    flnp.stopForegroundService();
  }
}

void requestPermissions() {
  //  Map<Permission, PermissionStatus> statuses =
  //await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  //await FlutterForegroundTask.requestNotificationPermission();
  [Permission.notification].request();
  //  await platform.invokeMethod('requestStoragePermission');
}

void initialization_functions(BuildContext? context) {
  if (initialized) {
    printf("Already initialized. Bailing from initialization_functions."); // DO NOT USE ERROR
    return;
  }
  register_callbacks(); // !!! GOAT DO NOT PUT ANY TORX FUNCTIONS BEFORE THIS !!! TODO

  String tor_location = "$nativeLibraryDir/libtor.so";
  String lyrebird_location = "nativeLibraryDir/liblyrebird.so"; // This is a FAKE location that is replaced by the library with native_library_directory
  String conjure_location = "nativeLibraryDir/libconjure.so"; // This is a FAKE location that is replaced by the library with native_library_directory
  String snowflake_location = "nativeLibraryDir/libsnowflake.so"; // This is a FAKE location that is replaced by the library with native_library_directory

  torx.torx_debug_level(0);

  torx.pthread_rwlock_wrlock(torx.mutex_global_variable);
  torx.tor_location[0] = tor_location.toNativeUtf8();
  torx.lyrebird_location[0] = lyrebird_location.toNativeUtf8();
  torx.conjure_location[0] = conjure_location.toNativeUtf8();
  torx.snowflake_location[0] = snowflake_location.toNativeUtf8();
  torx.native_library_directory[0] = nativeLibraryDir!.toNativeUtf8();
  torx.reduced_memory.value = 2; // 1 == 256mb, 2 == 64mb
  torx.working_dir[0] = applicationDocumentsDir!.toNativeUtf8(); // necessary before initial on systems where $HOME is not set
  torx.tor_data_directory[0] = "$applicationDocumentsDir/tor".toNativeUtf8(); // hardcoding this. This will override user settings for sanity purposes.
  torx.pthread_rwlock_unlock(torx.mutex_global_variable);

  printf("Tor Location: $tor_location");
  torx.initial(); // !!! GOAT DO NOT PUT ANY (other) TORX FUNCTIONS BEFORE THIS (such as set_torrc or errorr) !!! TODO
  printf("WARNING: This is debug build. Remember to check torrc and set proxy if necessary: Socks5Proxy 10.0.2.2:PORT");

  Directory(nativeLibraryDir!).list(recursive: false).forEach((f) {
    error(0, f.toString());
  });
  error(0, "Working dir: $applicationDocumentsDir");

  protocol_registration(ENUM_PROTOCOL_STICKER_HASH, "Sticker", "", 0, 0, 0, 1, 1, 0, 0, ENUM_EXCLUSIVE_GROUP_MSG, 0, 1, 0);
  protocol_registration(ENUM_PROTOCOL_STICKER_HASH_DATE_SIGNED, "Sticker Date Signed", "", 0, 2 * 4, crypto_sign_BYTES, 1, 1, 0, 0, ENUM_EXCLUSIVE_GROUP_MSG, 0, 1, 0);
  protocol_registration(ENUM_PROTOCOL_STICKER_HASH_PRIVATE, "Sticker Private", "", 0, 0, 0, 1, 1, 0, 0, ENUM_EXCLUSIVE_GROUP_PM, 0, 1, 0);
  protocol_registration(ENUM_PROTOCOL_STICKER_REQUEST, "Sticker Request", "", 0, 0, 0, 0, 0, 0, 0, ENUM_EXCLUSIVE_NONE, 0, 1, 0);
  protocol_registration(ENUM_PROTOCOL_STICKER_DATA_GIF, "Sticker data", "", 0, 0, 0, 0, 0, 0, 0, ENUM_EXCLUSIVE_NONE, 0, 1, ENUM_STREAM_NON_DISCARDABLE);
  protocol_registration(ENUM_PROTOCOL_AAC_AUDIO_MSG, "AAC Audio Message", "", 0, 0, 0, 1, 1, 0, 0, ENUM_EXCLUSIVE_GROUP_MSG, 0, 1, 0);
  protocol_registration(ENUM_PROTOCOL_AAC_AUDIO_MSG_DATE_SIGNED, "AAC Audio Message Date Signed", "", 0, 2 * 4, crypto_sign_BYTES, 1, 1, 0, 0, ENUM_EXCLUSIVE_GROUP_MSG, 0, 1, 0);
  protocol_registration(ENUM_PROTOCOL_AAC_AUDIO_MSG_PRIVATE, "AAC Audio Message Private", "", 0, 0, 0, 1, 1, 0, 0, ENUM_EXCLUSIVE_GROUP_PM, 0, 1, 0);

  int first_run = threadsafe_read_global_Uint8("first_run");
  printf("First run: $first_run");

  initialize_language();
  initialize_theme(context);
  requestPermissions();
  initialized = true;
}

Uint8List htobe32(int value) {
  value = value & 0xFFFFFFFF; // Ensure the value fits within 32 bits by masking with 0xFFFFFFFF (???)
  final byteData = ByteData(4);
  byteData.setUint32(0, value, Endian.big);
  return byteData.buffer.asUint8List();
}

int be32toh(Uint8List bytes) {
  final byteData = ByteData.sublistView(bytes);
  return byteData.getUint32(0, Endian.big);
}

class TorX extends StatefulWidget {
  const TorX({super.key});

  @override
  State<TorX> createState() => _TorXState();
}

class _TorXState extends State<TorX> with RestorationMixin, WidgetsBindingObserver {
  void _screenshotInit() {
    if (preventScreenshots && Platform.isAndroid) {
      ScreenProtector.protectDataLeakageOn();
    } else if (preventScreenshots && Platform.isIOS) {
      ScreenProtector.protectDataLeakageOff();
    }
  }

  void _screenshotDispose() {
    if (preventScreenshots && Platform.isAndroid) {
      ScreenProtector.protectDataLeakageOff();
    } else if (preventScreenshots && Platform.isIOS) {
      ScreenProtector.preventScreenshotOff();
    }
  }

  @override
  String get restorationId => 'app_state';
  @override
  void initState() {
    _screenshotInit();
    super.initState();
    Noti.initialize(flutterLocalNotificationsPlugin);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _screenshotDispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    error(0, "Checkpoint restoreState");
    resumptionTasks(); // THIS IS HIGHLY NECESSARY, DO NOT REMOVE. Necessary to re-register callbacks and re-fetch settings from lib.
    //  if (kDebugMode) Noti.showBigTextNotification(title: 'restoreState', body: '', fln: flutterLocalNotificationsPlugin);
    if (threadsafe_read_global_Uint8("keyed") != 0) {
      setBottomIndex(); // choose landing page
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    globalAppLifecycleState = state;
    switch (state) {
      case AppLifecycleState.resumed:
        error(0, "Checkpoint AppLifecycleState.resumed");
        resumptionTasks(); // necessary to remove foreground service
        //  if (kDebugMode) Noti.showBigTextNotification(title: 'AppLifecycleState.resumed', body: '', fln: flutterLocalNotificationsPlugin);
        break;
      case AppLifecycleState.inactive:
        error(0, "Checkpoint AppLifecycleState.inactive");
        //  if (kDebugMode) Noti.showBigTextNotification(title: 'AppLifecycleState.inactive', body: '', fln: flutterLocalNotificationsPlugin);
        break;
      case AppLifecycleState.paused:
        error(0, "Checkpoint AppLifecycleState.paused");
        //  if (kDebugMode) Noti.showBigTextNotification(title: 'AppLifecycleState.paused', body: '', fln: flutterLocalNotificationsPlugin);
        await _startForegroundService(); // 2024/09/22 MUST AWAIT otherwise it won't happen. DO NOT REMOVE AWAIT.
        writeUnread();
        break;
      case AppLifecycleState.detached:
        error(0, "Checkpoint AppLifecycleState.detached");
        // !!! DO NOT PUT ANYTHING OTHER THAN DEBUG PRINT IN HERE (.detached) It will fail and leave errors in android log. !!!
        //  if (kDebugMode) Noti.showBigTextNotification(title: 'AppLifecycleState.detached', body: '', fln: flutterLocalNotificationsPlugin);
        //  flutterLocalNotificationsPlugin.cancelAll();
        //  FlutterForegroundTask.stopService(); // NOTE: this will probably NOT occur and an abandoned foreground service could occur... however torx runs in background so its ok/good
        break;
      case AppLifecycleState.hidden:
        error(0, "Checkpoint AppLifecycleState.hidden");
        //  if (kDebugMode) Noti.showBigTextNotification(title: 'AppLifecycleState.hidden', body: '', fln: flutterLocalNotificationsPlugin);
        break;
    } // GOAT this switch can be used to do stuff when lifecycle changes occur, but there is a limit. When being detached, its hard to get anything done
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    printf("BUILD TIMES -----> ${Callbacks().build_times}");
    Callbacks().build_times++;
    initialization_functions(context);
    return MaterialApp(
        restorationScopeId: 'app',
        title: text.title,
        theme: ThemeData(
          primarySwatch: Colors.pink,
        ),
        home: threadsafe_read_global_Uint8("keyed") == 0 ? const RouteLogin() : const RouteBottom());
  }
}

void shareQr(String generated) async {
  String path = '$temporaryDir/qr.png';
  Pointer<Size_t> size_p = malloc(8); // free'd by calloc.free // 4 is wide enough, could be 8, should be sizeof, meh.
  Pointer<Utf8> generated_p = generated.toNativeUtf8();
  Pointer<Void> qr_raw = torx.qr_bool(generated_p, 8); // free'd by torx_free
  calloc.free(generated_p);
  generated_p = nullptr;
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
  await Share.shareXFiles(
    [XFile(path)],
  );
  destroy_file(path); // MUST AWAIT or this will corrupt
}

void saveQr(String data) async {
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

Image generate_qr(String data) {
  Pointer<Utf8> data_p = data.toNativeUtf8(); // free'd by calloc.free
  Pointer<Size_t> size_p = malloc(8); // free'd by calloc.free
  Pointer<Void> qr_raw = torx.qr_bool(data_p, 8); // free'd by torx_free
  Pointer<Void> png = torx.return_png(size_p, qr_raw);
  Image image = Image.memory(Pointer<Uint8>.fromAddress(png.address).asTypedList(size_p.value));
  torx.torx_free_simple(qr_raw);
  qr_raw = nullptr;
//  torx.torx_secure_free_simple(png); // GOAT TODO need to free png, but then the image is broke and our application crashes
  calloc.free(data_p);
  data_p = nullptr;
  calloc.free(size_p);
  size_p = nullptr;
  return image;
}

/* DO NOT DELETE: was once useful for getting screen 'position' (x,y) (for showMenu, which is useless) and may one be again */
Offset offs = const Offset(0, 0);
RelativeRect getPosition(context) {
  OverlayState? os = Navigator.of(context).overlay;
  RelativeRect position;
  if (offs == const Offset(0, 0) || os == null) // this is to handle an error we can't work out in RoutePopoverList jfwoqiefhwoif
  {
    position = RelativeRect.fill;
  } else {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay = os.context.findRenderObject()! as RenderBox;
    position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(offs, ancestor: overlay),
        button.localToGlobal(button.size.bottomLeft(Offset.zero) + offs, ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
  }

  return position;
}

/*RelativeRect getPosition(BuildContext context) {
  printf("Checkpoint 0");

  final RenderBox? button = context.findRenderObject() as RenderBox?;
  printf("Checkpoint 01");

  final RenderObject? overlayRenderObject = Navigator.of(context).overlay?.context.findRenderObject();
  printf("Checkpoint 02");

  if (button == null || overlayRenderObject == null || overlayRenderObject is! RenderBox) {
    printf("Checkpoint 1");
    throw Exception('Failed to find render objects.');
  }
  printf("Checkpoint 2");

  final RenderBox overlay = overlayRenderObject;
  final Rect buttonRect = Rect.fromPoints(
    button.localToGlobal(offs, ancestor: overlay),
    button.localToGlobal(button.size.bottomLeft(Offset.zero) + offs, ancestor: overlay),
  );

  return RelativeRect.fromRect(buttonRect, Offset.zero & overlay.size);
}*/
/*Widget list_view_string(String arg) {
  // ISSUE: this can be used to make RouteLog less janky, but multi-line selections are not possible. NOTE: need to add scroll controller / animatedbuilder, and resolve multi-line
  List<String> lines = arg.split('\n');
  return ListView.builder(
    itemCount: lines.length,
    itemBuilder: (context, index) {
      return SelectableText(lines[index],
          textAlign: TextAlign.left,
          style: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
            color: color.right_panel_text,
          ));
    },
  );
}*/

void toggleMute(int n) {
  if (t_peer.mute[n] == 0) {
    t_peer.mute[n] = 1;
  } else if (t_peer.mute[n] == 1) {
    t_peer.mute[n] = 0;
  } else {
    return;
  }
  int peer_index = torx.getter_int(n, INT_MIN, -1, -1, offsetof("peer", "peer_index"));
  set_setting_string(0, peer_index, "mute", t_peer.mute[n].toString());
}

void toggleBlock(int n) {
  torx.block_peer(n);
  changeNotifierOnlineOffline.callback(integer: n);
  changeNotifierChatList.callback(integer: n);
}

List<PopupMenuEntry<dynamic>> generate_message_menu(context, TextEditingController? controllerMessage, int n, int i, int f, int s) {
  int message_owner = -1;
  int stat = -1;
  int file_status = -1;
  int p_iter = -1;
  int null_terminated_len = 0;
  int protocol = 0;
  Icon ignoreIcon = const Icon(Icons.notifications_off);
  String ignoreText = text.unignore;
  Color blockColor = color.torch_off;
  String blockText = text.unblocked;

  void setIgnoreIcon(int n) {
    if (t_peer.mute[n] == 0) {
      ignoreIcon = Icon(Icons.notifications_active, color: color.torch_on);
      ignoreText = text.ignore;
    } else if (t_peer.mute[n] == 1) {
      ignoreIcon = Icon(Icons.notifications_off, color: color.torch_off);
      ignoreText = text.unignore;
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

  if (n > -1) {
    message_owner = torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "owner"));
    if (f > -1) {
      file_status = torx.getter_uint8(n, INT_MIN, f, -1, offsetof("file", "status"));
    }
    if (i > INT_MIN) {
      stat = torx.getter_uint8(n, i, -1, -1, offsetof("message", "stat"));
      p_iter = torx.getter_int(n, i, -1, -1, offsetof("message", "p_iter"));
      if (p_iter > -1) {
        null_terminated_len = protocol_int(p_iter, "null_terminated_len");
        protocol = protocol_int(p_iter, "protocol");
      }
    }
  }
  printf("Checkpoint generate_message_menu protocol $protocol: $n $i $f $s");
  if (n > -1) {
    setIgnoreIcon(n);
    setBlockIcon(n);
  }
  return <PopupMenuEntry>[
    if (s > -1 && !stickers[s].saved)
      PopupMenuItem(
          child: ListTile(
              leading: const Icon(Icons.save),
              title: Text(text.save),
              onTap: () {
                ui_sticker_save(s);
                changeNotifierStickerReady.callback(integer: s);
                Navigator.pop(context);
              })),
    if (s > -1 && n < 0 && i == INT_MIN)
      PopupMenuItem(
          child: ListTile(
              leading: const Icon(Icons.delete),
              title: Text(text.delete),
              onTap: () {
                ui_sticker_delete(s);
                changeNotifierStickerReady.callback(integer: s);
                Navigator.pop(context);
              })),
    if (f > -1 && (/*file_status == ENUM_FILE_OUTBOUND_PENDING || */ file_status == ENUM_FILE_INBOUND_PENDING))
      PopupMenuItem(
          child: ListTile(
              leading: const Icon(Icons.start),
              title: Text(text.start),
              onTap: () {
                int nnn = handle_stuff(n, i);
                torx.file_accept(nnn, f);
                Navigator.pop(context);
              })),
    if (f > -1 && (file_status == ENUM_FILE_OUTBOUND_ACCEPTED || file_status == ENUM_FILE_INBOUND_ACCEPTED))
      PopupMenuItem(
          child: ListTile(
              leading: const Icon(Icons.pause),
              title: Text(text.pause),
              onTap: () {
                int nnn = handle_stuff(n, i);
                torx.file_accept(nnn, f);
                Navigator.pop(context);
              })),
    if (f > -1 && (stat == ENUM_MESSAGE_RECV))
      PopupMenuItem(
          child: ListTile(
              leading: const Icon(Icons.cancel),
              title: Text(text.reject),
              onTap: () {
                int nnn = handle_stuff(n, i);
                torx.file_cancel(nnn, f);
                Navigator.pop(context);
              })),
    if (f > -1 && (stat != ENUM_MESSAGE_RECV))
      PopupMenuItem(
          child: ListTile(
              leading: const Icon(Icons.cancel),
              title: Text(text.cancel),
              onTap: () {
                int nnn = handle_stuff(n, i);
                torx.file_cancel(nnn, f);
                Navigator.pop(context);
              })),
    if (f < 0 && null_terminated_len > 0)
      PopupMenuItem(
          child: ListTile(
              leading: const Icon(Icons.copy),
              title: Text(text.copy),
              onTap: () {
                String message = getter_string(n, i, -1, offsetof("message", "message"));
                Clipboard.setData(ClipboardData(text: message));
                Navigator.pop(context);
              })),
    if (f < 0 && null_terminated_len > 0)
      PopupMenuItem(
          child: ListTile(
              leading: const Icon(Icons.edit),
              title: Text(text.edit),
              onTap: () {
                t_peer.pm_n[global_n] = -1;
                t_peer.edit_n[global_n] = n;
                t_peer.edit_i[global_n] = i;
                changeNotifierActivity.callback(integer: 1); // value is arbitrary
                if (controllerMessage != null) {
                  controllerMessage.text = t_peer.unsent[global_n] = getter_string(n, i, -1, offsetof("message", "message"));
                }
                Navigator.pop(context);
              })),
    if (message_owner == ENUM_OWNER_GROUP_PEER)
      PopupMenuItem(
          child: ListTile(
              leading: const Icon(Icons.message),
              title: Text(text.private_messaging),
              onTap: () {
                t_peer.edit_n[global_n] = -1;
                t_peer.edit_i[global_n] = INT_MIN;
                t_peer.pm_n[global_n] = n;
                changeNotifierActivity.callback(integer: 1); // value is arbitrary
                Navigator.pop(context);
              })),
    if (message_owner == ENUM_OWNER_GROUP_PEER)
      PopupMenuItem(
          child: ListTile(
              leading: const Icon(Icons.edit), // rename
              title: Text(text.rename),
              onTap: () {
                t_peer.pm_n[global_n] = -1;
                t_peer.edit_i[global_n] = INT_MIN;
                t_peer.edit_n[global_n] = n;
                changeNotifierActivity.callback(integer: 1); // value is arbitrary
                if (controllerMessage != null) {
                  controllerMessage.text = t_peer.unsent[global_n] = getter_string(n, INT_MIN, -1, offsetof("peer", "peernick"));
                }
                Navigator.pop(context);
              })),
    if (message_owner == ENUM_OWNER_GROUP_PEER)
      PopupMenuItem(
          child: ListTile(
              leading: ignoreIcon, // rename
              title: Text(ignoreText),
              onTap: () {
                toggleMute(n);
                changeNotifierPopoverList.callback(integer: n);
                Navigator.pop(context);
              })),
    if (message_owner == ENUM_OWNER_GROUP_PEER)
      PopupMenuItem(
          child: ListTile(
              leading: Icon(Icons.block, color: blockColor), // rename
              title: Text(blockText),
              onTap: () {
                toggleBlock(n);
                changeNotifierPopoverList.callback(integer: n);
                Navigator.pop(context);
              })),
    if (n > -1 && i > INT_MIN)
      PopupMenuItem(
          child: ListTile(
              leading: const Icon(Icons.delete),
              title: Text(text.delete),
              onTap: () {
                torx.message_edit(n, i, nullptr);
                Navigator.pop(context);
              })),
  ];
}

void print_message(int n, int i, int scroll) {
  if (n < 0 || i == INT_MIN) {
    error(0, "Sanity checkfailed in print_message");
    return;
  }
  int p_iter = torx.getter_int(n, i, -1, -1, offsetof("message", "p_iter"));
  if (p_iter < 0) {
    return; // message deleted
  }
  int stat = torx.getter_uint8(n, i, -1, -1, offsetof("message", "stat"));
  int protocol = protocol_int(p_iter, "protocol");

  if (stat == ENUM_MESSAGE_RECV && scroll == 1) {
    int message_len = torx.getter_uint32(n, i, -1, -1, offsetof("message", "message_len"));
    if (message_len >= CHECKSUM_BIN_LEN &&
        (protocol == ENUM_PROTOCOL_STICKER_HASH || protocol == ENUM_PROTOCOL_STICKER_HASH_PRIVATE || protocol == ENUM_PROTOCOL_STICKER_HASH_DATE_SIGNED)) {
      Pointer<Utf8> message = torx.getter_string(nullptr, n, i, -1, offsetof("message", "message"));
      int s = ui_sticker_set(message as Pointer<Uint8>);
      if (s < 0) {
        int y = 0;
        while (y < t_peer.stickers_requested[n].length && torx.memcmp(t_peer.stickers_requested[n][y] as Pointer<Void>, message as Pointer<Void>, CHECKSUM_BIN_LEN) != 0) {
          y++;
        }
        if (y == t_peer.stickers_requested[n].length) {
          t_peer.stickers_requested[n].add(message as Pointer<Uint8>);
          torx.message_send(n, ENUM_PROTOCOL_STICKER_REQUEST, message as Pointer<Void>, CHECKSUM_BIN_LEN);
        } else {
          // Already requested this sticker
          printf("Requested this sticker already. Not requesting again.");
          torx.torx_free_simple(message as Pointer<Void>); // We free it here, otherwise it gets freed after we remove it from t_peer.stickers_requested
          message = nullptr;
        }
      } else {
        torx.torx_free_simple(message as Pointer<Void>);
        message = nullptr;
      }
    } else if (message_len >= CHECKSUM_BIN_LEN && protocol == ENUM_PROTOCOL_STICKER_REQUEST && send_sticker_data) {
      Pointer<Utf8> message = torx.getter_string(nullptr, n, i, -1, offsetof("message", "message"));
      int s = ui_sticker_set(message as Pointer<Uint8>);
      if (s > -1) {
        int relevant_n = n; // TODO for groups, this should be group_n
        for (int cycle = 0; cycle < 2; cycle++) {
          int iter = 0;
          while (iter < stickers[s].peers.length && stickers[s].peers[iter] != relevant_n && stickers[s].peers[iter] > -1) {
            iter++;
          }
          if (relevant_n != stickers[s].peers[iter]) {
            //	printf("Checkpoint TRYING s=%d owner=%u\n",s,owner); // FINGERPRINTING
            int owner = torx.getter_uint8(relevant_n, INT_MIN, -1, -1, offsetof("peer", "owner"));
            if (owner == ENUM_OWNER_GROUP_PEER) {
              // if not on peer_n(pm), try group_n (public)
              int g = torx.set_g(n, nullptr);
              relevant_n = torx.getter_group_int(g, offsetof("group", "n"));
              continue;
              //  stream_cb_ui(n, p_iter, message, data_len); // recurse
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
          }
          break;
        }
      } else {
        error(0, "Peer requested sticker we do not have. Maybe we deleted it.");
      }
      torx.torx_free_simple(message as Pointer<Void>);
      message = nullptr;
    }

    int notifiable = protocol_int(p_iter, "notifiable");
    if (notifiable == 0) {
      return;
    }
    int nn = n;
    int owner = torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "owner"));
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
            title: getter_string(n, INT_MIN, -1, offsetof("peer", "peernick")),
            body: null_terminated_len != 0 ? getter_string(n, i, -1, offsetof("message", "message")) : protocol_string(p_iter, offsetof("protocols", "name")),
            payload: "$n $group_pm",
            fln: flutterLocalNotificationsPlugin);
        Vibration.vibrate(); // Vibrate regardless of mute setting, if current chat not open or application is not in the foreground
        FlutterRingtonePlayer().play(looping: false, fromAsset: "lib/other/beep.wav"); // Make sound if not muted
      }
      t_peer.unread[nn]++;
      if (owner == ENUM_OWNER_GROUP_CTRL) {
        totalUnreadGroup++;
      } else {
        totalUnreadPeer++;
      }
      if (launcherBadges) {
        AppBadgePlus.updateBadge(totalUnreadPeer + totalUnreadGroup + totalIncoming);
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
    int owner = torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "owner"));
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
        AppBadgePlus.updateBadge(totalUnreadPeer + totalUnreadGroup + totalIncoming);
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

void printf(String str) {
  if (kDebugMode) {
    print(str);
  }
}

void writeUnread() {
  if (log_unread) {
    for (int n = 0; torx.getter_byte(n, INT_MIN, -1, -1, offsetof("peer", "onion")) != 0; n++) {
      int owner = torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "owner")); // 0
      if (owner == ENUM_OWNER_CTRL || owner == ENUM_OWNER_GROUP_CTRL) {
        int peer_index = torx.getter_int(n, INT_MIN, -1, -1, offsetof("peer", "peer_index"));
        set_setting_string(0, peer_index, "unread", t_peer.unread[n].toString());
      }
    }
  }
}

void setBottomIndex() {
  bool set = false;
  for (int n = 0; torx.getter_byte(n, INT_MIN, -1, -1, offsetof("peer", "onion")) != 0; n++) {
    if (torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "owner")) == ENUM_OWNER_CTRL &&
        torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "status")) == ENUM_STATUS_PENDING) {
      bottom_index = 2; // default to view pending list
      set = true;
    }
  }
  if (set == false) {
    for (int n = 0; torx.getter_byte(n, INT_MIN, -1, -1, offsetof("peer", "onion")) != 0; n++) {
      if (torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "owner")) == ENUM_OWNER_CTRL &&
          torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "status")) == ENUM_STATUS_FRIEND) {
        bottom_index = 0; // default to view pending list
      }
    }
  }
}

void changeNick(int n, TextEditingController tec) {
  String peernick = getter_string(n, INT_MIN, -1, offsetof("peer", "peernick"));
  if (tec.text.isNotEmpty && tec.text != peernick) {
    Pointer<Utf8> new_nick = tec.text.toNativeUtf8(); // free'd by calloc.free
    torx.change_nick(n, new_nick);
    calloc.free(new_nick);
    new_nick = nullptr;
  }
}

bool write_test(String path) {
  // MUST BE ASYNC / FUTURE / AWAIT (probably due to 'try')
  try {
    final testFile = File('$path/jgIYZZHLdU9gCKud1VxptmJlH3zWd0bA'); // Random string must not clash with any file on user's device
    testFile.createSync(); // WARNING: MUST BE ASYNC OR THIS FUNCTION WILL FAILS (probably due to 'try')
    testFile.writeAsStringSync('test'); // WARNING: MUST BE ASYNC OR THIS FUNCTION WILL FAILS (probably due to 'try')
    testFile.deleteSync(); // WARNING: MUST BE ASYNC OR THIS FUNCTION WILL FAILS (probably due to 'try')
    return true;
  } catch (e) {
    error(0, "Directory is not writable. Choose a different directory.");
    return false;
  }
}

int handle_stuff(int n, int i) {
  int p_iter = torx.getter_int(n, i, -1, -1, offsetof("message", "p_iter"));
  int group_msg = protocol_int(p_iter, "group_msg");
  int nnn = n;
  int owner = torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "owner"));
  if (group_msg != 0 && owner == ENUM_OWNER_GROUP_PEER) {
    int g = torx.set_g(n, nullptr);
    nnn = torx.getter_group_int(g, offsetof("group", "n"));
  }
  return nnn;
}

String getter_group_id(int g) {
  Pointer<Uint8> id = torx.getter_group_id(g); // free'd by torx_free
  Pointer<Utf8> encoded = torx.b64_encode(id as Pointer<Void>, GROUP_ID_SIZE); // free'd by torx_free
  torx.torx_free_simple(id as Pointer<Void>);
  id = nullptr;
  String encoded_id = encoded.toDartString();
  torx.torx_free_simple(encoded as Pointer<Void>);
  encoded = nullptr;
  return encoded_id;
}

int ui_group_generate(int invite_required, String name) {
  Pointer<Utf8> name_p = name.toNativeUtf8(); // free'd by calloc.free
  int g = torx.group_generate(invite_required, name_p);
  calloc.free(name_p);
  name_p = nullptr;
  return g;
}

void ui_generate_onion(int owner, String peernick) {
  Pointer<Utf8> peernick_p = peernick.toNativeUtf8(); // free'd by calloc.free
  torx.generate_onion(owner, nullptr, peernick_p);
  calloc.free(peernick_p);
  peernick_p = nullptr;
}

int ui_add_peer(String name, String encoded_id) {
  int ret = -1;
  Pointer<Utf8> peernick = name.toNativeUtf8(); // free'd by calloc.free
  Pointer<Utf8> peeronion = encoded_id.toNativeUtf8(); // free'd by calloc.free
  if (torx.peer_save(peeronion, peernick) > -1) {
    ret = 0;
  }
  calloc.free(peeronion);
  peeronion = nullptr;
  calloc.free(peernick);
  peernick = nullptr;
  return ret;
}

int ui_group_join_public(String name, String encoded_id) {
  int g = -1;
  Pointer<Utf8> name_p = name.toNativeUtf8(); // free'd by calloc.free
  Pointer<Utf8> encoded_id_p = encoded_id.toNativeUtf8(); // free'd by calloc.free
  Pointer<Uint8> id = torx.torx_secure_malloc(GROUP_ID_SIZE) as Pointer<Uint8>; // free'd by torx_free
  int decoded_len = torx.b64_decode(id, GROUP_ID_SIZE, encoded_id_p);
//  printf("Checkpoint Decoded len: $decoded_len from $GROUP_ID_SIZE and $encoded_id");
  if (decoded_len == GROUP_ID_SIZE) {
    g = torx.group_join(-1, id, name_p, nullptr, nullptr);
  }
  torx.torx_free_simple(id as Pointer<Void>);
  id = nullptr;
  calloc.free(name_p);
  name_p = nullptr;
  calloc.free(encoded_id_p);
  encoded_id_p = nullptr;
  return g;
}

Color ui_statusColor(int n) {
  int sendfd_connected = torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "sendfd_connected"));
  int recvfd_connected = torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "recvfd_connected"));
  Color returnColor;
  if (torx.getter_uint8(n, INT_MIN, -1, -1, offsetof("peer", "status")) == ENUM_STATUS_BLOCKED) {
    returnColor = Colors.red;
  } else if (sendfd_connected > 0 && recvfd_connected > 0) {
    returnColor = Colors.green;
  } else if (sendfd_connected > 0 && recvfd_connected < 1) {
    returnColor = Colors.yellow;
  } else if (sendfd_connected < 1 && recvfd_connected > 0) {
    returnColor = Colors.orange;
  } else {
    returnColor = Colors.grey;
  }
  return returnColor;
}

scrollToBottom(ScrollController ctrler) {
  ctrler.jumpTo(ctrler.position.maxScrollExtent);
//  ctrler.animateTo(ctrler.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.ease);
}

void scrollIfBottom(ScrollController scrollController) {
  // This should be used sparingly.
  if (scrollController.hasClients && scrollController.positions.isNotEmpty && scrollController.position.pixels == scrollController.position.maxScrollExtent) {
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom(scrollController));
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const androidChannel = MethodChannel('com.torx.chat/android');
  Future<String> getNativeLibraryPath() async {
    return await androidChannel.invokeMethod('getNativeLibraryPath') as String;
  }

  Future<String> nativeLibraryPath() async {
    if (Platform.isAndroid) {
      return await getNativeLibraryPath();
    } else {
      return '';
    }
  }

  nativeLibraryDir = await nativeLibraryPath();
  applicationDocumentsDir = (await getApplicationDocumentsDirectory()).path; // getTemporaryDirectory getApplicationSupportDirectory getApplicationDocumentsDirectory
  temporaryDir = (await getTemporaryDirectory()).path;

  if (autoRunOnBoot) resumptionTasks(); // necessary to remove foreground service
  runApp(const TorX()); // UI Thread, which will be suspended while in background, unlike other methods called from main()

  launcherBadges = await AppBadgePlus.isSupported();
  error(0, "Checkpoint launcherBadges: $launcherBadges");
}
