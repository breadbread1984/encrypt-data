# Introduction

This project demos how to encrypt golden data in docker

# Usage

## 1. Install prerequisite packages

### If you develop on bare metal platform

```shell
sudo apt install tpm2-tools libtss2-dev pkg-config
```

### If you develop on a virtual platform (VM or wsl2)

```shell
sudo apt install swtpm swtpm-tools tpm2-tools libtpms0 tpm2-abrmd libtss2-dev pkg-config
```

launch emulator

```shell
mkdir -p /tmp/mytpm
sudo swtpm_setup --tpmstate /tmp/mytpm --tpm2 --overwrite \
  --create-ek-cert \
  --create-platform-cert \
  --logfile /tmp/mytpm/swtpm.log \
  --log level=10
sudo swtpm socket --tpmstate dir=/tmp/mytpm --tpm2 --server type=tcp,port=2321 --ctrl type=tcp,port=2322 --flags not-need-init,startup-clear
```

the above commands will block the terminal, open another terminal to start up tpm

```
export TPM2TOOLS_TCTI="swtpm:host=localhost,port=2321"
tpm2_startup -c
```

test tpm2 with

```shell
tpm2_getrandom --hex 4
```

stop emulator (after development)

```shell
ps -aux | grep swtpm
kill -SIGTERM <PID>
```

## 2. create key pair

### create primary key and key pair

```shell
tpm2_flushcontext -t
tpm2_createprimary -C o -g sha256 -G rsa -c primary.ctx
tpm2_create -G rsa -u key.pub -r key.priv -C primary.ctx -a "fixedtpm|fixedparent|sensitivedataorigin|userwithauth|decrypt" -c bind_key.ctx
```

note that value given to **-a** of **tpm2_create** must match the attribute value output by **tpm2_createprimary**

### encrypt golden data with key pair

```shell
bash encrypt.sh <path/to/plaintext> <path/to/ciphertext>
```

upon running successfully, a file with extension **.enc** appears. it is the cipher of the golden data

### decrypt golden data with key pair

```shell
bash decrypt.sh <path/to/ciphertext> <path/to/plaintext>
```

## 
