#!/bin/bash

# clear console in script start
clear

# color codes.
cecho () { echo "\033[36m\033[1m$1\033[0m"; }
red_echo () { echo "\033[31m\033[1m$1\033[0m"; }
green_echo () { echo "\033[32m\033[1m$1\033[0m"; }
yellow_echo () { echo "\033[33m\033[1m$1\033[0m"; }

# define services path
services_path="/services"

# systemd runner user
used_username="lordbecvold"

# normal mode (check if not maintenance)
normal_mode=true
###############################################################################
start_mysql() {
	sudo systemctl start mysql
	if $normal_mode
	then
		sudo systemctl status mysql | head -n 3
	fi
	green_echo "[X-PANEL]: mysql started"
}

stop_mysql() {
	sudo systemctl stop mysql
	if $normal_mode
	then
		sudo systemctl status mysql | head -n 3
	fi
	red_echo "[X-PANEL]: mysql stoped"
}

start_apache() {
	sudo systemctl start apache2
	if $normal_mode
	then
		sudo systemctl status apache2 | head -n 3
	fi
	green_echo "[X-PANEL]: apache2 started"
}

stop_apache() {
	sudo systemctl stop apache2
	if $normal_mode
	then
		sudo systemctl status apache2 | head -n 3
	fi
	red_echo "[X-PANEL]: apache2 stoped"
}

start_openvpn() {
	sudo systemctl start openvpn
	if $normal_mode
	then
		sudo systemctl status openvpn | head -n 3
	fi
	green_echo "[X-PANEL]: openvpn started"
}

stop_openvpn() {
	sudo systemctl stop openvpn
	if $normal_mode
	then
		sudo systemctl status openvpn | head -n 3
	fi
	red_echo "[X-PANEL]: openvpn stoped"
}

start_monitoring() {
	sudo systemctl start admin-suite-monitoring
	if $normal_mode
	then
		sudo systemctl status admin-suite-monitoring | head -n 3
	fi
	green_echo "[X-PANEL]: monitoring started"
}

stop_monitoring() {
	sudo systemctl stop admin-suite-monitoring
	if $normal_mode
	then
		sudo systemctl status admin-suite-monitoring | head -n 3
	fi
	red_echo "[X-PANEL]: monitoring stoped"
}

show_status() {
	sudo systemctl --no-pager status mysql | head -n 3
	sudo systemctl --no-pager status apache2 | head -n 3
	sudo systemctl --no-pager status openvpn | head -n 3
	sudo systemctl --no-pager status admin-suite-monitoring | head -n 3
}

system_update() {
	sudo apt autoremove -y
	sudo apt update -y
	sudo apt upgrade -y
	sudo apt-get dist-upgrade -y
	green_echo "[X-PANEL]: system update complete"
}

system_clean() {
	sudo find /var/log -type f -delete
	sudo rm -r /tmp/*
	sudo rm -r /root/.rpmdb
	sudo rm -r /root/.wget-hsts
	sudo rm -r /root/.mysql_history
	sudo rm -r /root/.sudo_as_admin_successful
	sudo rm -r /home/lordbecvold/.npm
	sudo rm -r /home/lordbecvold/.cache
	sudo rm -r /home/lordbecvold/.docker
	sudo rm -r /home/lordbecvold/.lesshst
	sudo rm -r /home/lordbecvold/.wget-hsts
	sudo rm -r /home/lordbecvold/.mysql_history
	sudo rm -r /home/lordbecvold/.python_history
	sudo rm -r /home/lordbecvold/.sudo_as_admin_successful
	ls -alF /tmp/
	ls -alF /var/log/
	green_echo "[X-PANEL]: system clean complete"
}

system_backup() {

	# stop all services
	stop_mysql
	stop_apache
	stop_openvpn
	stop_monitoring

	# delete old backup
	if [ -f "$services_path/vps-backup.tar.gz" ]
	then
		sudo rm -rf $services_path/vps-backup.tar.gz
		green_echo "[X-PANEL]: deleting old backup file..."
	fi

	# delete old dumps
	if [ -d "$services_path/dumps" ]
	then
		sudo rm -rf $services_path/dumps/
		green_echo "[X-PANEL]: deleting old dumps directory..."
	fi

	# backup configs #############################################################################
	green_echo "[X-PANEL]: dumping configs..."
	mkdir $services_path/dumps
	mkdir $services_path/dumps/config-files

	# backup apache configs
	mkdir $services_path/dumps/config-files/apache2
	sudo cp -R /etc/apache2 $services_path/dumps/config-files/apache2

	# backup php config
	mkdir $services_path/dumps/config-files/php
	sudo cp -R /etc/php $services_path/dumps/config-files/php

	# backup mysql configs
	mkdir $services_path/dumps/config-files/mysql
	sudo cp -R /etc/mysql $services_path/dumps/config-files/mysql

	# backup others configs
	sudo cp -R /home/$used_username/.bashrc $services_path/dumps/config-files

	# backup logs
	green_echo "[X-PANEL]: dumping logs..."
	mkdir $services_path/dumps/logs/
	sudo cp -R /var/log/* $services_path/dumps/logs/

	# backup databases ###########################################################################
	start_mysql
	green_echo "[X-PANEL]: dumping database..."
	mkdir $services_path/dumps/database

	# dump datases
	mysqldump becvar_site > $services_path/dumps/database/becvar_site.sql
	mysqldump mysql > $services_path/dumps/database/mysql.sql

	# stop mysql after database dump
	stop_mysql

	# backup services ############################################################################
	green_echo "[X-PANEL]: creating services archive..."
	sudo su -c "tar -cf - /services | pv -s $(sudo du -sb /services | awk '{print $1}') | gzip > /vps-backup.tar.gz" root
	sudo mv /vps-backup.tar.gz $services_path/
	sudo chown $used_username:$used_username $services_path/vps-backup.tar.gz

	# delete temporary dumps #####################################################################
	if [ -d "$services_path/dumps" ]
	then
		sudo rm -rf $services_path/dumps/
		green_echo "[X-PANEL]: deleting temporary dumps directory..."
	fi

	# start all services after backup
	start_mysql
	start_apache
	start_openvpn
	start_monitoring

	# print final msg
	green_echo "[X-PANEL]: backup is completed in $services_path/vps-backup.tar.gz"
}

system_maintenance() {
	normal_mode=false

	system_update
	system_backup
	show_status
	green_echo "[X-PANEL]: system maintenance complete"
}
###############################################################################

# print panel menu
echo "\033[33m\033[1m╔═══════════════════════════════════════════════════╗\033[0m"
echo "\033[33m\033[1m║\033[1m                   \033[32mSERVER PANEL\033[0m                    \033[33m\033[1m║\033[0m"
echo "\033[33m\033[1m╠═══════════════════════════════════════════════════╣\033[0m"
echo "\033[33m\033[1m║\033[1m \033[31mServices\033[0m                                          \033[33m\033[1m║\033[0m"
echo "\033[33m\033[1m║\033[1m  \033[34m1  -  Start MySQL\033[1m        \033[34m2  -  Stop MySQL\033[0m        \033[33m\033[1m║\033[0m"
echo "\033[33m\033[1m║\033[1m  \033[34m3  -  Start Apache2\033[1m      \033[34m4  -  Stop Apache2\033[0m      \033[33m\033[1m║\033[0m"
echo "\033[33m\033[1m║\033[1m  \033[34m5  -  Start OpenVPN\033[1m      \033[34m6  -  Stop OpenVPN\033[0m      \033[33m\033[1m║\033[0m"
echo "\033[33m\033[1m║\033[1m  \033[34m7  -  Start Monitoring\033[1m   \033[34m8  -  Stop Monitoring\033[0m   \033[33m\033[1m║\033[0m"
echo "\033[33m\033[1m║\033[1m  \033[34m99 -  Show status                                \033[33m\033[1m║\033[0m"
echo "\033[33m\033[1m╠═══════════════════════════════════════════════════╣\033[0m"
echo "\033[33m\033[1m║\033[1m \033[31mSystem\033[0m                	                    \033[33m\033[1m║\033[0m"
echo "\033[33m\033[1m║\033[1m  \033[34mA - System update\033[1m        \033[34mB - System clean\033[0m        \033[33m\033[1m║\033[0m"
echo "\033[33m\033[1m║\033[1m  \033[34mC - System backup\033[1m        \033[34mD - System maintenance\033[0m  \033[33m\033[1m║\033[0m"
echo "\033[33m\033[1m╠═══════════════════════════════════════════════════╣\033[0m"
echo "\033[33m\033[1m║\033[1m  \033[34m0 - Exit panel\033[0m                                   \033[33m\033[1m║\033[0m"
echo "\033[33m\033[1m╚═══════════════════════════════════════════════════╝\033[0m"

# read select number
if [ "$#" -eq 0 ]; then
	read num
else
	num=$1
fi

# select num
case $num in
	1)
		start_mysql
	;;
	2)
		stop_mysql
	;;
	3)
		start_apache
	;;
	4)
		stop_apache
	;;
	5)
		start_openvpn
	;;
	6)
		stop_openvpn
	;;
	7)
		start_monitoring
	;;
	8)
		stop_monitoring
	;;
	99)
		show_status
	;;
	a|A)
		system_update
	;;
	b|B)
		system_clean
	;;
	c|C)
		system_backup
	;;
	d|D)
		system_maintenance
	;;
	# panel exit
	0)
		exit
	;;
	# not found num
	*)
		red_echo "$num: not found"
	;;
esac
