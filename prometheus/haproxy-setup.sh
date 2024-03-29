#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 haproxy_priority" >&2
  exit 1
fi

/usr/bin/apt install net-tools

# Install haproxy
/usr/bin/apt-get install --no-install-recommends software-properties-common -y
/usr/bin/add-apt-repository ppa:vbernat/haproxy-2.8 -y
/usr/bin/apt-get -y install haproxy=2.8.\*

#/usr/bin/apt-get update

/usr/bin/apt-get -y install keepalived

# Configure haproxy
cat > /etc/default/haproxy <<EOD
# Set ENABLED to 1 if you want the init script to start haproxy.
ENABLED=1
# Add extra flags here.
#EXTRAOPTS="-de -m 16"
EOD
cat > /etc/haproxy/haproxy.cfg <<EOD
global
    log 127.0.0.1   local0
    log 127.0.0.1   local1 notice
    daemon
    maxconn 256

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    retries 3
    option redispatch
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend http-in
    bind *:80
    default_backend webservers

backend webservers
    mode http
    stats enable
    stats auth admin:admin
    stats uri /haproxy?stats
    stats admin if TRUE
    balance roundrobin
    balance roundrobin
    # Poor-man's sticky
    # balance source
    # JSP SessionID Sticky
    # appsession JSESSIONID len 52 timeout 3h
    option httpchk GET /
    option forwardfor
    option http-server-close
    server web1 192.168.20.11:80 maxconn 32 check
    server web2 192.168.20.12:80 maxconn 32 check
EOD

cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
/usr/sbin/service haproxy restart


cat >> /etc/sysctl.conf <<EOD 
net.ipv4.ip_nonlocal_bind=1
EOD
sysctl -p


cat > /etc/keepalived/keepalived.conf <<EOD
vrrp_script chk_haproxy {           # Requires keepalived-1.1.13
        script "killall -0 haproxy"     # cheaper than pidof
        interval 2                      # check every 2 seconds
        weight 2                        # add 2 points of prio if OK
}

vrrp_instance VI_1 {
        interface enp0s8
        state MASTER
        virtual_router_id 51
        priority $1
        virtual_ipaddress {
            192.168.20.2
        }
        track_script {
            chk_haproxy
        }
}
EOD

/etc/init.d/keepalived restart



#install node_exporter
#
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz

tar -xf node_exporter-1.7.0.linux-amd64.tar.gz

sudo mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin

rm -r node_exporter-1.7.0.linux-amd64*

sudo useradd -rs /bin/false node_exporter

cat > /etc/systemd/system/node_exporter.service <<EOD
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOD

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
sudo systemctl status node_exporter
