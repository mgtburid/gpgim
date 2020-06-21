#!/bin/bash

filestack=$(pwd)/gpgim_files

read -p "How the key should be indentified: "  userid
read -p "For how long key is supposed to be valid (default is never; use shortings from man gpg i.e. 1w = 1 week): " expire

# set expiration date to never if no input provided
[ -z $expire ] && expire="never"

# write gpg output to a hidden file
gpg --quick-generate-key $userid default default $expire &> $filestack/.output

# if provided userid already exists, its information is printed, file is deleted, and script stops
if [[ $(cat $filestack/.output) == *"already exists"* ]]; then rm -f $filestack/.output && echo "Userid '$userid' already exists. Delete a respective key or come up with a new userid value." && gpg --list-keys $userid | tail -5 && exit 1; fi

# the filename of the public key: userid+YYYY-Mon-Day-HH-MM-SS in SHA1
sha_userid=$(echo -n ${userid}_$(date +%Y-%m-%d-%H-%M-%S) | openssl dgst -sha1 | cut -d " " -f2)
gpg --armor --export $userid > $filestack/${sha_userid}.pub

# server configuration part
if [[ -f server_config ]]; then	
	for i in {1..5}
	do
		config_value=$(grep -v "#" server_config | awk "NF" | cut -d "=" -f2 | awk "NR==$i")
		srv_config+=( $config_value )
	done
	for var in ${srv_config[@]}
	do
		[[ $var != "0" ]] && score+=1 || score+=0
	done
	echo "Score is $score"
	if [[ $score = "00000" ]]; then
		echo "### Check the configuration in 'server_config', looks like all variables are set to 0. The newly created GPG key is called ${sha_userid}." && exit 1
	else
		for i in $(seq 0 ${#score}); do
			# no username = abort of the operation
			if [[ $i = 0 ]]; then
				[[ ${score:$i:1} = "0" ]] && echo "### No username provided in 'server_config'. The newly created GPG key is called ${sha_userid}." && exit 1
				[[ ${score:$i:1} != "0" ]] && user=${srv_config[$i]}
			# no IP && no hostname = abort of the operation
			elif [[ $i = 2 && ${score:$i:1} = "0" ]] && [[ $i = 1 && ${score:$i:1} = "0" ]]; then
				echo "### Neither an IP address, nor a hostname were provided in 'server_config'. The newly created GPG key is called ${sha_userid}." && exit 1
			# hostname available = hostname flag is set to 1
			elif [[ $i = 1 && ${score:$1:1} != "0" ]]; then
				hostname_flag=1
				hostname=${srv_config[$i]}
			# overriding hostname flag
			elif [[ $i = 2 ]]; then
				# hostname set but IP is not = hostname flag is set to 1
				[[ ${score:$(( $i-1 )):1} = "0" && ${score:$i:1} != "0" ]] && echo "### IP is set in 'server_config', hostname is not." && ip=${srv_config[$i]} ip_flag=1 && hostname_flag=0 && continue
				[[ ${score:$(( $i-1 )):1} != "0" && ${score:$i:1} = "0" ]] && echo "### Hostname is set in 'server_config', IP is not." && ip_flag=0 && hostname_flag=1
			# private key availability
			elif [[ $i = 3 ]]; then
				[[ ${score:$i:1} = "0" ]] && privkey_flag=0 && echo "### SSH key was not found, proceeding without it."
				[[ ${score:$i:1} != "0" ]] && privkey=${srv_config[$i]} && privkey_flag=1 && echo "### SSH key was found."
			elif [[ $i = 4 ]]; then
				[[ ${score:$i:1} = "0" ]] && echo "### The script does not know where to store the GPG key on the server, check the configuration in 'server_config'. The newly created GPG key is called ${sha_userid}." && exit 1
				[[ ${score:$i:1} != "0" ]] && echo "### Rendezvous directory received." && storage=${srv_config[$i]} && storage_flag=1
			fi
		done
	fi
	if [[ $ip_flag = 1 && $privkey_flag = 1 ]]; then
		sudo scp -i $privkey $filestack/${sha_userid}.pub $user@$ip:$storage
		# this is how other files will know how to access messages and keys via SCP
		echo "$privkey $user@$ip:$storage" > $filestack.Rendezvous
	elif [[ $hostname_flag = 1 && $privkey_flag = 1 ]]; then
		sudo scp -i $pivkey $filestack/${sha_userid}.pub $user@$hostname:$storage
		echo "$privkey $user@$hostname:$storage" > $filestack/.Rendezvous
	elif [[ $ip_flag = 1 ]]; then
		sudo scp $filestack/${sha_userid}.pub $user@$ip:$storage
		echo "$privkey $user@$ip:$storage" > $filestack/.Rendezvous
	elif [[ $hostname_flag = 1 ]]; then
		sudo scp $filestack/${sha_userid}.pub $user@$hostname:$storage
		echo "$privkey $user@$hostname:$storage" > $filestack/.Rendezvous
	fi
else
	echo "### Did not find 'server_config' file in the current directory. The newly created GPG key is called ${sha_userid}."
fi
