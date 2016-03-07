#!/bin/bash
#### lnmp-72 v1.0.7
############################################################################
source ./initfile
source ./base.txt
source ./config_init.txt
############################################################################
source ./server.txt
source ./apps.txt
############################################################################
clear
# Default GZIP Setting.
echo -e "Nginx Config Setting for CMS."
echo -e "\n"
echo -e "00. Default GZIP Setting."
cat <<EOF> ${NGINX_CONFIG_DIRECTORY}/00-gzip.conf
    gzip                    on;
    gzip_static             on;
    gzip_http_version       1.0;
    gzip_vary               on;
    gzip_comp_level         6;
    gzip_proxied            any;
    gzip_buffers            4 8k;
    gzip_types              text/plain text/xml text/css application/xhtml+xml application/xml application/rss+xml application/atom_xml application/x-javascript application/x-httpd-php;
    gzip_disable            "MSIE [1-6]\\.";
    gzip_disable            "Mozilla/4";
EOF
vim ${NGINX_CONFIG_DIRECTORY}/00-gzip.conf
#
# GeoIP Setting.
echo -e "01 GeoIP Setting."
cat <<EOF > ${NGINX_CONFIG_DIRECTORY}/01-GeoIP.conf
########################################################################
# GeoIP License
# This product includes GeoLite data created by MaxMind, available from 
# URL: http://www.maxmind.com
########################################################################
    geoip_country /usr/share/GeoIP/GeoIP.dat;
    map \$geoip_country_code \$allowed_country {
      default no;
      ${GEOIP_COUNTRY} yes;
    }
EOF
vim ${NGINX_CONFIG_DIRECTORY}/01-GeoIP.conf
#
echo -e "04 Header Secure Setup."
cat <<EOF > ${NGINX_CONFIG_DIRECTORY}/02-header.conf
# Header Secure Setup
add_header X-Frame-Options ${NGINX_HEADER_X_FRAME_OPT};
add_header X-Content-Type-Options ${NGINX_HEADER_X_CONTENT_TYPE_OPT};
add_header X-XSS-Protection "${NGINX_HEADER_X_XSS_PROTECT}";
add_header Content-Security-Policy "${NGINX_HEADER_CONTENT_SP}";
EOF
vim ${NGINX_CONFIG_DIRECTORY}/02-header.conf
####
echo -e "05 Header Buffer Setup."
cat <<EOF > ${NGINX_CONFIG_DIRECTORY}/03-buffer.conf
client_body_buffer_size ${NGINX_CLIENT_BODY};
client_header_buffer_size ${NGINX_CLIENT_HEAD};
client_max_body_size ${NGINX_CLIENT_MAXBODY};
large_client_header_buffers ${NGINX_LARGE_CLIENT_NUM} ${NGINX_LARGE_CLIENT_HEAD};
EOF
vim ${NGINX_CONFIG_DIRECTORY}/03-buffer.conf
####
echo -e "Nginx Setup HTTP/2.0"
cat <<EOF> ${NGINX_CONFIG_DIRECTORY}/04-h2.conf
    #Sets the size of the per worker input buffer.
    http2_recv_buffer_size 256k;
EOF
vim ${NGINX_CONFIG_DIRECTORY}/04-h2.conf
####
echo -e "Referer Spam Deny"
cat <<EOF > ${NGINX_BASE_DIRECTORY}/referrer_deny
set \$referrerspam 0;

if ( \$http_referer ~* '${RefererSpam00}' ){
  set \$referrerspam 1;
}
if ( \$http_referer ~* '${RefererSpam01}' ){
  set \$referrerspam 1;
}
if ( \$http_referer ~* '${RefererSpam02}' ){
  set \$referrerspam 1;
}
if ( \$http_referer ~* '${RefererSpam03}' ){
  set \$referrerspam 1;
}
if ( \$http_referer ~* '${RefererSpam04}' ){
  set \$referrerspam 1;
}
if ( \$http_referer ~* '${RefererSpam05}' ){
  set \$referrerspam 1;
}
if ( \$http_referer ~* '${RefererSpam06}' ){
  set \$referrerspam 1;
}
if ( \$http_referer ~* '${RefererSpam07}' ){
  set \$referrerspam 1;
}
if ( \$http_referer ~* '${RefererSpam08}' ){
  set \$referrerspam 1;
}
if ( \$http_referer ~* '${RefererSpam09}' ){
  set \$referrerspam 1;
}
if ( \$http_referer ~* '${RefererSpam10}' ){
  set \$referrerspam 1;
}
if ( \$http_referer ~* '${RefererSpam11}' ){
  set \$referrerspam 1;
}
# Deny of ReferrerSpam
if ( \$referrerspam = 1) {
  return 444;
}
EOF
vim ${NGINX_BASE_DIRECTORY}/referrer_deny
####
clear
############################################################################
#### Database Default Users DELETE Start.
echo "Database Default Users DELETE."
mysql -u root -p${DB_ROOT_PASSWD} -e "DELETE FROM mysql.user WHERE User='root' AND host IN ('127.0.0.1', '::1');"
mysql -u root -p${DB_ROOT_PASSWD} -e "FLUSH PRIVILEGES;"
mysql -u root -p${DB_ROOT_PASSWD} -e "SHOW DATABASES;"
mysql -u root -p${DB_ROOT_PASSWD} -e "SELECT host,user FROM mysql.user;"
mysql -u root -p${DB_ROOT_PASSWD}
#### Database Default Users DELETE End.
############################################################################
/usr/sbin/nginx -t
/usr/sbin/php-fpm -t
############################################################################
chmod +x ${INSTALL_PATH}/last_optimization