#!/bin/bash

rm -f message.gp
today=$(date +%Y-%m-%d)
filestack=$(pwd)/gpgim_files
privkey=$(cat $filestack/.Rendezvous | cut -d " " -f1)
rest=$(cat $filestack/.Rendezvous | cut -d " " -f2)

# message.txt's contents are ciphered, put into a respective file, and sent
[ $# -eq 0 ] && echo "You did not provide a list of recipients." && exit 1
while [ $# -gt 0 ];
do
	gpg --output message.gp -r $1 --encrypt --armor message.txt &> $filestack/.gpg_output
	[[ $(cat $filestack/.gpg_output) == *"skipped: No public key"* ]] && echo "A public key for/identified as '$1' is absent." && exit 1
	if [ ! -f $filestack/.gpg_output ]; then
		echo "A public key for '$1' is absent." && exit 1
	else
		if [ -z $privkey ]; then
			sudo scp message.gp $rest && echo "====SENT TO $1====" >> message.gp
		else
			sudo -i $privkey message.gp $rest
		fi
		cat message.gp >> $filestack/${today}_messages
	fi
	shift
done
