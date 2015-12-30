#!/bin/bash
#### CentOS7-default-install.git v1.5.0
## Nginx Build on User Directory.
echo "Start Nginx Build"
mkdir -p ~/rpm/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}/
mkdir -p ~/rpm/RPMS/{noarch,x86_64}
## .rpmmacros Edit
echo "%_topdir $HOME/rpm" >> ~/.rpmmacros
vim ~/.rpmmacros
## Nginx SourceCode Install.
rpm -ivh http://dl.fedoraproject.org/pub/epel/7/SRPMS/n/nginx-1.6.3-7.el7.src.rpm
## Nginx Source Directory.
cd ~/rpm/SOURCES
## Nginx Source Downloads.
curl -O http://nginx.org/download/nginx-1.9.9.tar.gz
tar zxvf ~/rpm/SOURCES/nginx-1.9.9.tar.gz
## Nginx BuildFile Edit.
## Nginx Version Edit.
sed -i "s|1.6.3|1.9.9|g" ~/rpm/SPECS/nginx.spec
sed -i "102a\export LANG='ja_JP.UTF-8'" ~/rpm/SPECS/nginx.spec
##
echo "SSL / http2 Setup? [y]"
read ngxhttpv2mod
if [ ${ngxhttpv2mod} = "y" ] ; then
sed -i "s|--with-http_spdy_module|--with-http_v2_module|g" ~/rpm/SPECS/nginx.spec
fi
## Error Pages Server Version Delete.
sed -i 's|^static char ngx_http_server_full_string\[\] = "Server: " NGINX_VER CRLF;$|/* & */|g' ~/rpm/SOURCES/nginx-1.9.9/src/http/ngx_http_header_filter_module.c
sed -i '50a\static char ngx_http_server_full_string[] = "Server: Nginx Server "CRLF;' ~/rpm/SOURCES/nginx-1.9.9/src/http/ngx_http_header_filter_module.c
vim ~/rpm/SOURCES/nginx-1.9.9/src/http/ngx_http_header_filter_module.c
tar zcvf ~/rpm/SOURCES/nginx-1.9.9.tar.gz ~/rpm/SOURCES/nginx-1.9.9
rm -fr ~/rpm/SOURCES/nginx-1.9.9
#
## nginx.spec Edit View.
vim ~/rpm/SPECS/nginx.spec
## Nginx Source Build Start.
rpmbuild -bb ~/rpm/SPECS/nginx.spec
ls -l ~/rpm/RPMS/noarch
ls -l ~/rpm/RPMS/x86_64
## Nginx Install
sudo rpm -ivh ~/rpm/RPMS/noarch/nginx-filesystem-1.9.9-7.el7.centos.noarch.rpm
sudo rpm -ivh ~/rpm/RPMS/x86_64/nginx-1.9.9-7.el7.centos.x86_64.rpm
sudo /usr/sbin/nginx -v
# SNI Check
sudo nginx -V 2>&1 | grep SNI
# TLS SNI support enabled
# http2 / v2_module
# http://nginx.org/en/docs/http/ngx_http_v2_module.html