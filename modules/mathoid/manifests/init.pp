# == Class: mathoid

class mathoid {
    include nodejs

    group { 'mathoid':
        ensure => present,
    }

    user { 'mathoid':
        ensure     => present,
        gid        => 'mathoid',
        shell      => '/bin/false',
        home       => '/srv/mathoid',
        managehome => false,
        system     => true,
    }

    git::clone { 'mathoid_deploy':
        ensure             => present,
        directory          => '/srv/mathoid',
        origin             => 'https://github.com/wikimedia/mathoid.git',
        branch             => 'master',
        owner              => 'mathoid',
        group              => 'mathoid',
        mode               => '0755',
        timeout            => '550',
        recurse_submodules => true,
        require            => [User['mathoid'], Group['mathoid']],
    }

    require_package(['librsvg2-dev', 'g++''])

    file { '/etc/mediawiki':
        ensure => directory,
    }

    file { '/etc/mediawiki/mathoid':
        ensure  => directory,
        require => File['/etc/mediawiki'],
    }

    file { '/etc/mediawiki/mathoid/config.yaml':
        ensure  => present,
        source  => 'puppet:///modules/mathoid/config.yaml',
        require => File['/etc/mediawiki/mathoid'],
        notify  => Service['mathoid'],
    }

    file { '/var/log/mathoid':
        ensure  => directory,
        owner   => 'mathoid',
        group   => 'mathoid',
        require => [User['mathoid'], Group['mathoid']],
    }

    exec { 'mathoid reload systemd':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
    }

    file { '/etc/systemd/system/mathoid.service':
        ensure => present,
        source => 'puppet:///modules/mathoid/mathoid.systemd',
        notify => Exec['mathoid reload systemd'],
    }

    service { 'mathoid':
        ensure    => running,
        require   => [
            File['/etc/systemd/system/mathoid.service'],
            Git::Clone['mathoid_deploy'],
        ],
    }

    logrotate::conf { 'mathoid':
        ensure => present,
        source => 'puppet:///modules/mathoid/logrotate.conf',
    }
}
