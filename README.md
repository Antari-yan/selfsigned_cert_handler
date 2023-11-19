## Self-signed certificate handler
This bash script can be use to create and manage one self-signed certificate.

It first checks if the desired certificates public and private key exist.  
Afterwards it checks if the md5 value of both files matches.  
Lastly it checks if the certificate is expired or if a set expiration timestamp has been reached.

Should any of the above checks return an undesired state a new certificate will be created.  
It can be defined where the new certificate should be created and it is recommended to set it to a different directory to prevent any unintended errors.

Currently this script can't handle `private key passphrase`, `subject alt name` and different `provider` beside self-signed.  
Also this script can only handle one certificate.

Using a separate config file to easily reuse the same script would be a good addition in the future.

## Usage
Set the following variables to the desired value:
* Name and path of private key
    * GEN_SSL_CERT_PRIVATE_KEY_NAME
    * GEN_SSL_CERT_PRIVATE_KEY_PATH

* Name and path of public key
    * GEN_SSL_CERT_PUBLIC_KEY_NAME
    * GEN_SSL_CERT_PUBLIC_KEY_PATH

* Temporary directory for the new certificate
    * GEN_SSL_CERT_NEW_CERT_TMP_DIR

* General certificate parameters
    * GEN_SSL_CERT_COUNTRY_NAME
    * GEN_SSL_CERT_STATE_OR_PROVINCE_NAME
    * GEN_SSL_CERT_LOCALITY_NAME
    * GEN_SSL_CERT_ORGANIZATION_NAME
    * GEN_SSL_CERT_ORGANIZATIONAL_UNIT_NAME
    * GEN_SSL_CERT_COMMON_NAME
    * GEN_SSL_CERT_EMAIL_ADDRESS
    * GEN_SSL_CERT_VALID_DAYS
    * GEN_SSL_CERT_RENEWAL_DAY
    * GEN_SSL_CERT_HASH_ALGORITHM

``` bash
# After setting the variables run the script as is:
bash selfsigned_cert_handler.sh
```

``` bash
# Show help:
bash selfsigned_cert_handler.sh -h
```

``` bash
# Force renewal:
bash selfsigned_cert_handler.sh --force
```
