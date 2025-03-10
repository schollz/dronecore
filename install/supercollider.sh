#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

sudo apt-get install -y libsamplerate0-dev libsndfile1-dev libasound2-dev libavahi-client-dev libreadline-dev libfftw3-dev libudev-dev libncurses5-dev git

# install supercollider
mkdir -p /tmp/supercollider
cd /tmp/supercollider
wget https://github.com/supercollider/supercollider/releases/download/Version-3.13.0/SuperCollider-3.13.0-Source.tar.bz2 -O sc.tar.bz2
tar xvf sc.tar.bz2 
cd /tmp/supercollider/SuperCollider-3.13.0-Source
mkdir -p build
cd /tmp/supercollider/SuperCollider-3.13.0-Source/build
cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_TESTING=OFF -DENABLE_TESTSUITE=OFF -DNATIVE=ON -DINSTALL_HELP=OFF -DNO_X11=ON -DSC_IDE=OFF -DSC_QT=OFF -DSC_ED=OFF -DSC_EL=OFF -DSUPERNOVA=OFF -DSC_VIM=OFF ..
cmake --build . --config Release --target all -- -j3
sudo cmake --build . --config Release --target install
sudo ldconfig


# install sc3-plugins
mkdir -p /tmp/sc3-plugins
cd /tmp/sc3-plugins
git clone --depth=1 --recursive --branch Version-3.13.0 https://github.com/supercollider/sc3-plugins.git
cd /tmp/sc3-plugins/sc3-plugins 
mkdir -p build
cd /tmp/sc3-plugins/sc3-plugins/build
mkdir -p /home/timeandspace/.local/share/SuperCollider/Extensions/
cmake -DCMAKE_INSTALL_PREFIX=/home/timeandspace/.local/share/SuperCollider/Extensions/ -DSC_PATH=/tmp/supercollider/SuperCollider-3.13.0-Source -DNATIVE=ON -DSUPERNOVA=OFF ..
cmake --build . --config Release -- -j4
cmake --build . --config Release --target install
cd / 
rm -rf /tmp/sc3-plugins
sudo ldconfig


# install ported plugins
cd /tmp 
git clone https://github.com/schollz/portedplugins
cd portedplugins
git submodule update --init --recursive 
mkdir build 
cd build
cmake -DCMAKE_BUILD_TYPE='Release' -DSC_PATH=/tmp/supercollider/SuperCollider-3.13.0-Source/ -DCMAKE_INSTALL_PREFIX=/home/timeandspace/.local/share/SuperCollider/Extensions/ -DSUPERNOVA=OFF -DNATIVE=ON ..
cmake --build . --config Release -- -j4
cmake --build . --config Release --target install

# cleanup
cd /
rm -rf /tmp/portedplugs
rm -rf /tmp/supercollider
