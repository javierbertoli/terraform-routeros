resource "routeros_ip_ssh_server" "ros" {
  # To enable strong_crypto, we need to first comment it,
  # set allow_none_crypto to false and then, revert the comment
  # It's an issue in the provider which, having both set, complains with
  # POST 'http://X.X.X.X/rest/ip/ssh/set' returned response code: 400, message:
  #  'Bad Request', details: 'failure: strong-crypto and allow-none-crypto can't be used at the same time'
  strong_crypto = true
  # allow_none_crypto           = false
  always_allow_password_login = false
  forwarding_enabled          = "no"
  host_key_type               = "ed25519"
}