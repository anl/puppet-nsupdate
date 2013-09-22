# == Class: nsupdate
#
# Full description of class nsupdate here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { nsupdate:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
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

  ensure_packages(['wget'])

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
    command => "/usr/bin/wget ${url}",
    cwd     => $install_dir,
    require => File[$install_dir],
    unless  => "/usr/bin/shasum -a 256 ${file_path} | /bin/grep ${checksum}",
  }

  if $on_boot {
    rclocal::register { 'nsupdate':
      content => template('nsupdate/rc.local.fragment.erb')
    }
  }
}
