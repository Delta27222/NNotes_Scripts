#!/bin/bash

front_base_name="front-"
back_base_name="backc"

sudo chmod +x ./mongo.sh ./frontend.sh ./back.sh ./loadbalancerFront.sh ./loadbalancerBack.sh

# Paso 1: Desinstalar el paquete LXD
echo "Paso 1: Desinstalando el paquete LXD..."
sudo snap remove lxd
echo "El paquete LXD ha sido desinstalado."

# Paso 2: Instalar el paquete LXD
echo "Paso 2: Instalando el paquete LXD..."
sudo snap install lxd
echo "El paquete LXD ha sido instalado."

# Paso 3: Inicializar un contenedor con la configuraci\u00f3n m\u00ednima
echo "Paso 3: Inicializando un contenedor con la configuraci\u00f3n m\u00ednima..."
lxd init --minimal
echo "Contenedor inicializado con \u00e9xito."

# Paso 4: Crear y lanzar tres contenedores basados en la imagen ubuntu:jammy FRONT
echo "Paso 4: Creando y lanzando tres contenedores basados en la imagen ubuntu:jammy para el front..."
for i in $(seq 1 3); do
    lxc launch ubuntu:jammy ${front_base_name}${i}
done
echo "Tres contenedores de front han sido creados y lanzados."

# Paso 5: Crear y lanzar tres contenedores basados en la imagen ubuntu:jammy BACK
echo "Paso 5: Creando y lanzando tres contenedores basados en la imagen ubuntu:jammy para el back..."
for i in $(seq 1 3); do
    lxc launch ubuntu:jammy back-${i}
done
echo "Tres contenedores de back han sido creados y lanzados."

#Colocar los siguientes contenedores para el back

