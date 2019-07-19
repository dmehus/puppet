# role: elasticsearch
class role::elasticsearch {
    include ::java

    class { 'elastic_stack::repo':
        version => 6,
    }

    $es_master_node = hiera('role::elasticsearch::master', false)
    $es_data_node = hiera('role::elasticsearch::data_node', false)
    $es_discovery_host = hiera('role::elasticsearch::discovery_host', ['es1.miraheze.org'])

    include ssl::wildcard

    class { 'elasticsearch':
        config => {
            'discovery.seed_hosts' => $es_discovery_host,
            'discovery.zen.ping.unicast.hosts' => $es_discovery_host,
            'cluster.name' => 'Miraheze',
            'node.master' => $es_master_node,
            'node.data' => $es_data_node,
            'network.bind_host' => '0.0.0.0',
            'network.publish_host' => '0.0.0.0',
            'xpack.security.enabled' => true,
            'xpack.security.http.ssl.enabled' => true,
            'xpack.security.transport.ssl.enabled' => true,
            'xpack.security.http.ssl.key' => '/etc/ssl/private/wildcard.miraheze.org.key',
            'xpack.security.http.ssl.certificate' => '/etc/ssl/certs/wildcard.miraheze.org.crt',
            'xpack.security.http.ssl.certificate_authorities' => '/etc/ssl/certs/GlobalSign.crt',
            'xpack.security.transport.ssl.key' => '/etc/ssl/private/wildcard.miraheze.org.key',
            'xpack.security.transport.ssl.certificate' => '/etc/ssl/certs/wildcard.miraheze.org.crt',
            'xpack.security.transport.ssl.certificate_authorities' => '/etc/ssl/certs/wildcard.miraheze.org.crt',
        },
        version => '6.8.1',
    }

    $es_instance = hiera('role::elasticsearch::instance', 'es-01')
    $es_heap = hiera('role::elasticsearch::heap', ['-Xms2g', '-Xmx2g'])

    # https://www.elastic.co/guide/en/elasticsearch/reference/master/heap-size.html
    elasticsearch::instance { $es_instance:
        jvm_options => $es_heap,
        init_defaults => {
            'MAX_OPEN_FILES' => '1500000',
        }
    }

    if $es_master_node {
        nginx::site { 'elasticsearch-lb.miraheze.org':
            ensure      => present,
            source      => 'puppet:///modules/role/elasticsearch/nginx-site.conf',
            monitor     => false,
            notify_site => Exec['nginx-syntax'],
        }

        exec { 'nginx-syntax':
            command     => '/usr/sbin/nginx -t',
            notify      => Exec['nginx-reload'],
            refreshonly => true,
        }

        exec { 'nginx-reload':
            command     => '/usr/sbin/service nginx reload',
            refreshonly => true,
            require     => Exec['nginx-syntax'],
        }

        ufw::allow { 'nginx port misc1':
            proto => 'tcp',
            port  => '443',
            from  => '185.52.1.76',
        }

        ufw::allow { 'nginx port mw1':
            proto => 'tcp',
            port  => '443',
            from  => '185.52.1.75',
        }

        ufw::allow { 'nginx port mw2':
            proto => 'tcp',
            port  => '443',
            from  => '185.52.2.113',
        }

        ufw::allow { 'nginx port mw3':
            proto => 'tcp',
            port  => '443',
            from  => '81.4.121.113',
        }

        ufw::allow { 'nginx port test1':
            proto => 'tcp',
            port  => '443',
            from  => '185.52.2.243',
        }
    }

    ufw::allow { 'elasticsearch data nodes access master node 9300 port (1)':
        proto => 'tcp',
        port  => '9300',
        from  => '168.235.110.5',
    }

    ufw::allow { 'elasticsearch data nodes access master node 9300 port (2)':
        proto => 'tcp',
        port  => '9300',
        from  => '168.235.110.25',
    }

    if $es_data_node {
        ufw::allow { 'elasticsearch master access data nodes 9300 port':
            proto => 'tcp',
            port  => '9300',
            from  => hiera('role::elasticsearch::master_ip')
        }
    }

    sysctl::parameters { 'disable ipv6':
        values   => {
            # Increase TCP max buffer size
            'net.ipv6.conf.all.disable_ipv6 = 1' => 1,
            'net.ipv6.conf.default.disable_ipv6' => 1,
            'net.ipv6.conf.lo.disable_ipv6' => 1,
        },
        priority => 60,
    }
 
    motd::role { 'role::elasticsearch':
        description => 'elasticsearch server',
    }
}
