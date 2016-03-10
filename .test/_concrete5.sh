#!/bin/bash
#### lnmp-72 v1.0.7
############################################################################
source ./initfile
############################################################################
source ./01_base.txt
source ./not_edit_init.txt
############################################################################
source ./03_apps.txt
source ./05_c5.txt
############################################################################
clear
echo -e "Nginx: ${CONFIG_CMS_DOMAIN} / SSL Setup"
# DH PARAM
echo -e "DH PARAM SETUP. 2048bit [y] / 4096bit [n]"
read SETDHPARAM
if [ ${SETDHPARAM} = "y" ] ; then
echo -e "${FRONT_SSL_DH} / Generating dhparam in 2048bit"
openssl dhparam -out ${FRONT_SSL_DH} 2048
else
echo -e "${FRONT_SSL_DH} / Generating dhparam in 4096bit"
openssl dhparam -out ${FRONT_SSL_DH} 4096
fi
chown nginx ${FRONT_SSL_DH}
chmod 700 ${FRONT_SSL_DH}
#
############################################################################
#
echo -e "Nginx Setup HTTP/2.0"
cat <<EOF> ${NGINX_BASE_DIRECTORY}/${CMS_CONFIG_PREFIX}_h2_param
    http2_max_concurrent_streams 128;
    http2_max_field_size 4k;
    http2_max_header_size 16k;
    http2_recv_timeout 30s;
    http2_idle_timeout 3m;
    http2_chunk_size 8k;
EOF
vim ${NGINX_BASE_DIRECTORY}/${CMS_CONFIG_PREFIX}_h2_param
#
echo -e "HTTP Method Deny / Cache Control Setup"
cat <<EOF > ${NGINX_BASE_DIRECTORY}/${CMS_CONFIG_PREFIX}_set_header_control
        # Cache Setup
        #
        set \$do_not_cache       0;
        if (\$request_method != "GET") {
            set \$do_not_cache    1;
        }
        if (\$request_uri ~* "${NGINX_BACKEND_DIRECTORY}") {
            set \$do_not_cache   1;
        }
        # WordPress
        if (\$http_cookie ~* "${NGINX_BACKEND_COOKIE}") {
            set \$do_not_cache   1;
        }

        # Mobile UA Setup
        #
        set \$mobile "";
        if (\$http_user_agent ~* "DoCoMo|J-PHONE|Vodafone|MOT-|UP\.Browser|DDIPOCKET|ASTEL|PDXGW|Palmscape|Xiino|sharp pda browser|Windows CE|L-mode|WILLCOM|SoftBank|Semulator|Vemulator|J-EMULATOR|emobile|mixi-mobile-converter") {
            set \$mobile ".kt";
        }
        if (\$http_user_agent ~* "iPhone|iPod|Opera Mini|Android.*Mobile|NetFront|PSP|BlackBerry|Windows Phone") {
            set \$mobile ".sp";
        }

        # HTTP Method Deny
        #
        if (\$request_method !~ ^(GET|HEAD|POST)\$ ) {
            return 444;
        }

        # Referrer Spam Deny
        #
        include referrer_deny;

        # Cache Control
        #
        add_header Cache-Control "public, max-age=${NGINX_BACKEND_CACHE_RELOAD}";

EOF
vim ${NGINX_BASE_DIRECTORY}/${CMS_CONFIG_PREFIX}_set_header_control
#
############################################################################
#
mkdir ${NGINX_USER_SESSION_DIR}
chmod 700 ${NGINX_USER_SESSION_DIR}
chown ${WEB_SERVER_SYSTEM_USER_GROUP} ${NGINX_USER_SESSION_DIR}
cp /etc/php-fpm.d/www.conf /etc/php-fpm.d/${CMS_CONFIG_PREFIX}.conf
sed -i "s|^\[www\]$|[${CMS_CONFIG_PREFIX}]|g" /etc/php-fpm.d/${CMS_CONFIG_PREFIX}.conf
sed -i "s|^listen = /var/run/php-fpm/www.sock$|listen = ${BACKEND_LISTEN_WWW_SOCK}|g" /etc/php-fpm.d/${CMS_CONFIG_PREFIX}.conf
sed -i "s|^slowlog = /var/log/php-fpm/www-slow.log$|;\0|g" /etc/php-fpm.d/${CMS_CONFIG_PREFIX}.conf
sed -i "s|^php_admin_value\[error_log\]\ \=\ /var/log/php-fpm/www-error.log$|;\0|g" /etc/php-fpm.d/${CMS_CONFIG_PREFIX}.conf
sed -i "319a\slowlog = ${APACHE_LOG_DIRECTORY}/${CMS_CONFIG_PREFIX}-slow.log" /etc/php-fpm.d/${CMS_CONFIG_PREFIX}.conf
sed -i "414a\php_admin_value[error_log] = ${APACHE_LOG_DIRECTORY}/${CMS_CONFIG_PREFIX}-error.log" /etc/php-fpm.d/${CMS_CONFIG_PREFIX}.conf
sed -i "s|php_value\[session.save_path\]|;\0|g" /etc/php-fpm.d/${CMS_CONFIG_PREFIX}.conf
sed -i "s|php_value\[soap.wsdl_cache_dir\]|;\0|g" /etc/php-fpm.d/${CMS_CONFIG_PREFIX}.conf
sed -i "423a\php_value[session.save_path]    = ${NGINX_USER_SESSION_DIR}" /etc/php-fpm.d/${CMS_CONFIG_PREFIX}.conf
sed -i "424a\php_value[soap.wsdl_cache_dir]  = ${PHP_FPM_SOAP_CACHE_DIR}" /etc/php-fpm.d/${CMS_CONFIG_PREFIX}.conf
vim /etc/php-fpm.d/${CMS_CONFIG_PREFIX}.conf
#
############################################################################
#### Database Setup Start.
echo "Database cms Setup."
mysql -u root -p${DB_ROOT_PASSWD} -e "CREATE DATABASE ${CREATE_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u root -p${DB_ROOT_PASSWD} -e "GRANT ALL PRIVILEGES ON ${CREATE_DB_NAME}.* TO ${DB_USER_NAME}@localhost IDENTIFIED BY \"${DB_USER_PASSWD}\";"
mysql -u root -p${DB_ROOT_PASSWD} -e "FLUSH PRIVILEGES;"
mysql -u root -p${DB_ROOT_PASSWD} -e "SHOW DATABASES;"
mysql -u root -p${DB_ROOT_PASSWD} -e "SELECT host,user FROM mysql.user;"
mysql -u root -p${DB_ROOT_PASSWD}
#### Database Setup End.
############################################################################
clear
############################################################################
echo -e "Nginx PHP-FPM Setup."
cat <<EOF > ${NGINX_BASE_DIRECTORY}/php_${CMS_CONFIG_PREFIX}
# PHP-FPM SSL Setting.
#
    location ~ \.php(\$|/) {
        include                         /etc/nginx/fastcgi_params;
        fastcgi_pass                    unix:${BACKEND_LISTEN_WWW_SOCK};
        fastcgi_index                   index.php;
        fastcgi_split_path_info         ^(.+\.php)(.*)$;
        fastcgi_param                   SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_intercept_errors        on;
        fastcgi_ignore_client_abort     off;
        fastcgi_connect_timeout         60;
        fastcgi_send_timeout            180;
        fastcgi_read_timeout            180;
        fastcgi_buffer_size             ${NGINX_PROXY_BUFFER_SIZE};
        fastcgi_buffers                 ${NGINX_LARGE_CLIENT_NUM} ${NGINX_PROXY_BUFFER_SIZE};
        fastcgi_busy_buffers_size       ${NGINX_PROXY_BUFFER_SIZE};
        fastcgi_temp_file_write_size    ${NGINX_PROXY_BUFFER_SIZE};
        # Community
        fastcgi_param PHP_VALUE         "allow_url_fopen=On";
        fastcgi_param                   HTTPS on;
        fastcgi_pass_header            "X-Accel-Redirect";
        fastcgi_pass_header            "X-Accel-Expires";
    }
EOF
#
vim ${NGINX_BASE_DIRECTORY}/php_${CMS_CONFIG_PREFIX}
#
cat <<EOF > ${NGINX_BASE_DIRECTORY}/pretty_url
# PRETTY-URL SSL Setting.
#
    location ~ / {
        if (!-e \$request_filename) {
            rewrite ^ /index.php last;
        }
    }
EOF
#
vim ${NGINX_BASE_DIRECTORY}/pretty_url
# WordPress

# concrete5
############################################################################
echo -e "${CONFIG_CMS_DOMAIN} SSL PARAM SETUP."
############################################################################
# concrete5
cat <<EOF > ${NGINX_CONFIG_DIRECTORY}/10-${CONFIG_CMS_DOMAIN}.conf
#### HTTP Config.
##
server {
    listen      80;
    listen      [::]:80;
    server_name ${CONFIG_CMS_DOMAIN};

    root   ${APACHE_FILE_DIRECTORY}/${CMS_CONFIG_PREFIX};
    charset ${NGINX_DEFAULT_CHARSET};

    access_log  ${APACHE_LOG_DIRECTORY}/nginx_${CONFIG_CMS_DOMAIN}.log;

    location ~ /\.(${NGINX_DENY_ALL_DIR}) { deny  all; }

    location ~ /php.ini { deny  all; }

    location / {
        if (\$server_port = 80) {
            rewrite (.*) https://\$host\$request_uri last;
            break;
        }
    }

    # redirect server error pages to the static page /403.html
    #
    error_page  403              /403.html;
    location = /403.html {
        root   ${APACHE_ERROR_DIRECTORY};
    }

    # redirect server error pages to the static page /404.html
    #
    error_page  404              /404.html;
    location = /404.html {
        root   ${APACHE_ERROR_DIRECTORY};
    }

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   ${APACHE_ERROR_DIRECTORY};
    }

}

#### SSL Config.
##
server {
    listen      443 ssl http2;
    listen      [::]:443 ssl http2;
    server_name ${CONFIG_CMS_DOMAIN};

    ssl                          on;
    ssl_certificate              ${FRONT_SSL_CERT};
    ssl_certificate_key          ${FRONT_SSL_KEY};
    ssl_dhparam                  ${FRONT_SSL_DH};

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload";

    ssl_prefer_server_ciphers    on;

    ssl_session_cache shared:SSL:${FRONT_SSL_SESSION};
    ssl_session_timeout          ${FRONT_SSL_SESSION};

    ssl_protocols ${ALL_SSL_PROTOCOLS};
    ssl_ciphers ${ALL_SSL_CIPHERS};

    #ssl_stapling                 on;
    #ssl_stapling_verify          on;
    #ssl_trusted_certificate      ${FRONT_SSLCA_CERT};
    #resolver                     ${SETUP_VPS_DNS_PRI_IP} ${SETUP_VPS_DNS_SEC_IP} valid=300s;

    # TERTIARY DNS: ${SETUP_VPS_DNS_TER_IP}

    #resolver_timeout             10s;

    # HTTP/2.0
    include ${CMS_CONFIG_PREFIX}_h2_param;

    root   ${APACHE_FILE_DIRECTORY}/${CMS_CONFIG_PREFIX};
    index ${NGINX_INDEX_FILE_LIST};
    charset ${NGINX_DEFAULT_CHARSET};

    access_log  ${APACHE_LOG_DIRECTORY}/nginx_${CONFIG_CMS_DOMAIN}_ssl.log;

    location ~ /\.(${NGINX_DENY_ALL_DIR}) { deny  all; }

    location ~ /php.ini { deny  all; }

    # Header Control
    #
    include ${CMS_CONFIG_PREFIX}_set_header_control;

    location = /*\.(${NGINX_LOCATION_ASCII_FILE}) {
        access_log      ${NGINX_LOCATION_LOG};
        expires         ${NGINX_EXPIRES_DAY};
        log_not_found   ${NGINX_LOG_NOT_FOUND};
        break;
    }

    location = /*\.(${NGINX_LOCATION_BINARY_FILE}) {
        access_log      ${NGINX_LOCATION_LOG};
        expires         ${NGINX_EXPIRES_DAY};
        log_not_found   ${NGINX_LOG_NOT_FOUND};
        break;
    }

    location = /google([a-f0-9]\.html) {
        valid_referers    *.google.com;
        if (\$invalid_referer) {
            return 403;
        }
        access_log      ${NGINX_LOCATION_LOG};
        log_not_found   ${NGINX_LOG_NOT_FOUND};
    }

    location = /robots.txt {
        access_log      ${NGINX_LOCATION_LOG};
        log_not_found   ${NGINX_LOG_NOT_FOUND};
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # PHP-FPM
    include php_${CMS_CONFIG_PREFIX};

    # PRETTY-URL
    include pretty_url;

    # SSL Admin Area Setup
    # WordPress Admin Directory
    location ~ /index.php/(${NGINX_BACKEND_DIRECTORY}) {
        # API
        valid_referers    ${CONFIG_CMS_DOMAIN} *.concrete5.org *.concrete5-japan.org *.google.com;
        if (\$invalid_referer) {
            return 403;
        }
        # GeoIP
        if (\$allowed_country != yes) {
            return 444;
        }
        allow           127.0.0.1;
        allow           ${SERVER_STATIC_IP_ADDR};
        allow           ${GLOBAL_IP_ADDR};
        deny            all;
        gzip            off;
        gzip_vary       off;
        access_log      off;
        log_not_found   off;
    }

    # concrete5
    location ~ /files/ {
        valid_referers    ${CONFIG_CMS_DOMAIN} ${NGINX_REFERERS_URI};
        if (\$invalid_referer) {
            return 403;
        }
    }

    # concrete5 Config Files Access Setup
    location ~ /(config(/\.*)|database.php) {
        allow   127.0.0.1;
        allow   ${SERVER_STATIC_IP_ADDR};
        deny    all;
    }

    # redirect server error pages to the static page /403.html
    #
    error_page  403              /403.html;
    location = /403.html {
        root   ${APACHE_ERROR_DIRECTORY};
    }

    # redirect server error pages to the static page /404.html
    #
    error_page  404              /404.html;
    location = /404.html {
        root   ${APACHE_ERROR_DIRECTORY};
    }

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   ${APACHE_ERROR_DIRECTORY};
    }
}
EOF
vim ${NGINX_CONFIG_DIRECTORY}/10-${CONFIG_CMS_DOMAIN}.conf
############################################################################
/usr/sbin/nginx -t
/usr/sbin/php-fpm -t
############################################################################
## Install File Download.
mkdir ${APACHE_FILE_DIRECTORY}/${CMS_CONFIG_PREFIX}
cd ${APACHE_FILE_DIRECTORY}
wget ${C5_DL_URL}
mv ${APACHE_FILE_DIRECTORY}/index.html ${APACHE_FILE_DIRECTORY}/${C5_VERSION}.zip
unzip ${APACHE_FILE_DIRECTORY}/${C5_VERSION}.zip
rm -f ${APACHE_FILE_DIRECTORY}/${C5_VERSION}.zip
mv ${APACHE_FILE_DIRECTORY}/${C5_VERSION}/* ${APACHE_FILE_DIRECTORY}/${CMS_CONFIG_PREFIX}/
#
cat <<EOF > ${APACHE_FILE_DIRECTORY}/${CMS_CONFIG_PREFIX}/.user.ini
display_errors = On
error_log = ${APACHE_LOG_DIRECTORY}/${CMS_CONFIG_PREFIX}_php_error.log
memory_limit = ${PHP_MEM_LIMIT}
post_max_size = ${PHP_POST_MAX}
upload_max_filesize = ${PHP_UPLOAD_MAX}
session.cookie_secure = ${PHP_SESSION_COOKIE}
session.save_path = ${NGINX_USER_SESSION_DIR}
mbstring.language = Japanese
mbstring.internal_encoding = ${SERVER_DEFAULT_CHARSET}
mbstring.encoding_translation = Off
mbstring.http_input = pass
mbstring.http_output = pass
mbstring.detect_order = auto
soap.wsdl_cache_dir = ${PHP_FPM_SOAP_CACHE_DIR}
short_open_tag=On
EOF
vim ${APACHE_FILE_DIRECTORY}/${CMS_CONFIG_PREFIX}/.user.ini
#
rm -fr ${APACHE_FILE_DIRECTORY}/${C5_VERSION}
touch ${APACHE_FILE_DIRECTORY}/index.html
echo "<!-- index.html -->" >> ${APACHE_FILE_DIRECTORY}/index.html
chown -R ${WEB_SERVER_SYSTEM_USER_GROUP}:${WEB_SERVER_SYSTEM_USER_GROUP} ${APACHE_FILE_DIRECTORY}/*
chown -R ${WEB_SERVER_SYSTEM_USER_GROUP}:${WEB_SERVER_SYSTEM_USER_GROUP} /var/lib/php/*
echo "$C5_VERSION install end."

# concrete5
############################################################################
clear
/usr/sbin/nginx -t
/usr/sbin/php-fpm -t
echo -e "Jp: Webサーバを再起動しますか？ [y/n]"
echo -e "En: Do you want to restart the Web server? [y/n]"
read WP_WEBSERVER_RESTART
#####################################
if [ ${WP_WEBSERVER_RESTART} = "y" ]; then
#systemctl restart httpd
systemctl restart php-fpm
systemctl restart nginx
systemctl restart mariadb
fi
#####################################
clear
echo -e "Jp: 選択したCMSのインストールに関する事前準備は完了しました。"
echo -e "Jp: ブラウザを起動して引き続きインストール作業を行ってください。"
echo -e "Jp: その後 last_optimization を実行し、ファイルのチェックを行ってください。\n"
echo -e "En: Advance preparation on the installation of the selected CMS was completed."
echo -e "En: Please continue to perform the installation work by starting the browser."
echo -e "En: Then run the last_optimization, please do check of files."
#### Adminer Install.
#https://www.adminer.org/static/download/4.2.3/adminer-4.2.3.php
# Adminer Pluginでも可。
############################################################
############################################################