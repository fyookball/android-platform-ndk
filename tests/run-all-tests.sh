#!/bin/bash
#
# Copyright (C) 2013 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# 
# Copyright (c) 2013 Dmitry Moskalchuk <dm@crystax.net>.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
#    1. Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
# 
#    2. Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY Dmitry Moskalchuk ''AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Dmitry Moskalchuk OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# The views and conclusions contained in the software and documentation
# are those of the authors and should not be interpreted as representing
# official policies, either expressed or implied, of Dmitry Moskalchuk.
# 

#
# Assumptions:
#
#   1) Emulators for armeabi, armeabi-v7a, mips, x86 should be started
#      before script execution;
#   2) script must be run from $NDK/platform/ndk dir.
#

FULL=""

while [ -n "$1" ]; do
    opt="$1"
    optarg=`expr "x$opt" : 'x[^=]*=\(.*\)'`
    case "$opt" in
        --help|-h|-\?)
            OPTION_HELP=yes
            ;;
        --full)
            FULL="--full"
            ;;
        *)
            echo "Unrecognized option: " "$opt"
            exit 1
            ;;
    esac
    shift
done

if [ "$OPTION_HELP" = "yes" ] ; then
    echo "Usage: $0 [options]"
    echo ""
    echo "Valid options:"
    echo ""
    echo "    --help|-h|-?      Print this help"
    echo "    --full            Run long tests too"
    echo ""
    exit 1
fi



TESTS_BUILD_DIR=/tmp/ndk-$USER/tests

RESULTS_BASE_DIR=/var/tmp/ndk.tests.results/
#RESULTS_DIR=/var/tmp/ndk.tests.results/2013.01.22-21:12:40
RESULTS_DIR=/var/tmp/ndk.tests.results/`date +%Y.%m.%d-%H:%M:%S`
GCC_TOOLCHAINS="4.7 4.6 4.4.3"
CLANG_TOOLCHAINS="clang3.1 clang3.2"
ARCHS=""


# just exit on error
function error_exit ()
{
    echo Failed!
    exit 1
}

mkdir -p $RESULTS_BASE_DIR || error_exit
mkdir    $RESULTS_DIR      || error_exit

# Find all devices
DEVICE_armeabi=
DEVICE_armeabi_v7a=
DEVICE_mips=
DEVICE_x86=

ADB_CMD=`which adb`
if [ -z "$ADB_CMD" ] ; then
    echo "ERROR: adb not found"
    exit 1
fi

# Get list of online devices, turn ' ' in device into '.'
DEVICES=`$ADB_CMD devices | grep -v offline | awk 'NR>1 {gsub(/[ \t]+device$/,""); print;}' | sed '/^$/d' | tr ' ' '.'`
for DEVICE in $DEVICES; do
    # undo previous ' '-to-'.' translation
    DEVICE=$(echo $DEVICE | tr '.' ' ')
    # get arch
    ARCH=`$ADB_CMD -s "$DEVICE" shell getprop ro.product.cpu.abi | tr -dc '[:print:]'`
    case "$ARCH" in
        armeabi-v7a)
            DEVICE_armeabi_v7a=$DEVICE
            ;;
        armeabi)
            DEVICE_armeabi=$DEVICE
            ;;
        x86)
            DEVICE_x86=$DEVICE
            ;;
        mips)
            DEVICE_mips=$DEVICE
            ;;
        *)
            echo "ERROR: Unsupported architecture: $ARCH"
            exit 1
    esac
done

# check that all required devices are present
if [ -z "$DEVICE_armeabi" ] ; then
    echo "ERROR: not found armeabi device/emulator"
    exit 1
fi

if [ -z "$DEVICE_armeabi_v7a" ] ; then
    echo "ERROR: not found armeabi-v7a device/emulator"
    exit 1
fi

if [ -z "$DEVICE_x86" ] ; then
    echo "ERROR: not found x86 device/emulator"
    exit 1
fi

if [ -z "$DEVICE_mips" ] ; then
    echo "ERROR: not found mips device/emulator"
    exit 1
fi

EMULATORS="armeabi:$DEVICE_armeabi armeabi-v7a:$DEVICE_armeabi_v7a x86:$DEVICE_x86 mips:$DEVICE_mips"

for EMU in $EMULATORS
do
    ARCH=${EMU%:*}
    DEVICE=${EMU#*:}
    echo "Starting tests for $ARCH using device $DEVICE"
    # GCC toolchains
    for toolchain in $GCC_TOOLCHAINS
    do
        echo "Running tests for toolchain GCC-$toolchain"
        LOG_BASE=$ARCH-gcc-$toolchain
        LOG_FILE=$RESULTS_DIR/$LOG_BASE.txt
        ANDROID_SERIAL=$DEVICE ./tests/run-tests.sh $FULL --continue-on-build-fail --abi=$ARCH --toolchain-version=$toolchain > $LOG_FILE
        cp $TESTS_BUILD_DIR/build-tests.log $RESULTS_DIR/$LOG_BASE.build-tests.log
    done
    # Clang toolchains
    for toolchain in $CLANG_TOOLCHAINS
    do
        echo "Running tests for toolchain $toolchain"
        LOG_BASE=$ARCH-$toolchain
        LOG_FILE=$RESULTS_DIR/$LOG_BASE.txt
        ANDROID_SERIAL=$DEVICE ./tests/run-tests.sh $FULL --continue-on-build-fail --abi=$ARCH --toolchain-version=$toolchain > $LOG_FILE
        cp $TESTS_BUILD_DIR/build-tests.log $RESULTS_DIR/$LOG_BASE.build-tests.log
    done
done


echo Done.
exit 0