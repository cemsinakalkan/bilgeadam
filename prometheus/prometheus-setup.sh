#!/bin/bash
#
/usr/bin/apt install net-tools

# prometheus user and group create
groupadd prometheus
useradd -s /sbin/nologin --system -g prometheus prometheus

# Prometheus installation

curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -qi -

tar xvf prometheus*.tar.gz

mkdir /var/lib/prometheus
for i in rules rules.d files_sd; do sudo mkdir -p /etc/prometheus/${i}; done

cd prometheus-*/

mv prometheus promtool /usr/local/bin/

mv prometheus.yml /etc/prometheus/prometheus.yml
mv consoles/ console_libraries/ /etc/prometheus/


#systemd servisinin olusturulmasi
cat > /etc/systemd/system/prometheus.service <<EOD
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target
[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/prometheus \
--config.file=/etc/prometheus/prometheus.yml \
--storage.tsdb.path=/var/lib/prometheus \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries \
--web.listen-address=0.0.0.0:9090 \
--web.external-url=
SyslogIdentifier=prometheus
Restart=always
[Install]
WantedBy=multi-user.target
EOD


# Dosya erisim haklarinin duzenlenmesi

for i in rules rules.d files_sd; do sudo chown -R prometheus:prometheus /etc/prometheus/${i}; done
for i in rules rules.d files_sd; do sudo chmod -R 775 /etc/prometheus/${i}; done
chown -R prometheus:prometheus /var/lib/prometheus/

systemctl daemon-reload

#systemctl enable prometheus
systemctl start prometheus



##Grafana installation
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"

sudo apt update

sudo apt install grafana -y

sudo systemctl start grafana-server



#consul installation
#
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install consul


consul keygen > /etc/consul.d/consul.keygen

consul_key=$(cat /etc/consul.d/consul.keygen)

#consul hcl edit
cat > /etc/consul.d/consul.hcl << EOD
bootstrap_expect = 1
server = true
data_dir = "/opt/consul"
log_level = "INFO"
client_addr = "0.0.0.0"
bind_addr = "192.168.20.101"
node_name = "consul"
leave_on_terminate = true
rejoin_after_leave = true
connect{
        enabled = true
}
ui_config{
        enabled = true
}
encrypt = "$consul_key"

EOD


#consul systemd servisinin olusturulmasi
cat > /etc/systemd/system/consul.service <<EOD
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
EnvironmentFile=-/etc/consul.d/consul.env
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOD

# Change consul directories permissions
chown -R consul:consul /opt/consul
chown -R consul:consul /etc/consul.d

# Enable consul service
systemctl enable consul.service
service consul start

