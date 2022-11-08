#!/bin/bash
# Opening ports for Calico CNI
sudo ufw allow 179/tcp
sudo ufw allow 4789/udp
sudo ufw allow 4789/tcp
sudo ufw allow 2379/tcp