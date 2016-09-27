#!/bin/bash


# Compiles zlib.
# Compiles openssl.
# Compiles and install qt.

# download files
download=1

# Clean directories that are going to be used.
clean=0

# Number of threads to compile tools.
nbthreads=8

# Installation directory for Qt
install_dir=~/qt/4.8.7/
make -p $install_dir
qt_install_dir_options="-prefix $install_dir"

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


# If cmake path was not given, verify that it is available on the system
# CMake is required to configure zlib
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

# Download archives (Qt, and openssl
if [ $download -eq 1 ]
then
  echo "Download openssl"
  curl -OL https://packages.kitware.com/download/item/6173/openssl-1.0.1h.tar.gz
  echo "Download Qt"
  curl -OL https://mirrors.tuna.tsinghua.edu.cn/qt/official_releases/qt/4.8/4.8.7/qt-everywhere-opensource-src-4.8.7.tar.gz
fi

md5_openssl=`md5sum ./openssl-1.0.1h.tar.gz | awk '{ print $1 }'`
md5_qt=`md5sum ./qt-everywhere-opensource-src-4.8.7.tar.gz | awk '{ print $1 }'`

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
cd ..

# Build Qt
echo "Build Qt"

cwd=$(pwd)

tar -xzvf qt-everywhere-opensource-src-4.8.7.tar.gz
cd qt-everywhere-opensource-src-4.8.7

./configure $qt_install_dir_options                           \
  -release -opensource -confirm-license -no-qt3support -no-phonon \
  -webkit -nomake examples -nomake demos                      \
  -openssl -I $cwd/openssl-1.0.1h/include                     \
  -L $cwd/openssl-1.0.1h
make -j $nbthreads
make install
