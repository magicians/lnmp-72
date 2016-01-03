#!/bin/bash
# == lnmp-70 v0.0.1 ==
source build
## Nginx Build on User Directory.
echo "Start Nginx Build"
mkdir -p ~/rpm/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}/
mkdir -p ~/rpm/RPMS/{noarch,x86_64}
## .rpmmacros Edit
echo "%_topdir $HOME/rpm" >> ~/.rpmmacros
vim ~/.rpmmacros
## Nginx SourceCode Install.
rpm -ivh http://dl.fedoraproject.org/pub/epel/7/SRPMS/n/${NGX_BUILD_SRPM}
## Nginx Source Directory.
cd ~/rpm/SOURCES
## Nginx Source Downloads.
curl -O http://nginx.org/download/${NGX_BUILD_SOURCE}
## Nginx BuildFile Edit.
## Nginx Version Edit.
sed -i "s|${NGX_BUILD_VERSION_SRPM}|${NGX_BUILD_VERSION_SOURCE}|g" ~/rpm/SPECS/nginx.spec
sed -i "102a\export LANG='ja_JP.UTF-8'" ~/rpm/SPECS/nginx.spec
##
echo "SSL / http2 Setup? [y]"
read ngxhttpv2mod
if [ ${ngxhttpv2mod} = "y" ] ; then
sed -i "s|--with-http_spdy_module|--with-http_v2_module|g" ~/rpm/SPECS/nginx.spec
fi
#
## nginx.spec Edit View.
vim ~/rpm/SPECS/nginx.spec
## Nginx Source Build Start.
rpmbuild -bb ~/rpm/SPECS/nginx.spec
ls -l ~/rpm/RPMS/noarch
ls -l ~/rpm/RPMS/x86_64
## Nginx Install
sudo rpm -ivh ~/rpm/RPMS/noarch/nginx-filesystem-${NGX_BUILD_VERSION_SOURCE}-${NGX_BUILD_VERSION_RE_SRPM}.el7.centos.noarch.rpm
sudo rpm -ivh ~/rpm/RPMS/x86_64/nginx-${NGX_BUILD_VERSION_SOURCE}-${NGX_BUILD_VERSION_RE_SRPM}.el7.centos.x86_64.rpm
sudo /usr/sbin/nginx -v
# SNI Check
sudo nginx -V 2>&1 | grep SNI
# TLS SNI support enabled
# http2 / v2_module
# http://nginx.org/en/docs/http/ngx_http_v2_module.html