# Flutter (https://flutter.dev) Development Environment for Linux
# ===============================================================
#
# This environment passes all Linux Flutter Doctor checks and is sufficient
# for building Android applications and running Flutter tests.
#
# To build iOS applications, a Mac development environment is necessary.

# Note: updating past stretch (Debian 9) will bump Java past version 8,
# which will break the Android SDK.

# Based on Flutter Repo CI (https://github.com/flutter/flutter/blob/master/dev/ci/docker_linux/Dockerfile)

FROM ubuntu:latest

LABEL maintainer="Avenuesec"

RUN apt-get update -y
RUN apt-get upgrade -y

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo

# Install basics
RUN apt-get install -y --no-install-recommends \
  git \
  wget \
  tree \
  curl \
  zip \
  unzip \
  openjdk-8-jdk \
  apt-transport-https \
  ca-certificates \
  gnupg \
  xz-utils \
  libglu1-mesa 

# Install the Command Line Tools.
ENV ANDROID_CMD_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-6609375_latest.zip"

ENV ANDROID_SDK_ROOT="/opt/android_sdk"
RUN mkdir -p "${ANDROID_SDK_ROOT}"

ENV ANDROID_CMD_TOOLS="${ANDROID_SDK_ROOT}/cmdline-tools"
RUN mkdir -p "${ANDROID_CMD_TOOLS}"

ARG ANDROID_SDK_VERSION="30.0.2"

ENV ANDROID_CMD_TOOLS_ARCHIVE="${ANDROID_CMD_TOOLS}/archive"
RUN wget --progress=dot:giga "${ANDROID_CMD_TOOLS_URL}" -O "${ANDROID_CMD_TOOLS_ARCHIVE}"
RUN unzip -q -d "${ANDROID_CMD_TOOLS}" "${ANDROID_CMD_TOOLS_ARCHIVE}"

# Add Android to path
ENV PATH="${ANDROID_SDK_ROOT}/tools:${PATH}"
ENV PATH="${ANDROID_SDK_ROOT}/tools/bin:${PATH}"
ENV PATH="${ANDROID_SDK_ROOT}/platform-tools:${PATH}"
ENV PATH="${ANDROID_SDK_ROOT}/build-tools/${ANDROID_SDK_VERSION}:${PATH}"
ENV PATH="${ANDROID_SDK_ROOT}/emulator:${PATH}"

# Silence warning.
RUN mkdir -p ~/.android
RUN touch ~/.android/repositories.cfg

# Suppressing output of sdkmanager to keep log size down
# (it prints install progress WAY too often).
RUN yes "y" | "${ANDROID_CMD_TOOLS}/tools/bin/sdkmanager" "tools" > /dev/null
RUN yes "y" | "${ANDROID_CMD_TOOLS}/tools/bin/sdkmanager" "build-tools;${ANDROID_SDK_VERSION}" > /dev/null
RUN yes "y" | "${ANDROID_CMD_TOOLS}/tools/bin/sdkmanager" "platforms;android-30" > /dev/null
RUN yes "y" | "${ANDROID_CMD_TOOLS}/tools/bin/sdkmanager" "platform-tools" > /dev/null
RUN yes "y" | "${ANDROID_CMD_TOOLS}/tools/bin/sdkmanager" "extras;android;m2repository" > /dev/null
RUN yes "y" | "${ANDROID_CMD_TOOLS}/tools/bin/sdkmanager" "extras;google;m2repository" > /dev/null
RUN yes "y" | "${ANDROID_CMD_TOOLS}/tools/bin/sdkmanager" "patcher;v4" > /dev/null
RUN yes "y" | "${ANDROID_CMD_TOOLS}/tools/bin/sdkmanager" "system-images;android-30;google_apis_playstore;x86_64" > /dev/null
RUN yes "y" | "${ANDROID_CMD_TOOLS}/tools/bin/sdkmanager" "emulator" > /dev/null
RUN yes "y" | "${ANDROID_CMD_TOOLS}/tools/bin/sdkmanager" "--licenses" > /dev/null

RUN rm -rf "${ANDROID_CMD_TOOLS_ARCHIVE}"

# Create Emulator flutter_emulator
RUN avdmanager create avd -f -n flutter_emulator -k "system-images;android-30;google_apis_playstore;x86_64" -d pixel

# Start Emulator to run doctor
RUN emulator @flutter_emulator -noaudio -no-boot-anim -no-window -no-accel -memory 2048 -no-snapshot-load &

# Wait the emulator warmup
RUN sleep 600

# Install Flutter
ENV FLUTTER_URL="https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_1.20.3-stable.tar.xz"
ENV FLUTTER_ROOT="/opt/flutter"

RUN mkdir -p "${FLUTTER_ROOT}/archive"
ENV FLUTTER_ARCHIVE="${FLUTTER_ROOT}/archive/flutter.tar.xz"
RUN wget --progress=dot:giga "${FLUTTER_URL}" -O "${FLUTTER_ARCHIVE}"
RUN tar --extract --file="${FLUTTER_ARCHIVE}" --directory=$(dirname ${FLUTTER_ROOT}) 
RUN rm "${FLUTTER_ARCHIVE}"

# Add flutter executable to path
ENV PATH="${PATH}:${FLUTTER_ROOT}/bin"

# Run Flutter Doctor to checkup
RUN ${FLUTTER_ROOT}/bin/flutter doctor