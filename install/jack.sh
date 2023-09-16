#!/bin/bash
#sudo apt install jackd
#sudo apt remove jackd
sudo apt-get install -y libasound2-dev libsndfile1-dev libreadline-dev libreadline6-dev libtinfo-dev
mkdir -p /tmp/jack2 
wget https://github.com/jackaudio/jack2/archive/v1.9.19.tar.gz -O /tmp/jack2/jack2.tar.gz
cd /tmp/jack2
tar xvfz jack2.tar.gz
cd /tmp/jack2/jack2-1.9.19
./waf configure --classic --alsa=yes --firewire=no --iio=no --portaudio=no --prefix /usr
./waf build
sudo ./waf install
cd / 
rm -rf /tmp/jack2
sudo ldconfig

sudo sh -c "echo @audio - memlock 256000 >> /etc/security/limits.conf"
sudo sh -c "echo @audio - rtprio 75 >> /etc/security/limits.conf"
