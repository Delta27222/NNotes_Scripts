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
  sudo lxc launch ubuntu:jammy "$container_name" --config cloud-init.user-data="$(cat back.yaml)"

  # podemos buscar las ip de las bases de datos podemos usar lxc list, o creamos un txt en el sh de mongo, y accedemos a ese txt
  # Pero aprovechamos el dns de los contenedores, y en vez de usar las ip, usaremos los nombres.lxd de los contenedores

  #echo "corriendo express app en ${container_name}"
  sudo lxc exec "$container_name" -- bash -c "cd /root/myapp && echo PORT=3000 > .env && echo DB_URI=$mongo_uri >> .env " #&& nohup npx ts-node src/app.ts &"


#podemos daemonizar la corrida del back creando un nuevo servicio
#[Unit]
#Description=My App

#[Service]
#ExecStart= algo con npx 
#ExecStart=/usr/local/bin/npm run dev
#Restart=always
#User=nobody
#Environment=PATH=/usr/bin:/usr/local/bin
#Environment=NODE_ENV=production
#WorkingDirectory=/path/to/your/app

#[Install]
#WantedBy=multi-user.target


#sudo systemctl daemon-reload
#sudo systemctl start my-app
done
