cmake_minimum_required(VERSION 3.14)
# FOSS android_sdk (untested) https://wiki.debian.org/AndroidTools
# XXX building for ios / android https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html

set(CMAKE_SYSTEM_NAME Android) # Must be before project
set(CMAKE_SYSTEM_VERSION 21) # TODO NOT WORKING in our dependancy builds. Defaulting to 1. use __ANDROID_MIN_SDK_VERSION__ ?
set(CMAKE_TLS_VERIFY TRUE)

project(fake LANGUAGES C) # the output of this is fake/junk

include(ExternalProject)
## XXX NOTICE: rm -rf build/ android/app/.cxx/Debug/* android/app/.cxx/RelWithDebInfo/* # can be safely called after BUILD_BINARIES=1 is run once. This will allow faster rebuilds and save extensive diskspace. XXX ##

set(CMAKE_ANDROID_NDK $ENV{ANDROID_NDK_HOME})
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_ANDROID_NDK}/build/cmake/android.toolchain.cmake)

# ANDROID_SYSROOT TODO set
# ANDROID_TOOLCHAIN TODO set
# ??? CMAKE_PREFIX_PATH ==

#set($ENV{TORX_TAG} "dev")			### XXX XXX XXX
#set($ENV{LAN_REPO} "http://10.8.88.1/") 	### XXX XXX XXX
#set($ENV{BUILD_BINARIES} 1)

## XXX -D BUILD_BINARIES=? (1) Determines dependencies should be re-built (tor , obfs4proxy, snowflake ), or just flutter UI + torx + deps (0), which requires JNILIBS folder populated already XXX ##
if($ENV{TORX_TAG})
	set(TAG_REPO "$ENV{TORX_TAG}")
else()
	set(TAG_REPO "main")
endif()
if($ENV{LAN_REPO})
	message(STATUS "Using LAN repository: $ENV{LAN_REPO}")
	set(REPO_TOR "$ENV{LAN_REPO}/tor.git")
	set(REPO_OBFS "$ENV{LAN_REPO}/obfs4.git")
	set(REPO_SNOWFLAKE "$ENV{LAN_REPO}/snowflake.git")
	set(REPO_TORX "$ENV{LAN_REPO}/libtorx.git")
else()
	message(STATUS "Using default remote repositories instead of LAN.")
	set(REPO_TOR "https://gitlab.torproject.org/tpo/core/tor.git") # http://xtlfhaspqtkeeqxk6umggfbr3gyfznvf4jhrge2fujz53433i2fcs3id.onion/tor.git
	set(REPO_OBFS "https://gitlab.com/Yawning/obfs4/")
	set(REPO_SNOWFLAKE "https://github.com/keroserene/snowflake/")
	set(REPO_TORX "https://github.com/TorX-Chat/libtorx/")
endif()

set(JNILIBS_DIR ../../../../../../../../../android/app/src/main/jniLibs/${ANDROID_ABI}/)

set(ANDROID_VERSION ${CMAKE_SYSTEM_VERSION}) ## find a way to set this properly from env variables, or ANDROID_PLATFORM (is an int), or ANDROID_API_LEVEL (i think also int?? not sure tho)
set(ANDROID_PLATFORM ${ANDROID_VERSION})
if("${ANDROID_ABI}" STREQUAL "arm64-v8a")
	set(TOR_PLATFORM aarch64-linux-android )
	set(GO_ARCH arm64) # see list 'go tool dist list'
	set(BINARY_PREFIX aarch64)
	set(ANDROID_VERSION_STR ${ANDROID_VERSION})
elseif("${ANDROID_ABI}" STREQUAL "armeabi-v7a")
	set(TOR_PLATFORM arm-linux-androideabi )
	set(GO_ARCH arm)
	set(BINARY_PREFIX armv7a)
	set(ANDROID_VERSION_STR eabi${ANDROID_VERSION})
elseif("${ANDROID_ABI}" STREQUAL "x86")
	set(TOR_PLATFORM i686-linux-android )
	set(GO_ARCH 386)
	set(BINARY_PREFIX i686)
	set(ANDROID_VERSION_STR ${ANDROID_VERSION})
elseif("${ANDROID_ABI}" STREQUAL "x86_64")
	set(TOR_PLATFORM x86_64-linux-android )
	set(GO_ARCH amd64)
	set(BINARY_PREFIX x86_64)
	set(ANDROID_VERSION_STR ${ANDROID_VERSION})
else()
	message("CHECKPOINT: Failed to match any known android arch: ${ANDROID_ABI}")
endif()
set(BINARY_PATH ${CMAKE_ANDROID_NDK}toolchains/llvm/prebuilt/linux-x86_64/bin/)
set(CLANG_BINARY ${BINARY_PREFIX}-linux-android${ANDROID_VERSION_STR}-clang)
set(CLANGPP_BINARY ${BINARY_PREFIX}-linux-android${ANDROID_VERSION_STR}-clang++)
set(CLANG_BINARY_PATH ${BINARY_PATH}${CLANG_BINARY})
set(CLANGPP_BINARY_PATH ${BINARY_PATH}${CLANGPP_BINARY})
set(CUSTOM_ARGS_FLUTTER -DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME} -DCMAKE_SYSTEM_VERSION=${CMAKE_SYSTEM_VERSION} -DCLANG_BINARY=${CLANG_BINARY} -DCLANGPP_BINARY=${CLANGPP_BINARY} -DCLANG_BINARY_PATH=${CLANG_BINARY_PATH} -DCLANGPP_BINARY_PATH=${CLANGPP_BINARY_PATH} -DANDROID_ABI=${ANDROID_ABI} -DANDROID_PLATFORM=${ANDROID_PLATFORM} -DCMAKE_ANDROID_ARCH_ABI=${ANDROID_ABI} -DCMAKE_ANDROID_NDK=${CMAKE_ANDROID_NDK} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})
set(JNILIBS_LIST _deps/event-build/lib/libevent_pthreads-2.2.so _deps/event-build/lib/libevent_core-2.2.so sodium-download-prefix/src/sodium-download/src/libsodium/.libs/libsodium.so _deps/png-build/libpng16.so sqlcipher-download-prefix/src/sqlcipher-download/.libs/libsqlcipher.so) # REMOVED: openssl-download-prefix/src/openssl-download/libcrypto_1_1.so openssl-download-prefix/src/openssl-download/libssl_1_1.so
################################################################################################################################################################
################################################################################################################################################################
################################################################################################################################################################
## XXX XXX TODO XXX XXX NOTICE: Ensure that NDK tools are in (prefixing might be best?) PATH otherwise OpenSSL build FAILS for Android	 XXX XXX TODO XXX XXX ##
################################################################################################################################################################
# if necessary to use cc method to build openssl (currently only works for stat libs), see https://github.com/openssl/openssl/issues/19857 for variables to set
################################################################################################################################################################
################################################################################################################################################################
add_executable( # Necessary to have a library or exec otherwise android sdk ignores this whole file. Will not make it to the APK because executables are ignored by SDK.
	${PROJECT_NAME}
	fake.c
)
if($ENV{BUILD_BINARIES})
	ExternalProject_Add(
		tor
		GIT_REPOSITORY ${REPO_TOR}
		GIT_TAG main # tor-0.4.8.11 # release-0.4.8 # main # NOTE: tor may recommend using a release. should talk to them.
		BUILD_IN_SOURCE 1
		UPDATE_COMMAND "" # XXX taken out of ./configure XXX #
		## XXX NOTE: based on testing, it seems like libtor.so has to be statically linked to everything because as a binary it does not look in the JNILIBS folder and fails if it cannot find its depends on android itself ##
		CONFIGURE_COMMAND cp -r ../../../torx-prefix/src/torx-build/_deps/event-src/include/ ../../../torx-prefix/src/torx-build/_deps/event-build && export CC=${CLANG_BINARY_PATH} && export CXX=${CLANGPP_BINARY_PATH} && export PATH=${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/:$ENV{PATH} && ./autogen.sh -v && ./configure --host=${TOR_PLATFORM} --enable-systemd=no --disable-system-torrc --disable-tool-name-check --enable-pic --disable-module-dirauth --enable-android --disable-unittests --disable-manpage --disable-html-manual --disable-module-relay --disable-asciidoc --disable-seccomp --disable-libscrypt --disable-lzma --disable-zstd --with-zlib-dir=../../../torx-prefix/src/torx-build/zlib-download-prefix/src/zlib-download/ --with-libevent-dir=../../../torx-prefix/src/torx-build/_deps/event-build --with-openssl-dir=../../../torx-prefix/src/torx-build/openssl-download-prefix/src/openssl-download/ --enable-static-zlib --enable-static-openssl --enable-static-libevent # TODO have put zlib as static because we currently fail to remove soname (and it is trivially small anyway), libevent is static because we suck at linking libevent-2.2.so, openssl is static only because the other two are XXX NOTE: we added --disable-system-torrc. This may or may not work with what we expect.
		BUILD_COMMAND make -j8
		INSTALL_COMMAND mkdir -p ${JNILIBS_DIR} && cp src/app/tor ${JNILIBS_DIR}/libtor.so
		BUILD_BYPRODUCTS src/app/tor
	)
	ExternalProject_Add(
		obfs4proxy
		GIT_REPOSITORY ${REPO_OBFS}
		BUILD_IN_SOURCE 1
		CONFIGURE_COMMAND ""
		BUILD_COMMAND CGO_ENABLED=1 CC=${CLANG_BINARY_PATH} CXX=${CLANGPP_BINARY_PATH} GOOS=android GOARCH=${GO_ARCH} go build -v -o obfs4proxy/obfs4proxy.so ./obfs4proxy
		INSTALL_COMMAND mkdir -p ${JNILIBS_DIR} && cp obfs4proxy/obfs4proxy.so ${JNILIBS_DIR}
		BUILD_BYPRODUCTS obfs4proxy/obfs4proxy.so
	)
	## CFLAGS=-I${CMAKE_ANDROID_NDK}toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include CXXFLAGS=-I${CMAKE_ANDROID_NDK}toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include
	##target_include_directories(obfs4proxy PUBLIC ${CMAKE_ANDROID_NDK}toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include)
	##target_link_directories(obfs4proxy PUBLIC ${CMAKE_ANDROID_NDK}toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib)
	ExternalProject_Add(
		snowflake
		GIT_REPOSITORY ${REPO_SNOWFLAKE}
		BUILD_IN_SOURCE 1
		CONFIGURE_COMMAND ""
		BUILD_COMMAND CGO_ENABLED=1 CC=${CLANG_BINARY_PATH} CXX=${CLANGPP_BINARY_PATH} GOOS=android GOARCH=${GO_ARCH} go build -v -o client/snowflake.so ./client
		INSTALL_COMMAND mkdir -p ${JNILIBS_DIR} && cp client/snowflake.so ${JNILIBS_DIR}
		BUILD_BYPRODUCTS client/snowflake.so
	)
	ExternalProject_Add(
		torx
	#	BUILD_ALWAYS TRUE # BUILD_BYPRODUCTS
		GIT_REPOSITORY ${REPO_TORX} ## XXX temp removed: -D ANDROID=${ANDROID_ABI} -D ANDROID_PLATFORM=${ANDROID_PLATFORM}
		GIT_TAG ${TAG_REPO}
	#	CMAKE_PLATFORM_NO_VERSIONED_SONAME TRUE
		CMAKE_ARGS ${CMAKE_ARGS} -D BUILD_TORX_DEPS=1 -D BUILD_SHARED_LIBS=1 -D LAN_REPO=$ENV{LAN_REPO} ${CUSTOM_ARGS_FLUTTER} # -D CMAKE_SYSROOT=$ENV{ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/
		INSTALL_COMMAND mkdir -p ${JNILIBS_DIR} && cp -t ${JNILIBS_DIR} libtorx.so ${JNILIBS_LIST}
	) # TODO get zlib, currently not able to remove sonames.
	# NOTE: regarding libpng, the copy is a response to a bug they introduced where they dropped the prefix. Introduced in one of the first two commits of feb 2023
	add_dependencies(tor torx) # because openssl libevent and zlib come from it
	add_dependencies(
		${PROJECT_NAME}
		torx
		obfs4proxy
		snowflake
		tor
	)
else()
	ExternalProject_Add(
		torx
	#	BUILD_ALWAYS TRUE
		GIT_REPOSITORY ${REPO_TORX} ## XXX temp removed: -D ANDROID=${ANDROID_ABI} -D ANDROID_PLATFORM=${ANDROID_PLATFORM}
		GIT_TAG ${TAG_REPO}
	#	CMAKE_PLATFORM_NO_VERSIONED_SONAME TRUE
		CMAKE_ARGS ${CMAKE_ARGS} -D BUILD_TORX_DEPS=0 -D BUILD_SHARED_LIBS=1 -D LAN_REPO=$ENV{LAN_REPO} ${CUSTOM_ARGS_FLUTTER} # -D CMAKE_SYSROOT=$ENV{ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/
		INSTALL_COMMAND mkdir -p ${JNILIBS_DIR} && cp -t ${JNILIBS_DIR} libtorx.so
	)
	add_dependencies(
		${PROJECT_NAME}
		torx
	)
endif()
