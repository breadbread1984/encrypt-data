#!/bin/bash

set -e
set -u
set -o pipefail

# setup swtpm
mkdir -p /run/swtpm
mkdir -p /tmp/mytpm
swtpm_setup --tpmstate /tmp/mytpm --tpm2 --overwrite \
  --create-ek-cert \
  --create-platform-cert \
  --logfile /tmp/mytpm/swtpm.log \
  --log level=10
swtpm socket --tpmstate dir=/tmp/mytpm --tpm2 --server type=tcp,port=2321 --ctrl type=tcp,port=2322 --flags not-need-init,startup-clear &
# wait for swtpm service's ready
sleep 5
tpm2_startup -c

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
