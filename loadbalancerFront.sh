#!/bin/sh

# front_lb_base_name="frontlb"
# front_base_name="front-"

# sudo lxc launch ubuntu:jammy "$front_lb_base_name" #--config cloud-init.user-data="$(cat lb.yaml)"

echo "Instalando nginx en frontend load balancer"
sudo lxc exec "$front_lb_base_name" -- apt update > /dev/null 2>&1
sudo lxc exec "$front_lb_base_name" -- apt install nginx -y > /dev/null 2>&1
sudo lxc exec "$front_lb_base_name" -- cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf__bak

nginx_conf="./nginx.conf"

# Escribir el NGINX config file
cat << EOF > "$nginx_conf"
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
events {
worker_connections 768;
# multi_accept on;
}
http {
upstream myapp1 {
EOF
# Iteramos por los frontend para agregarlos en el pool
for i in $(seq 1 3) 
do
  echo "server $front_base_name$i.lxd:300$i max_fails=3 fail_timeout=30s;" >> "$nginx_conf"
done
echo "}" >> "$nginx_conf"
cat << EOF >> "$nginx_conf"
server {
listen 80;
location / {
proxy_pass http://myapp1;
}
}
}
EOF

# pasamos el archivo de config al contenedor
sudo lxc file push "$nginx_conf" "$front_lb_base_name"/etc/nginx/nginx.conf
rm "$nginx_conf"
sudo lxc exec "$front_lb_base_name" -- systemctl restart nginx

# Modificando DNS local
echo "Modificando DNS local..."
echo "$(lxc list | grep "$front_lb_base_name" | awk '{print $6}' ) nnotes.local" | sudo tee -a /etc/hosts
echo "=================================================="
echo "Frontend Load Balancer configurado en nnotes.local"