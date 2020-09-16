#!/usr/bin/env bash
set -u
set -eo pipefail

create=
start=
while getopts cs args
do
    case $args in
        c)      create=1;;
        s)      start=1;;
    esac
done

# Disabling Auth
touch ~/.emulator_console_auth_token

# Create Emulator flutter_emulator
if [ ! -z "$create" ]; then
    echo "::info:: Creating Emulator"
    avdmanager create avd -f -n flutter_emulator -k "system-images;android-29;google_apis;x86_64" -d 21
    cp -f config.ini ~/.android/avd/flutter_emulator.avd/
    echo "::info:: Emulator successfully created"
fi

if [ ! -z "$start" ]; then
    # Start Emulator
    echo "::info:: Starting Emulator"
    nohup nohup emulator -avd flutter_emulator -no-audio -no-window -no-boot-anim -no-accel 0<&- &>/dev/null &

    # Wait for emulator
    echo "::info:: Waiting for Emulator boot complete"
    while [ "`adb wait-for-device shell getprop sys.boot_completed | tr -d '\r' `" != "1" ];
    do
        sleep 2
    done
    
    echo "::info:: Emulator successfully started"
fi