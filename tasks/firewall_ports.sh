#!/bin/bash
if systemctl start firewalld
then
    systemctl enable firewalld
    firewall-cmd --zone=public --add-port=22/tcp --permanent
    firewall-cmd --zone=public --add-port=80/tcp --permanent
    firewall-cmd --zone=public --add-port=443/tcp --permanent
    firewall-cmd --zone=public --add-port=4432/tcp --permanent
    firewall-cmd --zone=public --add-port=4433/tcp --permanent
    firewall-cmd --zone=public --add-port=5432/tcp --permanent
    firewall-cmd --zone=public --add-port=8080/tcp --permanent
    firewall-cmd --zone=public --add-port=8081/tcp --permanent
    firewall-cmd --zone=public --add-port=8140/tcp --permanent
    firewall-cmd --zone=public --add-port=8142/tcp --permanent
    firewall-cmd --zone=public --add-port=8143/tcp --permanent
    firewall-cmd --zone=public --add-port=8170/tcp --permanent
    firewall-cmd --reload
else
    echo "firewalld not installed, skipping..."
    exit 0
fi