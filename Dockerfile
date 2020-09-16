FROM ubuntu:latest

LABEL maintainer="Avenue securities"
LABEL repository="https://github.com/avenuesec/mobile_app.git"
LABEL version="1.0.0"

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo

# Install basics
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  git \
  wget \
  tree \
  curl \
  zip \
  unzip \
  openjdk-8-jdk \
  gcc \
  lib32stdc++6 \
  libstdc++6 \
  apt-transport-https \
  ca-certificates \
  gnupg \
  xz-utils \
  libglu1-mesa && \
  apt-get clean

# Install the Command Line Tools.
ENV ANDROID_CMD_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-6609375_latest.zip"

ENV ANDROID_SDK_ROOT="/opt/android_sdk"
RUN mkdir -p "${ANDROID_SDK_ROOT}"

ENV ANDROID_CMD_TOOLS="${ANDROID_SDK_ROOT}/cmdline-tools"
RUN mkdir -p "${ANDROID_CMD_TOOLS}"

ARG BUILD_TOOLS_VERSION="29.0.3"

ENV ANDROID_CMD_TOOLS_ARCHIVE="${ANDROID_CMD_TOOLS}/archive"
RUN wget --progress=dot:giga "${ANDROID_CMD_TOOLS_URL}" -O "${ANDROID_CMD_TOOLS_ARCHIVE}"
RUN unzip -q -d "${ANDROID_CMD_TOOLS}" "${ANDROID_CMD_TOOLS_ARCHIVE}"

# Add Android to path
ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin:${PATH}"
ENV PATH="${ANDROID_SDK_ROOT}/platform-tools:${PATH}"
ENV PATH="${ANDROID_SDK_ROOT}/build-tools/${BUILD_TOOLS_VERSION}:${PATH}"
ENV PATH="${ANDROID_SDK_ROOT}/emulator:${PATH}"

# Silence warning
RUN mkdir -p ~/.android
RUN touch ~/.android/repositories.cfg

# Suppressing output of sdkmanager to keep log size down
RUN yes "y" | "sdkmanager" "build-tools;${BUILD_TOOLS_VERSION}" > /dev/null
RUN yes "y" | "sdkmanager" "platforms;android-29" > /dev/null
RUN yes "y" | "sdkmanager" "platform-tools" > /dev/null
RUN yes "y" | "sdkmanager" "extras;google;google_play_services" > /dev/null
RUN yes "y" | "sdkmanager" "patcher;v4" > /dev/null
RUN yes "y" | "sdkmanager" "system-images;android-29;google_apis;x86_64" > /dev/null
RUN yes "y" | "sdkmanager" "emulator" > /dev/null
RUN yes "y" | "sdkmanager" "--licenses" > /dev/null

RUN rm -rf "${ANDROID_CMD_TOOLS_ARCHIVE}"

# Create & Start the Emulator once to make snapshot part of the image
COPY start-emulator.sh /start-emulator.sh
COPY config.ini /config.ini
RUN /start-emulator.sh -c -s

# Install Flutter
ENV FLUTTER_URL="https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_1.20.4-stable.tar.xz"
ENV FLUTTER_ROOT="/opt/flutter"

RUN mkdir -p "${FLUTTER_ROOT}/archive"
ENV FLUTTER_ARCHIVE="${FLUTTER_ROOT}/archive/flutter.tar.xz"
RUN wget --progress=dot:giga "${FLUTTER_URL}" -O "${FLUTTER_ARCHIVE}"
RUN tar --extract --file="${FLUTTER_ARCHIVE}" --directory=$(dirname ${FLUTTER_ROOT}) 
RUN rm "${FLUTTER_ARCHIVE}"

# Add flutter executable to path
ENV PATH="${PATH}:${FLUTTER_ROOT}/bin"

# Run Flutter PreCache
RUN ${FLUTTER_ROOT}/bin/flutter precache

# Run Flutter Doctor to checkup
RUN ${FLUTTER_ROOT}/bin/flutter doctor

# # Start Emulator
# CMD ./start-emulator.sh -s && /bin/bash