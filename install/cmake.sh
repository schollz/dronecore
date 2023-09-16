#!/bin/bash
sudo apt remove cmake
sudo apt install libssl-dev

cd ~/
wget https://github.com/Kitware/CMake/releases/download/v3.27.5/cmake-3.27.5.tar.gz
tar -zxvf cmake-3.27.5.tar.gz # directory depends on the archive version
cd cmake-3.27.5
./bootstrap
make -j 4
sudo make install
sudo ldconfig
cd ~/
rm -rf cmake*
