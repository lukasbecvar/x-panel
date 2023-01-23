#!/bin/bash

# Clear console in script start
clear

# Color codes.
green_echo () { echo "\033[32m\033[1m$1\033[0m"; }
dark_green_echo () { echo "\033[32m\033[3m$1\033[0m"; }
yellow_echo () { echo "\033[33m\033[1m$1\033[0m"; }
red_echo () { echo "\033[31m\033[1m$1\033[0m"; }
cecho () { echo "\033[36m\033[1m$1\033[0m"; }

# Vars
serviceDir="/services" # Services directory

# Services kill Functions 
kill_minecraft_server() { # Kill minecraft server
	cd $serviceDir/minecraft/
	sh srv_stop.sh
	red_echo "[Minecraft]: starting screen session killed!"
}

kill_teamspeak_server() { # Kill teamspeak
	sudo sh $serviceDir/teamspeak/ts3server_startscript.sh stop
	red_echo "[TeamSpeak]: killed!"
}

kill_mariadb() { # Kill mariadb
	sudo systemctl stop mariadb
	red_echo "[MariaDB]: killed!"
}

kill_apache2() { # Kill apache2
	sudo systemctl stop apache2
	red_echo "[Apache2]: killed!"
}

kill_open_vpn() { # Kill openvpn
	sudo systemctl stop openvpn
	red_echo "[OpenVPN]: stoping..."
}

kill_tor() { # Kill tor
	sudo systemctl stop tor
	red_echo "[TOR]: killed!"
}

# Services kill Functions 
start_minecraft_server() { # Start minecraft
	cd $serviceDir/minecraft/
	sh srv_start.sh
	red_echo "[Minecraft]: starting on screen session minecraft..."
}

start_teamspeak_server() { # Start teamspeak
	sudo sh $serviceDir/teamspeak/ts3server_startscript.sh start
	red_echo "[Team speak]: started..."
}

start_openvpn() { # Start openvpn
	sudo systemctl start openvpn
	red_echo "[OpenVPN]: started..."
}

start_mariadb() { # Start mariadb
	sudo systemctl start mariadb
	red_echo "[MariaDB]: started..."
}

start_apache2() { # Start apache2
	sudo chown -R www-data:www-data $serviceDir/web/
	sudo systemctl start apache2
	red_echo "[Apache2]: started..."
}

start_tor() { # Start tor
	sudo systemctl start tor
	red_echo "[TOR]: started..."
}

# Initiate functions 
services_status() { # Show services status

	# Clear console with select
	clear

	yellow_echo "#################################################################################################"
	dark_green_echo "SERVICES STATUS"
	yellow_echo "#################################################################################################"

	# Systemd status
	sudo systemctl --no-pager status ufw | head -n 3
    sudo systemctl --no-pager status sshd | head -n 3
	sudo systemctl --no-pager status apache2 | head -n 3
	sudo systemctl --no-pager status tor | head -n 3
	sudo systemctl --no-pager status openvpn | head -n 3
	sudo systemctl --no-pager status mariadb | head -n 3
	yellow_echo "#################################################################################################"

    # TeamSpeak status
    green_echo "[TeamSpeak]: status"
    sh $serviceDir/teamspeak/ts3server_startscript.sh status
    yellow_echo "#################################################################################################"

	# Screen services
	green_echo "Screen services"
	screen -list
	yellow_echo "#################################################################################################"
}

stop_all() { # Stop all services

	yellow_echo "#################################################################################################"
	green_echo "Stoping services..."
	yellow_echo "#################################################################################################"

	# Call kill functions
	kill_minecraft_server
	kill_teamspeak_server
	kill_mariadb
	kill_apache2
	kill_open_vpn
	kill_tor

	yellow_echo "#################################################################################################"
}

start_all() { # Start all services 

	yellow_echo "#################################################################################################"
	green_echo "Starting services..."
	yellow_echo "#################################################################################################"

	# Call starting functions
	start_minecraft_server
	#start_teamspeak_server
	start_openvpn
	start_mariadb
	start_apache2
	start_tor

	yellow_echo "#################################################################################################"
}

create_backup() { # Backup server

	# Stop all services
	stop_all

	# Start database for sql dump
	start_mariadb

	# Delete old backup
	FILE=$serviceDir/VPS_Backup.tar.gz
	if test -f "$FILE"; then
		sudo rm -r $serviceDir/VPS_Backup.tar.gz
		red_echo "Deleting old backup file..."
	fi

	# Delete old backup dir
	if [ -d "/Backup" ]
	then
		sudo rm -r /Backup
		red_echo "Deleting old backup directory..."
	fi

	# Create dir for backup
	sudo mkdir /Backup

	# Create dir for backup configs
	mkdir /Backup/configFiles
	mkdir /Backup/configFiles/php
	mkdir /Backup/configFiles/php/apache2
	mkdir /Backup/configFiles/apache2
	mkdir /Backup/configFiles/apache2/sites-available
	mkdir /Backup/configFiles/tor

	# Backup config files
	sudo cp -R /etc/apache2/apache2.conf /Backup/configFiles/apache2/
	sudo cp -R /etc/apache2/sites-available/default.conf /Backup/configFiles/apache2/sites-available/
	sudo cp -R /etc/apache2/sites-available/becvar_site.conf /Backup/configFiles/apache2/sites-available/
	sudo cp -R /etc/apache2/sites-available/onion.conf /Backup/configFiles/apache2/sites-available/
	sudo cp -R /etc/php/8.0/apache2/php.ini /Backup/configFiles/php/apache2/
	sudo cp -R /etc/tor/torrc /Backup/configFiles/tor/
	sudo cp -R /root/.bashrc /Backup/configFiles/
	sudo cp -R /etc/sudoers /Backup/configFiles/
	sudo cp -R /etc/ssh/sshd_config /Backup/configFiles/

	# Backup database
	red_echo "Backuping database..."
	sudo mkdir /Backup/database/
	red_echo "Dumping becvar_site"
	sudo mysqldump -u root becvar_site > /Backup/database/becvar_site.sql
	red_echo "Dumping mysql"
	sudo mysqldump -u root mysql > /Backup/database/mysql.sql

	# Backup services
	red_echo "Backuping services..."
	tar cf - $serviceDir/ -P | pv -s $(du -sb $serviceDir/ | awk '{print $1}') | gzip > $serviceDir.tar.gz
	sudo mv $serviceDir.tar.gz /Backup

	# Run start all services
	start_all

	# Tar complete backup
	red_echo "Backuping complete package..."
	tar cf - /Backup/ -P | pv -s $(du -sb /Backup/ | awk '{print $1}') | gzip > /VPS_Backup.tar.gz

	# Delete Backup temp folder
	sudo rm -r /Backup/

	# Move backup file to services dir
	mv /VPS_Backup.tar.gz $serviceDir/

	# Print final msg
	green_echo "[Backup]: is completed in $serviceDir/Backup.tar.gz"
	yellow_echo "#################################################################################################"
}

system_clean() { # Clean system temp, logs and system logs
	sudo find /var/log -type f -delete
	sudo rm -r /tmp/*
	green_echo "system /tmp, /var/log deleted"
	sudo apt autoremove
	sudo apt autoclean
	green_echo "[APT]: autoremove complete"
	sudo rm -r $serviceDir/minecraft/logs/*
	green_echo "[Minecraft]: logs deleted..."
	sudo rm -r $serviceDir/teamspeak/logs/*
	green_echo "[Teamspeak]: logs deleted..."
}

system_update() { # Run system update

	# Update system
	sudo apt-get update -y
	red_echo "[SYSTEM]: updated!"
	sudo apt-get upgrade -y
	red_echo "[SYSTEM]: upgraded!"
	sudo apt-get dist-upgrade -y
	red_echo "[SYSTEM]: distribution upgraded!"
}

installer() {

	# Run system update
	system_update 

	red_echo "[SYSTEM]: installing htop"
	sudo apt install htop
	red_echo "[SYSTEM]: installing nload"
	sudo apt install nload
	red_echo "[SYSTEM]: installing git"
	sudo apt install git
	red_echo "[SYSTEM]: installing ngrep"
	sudo apt install ngrep
	red_echo "[SYSTEM]: installing python2"
	sudo apt install python2
	red_echo "[SYSTEM]: installing python3"
	sudo apt install python2
	red_echo "[SYSTEM]: installing unzip"
	sudo apt install unzip
	red_echo "[SYSTEM]: installing unrar"
	sudo apt install unrar
	red_echo "[SYSTEM]: installing tar"
	sudo apt install tar
}

# GUI draw functions
services_controller() { # Run services controller

	# Clear console with select
	clear

	# Print panel menu
	echo "\033[33m\033[1m#################################################################################################\033[0m"
	echo "\033[33m\033[1m##\033[0m                                        \033[32mSERVER PANEL\033[0m                                         \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m#################################################################################################\033[0m"
	echo "\033[33m\033[1m##\033[0m                                                                                             \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m##\033[1m \033[32mMain services\033[0m                                                                               \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m##\033[0m                                                                                             \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m##\033[0m   \033[33m1    -   Start Apache2\033[0m           \033[33m2   -   Stop Apache2\033[0m                                     \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m##\033[0m   \033[33m3    -   Start MariaDB\033[0m           \033[33m4   -   Stop MariaDB\033[0m                                     \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m##\033[0m   \033[33m5    -   Start tor\033[0m               \033[33m6   -   Stop tor\033[0m                                         \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m##\033[0m   \033[33m7    -   Start OpenVPN\033[0m           \033[33m8   -   Stop OpenVPN\033[0m                                     \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m##\033[0m                                                                                             \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m##\033[1m \033[32mSub services\033[0m                                                                                \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m##\033[0m                                                                                             \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m##\033[0m   \033[33mA    -   Start TeamSpeak3\033[0m        \033[33mB   -   Stop TeamSpeak3\033[0m                                  \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m##\033[0m   \033[33mC    -   Start Minecraft\033[0m         \033[33mD   -   Stop Minecraft\033[0m                                   \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m##\033[0m                                                                                             \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m#################################################################################################\033[0m"
	echo "\033[33m\033[1m##\033[0m   \033[33m0    -   Back to main panel\033[0m                                                               \033[33m\033[1m##\033[0m"
	echo "\033[33m\033[1m#################################################################################################\033[0m"

	# Stuck menu for select action
	read selector

	# Selector methodes
	case $selector in

		1|cmd)
			start_apache2
		;;
		2|cmd)
			kill_apache2
		;;
		3|cmd)
			start_mariadb
		;;
		4|cmd)
			kill_mariadb
		;;
		5|cmd)
			start_tor
		;;
		6|cmd)
			kill_tor
		;;
		7|cmd)
			start_openvpn
		;;
		8|cmd)
			kill_open_vpn
		;;
		a|cmd)
			start_teamspeak_server
		;;
		b|cmd)
			kill_teamspeak_server
		;;
		c|cmd)
			start_minecraft_server
		;;
		d|cmd)
			kill_minecraft_server
		;;
		0|cmd)
			sh $serviceDir/x-panel.sh
		;;
		*)
			echo "\033[31m\033[1mYour vote not found!\033[0m \n"
		;;
	esac
}


# Print panel menu
echo "\033[33m\033[1m#################################################################################################\033[0m"
echo "\033[33m\033[1m##\033[0m                                        \033[32mSERVER PANEL\033[0m                                         \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m#################################################################################################\033[0m"
echo "\033[33m\033[1m##\033[0m                                                                                             \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[1m \033[32mServices\033[0m                                                                                    \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[0m                                                                                             \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[0m   \033[33m1    -   Services controller\033[0m     \033[33m2   -   Services status\033[0m                                  \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[0m   \033[33m3    -   Start all\033[0m               \033[33m4   -   Stop all\033[0m                                         \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[0m                                                                                             \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[1m \033[32mSystem\033[0m                                                                                      \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[0m                                                                                             \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[0m   \033[33m5    -   System update\033[0m           \033[33m6   -   System clean\033[0m                                     \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[0m                                                                                             \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[1m \033[32mOthers\033[0m                                                                                      \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[0m                                                                                             \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[0m   \033[33m7    -   Create backup\033[0m           \033[33m8    -   Complete maintenance\033[0m                            \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[0m   \033[33m9    -   Run installer\033[0m                                                                    \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m##\033[0m                                                                                             \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m#################################################################################################\033[0m"
echo "\033[33m\033[1m##\033[0m   \033[33m0    -   Exit panel\033[0m                                                                       \033[33m\033[1m##\033[0m"
echo "\033[33m\033[1m#################################################################################################\033[0m"

# Stuck menu for select action
read selector

# Selector methodes
case $selector in

	1|cmd)
		services_controller
	;;
	2|cmd)
		services_status
	;;
	3|cmd)
		start_all
	;;
	4|cmd)
		stop_all
	;;
	5|cmd)
		system_update
	;;
	6|cmd)
		system_clean
	;;
	7|cmd)
		create_backup
	;;
	8|cmd)
		system_update
		#system_clean
		create_backup
	;;
	9|cmd)
		installer
	;;
	0|cmd)
		exit
	;;
	*)
		echo "\033[31m\033[1mYour vote not found!\033[0m \n"
	;;
esac
