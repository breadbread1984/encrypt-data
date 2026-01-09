#!/bin/bash

set -e
set -u
set -o pipefail

mkdir -p docker/encoded_dataset

for file in test_dataset/*; do
  if [ -f "$file" ]; then
    filename="${file##*/}"
    bash encrypt.sh "$file" docker/encoded_dataset/"$filename".enc
  fi
done
