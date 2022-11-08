#!/bin/bash
# Opening ports for Control Plane
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 6443/tcp
sudo ufw allow 2379:2380/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 10259/tcp
sudo ufw allow 10257/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 22/tcp
sudo ufw allow 53/udp
sudo ufw allow 33434/udp
sudo ufw enable
