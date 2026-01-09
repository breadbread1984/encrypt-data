#!/bin/bash

set -e          # 命令失败退出（推荐）
set -u          # 未定义变量退出
set -o pipefail # 管道中任一命令失败退出

PRIMARY_KEY=/run/secrets/tpm2_primary_key
PUBLIC_KEY=/run/secrets/tpm2_public_key
PRIVATE_KEY=/run/secrets/tmp2_private_key

tpm2_flushcontext -t
tpm2_load -C ${PRIMARY_KEY} -u ${PUBLIC_KEY} -r ${PRIVATE_KEY} -c bind_key.ctx

# 解密脚本
FILE=$1
DEC_FILE=$2
KEY_CTX="bind_key.ctx"  # TPM RSA上下文

# 分离加密文件和加密密钥
ENCRYPTED_CONTENT="${FILE}.enc"
ENCRYPTED_KEY="${FILE}.rsa_key"
RSA_SIZE=256  # Confirm: tpm2_readpublic -c bind_key.ctx | openssl rsa -pubin -modulus | wc -c
TOTAL_SIZE=$(stat -c %s "$FILE")
ENC_SIZE=$((TOTAL_SIZE - RSA_SIZE))
dd if="$FILE" of=$ENCRYPTED_CONTENT bs=1 count="$ENC_SIZE" status=none
dd if="$FILE" of=$ENCRYPTED_KEY bs=1 skip="$ENC_SIZE" status=none

# 使用TPM解密AES密钥和IV
tpm2_rsadecrypt -c $KEY_CTX -o session_key.bin $ENCRYPTED_KEY

# 提取AES密钥和IV
AES_KEY=$(head -c 32 session_key.bin | xxd -p -c 32)
IV=$(tail -c 16 session_key.bin | xxd -p -c 16)

# 使用AES密钥和IV解密文件
openssl enc -d -aes-256-cbc -in $ENCRYPTED_CONTENT -out ${DEC_FILE} -K $AES_KEY -iv $IV

# 清理临时文件
rm -f session_key.bin $ENCRYPTED_CONTENT $ENCRYPTED_KEY

tpm2_flushcontext -t
