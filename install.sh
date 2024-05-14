#!/bin/bash

export front_base_name="front-"
export front_lb_base_name="frontlb"
export back_base_name="backc"
export back_lb_base_name="backlb"
export mongo_base_name="dbc"
export replicaSet_name="uniRS"

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

# Paso 5: Crear y lanzar un contenedor basados en la imagen ubuntu:jammy LBFRONT
echo "Paso 5: Creando y lanzando un contenedor basados en la imagen ubuntu:jammy para el load balancer front..."
lxc launch ubuntu:jammy ${front_lb_base_name}
echo "Un contenedor de load balancer front han sido creados y lanzados."

# Paso 6: Crear y lanzar tres contenedores basados en la imagen ubuntu:jammy BACK
echo "Paso 6: Creando y lanzando tres contenedores basados en la imagen ubuntu:jammy para el back..."
for i in $(seq 1 3); do
    lxc launch ubuntu:jammy ${back_base_name}${i} --config cloud-init.user-data="$(cat back.yaml)"
done
echo "Tres contenedores de back han sido creados y lanzados."

# Paso 7: Crear y lanzar un contenedor basados en la imagen ubuntu:jammy LBBACK
echo "Paso 7: Creando y lanzando un contenedor basados en la imagen ubuntu:jammy para el load balancer back..."
lxc launch ubuntu:jammy ${back_lb_base_name}
echo "Un contenedor de load balancer back han sido creados y lanzados."

# Paso 8: Crear y lanzar tres contenedores basados en la imagen ubuntu:jammy MONGODB
echo "Paso 8: Creando y lanzando tres contenedores basados en la imagen ubuntu:jammy para la bd..."
for i in $(seq 1 3); do
    lxc launch ubuntu:jammy ${mongo_base_name}${i} --config cloud-init.user-data="$(cat ./mongoRS.yaml)"
done
echo "Tres contenedores de base de Datos han sido creados y lanzados."

# DB
source ./mongo.sh

# BACK
source ./back.sh

# LBBACK
source ./loadbalancerBack.sh

# FRONT
source ./frontend.sh

# LBFRONT
source ./loadbalancerFront.sh

# Print a completion message in green
echo -e "\e[32mListo!!!\e[0m"