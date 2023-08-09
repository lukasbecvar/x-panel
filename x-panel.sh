#!/bin/bash

# Clear console in script start
clear

# Color codes.
green_echo () { echo "\033[32m\033[1m$1\033[0m"; }
yellow_echo () { echo "\033[33m\033[1m$1\033[0m"; }
red_echo () { echo "\033[31m\033[1m$1\033[0m"; }
cecho () { echo "\033[36m\033[1m$1\033[0m"; }

# Print panel menu
echo "\033[33m\033[1m#################################################\033[0m"
echo "\033[33m\033[1m#\033[1m                 \033[32mSERVER PANEL\033[0m                  \033[33m\033[1m#\033[0m"
echo "\033[33m\033[1m#################################################\033[0m"
echo "\033[33m\033[1m#\033[1m \033[31mServices\033[0m                                      \033[33m\033[1m#\033[0m"
echo "\033[33m\033[1m#\033[1m  \033[34m1 - Start all\033[1m        \033[34m2 - Stop all\033[0m            \033[33m\033[1m#\033[0m"
echo "\033[33m\033[1m#\033[1m  \033[34m3 - Start Apache\033[1m     \033[34m4 - Stop Apache\033[0m         \033[33m\033[1m#\033[0m"
echo "\033[33m\033[1m#\033[1m  \033[34m5 - Start mysql\033[1m      \033[34m6 - Stop mysql\033[0m          \033[33m\033[1m#\033[0m"
echo "\033[33m\033[1m#\033[0m                                               \033[33m\033[1m#\033[0m"
echo "\033[33m\033[1m#\033[1m \033[31mSystem\033[0m                	                \033[33m\033[1m#\033[0m"
echo "\033[33m\033[1m#\033[1m  \033[34mA - System update\033[1m    \033[34mB - System clean\033[0m        \033[33m\033[1m#\033[0m"
echo "\033[33m\033[1m#\033[1m  \033[34mC - System backup\033[1m    \033[34mD - System maintenance\033[0m  \033[33m\033[1m#\033[0m"
echo "\033[33m\033[1m#################################################\033[0m"
echo "\033[33m\033[1m#\033[1m  \033[34m0 - Exit panel\033[0m                               \033[33m\033[1m#\033[0m"
echo "\033[33m\033[1m#################################################\033[0m"

# Stuck menu for select action
read num

# select num
case $num in
	1)
		green_echo "start all"
	;;
	2)
		red_echo "stop all"
	;;
	3)
		green_echo "start apache"
	;;
	4)
		red_echo "stop apache"
	;;
	5)
		green_echo "start mysql"
	;;
	6)
		red_echo "stop mysql"
	;;
	a|A)
		yellow_echo "update"
	;;
	b|B)
		yellow_echo "system clean"
	;;
	c|C)
		yellow_echo "backup"
	;;
	d|D)
		cecho "maintenance"
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
