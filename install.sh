#!/bin/bash

distro=$(cat /etc/os-release)
mkdir gpgim_files
if [[ $distro == *"Red Hat"* || $distro == *"CentOs"*]]; then
	echo -e "Apparently, you are running a Red Hat/CentOs box. The program will now need to utilize sudo privileges to do its job. Enter a password if prompted.\n"
	sudo yum install gnupg2 openssl
elif [[ $distro == *"Ubuntu"* ]]; then
	echo -e "Apparently, you are running an Ubuntu box. The program will now need to utilize sudo privileges to do its job. Enter a password if prompted.\n"
	sudo apt-get install gnupg2 openssl
fi

echo "Done."
