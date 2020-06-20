#!/bin/bash

read -p "How the key should be indentified: "  userid
read -p "For how long key is supposed to be valid (default is never; use shortings from man gpg i.e. 1w = 1 week): " expire

# set expiration date to never if no input provided
[ -z $expire ] && expire="never"

# write gpg output to a hidden file
gpg --quick-generate-key $userid default default $expire &> .output

# if provided userid already exists, its information is printed, file is deleted, and script stops
if [[ $(cat .output) == *"already exists"* ]]; then rm -f .output && echo "Userid '$userid' already exists. Delete a respective key or come up with a new userid value." && gpg --list-keys $userid | tail -5 && exit 1; fi

# the filename of the public key: userid+YYYY-Mon-Day-HH-MM-SS in SHA1
sha_userid=$(echo -n ${userid}_$(date +%Y-%m-%d-%H-%M-%S) | openssl dgst -sha1 | cut -d " " -f2)
gpg --armor --export $userid > ${sha_userid}.pub

# scp part should be here
if [[ -f server_config ]]; then
	items=( "username" "hostname" "ipv4" "ipv6" "privkey" "storage" )
	for i in {1..5}
	do
		config_value=$(grep -v "#" server_config | awk "NF" | cut -d "=" -f2 | awk "NR==$i")
		echo $config_value
		echo "that was config_value $i"
		srv_config+=( $config_value )
	done
	echo "Server config: ${srv_config[@]}"
	for var in ${srv_config[@]}
	do
		[[ $var != "0" ]] && score+=1 || score+=0
	done
	echo "Score is $score"
	if [[ $score = "00000" ]]; then
		echo "### Check the configuration in 'server_config', looks like all variables are set to 0. The newly created GPG key is called ${sha_userid}." && exit 1
	else
		for i in $(seq 0 ${#score}); do
			echo $i
			if [[ $i = 0 && ${score:$i:1} = 0 ]]; then
				echo "### No username provided in 'server_config'. The newly create GPG key is called ${sha_userid}." && exit 1
			elif [[ $i = 2 && ${score:$i:1} = 0 ]] && [[ $i = 1 && ${score:$i:1} = 0 ]]; then
				echo "### Neither hostname, nor IP address were provided in 'server_config'. The newly created GPG key is called ${sha_userid}." && exit 1
			elif [[ $i = 2 && ${score:$i:1} = 0 ]]; then
				echo "IP is set in 'server_config'."
				ip_flag=1
			elif [[ $i = 1 && ${score:$1:1} = 0 ]]; then
				echo "### Hostname is set in 'server_config'."
				hostname_flag=1
			elif [[ $i = 3 && ${score:$i:1} = 0 ]]; then
				privkey_flag=0 && echo "### SSH key was not found, proceeding without it."
			elif [[ $i = 3 && ${score:$i:1} = 0 ]]; then
				privkey_flag=1 && echo "### SSH key was found."
			elif [[ $i = 4 && ${score:$i:1} = 0 ]]; then
				echo "### The script does not know where to store the GPG key on the server, check the configuration in 'server_config'. The newly created GPG key is called ${sha_userid}." && exit 1
			fi
		done
	fi
	echo "The newly created GPG key is called ${sha_userid}."
	if [[ $ip_flag = 1 && $privkey_flag = 1 ]]; then
		sudo scp -i $privkey ${sha_userid}.pub $user@$ip:$storage
	elif [[ $hostname_flag = 1 && $privkey_flag = 1 ]]; then
		sudo scp -i $pivkey ${sha_userid}.pub $user@$hostname:$storage
	elif [[ $ip_flag = 1 ]]; then
		sudo scp ${sha_userid}.pub $user@$ip:$storage
	elif [[ $hostname_flag = 1 ]]; then
		sudo scp ${sha_userid}.pub $user@$hostname:$storage
	fi
else
	echo "### Did not find 'server_config' file in the current directory. The newly created GPG key is called ${sha_userid}."
fi
