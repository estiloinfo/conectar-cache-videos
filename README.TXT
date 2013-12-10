#
#Cache videos youtube: Versión 1.2
#

CONFIGURACION PARA EL CACHE DE VIDEOS DE YOUTUBE

1. INTRODUCCION

	El siguiente documento esta diseñado para que los Administradores de red de 
	la Provincia de Santa Fe realicen la implementación en los servidores del 
	Plan Conectar Igualdad. En este caso optimizaremos el uso del proxy Squid 
	para realizar el cache de los videos de youtube.

	NOTA: Se presupone en este documento que el administrador de red ya ha 
	implementado los tutoriales anteriores "FIREWALL, SQUID y DansGuardian" y 
	por lo tanto tiene los conocimientos necesarios para pasar los archivos 
	descargados con este tutorial a los respectivos servidores que desee 
	configurar.

2. CONFIGURACION

	La configuración para realizar el cacheo de los videos de youtube la debemos 
	realizar en varias etapas. Todas estas tareas se deben realizar como 
	usuario root del servidor.

2.1. Instalación de NGINX

	Para poder cachear los videos nos apoyaremos en un servidor web que tiene 
	las posibilidades de actuar como proxy reverso. Este servidor web se 
	encargará de manejar las conexiones a youtube almacenando en un directorio 
	del equipo los videos que se van solicitando, de esta forma si un video 
	"previamente visualizado" se vuelve a pedir el mismo ya no se baja de 
	Internet sino que se lo entrega desde el servidor local, logrando con esto 
	un ahorro importante de ancho de banda. Para instalar este servidor debemos 
	ejecutar el siguiente comando.

	#apt-get install nginx

	a) Configuración inicial de NGINX

	Dentro del directorio /etc/nginx encontramos un archivo llamado nginx.conf, 
	este archivo contiene la configuración por defecto de la aplicación la cual 
	no utilizaremos, pero mantendremos una copia original de la misma. Para lo 
	cual ejecutamos los siguientes comando.

	#mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.org

	Finalmente copiamos los archivo de configuración "nginx.conf.ubuntu" y 
	"nginx.conf.debian" descargado con esta documentación en el directorio 
	/etc/nginx y lo renombramos a nginx.conf

	Para servidores Ubuntu
	#mv  nginx.conf.ubuntu  /etc/nginx/nginx.conf

	Para servidores Debian
	#mv  nginx.conf.debian  /etc/nginx/nginx.conf


	b) Creación de directorios de trabajo

	Debemos renombrar el archivo de configuración de acuerdo al tipo de servidor 
	con el que se cuenta y luego crear los directorios donde se almacenarán los 
	videos

	Para servidores Ubuntu, ejecutamos los siguientes comandos

	# cd /etc/nginx
	# mv nginx.conf.ubuntu nginx.conf
	# mkdir -p /var/share/videocache/files
	# mkdir -p /var/share/videocache/tmp
	# chown www-data /var/share/videocache -R

	Para servidores Debian virtualizados, ejecutamos los siguientes comandos.

	# cd /etc/nginx
	# mv nginx.conf.debian nginx.conf
	# mkdir -p /vol/share/videocache/files
	# mkdir -p /vol/share/videocache/tmp
	# chown www-data /vol/share/videocache -R

	a) Prueba del servicio

	En este momento ya tenemos realizada la configuración del aplicativo nginx, 
	debemos iniciarlo y verificar que no arroje ningún tipo de error, para levantar 
	el servicio ejecutamos el siguiente comando

	# /etc/init.d/nginx start

	Si el comando no arroja error, verificamos la conexión con nginx ejecutando 
	el siguiente comando

	# telnet localhost 8081

	Luego tipeamos HELLO y damos enter, deberíamos recibir un mensaje similar al 
	que se detalla a continuación

	<html>
	<head><title>400 Bad Request</title></head>
	<body bgcolor="white">
	<center><h1>400 Bad Request</h1></center>
	<hr><center>nginx/1.4.1</center>
	</body>
	</html>
	Connection closed by foreign host.

	Si recibimos este mensaje ya tenemos activo el servicio NGINX.


	b) Establecer el nginx como servicio

	Para que nginx se ejecute cada vez que se reinicia el servidor debemos 
	agregarlo como servicio para los cual ejecutaremos el siguiente  comando

	#update-rc.d nginx defaults

2.2.  Configuración del squid

	Debemos ahora configurar el squid para que envíe los pedidos de los videos 
	de youtube al servicio nginx, para lograr esto debemos editar el archivo de 
	configuración del squid, para ello, entramos en el directorio de 
	configuración 	para hacer un backup del archivo de configuración actual

	#cd /etc/squid
	#cp squid.conf squid.conf.org

	Ahora debemos editar el archivo squid.conf para configurar la regla para que 
	los videos de youtube sean manejados por nginx, para esto debemos agregar en 
	el archivo las siguientes lineas.

	Como primer paso debemos crear las ACLs par el manejo de youtube, para lo 
	cual nos paramos en la sección del archivo "squid.conf" donde se definen 
	las ACLs y agregamos las siguientes. (Estas directivas se encuentran en el 
	archivo descargado "squid.acl")

	acl youtube_videos url_regex -i ^http://.*\.(googlevideo|youtube)\.com/videoplayback\?
	acl range_request req_header Range .
	acl begin_param url_regex -i ["&]begin=
	acl id_param url_regex -i ["&]id=
	acl itag_param url_regex -i ["&]itag=
	acl sver3_param url_regex -i ["&]sver=3
	cache_peer 127.0.0.1 parent 8081 0 proxy-only no-query connect-timeout=10
	cache_peer_access 127.0.0.1 allow youtube_videos id_param itag_param 
	sver3_param !begin_param !range_request
	cache_peer_access 127.0.0.1 deny all
	

2.3.  Mantenimiento del tamaño del cache

	El tamaño del cache lo vamos limitar ejecutando en forma periódica un script 
	que se encargará de borrar los archivos viejos. Para ello copiamos el 
	archivo "cache.sh.debian" o "cache.sh.ubuntu" al directorio /etc/nginx y 
	luego lo renombramos a "cache.sh"

	Para servidores Ubuntu
	#mv  cache.sh.ubuntu  /etc/nginx/cache.sh

	Para servidores Debian
	#mv  cache.sh.debian  /etc/nginx/cache.sh

	Una vez que tenemos el archivo en /etc/nginx, de damos permiso de ejecucuion

	#chmod 770 /etc/nginx/cache.sh

	Finalmente editamos el archivo y cambiamos la variable SIZE que por defecto 
	está en 30G (treinta gigas) y ponemos el valor del tamaño que deseamos 
	mantener el cache, Ej: SIZE="100G" voy a mantener un cache de 100 gigas. Es 
	decir el script cada vez que se ejecuta lleva el tamaño del cache a 100G. 
	Luego de la ejecución el cache sigue creciendo y el mismo es ajustado en la 
	próxima ejecución. Por este motivo tenemos que hacer que este script se 
	ejecute en forma periódica, para lo cual agregamos en el cron la siguiente 
	directiva de ejecución.

	Editamos el cron
	#crontab -e

	Agregamos la siguiente directiva de ejecución
	00 8,10,12,14,16,18,20,22,23 * * *  /etc/nginx/cache.sh

	Cerramos la edición del cron para que la misma tome efecto

	Lo que hacemos con esta orden dentro del cron es que el script se ejecute 
	todos los días, la primera vez a las 8Hs y luego cada 2hs y hasta las 23Hs 
	la última ejecución. Es decir la ventana de crecimiento del cache es de 
	2Hs, durante esas 2Hs el cache superará el tamaño definido en el script. 

3. OPTIMIZACIONES

3.1. Eliminación de logs en NGINX (Solo funciona en algunas versiones de NGINX)

	Para que el servcio nginx no genere los logs de acceso, debemos editar el 
	archivo /etc/nginx/nginx.conf y cambiar las directivas access_log y 
	error_log por las siguientes

	access_log off;
	error_log off;

	Luego reiniciar el servicio   #/etc/init.d/nginx restart