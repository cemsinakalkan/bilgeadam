#!/bin/bash


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


cat > /etc/application.py <<EOD
import http.server
import socketserver
from http import HTTPStatus


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(HTTPStatus.OK)
        self.end_headers()
        self.wfile.write(b'Python Application Server Hostname: $HOSTNAME ')


httpd = socketserver.TCPServer(('', 8000), Handler)
httpd.serve_forever()
EOD

nohup python3 server.py </dev/null &>/dev/null &
