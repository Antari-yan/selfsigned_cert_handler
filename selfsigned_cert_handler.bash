#!/usr/bin/env bash

# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -o errexit  # Exit uppon error. Can be circumvented through adding "|| :" at the end e.g.: false || :
set -o nounset  # Throws error uppon undevined variable usage
set -o pipefail # Throws error when encountering an error within a pipe
#set -x  # Debugging

# Force renewal of certificate (enabled using --force option)
GEN_SSL_CERT_FORCE_RENEWAL=false

# Name and path of private key
GEN_SSL_CERT_PRIVATE_KEY_NAME=private.key
GEN_SSL_CERT_PRIVATE_KEY_PATH=.

# Name and path of public key
GEN_SSL_CERT_PUBLIC_KEY_NAME=public.pem
GEN_SSL_CERT_PUBLIC_KEY_PATH=.

# New certificate will be stored in a temporary directory,
# to prevent overwriting current certificate and failing the renewal, leading to a broken certificate
GEN_SSL_CERT_NEW_CERT_TMP_DIR=/tmp  

# General certificate parameters
GEN_SSL_CERT_COUNTRY_NAME=DE
GEN_SSL_CERT_STATE_OR_PROVINCE_NAME=NRW
GEN_SSL_CERT_LOCALITY_NAME=Cologne
GEN_SSL_CERT_ORGANIZATION_NAME=""
GEN_SSL_CERT_ORGANIZATIONAL_UNIT_NAME=""
GEN_SSL_CERT_COMMON_NAME=*.example.com
GEN_SSL_CERT_EMAIL_ADDRESS=""
GEN_SSL_CERT_VALID_DAYS=90
GEN_SSL_CERT_RENEWAL_DAY=30
GEN_SSL_CERT_HASH_ALGORITHM=sha512

# Concating all certificat parameters (changing may not be needed)
DEFAULT_CERTIFICATE_SUBJECT="/C=$GEN_SSL_CERT_COUNTRY_NAME/ST=$GEN_SSL_CERT_STATE_OR_PROVINCE_NAME/L=$GEN_SSL_CERT_LOCALITY_NAME/O=$GEN_SSL_CERT_ORGANIZATION_NAME/OU=$GEN_SSL_CERT_ORGANIZATIONAL_UNIT_NAME/CN=$GEN_SSL_CERT_COMMON_NAME/emailAddress=$GEN_SSL_CERT_EMAIL_ADDRESS"

# Variables to check current certificate (not to be changed)
GEN_SSL_CERT_PRIVATE_KEY_EXIST=false
GEN_SSL_CERT_PUBLIC_KEY_EXIST=false
GEN_SSL_CERT_GENERATE_NEW_CERT=true

# Missing features
#GEN_SSL_CERT_PRIVATE_KEY_PASSPHRASE=""
#GEN_SSL_CERT_SUBJECT_ALT_NAME=[]
#GEN_SSL_CERT_PROVIDER=selfsigned


function help
{
   # Display Help
   echo "Script to create and manage one self-signed certificate."
   echo
   echo "$FUNCNAME"
   echo "options:"
   echo "-h/--help   Print this Help."
   echo "--force  Force renewal of certificate."
   echo
}

optspec=":hf-:"
while getopts "$optspec" optchar; do
  case "${optchar}" in
    -)
      case "${OPTARG}" in
        help)
          help
          exit 0
          ;;
        force)
          GEN_SSL_CERT_FORCE_RENEWAL=true
          ;;
        *)
          if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
            echo "Unknown option --${OPTARG}" >&2
            exit 1
          fi
          ;;
      esac;;
    h)
      help
      exit 0
      ;;
    *)
      if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
        echo "Non-option argument: '-${OPTARG}'" >&2
        exit 1
      fi
      ;;
  esac
done


echo -e "\x1b[34;20mStarting certificate check\x1b[0m"

if [ "$GEN_SSL_CERT_FORCE_RENEWAL" = true ]; then
  echo -e "\x1b[32;20mForcefully renewing certificate\x1b[0m"
  GEN_SSL_CERT_GENERATE_NEW_CERT=true
else
  # Check if private key exist
  if [ -f $GEN_SSL_CERT_PRIVATE_KEY_PATH/$GEN_SSL_CERT_PRIVATE_KEY_NAME ]; then
    GEN_SSL_CERT_PRIVATE_KEY_EXIST=true
  fi

  # Check if public key exist
  if [ -f $GEN_SSL_CERT_PUBLIC_KEY_PATH/$GEN_SSL_CERT_PUBLIC_KEY_NAME ]; then
    GEN_SSL_CERT_PUBLIC_KEY_EXIST=true
  fi

  # Validate if certificate is complete and valid
  if [ $GEN_SSL_CERT_PRIVATE_KEY_EXIST = true ] && [ $GEN_SSL_CERT_PUBLIC_KEY_EXIST = true ]; then
    # Check the md5 value of both certificate parts
    private_key_md5_value=$(openssl rsa -modulus -in $GEN_SSL_CERT_PRIVATE_KEY_PATH/$GEN_SSL_CERT_PRIVATE_KEY_NAME -noout | openssl md5)
    public_key_md5_value=$(openssl x509 -modulus -in $GEN_SSL_CERT_PUBLIC_KEY_PATH/$GEN_SSL_CERT_PUBLIC_KEY_NAME -noout | openssl md5)

    echo -e "\x1b[34;20m$private_key_md5_value\x1b[0m"
    echo -e "\x1b[34;20m$public_key_md5_value\x1b[0m"

    if [ "$private_key_md5_value" = "$public_key_md5_value" ]; then
      if openssl x509 -checkend $(( $GEN_SSL_CERT_RENEWAL_DAY * 86400 )) -noout -in $GEN_SSL_CERT_PUBLIC_KEY_PATH/$GEN_SSL_CERT_PUBLIC_KEY_NAME # Check is done in seconds (24h*60m*60s+86400)
      then
        echo -e "\x1b[32;20mCertificate is valid for over $GEN_SSL_CERT_RENEWAL_DAY Days\x1b[0m"
        GEN_SSL_CERT_GENERATE_NEW_CERT=false
      else
        echo -e "\x1b[33;20mCertificate is valid for less than $GEN_SSL_CERT_RENEWAL_DAY Days\x1b[0m"
        GEN_SSL_CERT_GENERATE_NEW_CERT=true
      fi
    else
      echo -e "\x1b[31;20mCertificate is invalid\x1b[0m"
      GEN_SSL_CERT_GENERATE_NEW_CERT=true
    fi
  else
    echo -e "\x1b[31;20mCertificate is imcomplete\x1b[0m"
    GEN_SSL_CERT_GENERATE_NEW_CERT=true
  fi
fi


# Generate new certificate
if [ "$GEN_SSL_CERT_GENERATE_NEW_CERT" = true ]; then
  echo -e "\x1b[32;20mGenerating new certificate\x1b[0m"

  echo -e "\x1b[32;20mCreate Private Key in $GEN_SSL_CERT_NEW_CERT_TMP_DIR\x1b[0m"
  openssl genrsa -out $GEN_SSL_CERT_NEW_CERT_TMP_DIR/$GEN_SSL_CERT_PRIVATE_KEY_NAME 4096

  echo -e "\x1b[32;20mCreate Public Key in $GEN_SSL_CERT_NEW_CERT_TMP_DIR\x1b[0m"
  openssl req -x509 -new -nodes -key $GEN_SSL_CERT_NEW_CERT_TMP_DIR/$GEN_SSL_CERT_PRIVATE_KEY_NAME -$GEN_SSL_CERT_HASH_ALGORITHM -days $GEN_SSL_CERT_VALID_DAYS -subj $DEFAULT_CERTIFICATE_SUBJECT -out $GEN_SSL_CERT_NEW_CERT_TMP_DIR/$GEN_SSL_CERT_PUBLIC_KEY_NAME -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName= DNS:$GEN_SSL_CERT_COMMON_NAME"))

  echo -e "\x1b[32;20mMove new certificates from $GEN_SSL_CERT_NEW_CERT_TMP_DIR to $GEN_SSL_CERT_PUBLIC_KEY_PATH\x1b[0m"
  mv $GEN_SSL_CERT_NEW_CERT_TMP_DIR/$GEN_SSL_CERT_PRIVATE_KEY_NAME $GEN_SSL_CERT_PRIVATE_KEY_PATH/$GEN_SSL_CERT_PRIVATE_KEY_NAME
  mv $GEN_SSL_CERT_NEW_CERT_TMP_DIR/$GEN_SSL_CERT_PUBLIC_KEY_NAME $GEN_SSL_CERT_PUBLIC_KEY_PATH/$GEN_SSL_CERT_PUBLIC_KEY_NAME
fi

echo -e "\x1b[34;20mDone\x1b[0m"
