#!/bin/bash
# Compiles zlib.
# Compiles openssl.
# Compiles and install qt.

# download files
download=0

# Clean directories that are going to be used.
clean=0

# Number of threads to compile tools.
nbthreads=4

# Installation directory for Qt
install_dir=~/qt/4.8.7/
make -p $install_dir
qt_install_dir_options="-prefix $install_dir"

# OSX architectures
osx_architecture=x86_64

# OSX deployment target
osx_deployment_target=10.12

# OSX sysroot
osx_sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.12.sdk


# config cmake path
if [[ -z "$cmake" ]]
then
  cmake=`which cmake`
  if [ $? -ne 0 ]
  then
    echo "cmake not found"
    exit 1
  fi
  echo "Using cmake found here: $cmake"
fi


# If "clean", remove all directories and temporary files
# that are downloaded and used in this script.
if [ $clean -eq 1 ]
then
  echo "Remove previous files and directories"
  rm -rf zlib*
  rm -f openssl-1.0.1h.tar.gz
  rm -rf openssl-1.0.1h
  rm -f qt-everywhere-opensource-src-4.8.7.tar.gz
  rm -rf qt-everywhere-opensource-src-4.8.7
  rm -rf qt-everywhere-opensource-build-4.8.7
fi


# Download archives (Qt, and openssl
if [ $download -eq 1 ]
then
  echo "Download openssl"
  curl -OL https://packages.kitware.com/download/item/6173/openssl-1.0.1h.tar.gz
  echo "Download Qt"
  curl -OL https://mirrors.tuna.tsinghua.edu.cn/qt/official_releases/qt/4.8/4.8.7/qt-everywhere-opensource-src-4.8.7.tar.gz
fi

md5_openssl=`md5 ./openssl-1.0.1h.tar.gz | awk '{ print $4 }'`
md5_qt=`md5 ./qt-everywhere-opensource-src-4.8.7.tar.gz | awk '{ print $4 }'`

if [ "$md5_openssl" != "8d6d684a9430d5cc98a62a5d8fbda8cf" ]
then
  echo "MD5 mismatch. Problem downloading OpenSSL"
  exit 1
fi
if [ "$md5_qt" != "d990ee66bf7ab0c785589776f35ba6ad" ]
then
  echo "MD5 mismatch. Problem downloading Qt"
  exit 1
fi


zlib_macos_options="-DCMAKE_OSX_ARCHITECTURES=$osx_architecture
                -DCMAKE_OSX_SYSROOT=$osx_sysroot
                -DCMAKE_OSX_DEPLOYMENT_TARGET=$osx_deployment_target"

export KERNEL_BITS=64
qt_macos_options="-arch $osx_architecture -sdk $osx_sysroot"


 

# Build zlib
echo "Build zlib"

cwd=$(pwd)

mkdir zlib-install
mkdir zlib-build
git clone git://github.com/commontk/zlib.git
cd zlib-build
$cmake -DCMAKE_BUILD_TYPE:STRING=Release             \
       -DZLIB_MANGLE_PREFIX:STRING=slicer_zlib_      \
       -DCMAKE_INSTALL_PREFIX:PATH=$cwd/zlib-install \
       $zlib_macos_options                           \
       ../zlib
make -j $nbthreads
make install
cd ..
cp zlib-install/lib/libzlib.a zlib-install/lib/libz.a

# Build OpenSSL
echo "Build OpenSSL"

cwd=$(pwd)

tar -xzvf openssl-1.0.1h.tar.gz
cd openssl-1.0.1h/
./config zlib -I$cwd/zlib-install/include -L$cwd/zlib-install/lib shared
make -j $nbthreads build_libs
# If MacOS, install openssl libraries

install_name_tool -id $cwd/openssl-1.0.1h/libcrypto.dylib $cwd/openssl-1.0.1h/libcrypto.dylib
install_name_tool                                                                            \
        -change /usr/local/ssl/lib/libcrypto.1.0.0.dylib $cwd/openssl-1.0.1h/libcrypto.dylib \
        -id $cwd/openssl-1.0.1h/libssl.dylib $cwd/openssl-1.0.1h/libssl.dylib
cd ..

# Build Qt
echo "Build Qt"

cwd=$(pwd)

tar -xzvf qt-everywhere-opensource-src-4.8.7.tar.gz
cd qt-everywhere-opensource-src-4.8.7

# If MacOS, patch linked from thread: https://github.com/Homebrew/legacy-homebrew/issues/40585
curl https://gist.githubusercontent.com/ejtttje/7163a9ced64f12ae9444/raw | patch -p1

./configure $qt_install_dir_options                           \
  -release -opensource -confirm-license -no-qt3support -no-phonon \
  -webkit -nomake examples -nomake demos                      \
  -openssl -I $cwd/openssl-1.0.1h/include                     \
  ${qt_macos_options}                                         \
  -L $cwd/openssl-1.0.1h
make -j $nbthreads
make install
