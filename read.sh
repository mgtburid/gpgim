#!/bin/bash

today=$(date +%Y-%m-%d)
filestack=$(pwd)/gpgim_files
privkey=$(cat $filestack/.Rendezvous | cut -d " " -f1)
rest=$(cat $filestack/.Rendezvous | cut -d " " -f2)

[ -z $privkey ] && scp -v -r $rest. $filestack &> $filestack/.scp_output || scp -v -i $privkey $rest. $filestack &> $filestack/.scp_output
[ ! -f message.gp ] && echo "No messages or message file is not called message.gp." && exit 1
dir_con=$(ls $filestack -1 | grep .pub)
dir_con_num=$(echo "$dir_con" | wc -l)
case $1 in
	--read-only|-ro)
		gpg --decrypt message.gp &>> $filestack/${today}_decrypted_messages
		shift
		;;
	*)	
		gpg --decrypt message.gp &>> $filestack/${today}_decrypted_messages
		for key in $(seq 1 $dir_con_num)
		do
			echo "Importing key '$key'." >> $filestack/.gpgim_keys
			gpg --import $key &> $filestack/.gpgim_keys
		done
		shift
		;;
esac
