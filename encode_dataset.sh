#!/bin/bash

set -e
set -u
set -o pipefail

export TPM2TOOLS_TCTI="swtpm:host=localhost,port=2321"

mkdir -p docker/encoded_dataset

for file in test_dataset/*; do
	if [ -f "$file" ]; then
		filename="${file##*/}"
		bash encrypt.sh "$file" docker/encoded_dataset/"$filename".enc
	fi
done
