#!/bin/sh

# mongo_base_name="dbc"

# <comando> > /dev/null 2>&1 sirve para que el stderr y stdout se vayan a /dev/null y no se muestra nada en consola

#corremos un comando para pingear la bd que debe estar corriendo en el puerto indicado
#y chequeamos $? que es una variable que guarda el exit status del ultimo comando que se corrio
#0 quiere decir que el comando fue exitoso, y cualquier no-0 quiere decir que el comando no fue exitoso
check_mongo_running() {
  local container_name="$1"
  local port="$2"
  local mongo_command="mongosh --port $port --eval 'db.runCommand({ ping: 1})'"
  sudo lxc exec "$container_name" -- mongosh --port $port --eval 'db.runCommand({ping:1})' > /dev/null 2>&1
  return $?
}
#obtenemos la lista de contenedores, y agarramos la segunda cadena de la linea con el contenedor que buscamos
get_container_ip() {
  local container_name="$1"
  sudo lxc list | grep "$container_name" | awk '{print $6}'
}

echo "running mongo.sh"

# for i in $(seq 1 3)
# do
#   container_name="${mongo_base_name}${i}"
#   sudo lxc launch ubuntu:jammy "$container_name" --config cloud-init.user-data="$(cat ./mongoRS.yaml)"
# done

# NOTA: La bd no corre como un servicio, pero deberia cambiarse a servicio.

#obtenemos todas las ip de los contendores creados
#y hacemos rs.initiate() junto a rs.add()
for i in $(seq 1 3)
do
  primary_name="${mongo_base_name}1"
  container_name="${mongo_base_name}${i}"
  container_ip=$(get_container_ip "$container_name")

  echo "checking mongo in $container_name - $container_ip"

  until check_mongo_running "$container_name" 2888
  do
    echo "Waiting for mongo to start in $container_name"
    sleep 6
  done

  if [ $i -eq 1 ]
  then
    echo "initiating rs"
    sudo lxc exec "${primary_name}" -- mongosh --port 2888 --eval 'rs.initiate()'
  else
    echo "adding ${container_name} to rs"
    sudo lxc exec "${primary_name}" -- mongosh --port 2888 --eval "rs.add(\"${container_ip}:2888\")"
  fi
done

echo "mongo done!"
