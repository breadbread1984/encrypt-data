# Introduction

This project demos how to encrypt golden data in docker

# Usage

## If your develop on a virtual platform (VM or wsl2) Install TPM emulator if you develop on virtual platform

```shell
sudo apt swtpm swtpm-tools
```

## Install prerequisite packages

### If you develop on bare metal platform

```shell
sudo apt install tpm2-tools
```

### If you develop on a virtual platform (VM or wsl2)

```shell
sudo apt install swtpm swtpm-tools tpm2-tools libtpms0 tpm2-abrmd
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

## create bind key

```shell
tpm2_flushcontext -t
tpm2_createprimary -C o -g sha256 -G rsa -c primary.ctx
tpm2_create -G rsa -u key.pub -r key.priv -C primary.ctx -a "fixedtpm|fixedparent|sensitivedataorigin|userwithauth|restricted|decrypt" -c bind_key.ctx
```

note that value given to **-a** of **tpm2_create** must match the attribute value output by **tpm2_createprimary**


