<img alt="Logo" width="200" height="200" src="https://raw.githubusercontent.com/TorX-Chat/torx-gtk4/main/other/scalable/apps/logo-torx-symbolic.svg" align="right" style="position: relative; top: 0; left: 0;">

### TorX Flutter Client (torx-flutter)
This page is primarily for developers and contributors.
<br>If you are simply looking to download and run TorX, go to [Download](https://torx.chat/#download)
<br>If you want to contribute, see [Contribute](https://torx.chat/#contribute) and our [TODO Lists](https://torx.chat/todo.html)

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
rm -rf build/ android/app/.cxx/Debug/ android/app/.cxx/RelWithDebInfo
rm android/app/src/main/jniLibs/*/*.so
flutter pub run flutter_launcher_icons
flutter run

```

###### Subsequent builds (takes 10-20 seconds, including fresh builds of libtorx)
`flutter run`

###### For building a release (Remember to increase the version in pubspec.yaml or F-Droid will ignore the update.)
`flutter build apk`

#### License:
To discourage pre-release distribution of unsafe builds, source code is currently licensed as follows: Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)

#### Anti-Abandonware Clause:
While this clause remains visible in this file, if the [libtorx](https://github.com/TorX-Chat/libtorx) repository becomes dormant for >180 days, without having been moved to a different public repository (such as Gitlab, etc) and subsequently maintained from there, all public repositories under [TorX-Chat](https://github.com/TorX-Chat/) shall be considered released under the terms of GNU General Public License 3.0, retroactive to the time of the last commit in [libtorx](https://github.com/TorX-Chat/libtorx).

#### Contribution Agreement:
All ideas, suggestions, issues, pull requests, contributions of any kind, etc, are gifted to the original TorX developer without condition nor consideration, for the purpose of improving the software, for the benefit of all users, current and future.

#### Screenshots:
<a href="https://torx-chat.github.io/images/mobile_peerlist.png"><img src="https://torx-chat.github.io/images/mobile_peerlist.png" alt="Screenshot" style="max-height:400px;"></a>
<a href="https://torx-chat.github.io/images/mobile_grandchild.png"><img src="https://torx-chat.github.io/images/mobile_grandchild.png" alt="Screenshot" style="max-height:400px;"></a>
<a href="https://torx-chat.github.io/images/mobile_add_group.png"><img src="https://torx-chat.github.io/images/mobile_add_group.png" alt="Screenshot" style="max-height:400px;"></a>
<a href="https://torx-chat.github.io/images/mobile_group.png"><img src="https://torx-chat.github.io/images/mobile_group.png" alt="Screenshot" style="max-height:400px;"></a>
