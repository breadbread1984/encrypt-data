#!/bin/bash

tpm2_flushcontext -t
tpm2_load -C primary.ctx -u key.pub -r key.priv -c bind_key.ctx
# 解密脚本
FILE=$1
KEY_CTX="bind_key.ctx"  # TPM RSA上下文
DECRYPTED_FILE="${FILE%.tpm_enc}.dec"  # 解密后的文件名

# 分离加密文件和加密密钥
ENCRYPTED_CONTENT="${FILE}.enc"
ENCRYPTED_KEY="${FILE}.rsa_key"
dd if=$FILE bs=256 skip=0 of=$ENCRYPTED_CONTENT
dd if=$FILE bs=256 skip=$(stat -c%s $ENCRYPTED_CONTENT) of=$ENCRYPTED_KEY
echo "here"
# 使用TPM解密AES密钥和IV
tpm2_rsadecrypt -c $KEY_CTX -o session_key.bin $ENCRYPTED_KEY

# 提取AES密钥和IV
AES_KEY=$(head -c 32 session_key.bin | xxd -p -c 32)
IV=$(tail -c 16 session_key.bin | xxd -p -c 16)

# 使用AES密钥和IV解密文件
openssl enc -d -aes-256-cbc -in $ENCRYPTED_CONTENT -out $DECRYPTED_FILE -K $AES_KEY -iv $IV

# 清理临时文件
rm -f session_key.bin $ENCRYPTED_CONTENT $ENCRYPTED_KEY

echo "解密完成：$DECRYPTED_FILE"
