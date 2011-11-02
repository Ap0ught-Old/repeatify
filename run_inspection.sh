#! /bin/bash

LANGUAGE=objective-c
ARCH=x86_64
SYSROOT=/Developer/SDKs/MacOSX10.7.sdk
CLANG_INCLUDE=/usr/lib/clang/3.0/include
PCH_PATH=repeatify/repeatify-Prefix.pch

INCLUDES=''
for folder in `find lib -type d`
do
  INCLUDES="$INCLUDES -I $folder"
done
INCLUDES="$INCLUDES -F framework"
INCLUDES="$INCLUDES -F framework/CocoaLibSpotify.framework/Versions/A/Frameworks"

FILES=''
for file in `find repeatify -name "*.m"`
do
  FILES="$FILES $file"
done

oclint -x $LANGUAGE -arch $ARCH -isysroot=$SYSROOT -I $CLANG_INCLUDE $INCLUDES -include $PCH_PATH $FILES
