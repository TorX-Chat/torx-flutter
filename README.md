<img alt="Logo" width="256" height="256" src="https://raw.githubusercontent.com/TorX-Chat/torx-gtk4/main/other/scalable/apps/logo-torx-symbolic.svg" align="right" style="position: relative; top: 0; left: 0;">

### TorX Flutter Client (torx-flutter)
This page is for developers and contributors. If you are simply looking to download and run TorX, go to [TorX.Chat](https://torx.chat/#download)
<br>
<br>Note: There are toggles for BUILD_ALWAYS / BUILD_BINARIES and related notes in android/app/CMakeLists.txt
<br>You MUST ensure BUILD_BINARIES is set to 1 for the first build, and then you may desire to change it to 0 for subsequent builds.

#### Build Instructions:

###### Step 1: Create a new project (NOTE: This may be used to get the android/build.gradle file, which may be necessary to build and run if we haven't run in a while and we're getting 404 errors on .pom files)
```
flutter create --org com.torx --project-name chat --description "A chat software" --platforms android bare
cd bare && rm -r test && flutter pub global activate rename && flutter pub global run rename setAppName --targets android --value "TorX" && cd ..
git clone https://github.com/TorX-Chat/torx-flutter
cp -Rn bare/* torx-flutter
```

###### Step 2: First build / Build from scratch (takes several minutes) (WARNING: will delete libtor.so, libsnowflake.so, etc, which need to be rebuilt by modifying CMakeLists.txt -- the BUILD_BINARIES flag)
`cd torx-flutter && rm -rf build/ android/app/.cxx/Debug/ ; rm android/app/src/main/jniLibs/*/*.so ; flutter pub run flutter_launcher_icons && flutter run`

###### Subsequent builds (takes 10-20 seconds)
`cd torx-flutter && flutter run`

###### For building a release (Remember to increase the version in pubspec.yaml or F-Droid will ignore the update.)
`flutter build apk`

#### Contribution Agreement:
All ideas, suggestions, issues, pull requests, etc, are gifted to the primary developer for the purpose of improving the software, for the benefit of all users. Ownership of the contribution is not maintained by the contributor.

#### Screenshots:
<a href="https://torx-chat.github.io/images/mobile_peerlist.png"><img src="https://torx-chat.github.io/images/mobile_peerlist.png" alt="Screenshot" style="max-height:400px;"></a>
<a href="https://torx-chat.github.io/images/mobile_grandchild.png"><img src="https://torx-chat.github.io/images/mobile_grandchild.png" alt="Screenshot" style="max-height:400px;"></a>
<a href="https://torx-chat.github.io/images/mobile_add_group.png"><img src="https://torx-chat.github.io/images/mobile_add_group.png" alt="Screenshot" style="max-height:400px;"></a>
<a href="https://torx-chat.github.io/images/mobile_group.png"><img src="https://torx-chat.github.io/images/mobile_group.png" alt="Screenshot" style="max-height:400px;"></a>

#### Legacy TODO List (needs review / cleanup)
###### Tasks common with GTK
2024/05/03 If someone is fast on the censored region toggle while waiting for login, it will save the setting but not take effect until next restart
<br>2024/04/26 We need to do sanity checks on sticker/Image data or people can be crashed with junk stickers/images. (Verified occured once in flutter with a sticker sized 0 bytes)
<br>2023/??/?? Multi-Select -- Tables should allow multiple selections for deletion. It should hide Show QR and Copy (umm, ok maybe not) showing only Delete (or Accept + Reject)

###### Tasks unique to Flutter
2024/05/12 (Post release) calling peer_accept() while actively modifying peernick results in modifications being lost
<br>2024/05/10 (Post release) autoRunOnBoot: true (foreground task) + fix BootBroadcastReceiver.kt, then have a toggle in settings page for both.
<br>2024/05/05 Consider requesting battery optimization
<br>2024/05/05 AnimatedBuilder should replace many of our setState calls, for efficiency. Especially: activity button, and send/sticker/attach builds
<br>2024/05/03 Should use gallery with photo_view to allow swipping back/forward to see other images in PhotoView.
<br>2024/05/10 Search messages, then scroll to the selected one
<br>2023/??/?? can't change app name on the fly, but can change icon. Put alternate icon option (calculator, or something people never use). "The calculator theoretically opens chat but it doesn't work anymore. They said it requires entering a specific calculation," Micay said. 
<br>2023/??/?? add save_dir_always_ask (like in GTK) and put a toggle in settings
<br>2023/??/?? We lose TorX log and Tor log contents every time we .detach, so we might consider to store it in a library defined C pointer so it stays in RAM. We would just need to create the pointer in lib and the remaining work is done in flutter.
<br>2023/??/?? Message box height: 400 is too tall. Figure out a way to avoid hard coding it.
<br>2023/??/?? can we onload and offload message history? Like, keep last 50 messages of every peer, but dump the rest to save RAM?
<br>2023/??/?? Prevent un-encrypted backups of android data? Most chat apps do this but i'm on the fence. GrapheneOS project has some info that suggests we can block only unencrypted backups.
<br>2023/??/?? Comment out any unused color and language strings. Ensure that we don't have any strings not in our languages file.
<br>2023/??/?? *** Consider having a popup when adding something to clipboard. The clipboard would have a "Clear clipboard" and "Exit" option, along with a warning about other applications being able to steal clipboard contents
<br>2023/??/?? MaterialBanner() anywhere it exists needs to be checked for functionality. It works at least on RouteTorrc but elsewhere may be non-functional.
<br>2023/??/?? Experiment in Noti with grouping notifications per-user. If that fails, experiment with summaries if there are messages from multiple users? (no? summaries are dumb but per user grouping would be cool)
<br>2023/??/?? "Whenever items list is updated, ListView shall be updated automatically." https://googleflutter.com/flutter-add-item-to-listview-dynamically/ https://stackoverflow.com/questions/51343567/append-items-dynamically-to-listview
<br>2023/??/?? delete getTemporaryDirectory().path/qr.png on program startup and shutdown. Zero and delete might be best.
