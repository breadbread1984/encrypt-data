#!/bin/bash

set -e
set -u
set -o pipefail

# decode trainset
mkdir -p /tmp/decrypted/decoded_dataset
for file in /app/encoded_dataset/*; do
	if [ -f "$file" ]; then
		filename="${file##*/}"
		bash decrypt.sh "$file" /tmp/decrypted/decoded_dataset/"${filename%.*}"
	fi
done

# block container from death
tail -f /dev/null
