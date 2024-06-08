<img alt="Logo" width="200" height="200" src="https://raw.githubusercontent.com/TorX-Chat/torx-gtk4/main/other/scalable/apps/logo-torx-symbolic.svg" align="right" style="position: relative; top: 0; left: 0;">

### TorX Flutter Client (torx-flutter)
This page is primarily for developers and contributors.
<br>If you are simply looking to download and run TorX, go to [Download](https://torx.chat/#download)
<br>If you want to contribute, see [Contribute](https://torx.chat/#contribute) and our [TODO Lists](https://torx.chat/todo.html)
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
cd torx-flutter
```

###### Step 2: First build / Build from scratch (takes several minutes) (WARNING: will delete libtor.so, libsnowflake.so, etc)
```
rm -rf build/ android/app/.cxx/Debug/
rm android/app/src/main/jniLibs/*/*.so
flutter pub run flutter_launcher_icons
TORX_TAG=main BUILD_BINARIES=1 flutter run

```

###### Subsequent builds (takes 10-20 seconds, including fresh builds of libtorx)
`TORX_TAG=main flutter run`

###### For building a release (Remember to increase the version in pubspec.yaml or F-Droid will ignore the update.)
`TORX_TAG=main flutter build apk`

#### License:
To discourage pre-release distribution of unsafe builds, source code is currently licensed as follows: Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)

#### Contribution Agreement:
All ideas, suggestions, issues, pull requests, contributions of any kind, etc, are gifted to the original TorX developer without condition nor consideration, for the purpose of improving the software, for the benefit of all users, current and future.

#### Screenshots:
<a href="https://torx-chat.github.io/images/mobile_peerlist.png"><img src="https://torx-chat.github.io/images/mobile_peerlist.png" alt="Screenshot" style="max-height:400px;"></a>
<a href="https://torx-chat.github.io/images/mobile_grandchild.png"><img src="https://torx-chat.github.io/images/mobile_grandchild.png" alt="Screenshot" style="max-height:400px;"></a>
<a href="https://torx-chat.github.io/images/mobile_add_group.png"><img src="https://torx-chat.github.io/images/mobile_add_group.png" alt="Screenshot" style="max-height:400px;"></a>
<a href="https://torx-chat.github.io/images/mobile_group.png"><img src="https://torx-chat.github.io/images/mobile_group.png" alt="Screenshot" style="max-height:400px;"></a>
