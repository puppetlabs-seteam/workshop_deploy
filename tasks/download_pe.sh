#!/bin/bash

if yum list installed wget; then
    echo Wget already installed
else
    yum install -y wget
    if [ ! $? -eq 0 ]; then
        echo Failed to install wget via Yum!
        exit 1
    fi
fi

PE_VERSION=$(curl -s http://versions.puppet.com.s3-website-us-west-2.amazonaws.com/ | tail -n1)
PE_SOURCE=puppet-enterprise-${PE_VERSION}-el-7-x86_64
DOWNLOAD_URL=https://s3.amazonaws.com/pe-builds/released/${PE_VERSION}/${PE_SOURCE}.tar.gz

cd ~

if [ ! -d ${PE_SOURCE} ]; then
    if [ ! -f ${PE_SOURCE}.tar.gz ]; then
        while [ 1 ]; do
            wget -O download.tmp --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 --tries=0 --continue --quiet ${DOWNLOAD_URL}
            if [ $? = 0 ]; then break; fi; # check return value, break if successful (0)
            sleep 1s;
        done;
        mv download.tmp ${PE_SOURCE}.tar.gz
    fi
    tar zxf ${PE_SOURCE}.tar.gz
    rm -f ${PE_SOURCE}.tar.gz
fi