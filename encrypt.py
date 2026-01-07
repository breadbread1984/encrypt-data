#!/usr/bin/python3

from absl import flags, app
from os import urandom
import tpm2_pytss as tpm
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

FLAGS = flags.FLAGS

def add_options():
  flags.DEFINE_string('pub', default = 'key.pub', help = 'path to public key')
  flags.DEFINE_string('input', default = None, help = 'path to file to encrypt')
  flags.DEFINE_string('output', default = 'output.enc', help = 'path to output crypted file')
  flags.DEFINE_boolean('swtpm', default = False, help = 'whether use emulator')

def main(unused_argv):
  with open(FLAGS.pub, 'rb') as f:
    pub_data = f.read()
  if FLAGS.swtpm:
    esys_ctx = tpm.ESAPI(tcti = "mssim:host=127.0.0.1:2322")
  else:
    esys_ctx = tpm.ESAPI()
  key_handle = esys_ctx.load_external(tpm.TPM2B_PUBLIC.unmarshal(pub_data), tpm.ESYS_TR.NONE)

  aes_key = urandom(32)
  encrypted_aes_key = esys_ctx.RSA_Encrypt(
    key_handle, aes_key,
    scheme = tpm.TPMT_RSA_SCHEME(scheme = tpm.TPM2_ALG.OAEP),
    label = b""
  )[1]
  iv = urandom(12)
  cipher = Cipher(algorithms.AES(aes_key), modes.GCM(iv))
  encryptor = cipher.encryptor()

  # encrypt
  with open(FLAGS.input, 'rb') as f:
    data = f.read()
  ct = encryptor.update(data) + encryptor.finalize()
  tag = encryptor.tag

  # save code
  with open(FLAGS.output, 'wb') as f:
    f.write(encrypted_aes_key + iv + ct + tag)

if __name__ == "__main__":
  add_options()
  app.run(main)

