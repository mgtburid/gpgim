#!/bin/bash

today=$(date +%Y-%m-%d)
wget -m -np -c -R "index.html*" -P ./ ""
[ ! -f message.pgp ] && echo "Error, nothing to read from (message.pgp is absent)." && exit 1
gpg --decrypt message.pgp >& decrypted_messages
cat decrypted_messages >> ${today}_messages_decrypted
rm -f decrypted_messages
