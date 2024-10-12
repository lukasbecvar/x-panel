#!/bin/bash

# clear console after script start
clear

# color echo functions
echo_red() { echo "\033[0;31m$1\033[0m"; }
echo_yellow() { echo "\033[1;33m$1\033[0m"; }
echo_blue() { echo "\033[0;34m$1\033[0m"; }
echo_green() { echo "\033[0;32m$1\033[0m"; }
echo_orange() { echo "\033[0;33m$1\033[0m"; }
echo_cyan() { echo "\033[0;36m$1\033[0m"; }

# X-PANEL VARIABLES ###########################################################
# path to services directory
services_path="/services"

# main admin username
used_username="lukasbecvar"
###############################################################################

start_service() {
	sudo systemctl start $1
	sudo systemctl status $1 | head -n 3
	echo_green "[X-PANEL]: $1 started"
}

stop_service() {
	sudo systemctl stop $1
	sudo systemctl status $1 | head -n 3
	echo_red "[X-PANEL]: $1 stopped"
}

show_status() {
	sudo systemctl --no-pager status sshd | head -n 3
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
	echo_green "[X-PANEL]: system update complete"
}

system_clean() {
	sudo find /var/log -type f -delete
	sudo rm -r /tmp/*
	sudo rm -r /root/.rpmdb
	sudo rm -r /root/.wget-hsts
	sudo rm -r /root/.mysql_history
	sudo rm -r /root/.sudo_as_admin_successful
	sudo rm -r /home/lukasbecvar/.npm
	sudo rm -r /home/lukasbecvar/.cache
	sudo rm -r /home/lukasbecvar/.rpmdb
	sudo rm -r /home/lukasbecvar/.docker
	sudo rm -r /home/lukasbecvar/.lesshst
	sudo rm -r /home/lukasbecvar/.wget-hsts
	sudo rm -r /home/lukasbecvar/.mysql_history
	sudo rm -r /home/lukasbecvar/.python_history
	sudo rm -r /home/lukasbecvar/.sudo_as_admin_successful
	ls -alF /tmp/
	ls -alF /var/log/
	echo_green "[X-PANEL]: system clean complete"
}

system_backup() {
	# stop all services
	stop_service "mysql"
	stop_service "apache2"
	stop_service "openvpn"
	stop_service "admin-suite-monitoring"

	# delete old backup
	if [ -f "$services_path/vps-backup.tar.gz" ]
	then
		sudo rm -rf $services_path/vps-backup.tar.gz
		echo_green "[X-PANEL]: deleting old backup file..."
	fi

	# delete old dumps
	if [ -d "$services_path/dumps" ]
	then
		sudo rm -rf $services_path/dumps/
		echo_green "[X-PANEL]: deleting old dumps directory..."
	fi

	# backup configs #############################################################################
	echo_green "[X-PANEL]: dumping configs..."
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
	sudo cp -R /etc/systemd/system/admin-suite-monitoring.service $services_path/dumps/config-files

	# backup logs
	echo_green "[X-PANEL]: dumping logs..."
	mkdir $services_path/dumps/logs/
	sudo cp -R /var/log/* $services_path/dumps/logs/

	# backup databases ###########################################################################
	start_service "mysql"
	echo_green "[X-PANEL]: dumping database..."
	mkdir $services_path/dumps/database

	# dump datases
	mysqldump becvar_site > $services_path/dumps/database/becvar_site.sql
	mysqldump becvar_site > $services_path/dumps/database/admin_suite.sql
	mysqldump becvar_site > $services_path/dumps/database/code_paste.sql
	mysqldump mysql > $services_path/dumps/database/mysql.sql

	# stop mysql after database dump
	stop_service "mysql"

	# backup services ############################################################################
	echo_green "[X-PANEL]: creating services archive..."
	sudo su -c "tar -cf - /services | pv -s $(sudo du -sb /services | awk '{print $1}') | gzip > /vps-backup.tar.gz" root
	sudo mv /vps-backup.tar.gz $services_path/
	sudo chown $used_username:$used_username $services_path/vps-backup.tar.gz

	# delete temporary dumps #####################################################################
	if [ -d "$services_path/dumps" ]
	then
		sudo rm -rf $services_path/dumps/
		echo_green "[X-PANEL]: deleting temporary dumps directory..."
	fi

	# start all services after backup
	start_service "mysql"
	start_service "apache2"
	start_service "openvpn"
	start_service "admin-suite-monitoring"

	# print final msg
	echo_green "[X-PANEL]: backup is completed in $services_path/vps-backup.tar.gz"
}

system_maintenance() {
	system_update
	system_backup
	show_status
	echo_green "[X-PANEL]: system maintenance complete"
}

# print panel menu selection
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

# read selection input
if [ "$#" -eq 0 ]; then
	read num
else
	num=$1
fi

# selection cases
case $num in
	1)
		start_service "mysql"
	;;
	2)
		stop_service "mysql"
	;;
	3)
		start_service "apache2"
	;;
	4)
		stop_service "apache2"
	;;
	5)
		start_service "openvpn"
	;;
	6)
		stop_service "openvpn"
	;;
	7)
		start_service "admin-suite-monitoring"
	;;
	8)
		stop_service "admin-suite-monitoring"
	;;
	99|status)
		show_status
	;;
	a|A|update)
		system_update
	;;
	b|B|clean)
		system_clean
	;;
	c|C|backup)
		system_backup
	;;
	d|D|maintenance)
		system_maintenance
	;;
	0)
		exit
	;;
	*)
		echo_red "option: $num not found"
	;;
esac
