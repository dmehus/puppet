# firewall for all servers
class base::ufw {
    include ::ufw

    ufw::allow { 'ssh':
        proto => 'tcp',
        port  => 22,
    }

    ufw::allow { 'nrpe':
        proto => 'tcp',
        port  => 5666,
    }

    # temp for swift testing with nsf1
    ufw::allow { 'test1 swift':
        ensure => absent,
    }

    file { '/root/ufw-fix':
        ensure => present,
        source => 'puppet:///modules/base/ufw/ufw-fix',
        mode   => '0755',
    }
}
