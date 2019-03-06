#!/bin/bash
#
# About: Install PIA Front automatically
# Author: liberodark
# License: GNU GPLv3

  update_source="https://raw.githubusercontent.com/liberodark/pia-front_centos/master/install.sh"
  version="1.0.0"

  echo "Welcome on PIA Front Install Script $version"

  # make update if asked
  if [ "$1" = "noupdate" ]; then
    update_status="false"
  else
    update_status="true"
  fi ;

  # update updater
  if [ "$update_status" = "true" ]; then
    wget -O $0 $update_source
    $0 noupdate
    exit 0
fi ;

#=================================================
# CHECK ROOT
#=================================================

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

#=================================================
# RETRIEVE ARGUMENTS FROM THE MANIFEST
#=================================================

app=pia
final_path=/opt/$app
test ! -e "$final_path" || echo "This path already contains a folder" exit

#==============================================
# INSTALL DEPS
#==============================================

echo Install Nodejs LTS 10.x
curl --silent --location https://rpm.nodesource.com/setup_10.x | bash - &> /dev/null


#echo Get updates
#yum update -y &> /dev/null

echo Install dependencies
yum -y install wget nodejs ufw &> /dev/null

#==============================================
# FIREWALL
#==============================================

echo Enable firewall
systemctl enable ufw &> /dev/null
systemctl start ufw &> /dev/null

echo Open ports
#ufw allow http &> /dev/null
#ufw allow https &> /dev/null
ufw allow 4200/tcp &> /dev/null
ufw allow ssh &> /dev/null

#==============================================
# INSTALL PIA
#==============================================

echo Download PIA

wget https://github.com/kosmas58/pia/archive/2.0.0.5.tar.gz -O pia.tar.gz &> /dev/null
tar -xvf pia.tar.gz && rm pia.tar.gz &> /dev/null

echo Install PIA
mv pia/ $final_path/ &> /dev/null

pushd $final_path
npm install &> /dev/null
npm install -g @angular/cli@1.7.4 &> /dev/null
popd

#=================================================
# MODIFY A CONFIG FILE
#=================================================

#mv $final_path/src/environments/environment.prod.ts.example $final_path/src/environments/environment.prod.ts

#cd $final_path

#npm install
#npm audit fix --force
#ng build prod

#==============================================
# INSTALL SERVICE
#==============================================
echo Install $app service
echo

"[Unit]
Description=$app
After=network.target

[Service]
WorkingDirectory=$final_path
User=admin
Group=users
Type=simple
UMask=000
ExecStart=/usr/bin/ng serve --port 4200 --host 0.0.0.0
RestartSec=30
Restart=always

[Install]
WantedBy=multi-user.target"

> /etc/systemd/system/$app.service

#=================================================
# SETUP APP
#=================================================

#echo Change permission for www-data
#chown -R www-data:www-data $final_path &> /dev/null

echo Enable services
systemctl enable $app.service
systemctl start $app.service
