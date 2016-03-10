#!/bin/bash
#### lnmp-72 v1.0.7
############################################################################
source ./initfile
source ./base.txt
source ./config_init.txt
############################################################################
source ./server.txt
############################################################################
echo -e "Jp: WebServer(Nginx)をインストールします。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: It will install the WebServer (Nginx). [y] / Already one time when it is passed through the shell [n]"
read set_webserver_inst
if [ ${set_webserver_inst} = "y" ] ; then
# CentOS7 httpd normal install.
clear
#### PHP Install.
echo -e "Jp: PHP7.x をインストールする場合は [y] / PHP5.6 をインストールする場合は [n]"
echo -e "En: If you want to install PHP7.x [y] / If you want to install the PHP5.6 [n]"
read DEFPHPINST_70_56
if [ ${DEFPHPINST_70_56} = "y" ] ; then
echo -e "Jp: PHP7.x をインストールします"
echo -e "En: It will install the PHP7.x"
yum --enablerepo=remi,remi-php70 install php php-cli php-devel php-common php-ldap php-pdo php-mbstring php-gd php-pear php-xml php-pecl-apc php-mcrypt php-mysqli php-pecl-zip php-fpm mariadb mariadb-server
else
echo -e "Jp: PHP5.6 をインストールします"
echo -e "En: It will install the PHP5.6"
yum --enablerepo=remi,remi-php56 install php php-cli php-devel php-common php-ldap php-pdo php-mbstring php-gd php-pear php-xml php-pecl-apc php-mcrypt php-mysqli php-pecl-zip php-fpm mariadb mariadb-server
fi
####
fi
clear
echo -e "Jp: PHP-FPMをセットアップします。"
echo -e "En: It will set up the PHP-FPM."
cp /etc/php-fpm.d/www.conf /etc/php-fpm.d/www_conf.origin
vim /etc/php-fpm.d/www.conf
echo -e "PHP-FPM Edit."
sed -i "s|^listen = 127.0.0.1:9000|listen = ${BACKEND_LISTEN_SOCK}|g" /etc/php-fpm.d/www.conf
sed -i 's|^listen.allowed_clients = 127.0.0.1|;\0|' /etc/php-fpm.d/www.conf
sed -i "s|^;listen.owner = nobody|listen.owner = ${WEB_SERVER_SYSTEM_USER_GROUP}|g" /etc/php-fpm.d/www.conf
sed -i "s|^;listen.group = nobody|listen.group = ${WEB_SERVER_SYSTEM_USER_GROUP}|g" /etc/php-fpm.d/www.conf
sed -i "s|^user = apache$|user = ${WEB_SERVER_SYSTEM_USER_GROUP}|g" /etc/php-fpm.d/www.conf
sed -i "s|^group = apache$|group = ${WEB_SERVER_SYSTEM_USER_GROUP}|g" /etc/php-fpm.d/www.conf
sed -i 's|^;listen.mode|listen.mode|g' /etc/php-fpm.d/www.conf
sed -i 's|^pm = dynamic|pm = static|g' /etc/php-fpm.d/www.conf
sed -i "s|^pm.max_children = 50|pm.max_children = ${PHP_FPM_MAX_CHILDREN}|g" /etc/php-fpm.d/www.conf
sed -i "s|^;pm.max_requests = 500|pm.max_requests = ${PHP_FPM_MAX_REQUEST}|g" /etc/php-fpm.d/www.conf
vim /etc/php-fpm.d/www.conf
# PHP.ini Edit
#
echo -e "Jp: PHP.iniを編集します。"
echo -e "En: You will edit the PHP.ini."
cp /etc/php.ini /etc/php.ini.origin
sed -i "s|^expose_php = On|expose_php = Off|g" /etc/php.ini
sed -i "s|^session.hash_function = 0|session.hash_function = 1|g" /etc/php.ini
sed -i "s|^;session.entropy_file = /dev/urandom|session.entropy_file = /dev/urandom|g" /etc/php.ini
sed -i "s|^;session.entropy_length = 32|session.entropy_length = 32|g" /etc/php.ini
sed -i "s|^;date.timezone =|date.timezone = \"${PHP_DATE_TIMEZONE}\"|g" /etc/php.ini
sed -i "s|^session.save_path = \"/tmp\"$|;\0|g" /etc/php.ini
sed -i "s|^soap.wsdl_cache_dir=\"/tmp\"$|;\0|g" /etc/php.ini
vim /etc/php.ini
#
clear
echo -e "Jp: Apacheをセットアップします。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: You set up the Apache. [y] / Already one time when it is passed through the shell [n]"
read optserverinst02
if [ ${optserverinst02} = "y" ] ; then
#########################################
echo -e "Apache Backend Setup."
# httpd.conf Edit.
echo -e "httpd.conf Edit."
sed -i 's|Options Indexes FollowSymLinks$|Options -Indexes +FollowSymLinks|g' ${APACHE_BASE_CONFIG_DIRECTORY}/httpd.conf
sed -i "s|^ErrorLog \"logs/error_log\"$|ErrorLog \"${APACHE_LOG_DIRECTORY}/httpd_error_log\"|g" ${APACHE_BASE_CONFIG_DIRECTORY}/httpd.conf
sed -i "s|CustomLog \"logs/access_log\" combined$|CustomLog \"${APACHE_LOG_DIRECTORY}/httpd_access_log\" combined|g" ${APACHE_BASE_CONFIG_DIRECTORY}/httpd.conf
sed -i "s|^User apache$|User ${WEB_SERVER_SYSTEM_USER_GROUP}|g" ${APACHE_BASE_CONFIG_DIRECTORY}/httpd.conf
sed -i "s|^Group apache$|Group ${WEB_SERVER_SYSTEM_USER_GROUP}|g" ${APACHE_BASE_CONFIG_DIRECTORY}/httpd.conf
sed -i "s|^#ServerName www.example.com:80$|ServerName ${CONFIG_HOST_DOMAIN}:80|g" ${APACHE_BASE_CONFIG_DIRECTORY}/httpd.conf
echo "ServerTokens Prod" >> ${APACHE_BASE_CONFIG_DIRECTORY}/httpd.conf
echo "KeepAlive On" >> ${APACHE_BASE_CONFIG_DIRECTORY}/httpd.conf
echo "ServerSignature Off" >> ${APACHE_BASE_CONFIG_DIRECTORY}/httpd.conf
vim ${APACHE_BASE_CONFIG_DIRECTORY}/httpd.conf
#
# 00-base.conf Edit.
echo -e "00-base.conf Edit."
sed -i 's|^LoadModule authn_anon_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-base.conf
sed -i 's|^LoadModule authn_dbm_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-base.conf
sed -i 's|^LoadModule authz_owner_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-base.conf
sed -i 's|^LoadModule authz_dbm_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-base.conf
sed -i 's|^LoadModule status_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-base.conf
sed -i 's|^LoadModule userdir_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-base.conf
sed -i 's|^LoadModule cache_disk_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-base.conf
vim ${APACHE_MOD_CONFIG_DIRECTORY}/00-base.conf
#
# 00-dev.conf Edit.
echo -e "00-dev.conf Edit."
sed -i 's|^LoadModule dav_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-dav.conf
sed -i 's|^LoadModule dav_fs_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-dav.conf
sed -i 's|^LoadModule dav_lock_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-dav.conf
vim ${APACHE_MOD_CONFIG_DIRECTORY}/00-dav.conf
#
# 00-proxy.conf Edit.
echo -e "00-proxy.conf Edit."
sed -i 's|^LoadModule lbmethod_bybusyness_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule lbmethod_byrequests_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule lbmethod_bytraffic_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule lbmethod_heartbeat_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule proxy_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule proxy_express_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule proxy_fcgi_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule proxy_fdpass_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule proxy_scgi_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule proxy_balancer_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule proxy_ftp_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule proxy_http_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule proxy_ajp_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule proxy_connect_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
sed -i 's|^LoadModule proxy_wstunnel_module|#\0|' ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
vim ${APACHE_MOD_CONFIG_DIRECTORY}/00-proxy.conf
#
# extract_forwarded Buile.
echo -e "extract_forwarded Build."
cd /usr/local/src
git clone ${APACHE_MOD_EXTRACT_FORWARDED} extract_forwarded
cd /usr/local/src/extract_forwarded
apxs -i -c -a mod_extract_forwarded.c
cd /usr/local/src/
rm -rf extract_forwarded
#
# 99-nginx.conf Create.
echo -e "99-nginx.conf Create."
cat <<EOF > ${APACHE_MOD_CONFIG_DIRECTORY}/99-nginx.conf
# Proxy Mod Conflict
#LoadModule extract_forwarded_module modules/mod_extract_forwarded.so
# Nginx IP Address
#MEForder refuse,accept
#MEFrefuse all
# Nginx Local IP
#MEFaccept 127.0.0.1
EOF
vim ${APACHE_MOD_CONFIG_DIRECTORY}/99-nginx.conf
#
cat <<EOF> ${APACHE_CONFIG_DIRECTORY}/referer_spam.conf
# Referer Spam Deny All.
#
    SetEnvIfNoCase Referer ${RefererSpam00} referrerspam=yes
    SetEnvIfNoCase Referer ${RefererSpam02} referrerspam=yes
    SetEnvIfNoCase Referer ${RefererSpam03} referrerspam=yes
    SetEnvIfNoCase Referer ${RefererSpam04} referrerspam=yes
    SetEnvIfNoCase Referer ${RefererSpam05} referrerspam=yes
    SetEnvIfNoCase Referer ${RefererSpam06} referrerspam=yes
    SetEnvIfNoCase Referer ${RefererSpam07} referrerspam=yes
    SetEnvIfNoCase Referer ${RefererSpam08} referrerspam=yes
    SetEnvIfNoCase Referer ${RefererSpam09} referrerspam=yes
    SetEnvIfNoCase Referer ${RefererSpam10} referrerspam=yes
    SetEnvIfNoCase Referer ${RefererSpam11} referrerspam=yes
EOF
#
vim ${APACHE_CONFIG_DIRECTORY}/referer_spam.conf
#
# extract_forwarded Comment Out.
echo -e "extract_forwarded Comment Out."
sed -i 's|^LoadModule extract_forwarded_module /usr/lib64/httpd/modules/mod_extract_forwarded.so$|#\0|g' ${APACHE_BASE_CONFIG_DIRECTORY}/httpd.conf
vim ${APACHE_BASE_CONFIG_DIRECTORY}/httpd.conf
#
# welcome.conf Edit.
echo -e "welcome.conf Edit."
sed -i 's|^<LocationMatch|#\0|' ${APACHE_CONFIG_DIRECTORY}/welcome.conf
sed -i 's|^    Options -Indexes|#\0|' ${APACHE_CONFIG_DIRECTORY}/welcome.conf
sed -i 's|^    ErrorDocument|#\0|' ${APACHE_CONFIG_DIRECTORY}/welcome.conf
sed -i 's|^</LocationMatch>|#\0|' ${APACHE_CONFIG_DIRECTORY}/welcome.conf
sed -i 's|^<Directory /usr/share/httpd/noindex>|#\0|' ${APACHE_CONFIG_DIRECTORY}/welcome.conf
sed -i 's|^    AllowOverride None|#\0|' ${APACHE_CONFIG_DIRECTORY}/welcome.conf
sed -i 's|^    Require all granted|#\0|' ${APACHE_CONFIG_DIRECTORY}/welcome.conf
sed -i 's|^</Directory>|#\0|' ${APACHE_CONFIG_DIRECTORY}/welcome.conf
sed -i 's|^Alias /.noindex.html /usr/share/httpd/noindex/index.html|#\0|' ${APACHE_CONFIG_DIRECTORY}/welcome.conf
sed -i 's|^Alias /noindex/css/bootstrap.min.css /usr/share/httpd/noindex/css/bootstrap.min.css|#\0|' ${APACHE_CONFIG_DIRECTORY}/welcome.conf
sed -i 's|^Alias /noindex/css/open-sans.css /usr/share/httpd/noindex/css/open-sans.css|#\0|' ${APACHE_CONFIG_DIRECTORY}/welcome.conf
sed -i 's|^Alias /images/apache_pb.gif /usr/share/httpd/noindex/images/apache_pb.gif|#\0|' ${APACHE_CONFIG_DIRECTORY}/welcome.conf
sed -i 's|^Alias /images/poweredby.png /usr/share/httpd/noindex/images/poweredby.png|#\0|' ${APACHE_CONFIG_DIRECTORY}/welcome.conf
vim ${APACHE_CONFIG_DIRECTORY}/welcome.conf
mkdir -p /var/www/{html,logs,error,icons,cgi-bin}
mkdir ${PHP_FPM_SOAP_CACHE_DIR}
chmod 700 ${PHP_FPM_SOAP_CACHE_DIR}
chown ${WEB_SERVER_SYSTEM_USER_GROUP} ${PHP_FPM_SOAP_CACHE_DIR}
touch /var/www/error/{401.html,403.html,404.html,50x.html,index.html}
echo "401 - Authorization Required." >> /var/www/error/401.html
echo "403 - Forbidden." >> /var/www/error/403.html
echo "404 - Not Found." >> /var/www/error/404.html
echo "500 - Internal Server Error." >> /var/www/error/50x.html
chown -R ${WEB_SERVER_SYSTEM_USER_GROUP}:${WEB_SERVER_SYSTEM_USER_GROUP} /var/www/{html,logs,error,icons,cgi-bin}
chown -R ${WEB_SERVER_SYSTEM_USER_GROUP}:${WEB_SERVER_SYSTEM_USER_GROUP} /var/lib/php/{session,wsdlcache}
#
mv ${APACHE_CONFIG_DIRECTORY}/ssl.conf ${APACHE_CONFIG_DIRECTORY}/ssl_conf
######################################################################
# GeoIP DB Directory
######################################################################
echo -e "GeoIP DB Directory Setup."
mv ${APACHE_CONFIG_DIRECTORY}/geoip.conf ${APACHE_CONFIG_DIRECTORY}/geoip_conf
cat <<EOF > ${APACHE_CONFIG_DIRECTORY}/geoip.conf
<IfModule mod_geoip.c>
  GeoIPEnable On
  GeoIPScanProxyHeaders On
  GeoIPDBFile ${GEOIP_PATH}/${GEOIP_FILE}
  GeoIPDBFile ${GEOIP_PATH}/${GEOIP_FILE} MemoryCache
  GeoIPDBFile ${GEOIP_PATH}/${GEOIP_FILE} CheckCache
</IfModule>

<Location "/">
  Order Deny,Allow
  Include ${APACHE_CONFIG_DIRECTORY}/referer_spam.conf
  Deny from env=referrerspam
  Deny from all
  # GeoIP
  SetEnvIf GEOIP_COUNTRY_CODE ${GEOIP_COUNTRY} AllowCountry
  # Japan Only.
  Allow from env=AllowCountry
  Allow from ${GLOBAL_IP_ADDR}
</Location>

#Logs
LogFormat "%a [%h] %u %t %D \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"   GeoIP_Address=\"%{GEOIP_ADDR}e\" Country_Code=\"%{GEOIP_COUNTRY_CODE}e\" Country_Name=\"%{GEOIP_COUNTRY_NAME}e\"" combined
EOF
vim ${APACHE_CONFIG_DIRECTORY}/geoip.conf
#
cd ${GEOIP_PATH}
# GeoIP.dat mv GeoIP.dat.YYYYmmdd-IMS.bak
mv ${GEOIP_FILE} ${GEOIP_FILE}."$(date +%Y%m%d-%I%M%S).bak"
# GeoIP New Get Files
wget ${GEOIP_URL}/${GEOIP_FILE}.gz
# GeoIP.dat Gunzip
gunzip ${GEOIP_FILE}.gz
cd ${INSTALL_PATH}
####
cat <<EOF > /etc/cron.weekly/GeoIP
#!/bin/bash
# GeoIP DB Directory
cd ${GEOIP_PATH}
# GeoIP.dat mv GeoIP.dat.YYYYmmdd-IMS.bak
mv ${GEOIP_FILE} ${GEOIP_FILE}."\$(date +%Y%m%d-%I%M%S).bak"
# GeoIP New Get Files
wget ${GEOIP_URL}/${GEOIP_FILE}.gz
# GeoIP.dat Gunzip
gunzip ${GEOIP_FILE}.gz
cd
# Apache Nginx restart
systemctl restart php-fpm
systemctl restart nginx
EOF
vim /etc/cron.weekly/GeoIP
chmod +x /etc/cron.weekly/GeoIP
####
fi
######################################################################
echo -e "Jp: Nginxをセットアップします。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: You set up the Nginx. [y] / Already one time when it is passed through the shell [n]"
read set_nginx_setup
if [ ${set_nginx_setup} = "y" ] ; then
######################################################################
# Default Setting.
######################################################################
echo -e "Nginx Default Setting."
sed -i "s|^user  nginx;$|user  ${WEB_SERVER_SYSTEM_USER_GROUP};|g" ${NGINX_BASE_DIRECTORY}/nginx.conf
sed -i "s|^worker_processes  1;$|worker_processes  ${NGINX_WORKER_PROCESSES};|g" ${NGINX_BASE_DIRECTORY}/nginx.conf
sed -i "3a\#worker_cpu_affinity ${NGINX_WORKER_CPU_AFFINITY};" ${NGINX_BASE_DIRECTORY}/nginx.conf
sed -i "4a\#worker_priority ${NGINX_WORKER_PRIORITY};" ${NGINX_BASE_DIRECTORY}/nginx.conf
sed -i "s|^error_log  /var/log/nginx/error.log|error_log  ${APACHE_LOG_DIRECTORY}/nginx_error.log|g" ${NGINX_BASE_DIRECTORY}/nginx.conf
sed -i "s|access_log  /var/log/nginx/access.log  main|access_log  ${APACHE_LOG_DIRECTORY}/nginx_access.log  main|g" ${NGINX_BASE_DIRECTORY}/nginx.conf
sed -i "s|keepalive_timeout   65|keepalive_timeout   ${NGINX_KEEPALIVE_TIMEOUT}|g" ${NGINX_BASE_DIRECTORY}/nginx.conf
sed -i "s|\"\$request\"|\"\$request\" \"\$uri\"|g" ${NGINX_BASE_DIRECTORY}/nginx.conf
sed -i "s|#tcp_nopush     on|tcp_nopush      on|g" ${NGINX_BASE_DIRECTORY}/nginx.conf
sed -i "28a\    server_tokens     off;" ${NGINX_BASE_DIRECTORY}/nginx.conf
sed -i "29a\    #etag             off;" ${NGINX_BASE_DIRECTORY}/nginx.conf
vim ${NGINX_BASE_DIRECTORY}/nginx.conf
/usr/sbin/nginx -t
/usr/sbin/apachectl configtest
############################################################################
fi
#########################################
echo -e "Jp: Logrotate and Databaseをセットアップします。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: You set up the Logrotate and Database. [y] / Already one time when it is passed through the shell [n]"
read set_db_and_logrotate
if [ ${set_db_and_logrotate} = "y" ] ; then
#########################################
####
echo "Logrotate Setup."
cat <<EOF > /etc/logrotate.d/webserver
/var/www/logs/*log {
    create 0644 ${WEB_SERVER_SYSTEM_USER_GROUP} ${WEB_SERVER_SYSTEM_USER_GROUP}
    daily
    rotate 10
    missingok
    notifempty
    sharedscripts
    delaycompress
    postrotate
        /bin/systemctl reload php-fpm.service > /dev/null 2>/dev/null || true
        /bin/kill -USR1 `cat /run/nginx.pid 2>/dev/null` 2>/dev/null || true
    endscript
}
EOF
vim /etc/logrotate.d/webserver
#### DB
echo -e "MariaDB conf Edit."
sed -i "10a\innodb_buffer_pool_size = ${DB_BUFFER_POOL_SIZE}" ${MARIADB_CONF_DIR}
sed -i "11a\innodb_log_file_size = ${DB_LOG_FILE_SIZE}" ${MARIADB_CONF_DIR}
sed -i "12a\default-storage-engine = ${DB_STORAGE_ENGINE}\n" ${MARIADB_CONF_DIR}
vim ${MARIADB_CONF_DIR}
####
echo -e "Jp: Databaseを有効化します。[y]"
echo -e "En: Enabled Database. [y]"
read set_db_enabled
if [ ${set_db_enabled} = "y" ] ; then
systemctl enable php-fpm
systemctl enable nginx
systemctl enable mariadb
systemctl start php-fpm
systemctl start nginx
systemctl start mariadb
mysql_secure_installation
fi
####
fi
####
## clamd cron setup
echo -e "Jp: clamavのインストールしている場合は [y] / インストールしていない場合は [n]"
echo -e "En: If you have installed the clamav [y] / If you do not have installed [n]"
read websvclamd
if [ ${websvclamd} = "y" ] ; then
cat <<EOF > /etc/cron.daily/public
#!/bin/bash
ExcludeDirectory=/etc/.clamav/exclude
if [ -s \$ExcludeDirectory ]; then
for i in \`cat \$ExcludeDirectory\`
do
if [ \$(echo "\$i"|grep \/$) ]; then
i=\`echo \$i|sed -e 's/^\([^ ]*\)\/$/\1/p' -e d\`
excludeopt="\${excludeopt} --exclude-dir=\$i"
else
excludeopt="\${excludeopt} --exclude=\$i"
fi
done
fi
yum -y update clamav > /dev/null 2>&1
freshclam > /dev/null
clamscan --recursive --remove ${excludeopt} /var/www >> /home/${USER_NAME}/logs/clamscan/clamscan_pub.log 2>&1
cd /home/${USER_NAME}/logs/clamscan
mv clamscan_pub.log clamscan_pub."\$(date +%Y%m%d-%I%M%S).txt"
chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/logs/clamscan/*
EOF
#
chmod 700 /etc/cron.daily/public
vim /etc/cron.daily/public
fi
####
echo -e "WebServer Setup End."
####
