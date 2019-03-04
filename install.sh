#!/bin/sh

#=================================================
# CHECK ROOT
#=================================================

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

#=================================================
# RETRIEVE ARGUMENTS FROM THE MANIFEST
#=================================================

app=pia_front
final_path=/opt/$app
test ! -e "$final_path" || echo "This path already contains a folder" exit

#==============================================
# INSTALL DEPS
#==============================================

echo Install Nodejs LTS 10.x
curl --silent --location https://rpm.nodesource.com/setup_10.x | bash -


echo Get updates
yum update -y

echo Install dependencies
yum -y install git nodejs ufw

echo Install angular-cli
npm install -g @angular/cli

#==============================================
# FIREWALL
#==============================================

echo Open ports
#ufw allow http &> /dev/null
#ufw allow https &> /dev/null
ufw allow 4200/tcp
ufw allow ssh
echo Enable firewall
ufw enable

#==============================================
# INSTALL PIA
#==============================================

echo Download PIA
git clone https://github.com/LINCnil/pia.git

echo Install PIA
mv pia $final_path/

#=================================================
# MODIFY A CONFIG FILE
#=================================================

mv $final_path/src/environments/environment.prod.ts.example $final_path/src/environments/environment.prod.ts

cd $final_path

npm install
npm audit fix --force
ng build prod

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
