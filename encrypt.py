#!/usr/bin/python3

from absl import flags, app
from os import urandom
import tpm2_pytss as tpm
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.asymmetric import rsa, padding

FLAGS = flags.FLAGS

def add_options():
  flags.DEFINE_string('pub', default = 'key.pub', help = 'path to public key')
  flags.DEFINE_string('priv', default = 'key.priv', help = 'path to private key')
  flags.DEFINE_string('input', default = None, help = 'path to file to encrypt')
  flags.DEFINE_string('output', default = 'output.enc', help = 'path to output crypted file')

def main(unused_argv):
  with open('key.pub', 'rb') as f:
    pub_key = serialization.load_pem_public_key(f.read())
  aes_key = urandom(32)
  encrypted_aes_key = pub_key.encrypt(
    aes_key,
    padding.OAEP(
      mgf = padding.MGF1(algorithm = hashes.SHA256()),
      algorithm = hashes.SHA256(),
      label = None
    )
  )
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

