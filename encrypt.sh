#!/bin/bash

set -e          # 命令失败退出（推荐）
set -u          # 未定义变量退出
set -o pipefail # 管道中任一命令失败退出

tpm2_flushcontext -t
tpm2_load -C primary.ctx -u key.pub -r key.priv -c bind_key.ctx

FILE=$1
KEY_CTX="bind_key.ctx"  # 你的TPM RSA上下文
AES_KEY=$(openssl rand -hex 32)  # 32字节AES-256密钥
IV=$(openssl rand -hex 16)       # 16字节IV

# AES加密文件（CBC模式）
echo -n $IV | xxd -r -p > iv.bin
echo -n $AES_KEY | xxd -r -p > aes.key

openssl enc -aes-256-cbc -in $FILE -out ${FILE}.enc -K $AES_KEY -iv $IV

# RSA加密AES密钥+IV（总<512字节）
cat aes.key iv.bin > session_key.bin
tpm2_rsaencrypt -c $KEY_CTX -o ${FILE}.rsa_key session_key.bin

# 打包
cat ${FILE}.enc ${FILE}.rsa_key > ${FILE}.tpm_enc
rm -rf *.bin ${FILE}.enc ${FILE}.rsa_key aes.key iv.bin
tpm2_flushcontext -t
