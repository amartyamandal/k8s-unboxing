#!/bin/bash
# Opening ports for Worker Nodes
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 10250/tcp
sudo ufw allow 30000:32767/tcp
sudo ufw allow 22/tcp
sudo ufw allow 53/udp
sudo ufw allow 33434/udp
sudo ufw enable