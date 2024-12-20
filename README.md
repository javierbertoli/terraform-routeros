# terraform-routeros
A terraform project to manage MikroTik routers through their APIs

## Initial configuration

```
export HOST=your_host_ip_or_fqdn
export USER=your_mk_user_initially_admin

# Enable SSL API
ssh ${USER}@${HOST} "/ip/service/enable api"      # Initially unencrypted, until you setup SSL
ssh ${USER}@${HOST} "/ip/service/enable api-ssl"  # With SSL
# If you want to enable from just an specific IP
# ssh ${USER}@${HOST} /ip/service/set api-ssl disabled=no address=www.xxxx.yyy.zzz/32

# To use Letsencrypt certs, you need to import the CAs in your MK
ssh ${USER}@${HOST} "/tool fetch url=https://curl.se/ca/cacert.pem"
ssh ${USER}@${HOST} "/certificate import file-name=cacert.pem passphrase=\"\""
```

## Examples
Check in the [examples directory](./examples) how to configure the different resources.

## TODO
* Add documentation
* Import the initial values from a default configuration, so it's easier to apply on a newly installed MK
* Lots of other stuff :)
