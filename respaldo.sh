#!/bin/bash
# Script de respaldo. Sincroniza una carpera local hacia un servidor destino (cloud03).
# y le informa del resultado de la operación tras terminar.
# VODEMIA SRL. Enero 2017.
# Programó: Germán.

#Origen de los datos a respaldar
origen="/home/cvs/CVSrepo /home/git"

#Destino de los datos a respaldar
usuario="vodemia"
servidor="cloud03.vodemia.com"
destino="/var/local/backup254"
sshfile="/home/usuario/.sshpass.txt"
#direction temporal de trabajo en servidor destino
remoutdir="/tmp/bk"
#beacon en servidor destino con resultado de este script
remoutfile=$remoutdir"/"$(date +%Y%m%d);


# ------------------ INICIO DE SCRIPT --------------------------

#El script lo corre el cron /etc/cron.d/respaldo
#Sincronizamos
sshpass -f $sshfile rsync -avh -e "ssh -p 5430" $origen $usuario@$servidor:$destino --delete
#Guardamos el resultado de la operacion
result=$?
#Despositamos el resultado en un archivo del servidor destino para que aquel lo interprete
sshpass -f $sshfile ssh -p 5430 $usuario@$servidor "mkdir $remoutdir 2> /dev/null; echo $result > $remoutfile"
