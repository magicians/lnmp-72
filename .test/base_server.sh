#!/bin/bash
#### lnmp-72 v1.0.7
############################################################################
source ./initfile
############################################################################
source ./01_base.txt
source ./not_edit_init.txt
############################################################################
# totem on Malware Infection. / uninstall.
yum remove -y totem*
yum -y install firewalld
echo -e "Jp: ローカルセットアップを開始します。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: It will start the local setup. [y] / Already one time when it is passed through the shell [n]"
read set_localnet
####
if [ ${set_localnet} = "y" ] ; then
#### 接続先を固定する、他からの接続は原則拒否推奨。
echo -e "Jp: 接続は固定IPですか？ [y]"
echo -e "En: Is the connection fixed IP? [y]"
read set_connection_ip
############
if [ ${set_connection_ip} = "y" ] ; then
# 固定IPによる接続
	echo "sshd: ${GLOBAL_IP_ADDR}" >> /etc/hosts.allow
	echo "ALL: ALL" >> /etc/hosts.deny
fi
############
vi /etc/hosts.allow && vi /etc/hosts.deny
fi
####
############################################################################
#### アクセス権限をユーザに付与。
############################################################################
#
echo -e "Jp: アクセス権限をユーザに付与します [y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: It will grant access privileges to users. [y] / Already one time when it is passed through the shell [n]"
read set_accessuser
if [ ${set_accessuser} = "y" ] ; then
sed -i "s|^#auth\t\trequired|auth\t\trequired|" /etc/pam.d/su
#
vi /etc/pam.d/su
visudo
echo -e "Locale Setup. / LANG=${SERVER_DEFAULT_LANG}"
localectl
localectl set-locale LANG=${SERVER_DEFAULT_LANG}
localectl
fi
#
############################################################################
#### SSHの初期設定。
############################################################################
#
echo -e "Jp: SSHの初期設定を開始します。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: It will start the initial configuration of the SSH. [y] / Already one time when it is passed through the shell [n]"
read set_sshdconfig
if [ ${set_sshdconfig} = "y" ] ; then
## SSH ポート変更
sed -i "s|^#Port 22$|Port $SSH_EDIT_PORT|" /etc/ssh/sshd_config
## SSH rootでのログインを不可にする
sed -i "s|^#PermitRootLogin yes|PermitRootLogin no|" /etc/ssh/sshd_config
sed -i "s|^PermitRootLogin yes|PermitRootLogin no|" /etc/ssh/sshd_config
## SSH 空パスワードによるログインを不可にする
#sed -i "s|^#PermitEmptyPasswords no$|PermitEmptyPasswords no|g" /etc/ssh/sshd_config
## SSH 公開鍵での接続を有効化する
sed -i "s|^#PubkeyAuthentication yes|PubkeyAuthentication yes|" /etc/ssh/sshd_config
## SSH パスワードによるログインを不可にする
sed -i "s|^PasswordAuthentication yes|PasswordAuthentication no|" /etc/ssh/sshd_config
## SSH でログインするユーザを指定する
echo "AllowUsers ${USER_NAME}" >> /etc/ssh/sshd_config
## sshd_config の確認・及び間違いがあれば変更する
vi /etc/ssh/sshd_config
## sshd_config のテスト
sshd -t
fi
#
############################################################################
#### iptablesセットアップ・シェルスクリプトを作成。
############################################################################
#
echo -e "Jp: iptables-servicesのインストール [y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: installation of iptables-services [y] / Already one time when it is passed through the shell [n]"
read set_iptables_serv
if [ ${set_iptables_serv} = "y" ] ; then
yum -y install iptables-services
systemctl stop firewalld
systemctl disable firewalld
systemctl start iptables
systemctl enable iptables
systemctl is-enabled iptables
fi
# iptablesセットアップ
echo -e "Jp: iptablesセットアップ [y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: iptables setup [y] / Already one time when it is passed through the shell [n]"
read set_iptables_param
if [ ${set_iptables_param} = "y" ] ; then
# iptables setup.
echo -e "iptables setup."
cat <<EOF > /home/${USER_NAME}/.ipv4tables_setup
#!/bin/bash

#COMMIT File
IPv4_TABLES_CONF_TMP=\`mktemp\`

#iptablesの停止
systemctl stop iptables

#COMMIT Start
echo "*filter" >> \$IPv4_TABLES_CONF_TMP
#デフォルトルール

echo ":INPUT DROP [0:0]" >> \$IPv4_TABLES_CONF_TMP
echo ":FORWARD DROP [0:0]" >> \$IPv4_TABLES_CONF_TMP
echo ":OUTPUT ACCEPT [0:0]" >> \$IPv4_TABLES_CONF_TMP

#ループバック
echo "-A INPUT -i lo -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP

#ICMP ACCEPT
echo "-A INPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP
echo "-A INPUT -p icmp -m icmp --icmp-type 8 -m hashlimit --hashlimit-name t_icmp --hashlimit 1/m --hashlimit-burst ${HASH_LIMIT_PACKET} --hashlimit-mode srcip --hashlimit-htable-expire ${HASH_LIMIT_TIME} -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP

#ICMP さくらのシンプル監視のみ許可
echo "-A INPUT -s ${MONITORING_SERVER_IPADDR} -p icmp -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP
echo "-A INPUT -s ${MONITORING_SERVER_IPADDR} -p tcp -m tcp --dport 80 -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP
echo "-A INPUT -s ${MONITORING_SERVER_IPADDR} -p tcp -m tcp --dport 443 -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP

#パケットチェック
echo "-A INPUT -p 50 -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP
echo "-A INPUT -p 51 -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP

#マルチキャストDNS
echo "-A INPUT -d 224.0.0.251/32 -p udp -m udp --dport 5353 -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP

#接続時のSSHポート及びサーバポートの設定
#SSH
echo "-A INPUT -p tcp -m state --syn --state NEW --dport ${SSH_EDIT_PORT} -m hashlimit --hashlimit-name t_sshd --hashlimit 1/m --hashlimit-burst ${HASH_LIMIT_PACKET} --hashlimit-mode srcip --hashlimit-htable-expire ${HASH_LIMIT_TIME} -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP
#HTTP
echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP
#HTTPS
echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP

#FTPからの接続は破棄
echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 20 -j DROP" >> \$IPv4_TABLES_CONF_TMP
echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 21 -j DROP" >> \$IPv4_TABLES_CONF_TMP
echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 23 -j DROP" >> \$IPv4_TABLES_CONF_TMP

#LOCAL IP Addr ACCEPT, プライベートネットワークを構築している場合のみ変更する
echo "-A INPUT -s ${LOCAL_IP_ADDR} -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP
echo "-A INPUT -d ${LOCAL_IP_ADDR} -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP

#接続済みのセッションを接続許可
echo "-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT" >> \$IPv4_TABLES_CONF_TMP

#セキュアセットアップ・外部からのSNMP通信(UDP:161)をFWで破棄
echo "-A INPUT -p udp -m udp --dport 161 -j DROP" >> \$IPv4_TABLES_CONF_TMP

#セキュアセットアップ・データを持たないパケットの接続を破棄
echo "-A INPUT -p tcp -m tcp --tcp-flags ALL NONE -j DROP" >> \$IPv4_TABLES_CONF_TMP

#セキュアセットアップ・SYNflood攻撃と思われる接続を破棄
echo "-A INPUT -p tcp -m tcp ! --syn -m state --state NEW -j DROP" >> \$IPv4_TABLES_CONF_TMP

#セキュアセットアップ・ステルススキャン接続を破棄
echo "-A INPUT -p tcp -m tcp --tcp-flags ALL ALL -j DROP" >> \$IPv4_TABLES_CONF_TMP

#セキュアセットアップ・ブロードキャスト・パケットの破棄
echo "-A INPUT -m pkttype --pkt-type broadcast -j DROP" >> \$IPv4_TABLES_CONF_TMP

#セキュアセットアップ・マルチキャスト・パケットの破棄
echo "-A INPUT -m pkttype --pkt-type multicast -j DROP" >> \$IPv4_TABLES_CONF_TMP

#セキュアセットアップ・無効ヘッダがあるTCPパケットを破棄
echo "-A INPUT -m state --state INVALID -j DROP" >> \$IPv4_TABLES_CONF_TMP

#セキュアセットアップ・ブロードキャストからの接続を破棄
echo "-A INPUT -d 0.0.0.0/8 -j DROP" >> \$IPv4_TABLES_CONF_TMP
echo "-A INPUT -d 255.255.255.255/32 -j DROP" >> \$IPv4_TABLES_CONF_TMP
echo "-A INPUT -d 224.0.0.1 -j DROP" >> \$IPv4_TABLES_CONF_TMP
echo "-A INPUT -j DROP" >> \$IPv4_TABLES_CONF_TMP

##セキュアセットアップ・Ping及び113ポートからの接続を拒否
echo "-A INPUT -p tcp -m tcp --dport 113 -j REJECT --reject-with tcp-reset" >> \$IPv4_TABLES_CONF_TMP
echo "-A INPUT -j REJECT --reject-with icmp-host-prohibited" >> \$IPv4_TABLES_CONF_TMP
echo "-A FORWARD -j REJECT --reject-with icmp-host-prohibited" >> \$IPv4_TABLES_CONF_TMP

#COMMIT End
echo "COMMIT" >> \$IPv4_TABLES_CONF_TMP

#iptablesの保存
cat \$IPv4_TABLES_CONF_TMP > /etc/sysconfig/iptables

#iptablesの起動
systemctl start iptables
iptables -L
EOF
vi /home/${USER_NAME}/.ipv4tables_setup
#
# ip6tables
cat <<EOF > /home/${USER_NAME}/.ipv6tables_setup
#!/bin/bash

#COMMIT File
IPv6_TABLES_CONF_TMP=\`mktemp\`

#iptablesの停止
systemctl stop ip6tables

#COMMIT Start
echo "*filter" >> \$IPv6_TABLES_CONF_TMP
#デフォルトルール

echo ":INPUT DROP [0:0]" >> \$IPv6_TABLES_CONF_TMP
echo ":FORWARD DROP [0:0]" >> \$IPv6_TABLES_CONF_TMP
echo ":OUTPUT ACCEPT [0:0]" >> \$IPv6_TABLES_CONF_TMP

#接続済みのセッションを接続許可
echo "-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT" >> \$IPv6_TABLES_CONF_TMP

#ICMP ACCEPT
echo "-A INPUT -p ipv6-icmp -j ACCEPT" >> \$IPv6_TABLES_CONF_TMP

#ループバック
echo "-A INPUT -i lo -j ACCEPT" >> \$IPv6_TABLES_CONF_TMP
echo "-A INPUT -d fe80::/64 -p udp -m udp --dport 546 -m state --state NEW -j ACCEPT" >> \$IPv6_TABLES_CONF_TMP

#パケットチェック
echo "-A INPUT -p 50 -j ACCEPT" >> \$IPv6_TABLES_CONF_TMP
echo "-A INPUT -p 51 -j ACCEPT" >> \$IPv6_TABLES_CONF_TMP

#接続時のSSHポート及びサーバポートの設定
#SSH
#echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT" >> \$IPv6_TABLES_CONF_TMP
#HTTP
echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT" >> \$IPv6_TABLES_CONF_TMP
#HTTPS
echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT" >> \$IPv6_TABLES_CONF_TMP

#FTPからの接続は破棄
echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 20 -j DROP" >> \$IPv6_TABLES_CONF_TMP
echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 21 -j DROP" >> \$IPv6_TABLES_CONF_TMP
echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 23 -j DROP" >> \$IPv6_TABLES_CONF_TMP

#外部からのSNMP通信(UDP:161)をFWで破棄
echo "-A INPUT -p udp -m udp --dport 161 -j DROP" >> \$IPv6_TABLES_CONF_TMP

#セキュアセットアップ・データを持たないパケットの接続を破棄
echo "-A INPUT -p tcp -m tcp --tcp-flags ALL NONE -j DROP" >> \$IPv6_TABLES_CONF_TMP

#セキュアセットアップ・SYNflood攻撃と思われる接続を破棄
echo "-A INPUT -p tcp -m tcp ! --syn -m state --state NEW -j DROP" >> \$IPv6_TABLES_CONF_TMP

#セキュアセットアップ・ステルススキャン接続を破棄
echo "-A INPUT -p tcp -m tcp --tcp-flags ALL ALL -j DROP" >> \$IPv6_TABLES_CONF_TMP

#ブロードキャスト・パケットの破棄
echo "-A INPUT -m pkttype --pkt-type broadcast -j DROP" >> \$IPv6_TABLES_CONF_TMP

#マルチキャスト・パケットの破棄
echo "-A INPUT -m pkttype --pkt-type multicast -j DROP" >> \$IPv6_TABLES_CONF_TMP

#無効ヘッダがあるTCPパケットを破棄
echo "-A INPUT -m state --state INVALID -j DROP" >> \$IPv6_TABLES_CONF_TMP

#ALL
echo "-A INPUT -j DROP" >> \$IPv6_TABLES_CONF_TMP

##セキュアセットアップ・Ping及び113ポートからの接続を拒否
echo "-A INPUT -p tcp -m tcp --dport 113 -j REJECT --reject-with tcp-reset" >> \$IPv6_TABLES_CONF_TMP
echo "-A INPUT -j REJECT --reject-with icmp6-adm-prohibited" >> \$IPv6_TABLES_CONF_TMP
echo "-A FORWARD -j REJECT --reject-with icmp6-adm-prohibited" >> \$IPv6_TABLES_CONF_TMP

#COMMIT End
echo "COMMIT" >> \$IPv6_TABLES_CONF_TMP

#iptablesの保存
cat \$IPv6_TABLES_CONF_TMP > /etc/sysconfig/ip6tables

#iptablesの起動
systemctl start ip6tables
ip6tables -L
EOF
vi /home/${USER_NAME}/.ipv6tables_setup
chmod 400 /home/${USER_NAME}/.ipv6tables_setup
chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.ipv6tables_setup
#
############################################################################
#### ユーザディレクトリにiptablesセットアップ・シェルスクリプトを保存。
############################################################################
#
echo -e "Jp: セットアップ先はグローバル環境ですか？ [y/n]"
echo -e "En: Is the destination is a global environment? [y/n]"
read set_globaliptables_param
if [ ${set_globaliptables_param} = "y" ] ; then
	# グローバル環境では使わない。※ ローカル環境専用
	sed -i "s|^echo \"-A INPUT -s ${LOCAL_IP_ADDR} -j ACCEPT\" >> \$IPv4_TABLES_CONF_TMP$|#\0|g" /home/${USER_NAME}/.ipv4tables_setup
	sed -i "s|^echo \"-A INPUT -d ${LOCAL_IP_ADDR} -j ACCEPT\" >> \$IPv4_TABLES_CONF_TMP$|#\0|g" /home/${USER_NAME}/.ipv4tables_setup
fi
clear
echo -e "Jp: さくらのシンプル監視のご利用について？ : 未使用 [ y ] / 利用 [ n ]"
echo -e "En: About the use of Sakura of simple monitoring? : Unused [y] / use [n]"
read set_sakura_simple_monitoring
if [ ${set_sakura_simple_monitoring} = "y" ] ; then
	sed -i "s|^echo \"-A INPUT -s ${MONITORING_SERVER_IPADDR} -p|#\0|g" /home/${USER_NAME}/.ipv4tables_setup
else
	sed -i "s|^echo \"-A INPUT -p icmp -m icmp --icmp-type 0|#\0|g" /home/${USER_NAME}/.ipv4tables_setup
	sed -i "s|^echo \"-A INPUT -p icmp -m icmp --icmp-type 8|#\0|g" /home/${USER_NAME}/.ipv4tables_setup
fi
vi /home/${USER_NAME}/.ipv4tables_setup
## ユーザディレクトリに保存したセットアップ・シェルスクリプトのアクセス権を変更。
chmod 400 /home/${USER_NAME}/.ipv4tables_setup
chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.ipv4tables_setup
chmod 701 /home/${USER_NAME}
#
systemctl enable ip6tables
systemctl is-enabled ip6tables
systemctl start ip6tables
sh /home/${USER_NAME}/.ipv4tables_setup
sh /home/${USER_NAME}/.ipv6tables_setup
#
vi /etc/sysconfig/iptables
vi /etc/sysconfig/ip6tables
fi
#
############################################################################
## iptablesの確認とip6tables-IPv6の無効化
systemctl restart sshd
ss -lt
#
############################################################################
## SELINUXの変更。SakuraVPSでは既に disabled されているのでデフォルトで n を選択して下さい。
echo -e "Jp: SELINUXを無効化します。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: isable SELINUX. [y] / Already one time when it is passed through the shell [n]"
read set_selinux_config
if [ ${set_selinux_config} = "y" ] ; then
getenforce
setenforce 0
getenforce
sed -i 's|^SELINUX=enforcing$|SELINUX=disabled|g' /etc/selinux/config
vi /etc/selinux/config && vi /etc/sysconfig/selinux
#
fi
############################################################################
#### リポジトリの追加。
############################################################################
#
echo -e "Jp: CentOS7のリポジトリを追加します。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: It'll add the CentOS7 repository. [y] / Already one time when it is passed through the shell [n]"
read set_centos7_repository
if [ ${set_centos7_repository} = "y" ] ; then
## Rpmforge Repository
echo -e "Jp: CentOS7のリポジトリを追加します。"
echo -e "En: It'll add the CentOS7 repository."
rpm --import ${RepoRPMForgeGPG}
rpm -ivh ${RepoRPMForgex86}
#
## Epel Repository
rpm --import ${RepoEpelGPG}
rpm -ivh ${RepoEPELx86}
#
## Elrepo Repository
rpm --import ${RepoElrepoGPG}
rpm -ivh ${RepoElrepox86}
#
## Remi Repository
rpm --import ${RepoRemiGPG}
rpm -ivh ${RepoRemix86}
#
############################################################################
#
sed -i "11a\exclude=clam*" /etc/yum.repos.d/rpmforge.repo
vi /etc/yum.repos.d/rpmforge.repo && vi /etc/yum.repos.d/epel.repo && vi /etc/yum.repos.d/elrepo.repo && vi /etc/yum.repos.d/remi.repo
#
## 各リリースのアップデート
yum -y update rpmforge-release epel-release elrepo-release remi-release
#
fi
############################################################################
#### yumアップデート、グループインストール、yum-cronのインストール。
############################################################################
#
echo -e "Jp: yumアップデート、グループインストール、yum-cronのインストールを開始します。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: yum update, group installation, you will start the installation of the yum-cron. [y] / Already one time when it is passed through the shell [n]"
read set_yum_update
if [ ${set_yum_update} = "y" ] ; then
yum -y update
yum -y install git mercurial etckeeper
touch /etc/.gitignore
echo "shadow*" >> /etc/.gitignore
echo "gshadow*" >> /etc/.gitignore
echo "passwd*" >> /etc/.gitignore
echo "group*" >> /etc/.gitignore
vi /etc/.gitignore
#
yum -y groupinstall "Base" "Development tools" "Japanese Support"
# CentOS7 httpd normal install.
yum -y install pcre-devel zlib-devel openssl-devel libxslt-devel GeoIP-devel gd-devel perl-ExtUtils-Embed gperftools-devel httpd-devel httpd mod_ssl mod_geoip GeoIP
#
## yum-cron install
yum -y install yum-cron
sudo sed -i "s|^apply_updates = no$|apply_updates = yes|g" /etc/yum/yum-cron.conf
vim /etc/yum/yum-cron.conf
systemctl enable yum-cron
systemctl start yum-cron
systemctl is-enabled yum-cron
## yum clean all
yum clean all
# etckeeper init
etckeeper init
etckeeper commit "VPS Installed First Commit."
# CentOS7.2 Error Log
sed -i "s|authpriv.*|#\0|g" /etc/rsyslog.conf
sed -i "57a\authpriv.notice                                          /var/log/secure" /etc/rsyslog.conf
vim /etc/rsyslog.conf
fi
#
############################################################################
#### denyhosts install. Denyhosts の追加。
############################################################################
#
echo -e "Jp: denyhostsのインストールを開始します。[y/n]"
echo -e "En: It will start the installation of denyhosts.[y/n]"
read set_sakurasms
if [ ${set_sakurasms} = "y" ] ; then
yum -y install denyhosts
echo "${GLOBAL_IP_ADDR}" >> /var/lib/denyhosts/allowed-hosts
echo "${MONITORING_SERVER_IPADDR}" >> /var/lib/denyhosts/allowed-hosts
vim /var/lib/denyhosts/allowed-hosts
systemctl enable denyhosts
systemctl start denyhosts
systemctl is-enabled denyhosts
fi
#
############################################################################
############################################################################
#### ユーザディレクトリにスキャンログを保存する。
############################################################################
#
echo -e "Jp: ユーザディレクトリにスキャンログディレクトリを作成。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: Create a scan log directory to the user directory. [y] / Already one time when it is passed through the shell [n]"
read set_user_logs
if [ ${set_user_logs} = "y" ] ; then
mkdir -p /home/${USER_NAME}/logs/clamscan
chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/logs/*
chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/logs
fi
#
############################################################################
#### 管理者用メールを設定する。ログ管理ソフトウェアも追加。
############################################################################
#
echo -e "Jp: 管理者用メールを設定する。ログ管理ソフトウェアも追加。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: It sets up a mail for the administrator. Additional log management software. [y] / Already one time when it is passed through the shell [n]"
read set_logwatch_inst
if [ ${set_logwatch_inst} = "y" ] ; then
sed -i '/^root:/d' /etc/aliases
echo "root:           ${ALIASES_ROOT_MAIL_ADDR}" >> /etc/aliases
vi /etc/aliases
newaliases
echo test | mail root
yum -y install logwatch
fi
#
############################################################################
#### rkhunter install. 先に入れた物より比較的更新頻度が高いチェッカーを追加する。
############################################################################
#
echo -e "Jp: rkhunterのインストール。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: installation of rkhunter. [y] / Already one time when it is passed through the shell [n]"
read set_rkhunter_inst
if [ ${set_rkhunter_inst} = "y" ] ; then
yum -y install rkhunter
rkhunter --update
mkdir /etc/.clamav
touch /etc/.clamav/exclude
sed -i "641a\# for Clamav" /etc/rkhunter.conf
sed -i "642a\ALLOWHIDDENDIR=/etc/.clamav" /etc/rkhunter.conf
sed -i "684a\# for Clamav" /etc/rkhunter.conf
sed -i "685a\ALLOWHIDDENFILE=/etc/.clamav/exclude" /etc/rkhunter.conf
sed -i "686a\#Passwd" /etc/rkhunter.conf
sed -i "687a\ALLOWHIDDENFILE=/etc/.pwd.lock" /etc/rkhunter.conf
sed -i "308a\ALLOW_SSH_ROOT_USER=no" /etc/rkhunter.conf
sed -i "s|^ALLOW_SSH_ROOT_USER=unset$|#ALLOW_SSH_ROOT_USER=unset|g" /etc/rkhunter.conf
vi /etc/rkhunter.conf
# passwd / group permission 604
chmod 604 /etc/{passwd,passwd-,group,group-}
ls -la /etc | grep passwd*
ls -la /etc | grep group*
clear
rkhunter --propupd
rkhunter --check --skip-keypress --report-warnings-only --no-mail-on-warning
#
fi
#
############################################################################
#### tripwire install. 改竄チェック
############################################################################
#
echo -e "Jp: tripwireのインストール。[y] / 既に一回このシェルを通している場合/必要無い場合 [n]"
echo -e "En: installation of tripwire. [y] / Already one time when it is passed through the shell [n]"
####
read set_tripwire_inst
if [ ${set_tripwire_inst} = "y" ] ; then
yum -y install tripwire
tripwire-setup-keyfiles
sed -i 's/^LOOSEDIRECTORYCHECKING\s\+=false$/LOOSEDIRECTORYCHECKING =true/' /etc/tripwire/twcfg.txt
twadmin -m F -c /etc/tripwire/tw.cfg -S /etc/tripwire/site.key /etc/tripwire/twcfg.txt
#
cat <<EOF > /etc/tripwire/twpolmake.pl
#!/usr/bin/perl
# Tripwire Policy File customize tool
# ----------------------------------------------------------------
# Copyright (C) 2003 Hiroaki Izumi
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
# ----------------------------------------------------------------
# Usage:
#    perl twpolmake.pl {Pol file}
# ----------------------------------------------------------------
#
\$POLFILE=\$ARGV[0];

open(POL,"\$POLFILE") or die "open error: \$POLFILE" ;
my(\$myhost,\$thost) ;
my(\$sharp,\$tpath,\$cond) ;
my(\$INRULE) = 0 ;

while (<POL>) {
    chomp;
    if ((\$thost) = /^HOSTNAME\s*=\s*(.*)\s*;/) {
        \$myhost = \`hostname\` ; chomp(\$myhost) ;
        if (\$thost ne \$myhost) {
            \$_="HOSTNAME=\"\$myhost\";" ;
        }
    }
    elsif ( /^{/ ) {
        \$INRULE=1 ;
    }
    elsif ( /^}/ ) {
        \$INRULE=0 ;
    }
    elsif (\$INRULE == 1 and (\$sharp,\$tpath,\$cond) = /^(\s*\#?\s*)(\/\S+)\b(\s+->\s+.+)\$/) {
        \$ret = (\$sharp =~ s/\#//g) ;
        if (\$tpath eq '/sbin/e2fsadm' ) {
            \$cond =~ s/;\s+(tune2fs.*)\$/; \#\$1/ ;
        }
        if (! -s \$tpath) {
            \$_ = "\$sharp#\$tpath\$cond" if (\$ret == 0) ;
        }
        else {
            \$_ = "\$sharp\$tpath\$cond" ;
        }
    }
    print "\$_\n" ;
}
close(POL) ;
EOF
#
## 先に生成していたパスワードを数回にわけて打ち込む。※コピペでも可。
#
vim /etc/tripwire/twpolmake.pl
perl /etc/tripwire/twpolmake.pl /etc/tripwire/twpol.txt > /etc/tripwire/twpol.txt.new
twadmin -m P -c /etc/tripwire/tw.cfg -p /etc/tripwire/tw.pol -S /etc/tripwire/site.key /etc/tripwire/twpol.txt.new
#
rm -f /etc/tripwire/twcfg.txt*
rm -f /etc/tripwire/twpol.txt*
tripwire -m i -s -c /etc/tripwire/tw.cfg
tripwire --init
tripwire --check
#
## crontab set tripwire.sh Cronで定期的にチェックさせる
cat <<EOF > /etc/cron.daily/tripwire.sh
#!/bin/bash

PATH=/usr/sbin:/usr/bin:/bin:/usr/local/tripwire/sbin

# パスフレーズ設定
SITEPASS=${INITSITEPASS}  # サイトパスフレーズ
LOCALPASS=${INITLOCALPASS} # ローカルパスフレーズ

cd /etc/tripwire

# Tripwireチェック実行
tripwire -m c -s -c tw.cfg|mail -s "Tripwire(R) Integrity Check Report in `hostname`" root

# ポリシーファイル最新化
twadmin -m p -c tw.cfg -p tw.pol -S site.key > twpol.txt
perl twpolmake.pl twpol.txt > twpol.txt.new
twadmin -m P -c tw.cfg -p tw.pol -S site.key -Q \$SITEPASS twpol.txt.new > /dev/null
rm -f twpol.txt* *.bak

# データベース最新化
rm -f /usr/local/tripwire/lib/tripwire/*.twd*
tripwire -m i -s -c tw.cfg -P \$LOCALPASS
EOF
####
vim /etc/cron.daily/tripwire.sh
chmod 700 /etc/cron.daily/tripwire.sh
####
fi
#
############################################################################
#### clamd install. VirusScanを追加。
############################################################################
#
echo -e "Jp: clamavのインストール。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: installation of clamav. [y] / Already one time when it is passed through the shell [n]"
read set_clamav_inst
if [ ${set_clamav_inst} = "y" ] ; then
yum install clamav clamav-update
# Freshclam Setup
sed -i "s|^Example|#\0|g" /etc/freshclam.conf
sed -i "s|^#DatabaseDirectory /var/lib/clamav$|DatabaseDirectory /var/lib/clamav|g" /etc/freshclam.conf
sed -i "s|^#UpdateLogFile /var/log/freshclam.log$|UpdateLogFile /var/log/freshclam.log|g" /etc/freshclam.conf
sed -i "s|^DatabaseOwner clamupdate$|#\0|g" /etc/freshclam.conf
sed -i "s|^DatabaseMirror database.clamav.net$|#\0|g" /etc/freshclam.conf
sed -i "56a\DatabaseOwner root" /etc/freshclam.conf
sed -i "80a\DatabaseMirror db.jp.clamav.net" /etc/freshclam.conf
sed -i "s|^FRESHCLAM_DELAY=disabled-warn|#\0|g" /etc/sysconfig/freshclam
vim /etc/freshclam.conf
vim /etc/sysconfig/freshclam
# ExcludeDirectory
echo "/proc/" >> /etc/.clamav/exclude
echo "/sys/" >> /etc/.clamav/exclude
vim /etc/.clamav/exclude
chmod 700 /etc/.clamav
chmod 600 /etc/.clamav/exclude
#
## clamd cron setup
cat <<EOF > /etc/cron.daily/clamscan
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
clamscan -i -r --remove ${excludeopt} /home >> /home/${USER_NAME}/logs/clamscan/clamscan.log 2>&1
cd /home/${USER_NAME}/logs/clamscan
mv clamscan.log clamscan."\$(date +%Y%m%d-%I%M%S).txt"
chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/logs/clamscan/*
EOF
#
chmod 700 /etc/cron.daily/clamscan
vim /etc/cron.daily/clamscan
## clamd startup
rm -f /etc/cron.d/clamav-update
freshclam
clamscan --infected --remove --recursive
#
fi
## ntp.conf Edit
systemctl stop ntpd
systemctl disable ntpd
systemctl is-enabled ntpd
#
## sysctl Edit IPv6の無効化及び、PostfixをIPv4のみ設定にする。
#
echo -e "Jp: sysctlのセットアップ。[y] / 既に一回このシェルを通している場合は [n]"
echo -e "En: sysctl setup. [y] / Already one time when it is passed through the shell [n]"
read set_sysctl_setup
if [ ${set_sysctl_setup} = "y" ] ; then
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
echo "net.ipv4.icmp_ignore_bogus_error_responses = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rfc1337 = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 15" >> /etc/sysctl.conf
vi /etc/sysctl.conf
sysctl -p
sed -i 's|^inet_protocols = all$|inet_protocols = ipv4|' /etc/postfix/main.cf
vi /etc/postfix/main.cf
#
fi
echo -e "Jp: ここで一度、別のターミナルを立ち上げてください。"
echo -e "Jp: ユーザ権限でSSHログインし NGXBUILD.sh を実行して Nginx のビルドインストールをして下さい。"
echo -e "En: Here once, please launch another terminal."
echo -e "En: Build your Nginx by running the SSH login NGXBUILD.sh in user permissions."
#
############################################################################