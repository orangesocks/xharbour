#!/bin/sh
[ "$BASH" ] || exec bash `which $0` ${1+"$@"}
#
# $Id: make_xmingw.sh,v 1.2 2005/01/12 16:36:00 druzus Exp $
#
# This script simplifies cross-compiling xHarbour for Windows from Unix systems.
#
# Copyright 2003-2005 by Phil Krylov <phil a t newstar.rinet.ru>
#

UNAME=`uname`

export HB_ARCHITECTURE=w32
export HB_COMPILER=mingw32

export PREFIX=/usr/local/mingw32-xharbour
export C_USR="-DHOST_OS_UNIX_COMPATIBLE $C_USR"
export PRG_USR="-D__PLATFORM__Windows -undef:__PLATFORM__UNIX -undef:__PLATFORM__$UNAME $PRG_USR"

if [ -f /etc/debian-version ]; then
    MINGW_PREFIX=/usr
    TARGET=i586-mingw32msvc
    CCPREFIX="$TARGET-"
elif [ -f /etc/gentoo-release ]; then
    MINGW_PREFIX=/opt/xmingw
    TARGET=i386-mingw32msvc
    CCPREFIX="$TARGET-"
elif [ "$UNAME" = "FreeBSD" ]; then
    MINGW_PREFIX=/usr/local/mingw32
    TARGET="."
    CCPREFIX=""
elif find /usr/local/bin -name "i[3456]86-mingw*-gcc" -maxdepth 1 &>/dev/null; then
    MINGW_PREFIX=/usr/local
    TARGET=`find /usr/local/bin -name "i[3456]86-mingw*-gcc" -maxdepth 1|sed -e '1 !d' -e 's/.*\(i[3456]86-mingw[^-]*\).*/\1/g'`
    CCPREFIX="$TARGET-"
else
    echo "Can't determine the location for the MinGW32 cross-compiler."
    echo "Please add your platform to the $0 script."
    exit 1
fi
PATH="$MINGW_PREFIX/bin:$MINGW_PREFIX/$TARGET/bin:$PATH"

if which harbour &> /dev/null; then
    rm -f -r /tmp/harbour.exe
    ln -s `which harbour` /tmp/harbour.exe
    export HB_BIN_COMPILE=/tmp
else
    echo "You must have a working xHarbour executable for your platform on your PATH."
    exit 1
fi

export PATH CCPREFIX

. `dirname $0`/make_gnu.sh $*

