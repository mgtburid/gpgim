# gpgim
GPGIM (gee-pee-Jim) is a messaging solution based on GPG and the communication medium setup by the users.

## Installation
```
mkdir gpgim
git clone https://github.com/mgtburid/gpgim gpgim
cd gpgim; bash install.sh
```
If for some reason ```install.sh``` fails, make sure you have _gnupg2_ and _openssl_ installed on your machine - these are the only dependencies. Additionally, create a _gpgim_files_ directory in the folder you are going to run GPGIM from.

## Description
The program is currently in the Alpha stage and some features are not yet available. Bash only.

The work principle is the following:
1. User configures a file called ```server_config``` as per their Rendezvous' configuration.
2. User generates a GPG key by running ```pubkey.sh``` that is going to be used in the communication. This key is sent to Rendezvous.
3. User generates and encrypts a message using the previously created key, which is done by running ```send.sh``` as ```bash send.sh key-name```. Note that the message is going to be generated from a file called ```message.txt``` in the same folder that ```send.sh``` is run from. This message is also sent to Rendezvous.
4. User runs ```read.sh``` which downloads the message (or both the message and a key for it) and decrypts it.

All files GPGIM generates or downloads are stored in the ```gpgim_files``` directory. Files that the user is running are one layer higher of the said directory.

## Terminology
**Rendezvous** is a server in between both parties that is storing all files (keys and messages) users exchange in the process of communication. Make sure files are stored in a place where _wget_ can get them from.

## TODO
With ascending complexity:
- [x] Make sure server_config notes make sense and reflect the program algorithm.
- [x] Make sure ```read.sh``` downloads necessary files from the place configured by the user. Optionally, consider if it is worth to replace _wget_ with _scp_.
- [x] Make sure there is support for multiple files and the script can actually distinguish between a GPG key and a message.
- [x] Figure out the problem with _scp_ downloading entire Rendezvous folder instead of files inside of it.
- [ ] Write (cron and PHP) a script that is going to delete GPG keys upon them being downloaded from Rendezvous. Same applies to regular messages, which are also supposed to be purged every 24 hours.
