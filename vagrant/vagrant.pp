# Include this module
include rclocal

class { 'nsupdate':
  key_contents => 'abc123',
  keyfile      => '/root/nsupdate.key',
  nameserver   => 'ns.example.com',
  rr           => 'host.example.com',
  zone         => 'example.com',
}

