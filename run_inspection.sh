#! /bin/bash

INCLUDES=''
INCLUDES="$INCLUDES -x objective-c -arch x86_64"
INCLUDES="$INCLUDES -isysroot /Developer/SDKs/MacOSX10.7.sdk"
INCLUDES="$INCLUDES -F framework"
INCLUDES="$INCLUDES -F framework/CocoaLibSpotify.framework/Versions/A/Frameworks"
INCLUDES="$INCLUDES -I /usr/lib/clang/3.0/include"

for folder in `find lib -type d`
do
  INCLUDES="$INCLUDES -I $folder"
done

INCLUDES="$INCLUDES -include repeatify/repeatify-Prefix.pch"

mo_path=$1

for file in `find repeatify -name "*.m"`
do
  #echo "$mo_path $INCLUDES $file | grep '^repeatify'"
  echo "$mo_path $file"
  $mo_path $INCLUDES $file | grep '^repeatify'
done