#!/bin/bash
set -e

echo "Staring environment configuration ..."

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y perl
sudo apt-get install build-essential
sudo apt-get install gnuplot-x11

echo "Done!"