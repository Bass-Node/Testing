# syntax=docker/dockerfile:1.0.0-experimental

FROM ubuntu:18.04

ARG SCRIPTARGS=""

ARG GSSBASE=/gssbase
ARG INSTALLBASE=$GSSBASE/installers
ARG SRCDIR=$GSSBASE/src

# install ssh client and git
RUN  apt-get -yq update && \
     apt-get -yq install openssh-client && \
     apt-get -yq install git && \
     apt-get -yq install curl && \
     apt-get -yq install jq && \
     apt-get install -y lsb-release && \
     apt-get install sudo -y

RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata

#Create dirs
RUN mkdir -p -m 777 $SRCDIR && \
  mkdir -p -m 777 $INSTALLBASE

# Download public key for github.com
RUN --mount=type=ssh mkdir -p -m 0600 ~/.ssh && \
  ssh-keyscan github.com >> ~/.ssh/known_hosts

# Get UBS Script
ARG DL_SCRIPT=download_latest_release.sh
COPY ./$DL_SCRIPT $INSTALLBASE

#Install UBS
RUN cd ${INSTALLBASE} && ./$DL_SCRIPT ${SCRIPTARGS} && \ 
  INSTALLER=$(find $INSTALLBASE -iname *.run -type f -printf "%f\n") && \ 
  if [ !  -z "$INSTALLER" ]; then chmod +x $INSTALLER && ./$INSTALLER ; else echo "Release of ubuntu_bionic_setup install failed." && exit 1 ; fi

# Clone private repositories
ARG GSS_BUILD=gss_build
ARG GSS_BUILD_DIR=$SRCDIR/$GSS_BUILD
RUN --mount=type=ssh git clone git@github.com:GreenseaSystems/$GSS_BUILD.git $GSS_BUILD_DIR

RUN --mount=type=ssh cd $GSS_BUILD_DIR && \
  ./build_gss_package.sh && \
  INSTALLER=$(find $GSS_BUILD_DIR -iname *.deb -type f -printf "%f\n") && echo "HERE: $INSTALLER" && \ 
  if [ !  -z "$INSTALLER" ]; then dpkg -i ./$INSTALLER ; else echo "${GSS_BUILD} setup failed." && exit 1 ; fi

# Clone, Build, Install UBS
ARG UBS=ubuntu_bionic_setup
ARG UBS_DIR=$SRCDIR/$UBS
RUN --mount=type=ssh git clone git@github.com:GreenseaSystems/$UBS.git $UBS_DIR

RUN --mount=type=ssh cd ${UBS_DIR} && \
  INSTALLER=$($UBS_DIR/build_ubuntu_18.04_setup_installer.sh | grep "successfully created" | cut -d \" -f2) && \ 
  if [ !  -z "$INSTALLER" ]; then sudo $UBS_DIR/$INSTALLER ; else echo "$UBS setup failed." && exit 1 ; fi

#CMD /<FILETORUN>.sh