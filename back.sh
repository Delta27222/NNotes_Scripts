#!/bin/sh

# estas variables pueden ser exportadas en el sh padre con export <VARIABLE>
replicaSet_name="uniRS"
mongo_base_name="dbc"
# y podemos hacer lo mismo para los ciclo for, porque podemos crear mas o menos de 3 contenedores
back_base_name="backc"

echo "running back.sh"
#armamos el uri de mongo usando dbc.lxd
mongo_uri="mongodb://"

for i in $(seq 1 3)
do
  if [ "$i" -lt 3 ]
  then
    #mongo_uri+="${mongo_base_name}:2888,"
    mongo_uri=$(printf "%s%s%s.lxd:2888," "$mongo_uri" "$mongo_base_name" "$i")
  else
    #mongo_uri+="${mongo_base_name}:2888"
    mongo_uri=$(printf "%s%s%s.lxd:2888/" "$mongo_uri" "$mongo_base_name" "$i")
  fi
done

#mongo_uri+="/?replicaSet=${replicaSet_name}"
mongo_uri=$(printf "%s?replicaSet=%s" "$mongo_uri" "$replicaSet_name")
echo "mongo URI: ${mongo_uri}"

for i in $(seq 1 3)
do
  container_name="${back_base_name}${i}"
  # el cloud-config es mas lento
  sudo lxc launch ubuntu:jammy "$container_name" --config cloud-init.user-data="$(cat back.yaml)"
done

  # lxc exec "$container_name" -- sh -c 'cloud-init status --wait'

  # hacemos dos for, para que primero se creen todos los contenedores, y despues se verifique que ya estan listos (asi el cloud initi se ejucuta concurrentemente)
for i in $(seq 1 3)
do
  container_name="${back_base_name}${i}"
  while [ "$(sudo lxc exec "$container_name" -- sh -c 'cloud-init status | grep -oP "status: \K.*"')" != "done" ]
  do
    echo "Esperando por cloud-init..."
    sleep 6
  done

  sudo lxc exec "$container_name" -- bash -c "cd /opt/app/myapp && echo PORT=3000 > .env && echo DB_URI=$mongo_uri >> .env "

  echo "creando servicio para correr backend en $container_name..."
  # Create the systemd service file
  sudo lxc exec "$container_name" -- bash -c "echo '[Unit]
Description=My Express TS Backend
After=network.target

[Service]
ExecStart=/usr/bin/npm run dev
WorkingDirectory=/opt/app/myapp
User=nobody
Group=nogroup
Restart=always

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/myapp.service"

  sudo lxc exec "$container_name" -- bash -c "systemctl enable myapp && systemctl start myapp"

  echo "backend $container_name listo!"

  # echo "========== Agregando configuraci\u00f3n para puerto $((3000)) ..."
  # lxc config device add container_name puerto$((3000)) proxy listen=tcp:0.0.0.0:$((3000)) connect=tcp:127.0.0.1:$((3000))
done