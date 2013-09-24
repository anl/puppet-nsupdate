# == Class: nsupdate
#
# Deploy infrastructure for a node to update its DNS record using nsupdate.
#
# === Parameters
#
# [*base_url*]
#   Base of the URL from which nsupdate wrapper script should be downloaded.
#   Should not have a trailing slash ("/").
#
# [*checksum*]
#   SHA256 checksum of nsupdate wrapper script.
#
# [*install_path*]
#   Top-level directory under which wrapper script will be installed; defaults
#   to /opt/nsupdate.
#
# [*key_contents*]
#   Contents of the dnssec key file used by the "nsupdate" binary.  Default
#   of an empty string will cause updates to fail - populating this is
#   mandatory for intended functionality.
#
# [*keyfile*]
#   Path to dnssec key file used by the "nsupdate" binary.  Must be set; note
#   that file name is important for nsupdate to function correctly - e.g. must
#   be something similar to
#   "/root/Kec2-puppet.dyn.hurricane-ridge.com.+157+10777.key" - cannot simply
#   be "/root/nsupdate.key".
#
# [*nameserver*]
#   DNS server to which updates will be sent.  Must be a valid domain name.
#
# [*on_boot*]
#   If true (default), update DNS record on boot via /etc/rc.local.
#
# [*rr*]
#   DNS Resource Record to update; must be a valid domain name.
#
# [*ttl*]
#   TTL for RR that will be updated; default: 120s.
#
# [*shasum_pkg*]
#   Package that includes "shasum" binary; defaults to "perl" for Ubuntu
#   compatibility.
#
# [*version*]
#   Version of nsupdate wrapper script to download; used in constructing
#   download URL; default: 0.1.0.
#
# [*zone*]
#   DNS zone to which updates should be applied; must be a valid domain name.
#
# === Examples
#
# class  { 'nsupdate':
#   key_contents => 'dyn.example.com. IN KEY 512 3 157 WXakPayhg7tqS15w5wPdaVWQ+DpM19qHKQ272B5O6W4zPb1UtgqG/9xBOumVdkL8MnML2D/xh+fY3b9WApZrUA==',
#   keyfile      => '/root/Kdyn.example.com.+157+10777.key',
#   nameserver   => 'ns.example.com',
#   rr           => 'host.example.com',
#   zone         => 'example.com',
# }
#
# === Authors
#
# Andrew Leonard
#
# === Copyright
#
# Copyright 2013 Andrew Leonard
#
class nsupdate(
  $base_url = 'https://raw.github.com/anl/nsupdate-wrapper', # no trailing '/'
  $checksum = '7dd37d2d6ce6bfe306e2a1e777a25e285210ebd302ee8149654570e6fb5e37bb',
  $file_name = 'do_nsupdate.sh',
  $install_path = '/opt/nsupdate', # no trailing '/'
  $key_contents = '',
  $keyfile = false,
  $nameserver = '',
  $on_boot = true,
  $rr = '',
  $ttl = 120,
  $shasum_pkg = 'perl',
  $version = '0.1.0',
  $zone = ''
  ) {

  ensure_packages([$shasum_pkg, 'wget'])

  unless is_string($keyfile) {
    fail('Invalid keyfile path')
  }

  unless is_domain_name($nameserver) {
    fail('Invalid nameserver')
  }

  unless is_domain_name($rr) {
    fail('Invalid RR to update')
  }

  unless is_integer($ttl) {
    fail('Invalid TTL')
  }

  unless is_domain_name($zone) {
    fail('Invalid zone')
  }

  $install_dir = "${install_path}/bin"
  $file_path = "${install_dir}/${file_name}"
  $url = "${base_url}/${version}/${file_name}"

  file { $install_path:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
  }

  file { $install_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    require => File[$install_path],
  }

  exec { "download ${file_name}":
    command => "/usr/bin/wget ${url} && chmod 555 ${file_name}",
    cwd     => $install_dir,
    require => File[$install_dir],
    unless  => "/usr/bin/shasum -a 256 ${file_path} | /bin/grep ${checksum}",
  }

  file { $keyfile:
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $key_contents,
  }

  if $on_boot {
    rclocal::register { 'nsupdate':
      content => template('nsupdate/rc.local.fragment.erb')
    }
  }
}
