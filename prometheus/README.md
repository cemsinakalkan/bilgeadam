Vagrant File in bulundugu dizinde 

vagrant ssh web1
vagratn ssh app1 

seklinde ssh yapabilirsiniz.

###################################################################
IP adresleri , asagidaki kayıtları host dosyanıza ekleyin.
##################################################################
192.168.20.2  virtualip.com
192.168.20.9  haproxy1.com
192.168.20.10 haproxy2.com
192.168.20.11 web1.com
192.168.20.12 web2.com
192.168.20.21 app1.com
192.168.20.22 app2.com
192.168.20.101 lab.prometheus.com lab.grafana.com lab.consul.com

#################################################################
Uygulama Portları
################################################################
prometheus port  9090
grafana port     3000
consul arayüz    8500
web1 (nginx)     80
web2 (nginx)     80
app1 (python)    8000
app2 (python)    8000
node-exporter    9100

######################################################################


prometheus check config


promtool check config  /etc/prometheus/prometheus.yml

#####################################################################
