#!/bin/bash

#Función que chequea el tamaño del cache de videos

#Defino el tamaño que quiero tener  (M: mega, G: Giga)
SIZE="30G"

#Directorio donde se encuentra el cache
DIR="/var/share/videocache/files"

#Convierto todo a bytes
if [[ ${SIZE} =~ .G ]]; then
	TAM=$(( $( echo ${SIZE} | cut -dG -f1 ) * 1024 ** 3 ))
else
	TAM=$(( $( echo ${SIZE} | cut -dM -f1 ) * 1024 ** 2 ))
fi


#Busco los archivos no accedidos recientemente y generpo un temporal
find $DIR -type f -printf '%AY%Am%Ad%AH%AM %p\n' | sort | cut -d\  -f2 > /tmp/_cachevideo

#selecciono los archivos para borrar
for i in $(cat /tmp/_cachevideo); do

	#Verifico el tama¤o actual del cache
	if [ $(du -sb ${DIR} | cut -f1) -gt $TAM ]; then

		#Borro el archivo
		rm ${i}

	else

		break

	fi

done

#Borro el archivo temporal
rm /tmp/_cachevideo

