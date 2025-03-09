#!/bin/bash
sudo apt remove cmake
sudo apt install libssl-dev

cd ~/
wget https://github.com/Kitware/CMake/releases/download/v3.31.6/cmake-3.31.6.tar.gz
tar -zxvf cmake-3.31.6.tar.gz # directory depends on the archive version
cd cmake-3.31.6
./bootstrap
make -j 4
sudo make install
sudo ldconfig
cd ~/
rm -rf cmake*
