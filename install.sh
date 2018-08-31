#!/usr/bin/env bash

##########################################################################
#
# install.sh
#
##########################################################################

set -e

##########################################################################
# set author info
date1=`date "+%Y-%m-%d %H:%M:%S"`
date2=`date "+%Y%m%d%H%M%S"`
author="yong.ran@cdjdgm.com"

##########################################################################
# envirionment
# repo urls
centos_ver=7
centos_repo=https://mirrors.aliyun.com/repo/Centos-${centos_ver}.repo
epel_repo=https://mirrors.aliyun.com/repo/epel-${centos_ver}.repo
docker_repo=https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# gps urls
centos_gpg=https://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-${centos_ver}
epel_gpg=https://mirrors.aliyun.com/epel/RPM-GPG-KEY-EPEL-${centos_ver}
docker_gpg=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
# compose
compose_ver=1.22.0
compose_url=https://github.com/docker/compose/releases/download/${compose_ver}/docker-compose-$(uname -s)-$(uname -m)

##########################################################################
# set echo color
color_red='\033[0;31m'
color_green='\033[0;32m'
color_yellow='\033[0;33m'
color_blue='\033[0;34m'
color_end='\033[0m'

# fun echo color
fun_echo_red() {
    echo -e "${color_red}$@${color_end}"
}
fun_echo_green() {
    echo -e "${color_green}$@${color_end}"
}
fun_echo_yellow() {
    echo -e "${color_yellow}$@${color_end}"
}
fun_echo_blue() {
    echo -e "${color_blue}$@${color_end}"
}
trap "fun_echo_red '******* ERROR: Something went wrong.*******'; exit 1" sigterm
trap "fun_echo_red '******* Caught sigint signal. Stopping...*******'; exit 2" sigint

##########################################################################
# entry base dir
pwd=`pwd`
base_dir="${pwd}"
source="$0"
while [ -h "$source" ]; do
    base_dir="$( cd -P "$( dirname "$source" )" && pwd )"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$base_dir/$source"
done
base_dir="$( cd -P "$( dirname "$source" )" && pwd )"
cd ${base_dir}

##########################################################################
# result code
re_err=1
re_ok=0

# show usage
fun_usage() {
    fun_echo_yellow "Usage: `basename $0` [-l] [-h]"
    fun_echo_yellow "        [-l]          : load images from local tar archive file, default is false/empty."
    exit $re_err
}
# get option param
while getopts lh option
do
    case $option in
    l)
        image_local=true
        ;;
    h)
        fun_usage
        ;;
    \?)
        fun_usage
        ;;
    esac
done

# fun_log_echo
fun_log_echo() {
    l_arg=$1
    l_bs=`basename $0`
    l_time=`date "+%Y-%m-%d %H:%M:%S"`
    #echo "[$l_time]:[$l_bs]:$l_arg" >> "$LOG_FILE_NAME"
    fun_echo_green "$l_arg"
    return $re_ok
}

# update hosts for github and amazonaws
fun_update_hosts() {
    fun_log_echo "\>\>\>update hosts for github and amazonaws."
    sed -i '/github/d' /etc/hosts && \
    sed -i '/amazonaws/d' /etc/hosts && \
    sed -i '/github.com/d' /etc/hosts && \
    sed -i '/codeload.github.com/d' /etc/hosts && \
    sed -i '/assets-cdn.github.com/d' /etc/hosts && \
    sed -i '/github.global.ssl.fastly.net/d' /etc/hosts && \
    sed -i '/s3.amazonaws.com/d' /etc/hosts && \
    sed -i '/github-cloud.s3.amazonaws.com/d' /etc/hosts && \
    sed -i '/github-production-release-asset-2e65be.s3.amazonaws.com/d' /etc/hosts

    cat << EOF >> /etc/hosts
# github and amazonaws
192.30.253.112 github.com
192.30.253.113 github.com
192.30.253.120 codeload.github.com
192.30.253.121 codeload.github.com
151.101.72.133 assets-cdn.github.com
151.101.76.133 assets-cdn.github.com
151.101.73.194 github.global.ssl.fastly.net
151.101.77.194 github.global.ssl.fastly.net
52.216.100.205 s3.amazonaws.com
52.216.130.69 s3.amazonaws.com
52.216.64.104 github-cloud.s3.amazonaws.com
52.216.166.91 github-cloud.s3.amazonaws.com
52.216.100.19 github-production-release-asset-2e65be.s3.amazonaws.com
52.216.230.163 github-production-release-asset-2e65be.s3.amazonaws.com
EOF
    return $re_ok
}

# install repositories and packages
fun_install_packages() {
    fun_log_echo "\>\>\>install repositories and packages."
    fun_log_echo "\>\>\>download repos for centos, epel, docker"
    rm -rf /etc/yum.repos.d/*.repo && \
    curl -L -o /etc/yum.repos.d/centos.repo ${centos_repo} && \
    curl -L -o /etc/yum.repos.d/epel.repo ${epel_repo} && \
    curl -L -o /etc/yum.repos.d/docker.repo ${docker_repo} && \
    sed -i '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/centos.repo && \
    sed -i '/mirrors.cloud.aliyuncs.com/d' /etc/yum.repos.d/centos.repo && \
    yum clean all && \
    yum makecache && \
    rm -rf /etc/pki/rpm-gpg/*
    fun_log_echo ""
    fun_log_echo "\>\>\>download rpm-gpg for centos, epel, docker"
    curl -L -o /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-${centos_ver} ${centos_gpg} && \
    curl -L -o /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${centos_ver} ${epel_gpg} && \
    curl -L -o /etc/pki/rpm-gpg/RPM-GPG-KEY-DOCKER-CE ${docker_gpg}
    fun_log_echo ""
    fun_log_echo "\>\>\>import rpm-gpg for centos, epel, docker"
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-${centos_ver} && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${centos_ver} && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-DOCKER-CE
    fun_log_echo ""
    fun_log_echo "\>\>\>install packages for passwd openssl wget net-tools gettext zip unzip"
    yum install -y passwd openssl wget net-tools gettext zip unzip && \
    yum clean all
    return $re_ok
}

# install docker-compose
fun_install_compose() {
    fun_log_echo "\>\>\>install docker-compose from ${compose_url}"
    curl -L -o /usr/local/bin/docker-compose "${compose_url}" && \
    chmod +x /usr/local/bin/docker-compose
    return $re_ok
}


##########################################################################
# update hosts for github and amazonaws
fun_update_hosts

# install packages
fun_install_packages

# install docker-compose
fun_install_compose

fun_log_echo "complete."
fun_log_echo ""

exit $?
