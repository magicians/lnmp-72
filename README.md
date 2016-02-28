# lnmp-72
CentOS7.2 + Nginx + MariaDB + PHP7    

## Setup
** 1. ** git clone git://github.com/hisanuco/lamp-72c.git install  

** 2. ** sed -i "s|^USER_NAME=root$|#\0|g" initfile && sed -i "s|^#USER_NAME=$|USER_NAME=$(echo `pwd` | sed -e 's|/home/||' | sed -e 's|/install||' )|g" initfile && vi initfile && sh startup  

** 3. ** sed -i "s|^SETUP_WEBSERVER_HOSTNAME=localhost.localdomain$|SETUP_WEBSERVER_HOSTNAME=${HOSTNAME}|g" default.txt  

** 4. ** sed -i "s|^SERVER_STATIC_IP_ADDR=$|SERVER_STATIC_IP_ADDR=$(/sbin/ip -o route get 255.255.255.255 | /bin/grep -Eo 'src\s+\S+' | /bin/awk '{print $2}')|g" default.txt  

** 5. ** vi default.txt && vi server.txt && vi database.txt   

** 6. ** sudo sh 01.DEFAULT-SETUP.sh && sh O2.WEBSERVER-SETUP.sh && sh 03.DB-SETUP.sh  

** 7. ** WebBrowser / ownCloud Install.  

** 8. ** sudo sh last_optimization ( reboot )  

====

**Version v1.0.5**  
**Version v1.0.2**  
**Version v1.0.1**  
**Version v1.0.0**  
