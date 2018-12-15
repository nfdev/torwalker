#!/bin/bash

sudo apt-get install tor torsocks
sytemctl disable tor.service

echo "0 1 * * * ~/torwalker/check.sh google.co.jp" | crontab -

