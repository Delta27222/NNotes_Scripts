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

  # debemos buscar las ip de las bases de datos podemos usar lxc list, o creamos un txt en el sh de mongo, y accedemos a ese txt
  # Pero aprovechamos el dns de los contenedores

  # Clonar el repositorio de GitHub dentro del contenedor
  echo "========== Clonando el repositorio de GitHub ..."
  lxc exec container_name -- git clone https://github.com/italovisconti/NNotes-RestAPI.git /opt/app/NNotes-RestAPI

  # Agregar instrucciones adicionales
  echo "========== Creando directorio y descargando script ..."
  lxc exec container_name -- bash -c 'mkdir -p /opt/scripts && cd /opt/scripts && sudo curl -LJO https://raw.githubusercontent.com/italovisconti/NNotes-RestAPI/main/src/scripts/script.sh && sudo chmod +x /opt/scripts/script.sh'

  # Entramos al lugar donde se encuentran los servicios
  echo "========== Accediendo al directorio de servicios ..."
  lxc exec container_name -- bash -c 'cd /lib/systemd/system/'

  # Descargamos el archivo del servicio que queremos
  echo "========== Descargando archivo de servicio ..."
  lxc exec container_name -- bash -c 'sudo curl -LJO https://github.com/italovisconti/NNotes-RestAPI/raw/main/src/services/back-'"${i}"'.service'

  # Movemos el archivo a la carpeta que queremos
  echo "========== Movemos el archivo del servicio a /lib/systemd/system/..."
  lxc exec container_name -- mv /root/back-"${i}".service /lib/systemd/system/

  # Corremos el servicio
  echo "========== Iniciando el servicio ..."
  lxc exec container_name -- bash -c "sudo systemctl start back-'"${i}"'"

  # Activamos el enable del servicio
  echo "========== Habilitando el inicio autom\u00e1tico del servicio ..."
  lxc exec container_name -- bash -c "sudo systemctl enable back-'"${i}"'"

  # Recargamos la configuraci\u00f3n de systemd
  echo "========== Recargando configuraci\u00f3n de systemd ..."
  lxc exec container_name -- bash -c 'sudo systemctl daemon-reload'

  # Agregamos la configuraci\u00f3n para el puerto din\u00e1mico    (CREO QUE ESTO NO ES NECESARIO)
  # echo "========== Agregando configuraci\u00f3n para puerto $((3000)) ..."
  # lxc config device add container_name puerto$((3000)) proxy listen=tcp:0.0.0.0:$((3000)) connect=tcp:127.0.0.1:$((3000))
done
