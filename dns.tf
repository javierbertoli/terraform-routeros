resource "routeros_ip_dns" "ros" {
  servers = (try(var.dns.forwarders, "") != ""
    ? local.dns_forwarders
    : null
  )
  allow_remote_requests      = true
  max_concurrent_queries     = 1000
  cache_size                 = var.malicious_contents_filtering.enabled ? 32768 : 20480
  cache_max_ttl              = "5m"
  doh_max_server_connections = local.dns_use_doh ? 100 : null
  doh_max_concurrent_queries = local.dns_use_doh ? 1000 : null
  use_doh_server             = local.dns_use_doh ? local.dns_doh_url : null
  # Requires the CAs in the MK. Check README.md
  # /tool fetch url=https://curl.se/ca/cacert.pem
  # /certificate import file-name=cacert.pem passphrase=””
  verify_doh_cert = local.verify_doh_cert
}

resource "routeros_ip_dns_record" "ros" {
  for_each = try(var.dns.records, {})
  # If key or name ends with ".", use as-is. Else, add domain
  name = (
    endswith(try(each.value.name, each.key), ".")
    ? trim(try(each.value.name, each.key), ".")
    : try("${each.value.name}.${var.domain}", "${each.key}.${var.domain}")
  )
  type    = try(each.value.type, "A")
  address = try(each.value.target, null)
  cname = (
    try(each.value.cname, null) == null
    ? null
    : (
      length(regexall("[.]", each.value.cname)) > 0
      ? each.value.cname
      : "${each.value.cname}.${var.domain}"
    )
  )
  comment = upper("tf - ${lookup(each.value, "comment", each.key)}")
}

resource "routeros_ip_dns_adlist" "ros" {
  for_each   = toset(local.malicious_contents_filtering_urls)
  url        = each.key
  ssl_verify = true
}
