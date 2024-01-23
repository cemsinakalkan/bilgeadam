#!/bin/bash

# Install nginx
/usr/bin/apt-get update
/usr/bin/apt-get install net-tools


/usr/bin/apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring -y

/usr/bin/curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
| sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null


echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list



echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
    | sudo tee /etc/apt/preferences.d/99nginx



/usr/bin/apt update
/usr/bin/apt install nginx

#/usr/bin/apt-get -y install nginx



cat > /usr/share/nginx/html/index.html <<EOD
<html><head><title>${HOSTNAME}</title></head><body><h1>${HOSTNAME}</h1>
<p>This is the default web page for ${HOSTNAME}.</p>
</body></html>
EOD

# Log the X-Forwarded-For
#perl -pi -e  's/^LogFormat "\%h (.* combined)$/LogFormat "%h %{X-Forwarded-For}i $1/' /etc/apache2/apache2.conf

systemctl start nginx 
#/usr/sbin/service apache2 restart

