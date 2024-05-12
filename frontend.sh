#!/bin/bash

# Paso 5: Iterar sobre los contenedores del front para ejecutar las siguientes tareas
for i in $(seq 1 3); do
    echo "==================== Contenedor frontend-$i =========="
    echo "========== Instalar Node.js y Git ..."

    # Actualizar los paquetes existentes dentro del contenedor
    echo "########---Actualizamos los paquetes existentes---########"
    lxc exec front-$i -- apt update

    # Instalar Git y Curl dentro del contenedor
    echo "########---Instalamos Git y Curl---########"
    lxc exec front-$i -- apt install -y curl git

    # Descargar la versi\u00f3n 20 de Node.js dentro del contenedor
    echo "########---Descargamos la versi\u00f3n 20 de Node.js---########"
    lxc exec front-$i -- bash -c 'curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash'

    # Instalar Node.js dentro del contenedor
    echo "########---Instalamos Node.js---########"
    lxc exec front-$i -- apt-get install nodejs -y

    # Clonar el repositorio de GitHub dentro del contenedor
    echo "========== Clonando el repositorio de GitHub ..."
    lxc exec front-$i -- git clone https://github.com/italovisconti/NNotes.git /opt/app/NNotes

    # Agregar instrucciones adicionales
    echo "========== Creando directorio y descargando script ..."
    lxc exec front-$i -- bash -c 'mkdir -p /opt/scripts && cd /opt/scripts && sudo curl -LJO https://raw.githubusercontent.com/italovisconti/NNotes/main/src/scripts/script.sh && sudo chmod +x /opt/scripts/script.sh'

    # Entramos al lugar donde se encuentran los servicios
    echo "========== Accediendo al directorio de servicios ..."
    lxc exec front-$i -- bash -c 'cd /lib/systemd/system/'

    # Descargamos el archivo del servicio que queremos
    echo "========== Descargando archivo de servicio ..."
    lxc exec front-$i -- bash -c 'sudo curl -LJO https://raw.githubusercontent.com/italovisconti/NNotes/main/src/services/front-'"${i}"'.service'

    # Movemos el archivo a la carpeta que queremos
    echo "========== Movemos el archivo del servicio a /lib/systemd/system/..."
    lxc exec front-$i -- mv /root/front-"${i}".service /lib/systemd/system/

    # Corremos el servicio
    echo "========== Iniciando el servicio ..."
    lxc exec front-$i -- bash -c "sudo systemctl start front-'"${i}"'"

    # Activamos el enable del servicio
    echo "========== Habilitando el inicio autom\u00e1tico del servicio ..."
    lxc exec front-$i -- bash -c "sudo systemctl enable front-'"${i}"'"

    # Recargamos la configuraci\u00f3n de systemd
    echo "========== Recargando configuraci\u00f3n de systemd ..."
    lxc exec front-$i -- bash -c 'sudo systemctl daemon-reload'

    # Agregamos la configuraci\u00f3n para el puerto din\u00e1mico
    echo "========== Agregando configuraci\u00f3n para puerto $((3000 + i)) ..."
    lxc config device add front-$i puerto$((3000 + i)) proxy listen=tcp:0.0.0.0:$((3000 + i)) connect=tcp:127.0.0.1:$((3000 + i))
done