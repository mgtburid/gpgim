#!/bin/bash

today=$(date +%Y-%m-%d)
rm -f message.pgp

# message.txt's contents are ciphered, put into a respective file, and sent
[ $# -eq 0 ] && echo "You did not provide a list of recipients." && exit 1
while [ $# -gt 0 ];
do
	gpg --output message.pgp -r $1 --encrypt --armor message.txt &> .output; if [ ! -f .output ]; then echo "A public key for '$1' is absent." && shift; fi || cat message.pgp >> ${today}_messages; echo "Message was successfully sent to '$1'."
	[[ $(cat .output) == *"skipped: No public key"* ]] && echo "A public key for '$1' is absent."
	shift
done
