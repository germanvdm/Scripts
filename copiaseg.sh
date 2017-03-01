#!/bin/bash
# Script de verificación de respaldo y ejecución de copia de seguridad.
# VODEMIA SRL. Enero 2017.
# Programó: Germán.

# Parámetros: '-r' para ejecutar copia de seguridad además de la verificación de respaldo.

# Variables a usar
tmpdir="/tmp"
bkdir="/tmp/bk"
bkfile=$bkdir"/"$(date +%Y%m%d)
msg="";
sub="Resultado de backup: ";
to="info@vodemia.com gvuletich.vdm@gmail.com";
#to="gvuletich.vdm@gmail.com";

# Cuidado con $tardir, es parametro de un comando rm
tardir="/var/local/respaldos/serv254/"
mysqldir="/var/local/backup254/mysql/"
tarname="backup-"$(date +%Y'_'%m'_'%d'_'%H)".tar.gz";
numbackups=3;
minfree=15;
maxbkdeleted=4;

# Funcion que borra el respaldo mas antiguo
function limpiar {
        # si hay mas de 5 respaldos borra el ultimo
        flag=0;
        files=$(ls $tardir | wc -l);
        while [[ $files -ge $numbackups ]];
        do
                older=$(find $tardir -type f -printf '%T+ %p\n' | sort | head -n 1 | awk {'print $2'});
                #nos aseguramos de no borrar nada fuera de $tardir
                if [[ "$older" =~ ^$tardir* ]];
                then
                        rm -f "$older";
                fi
                files=$(ls $tardir | wc -l);
                flag=$(($flag + 1))
                if [[ $flag -ge $maxbkdeleted ]];
                then
                        break;
                fi
        done
}



# Función que comprime el directorio de respaldo.
# Que hace?: verifica espacio libre, si no hay suficiente cancela, si hay espacio
# genera un tar.gz y agrega el resultado de la operacion al cuerpo del mail.
function comprimir {
        used=$(df -k $tardir | awk {'print $5'} | tail -n 1 | tr -d '%');
        free=$((100 - $used))
        if [[ $free -le $minfree ]];
        then
                msg=$msg$'\n'"ATENCION: No se pudo crear una copia del respaldo. Solo un "$free"% de espacio libre en disco.";
                return 1;
        fi

        limpiar

        tar -zcvf $tardir$tarname -C /var/local/ backup254
        result=$?
        if [[ "$result" -eq "0" ]];
        then
                fsize=$(du -h $tardir$tarname | awk {'print $1'});
                msg=$msg$'\n'"Copia de seguriad finalizada. Archivo: $tarname ($fsize) ."$'\n'"Queda un $free% de espacio en disco.";
        else
                msg=$msg$'\n'"ATENCION: Hubo un fallo al comprimir. No se pudo crear una copia del respaldo."
        fi
        return 0;
}

# Funcion de respaldo de mysql
# Que haces?: crea un dump de mysql en el directorio bakcup254

function bkmysql {
        dbname=$mysqldir"all_dbs.sql";
        mysqldump -u vdm --password=vdm308 --all-databases > $dbname &
        msg=$msg$'\n'"Base de datos respaldada. Archivo: $dbname .";
        sleep 60;
}


# ------------------ INICIO DE SCRIPT --------------------------
# Que hace?: verifica el contenido de un beacon (archivo) dejado por el 
# servidor cliente que se respalda en este servidor. Dicho beacon contiene 
# informacion sobre el resultado de la sincronización. Si se invoca con -r 
# llama a la funcion de comprimir. El script lo corre el cron /etc/cron.d/copiaseg

# Verifica que el beacon exista, en caso contrario envia mail y termina.
if [ -f $bkfile ];
then
        result=$(head -n 1 $bkfile);
else
        echo "No se ha completado el respaldo. Beacon $bkfile no encontrado." > $tmpdir"/"$(date +%Y%m%d%H)".err";
        msg="El respaldo ha finalizado con error. Fecha: "$(date +%Y'-'%m'-'%d' '%H':'%M':'%S)"hs";
        subject=$sub"Error";
        echo $msg | mail -s "$subject" $to;
        exit;
fi

# Si el beacon existe verifica el resultado del rsync;
# rsync termina con '0' en caso de éxito, con '!=0' en caso contrario.
if [[ "$result" -eq "0" ]];
then
        msg="El respaldo ha finalizado con Exito. Fecha: "$(date +%Y'-'%m'-'%d' '%H':'%M':'%S)"hs";
        subject=$sub"Ok"
else
        msg="El respaldo ha finalizado con Error. Fecha: "$(date +%Y'-'%m'-'%d' '%H':'%M':'%S)"hs";
        subject=$sub"Error"
        echo "No se ha completado el respaldo. Rsync finalizo con salida "$result" del lado emisor." > $tmpdir"/"$(date +%Y%m%d%H)".err";
fi

# Una vez hecha la verificación limpia el directorio del beacon
rm -f /tmp/bk/*

# Respalda la base de datos
if [[ "$1" == "-q" || "$2" == "-q" ]];
then
        bkmysql
fi

# Si fue invocado con '-r' comprime.
if [[ "$1" == "-r" || "$2" == "-r" ]];
then
        comprimir
fi

# Envia mail con resultados y termina.
echo "$msg" | mail -s "$subject" $to;
exit;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        133,1       Final
