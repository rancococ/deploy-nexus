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
# args
arg_help=
arg_update=
arg_compose=

##########################################################################
# parse parameter
# echo $@
# 定义选项， -o 表示短选项 -a 表示支持长选项的简单模式(以 - 开头) -l 表示长选项 
# a 后没有冒号，表示没有参数
# b 后跟一个冒号，表示有一个必要参数
# c 后跟两个冒号，表示有一个可选参数(可选参数必须紧贴选项)
# -n 出错时的信息
# -- 也是一个选项，比如 要创建一个名字为 -f 的目录，会使用 mkdir -- -f ,
#    在这里用做表示最后一个选项(用以判定 while 的结束)
# $@ 从命令行取出参数列表(不能用用 $* 代替，因为 $* 将所有的参数解释成一个字符串
#                         而 $@ 是一个参数数组)
# args=`getopt -o ab:c:: -a -l apple,banana:,cherry:: -n "${source}" -- "$@"`
args=`getopt -o huc -a -l help,update,compose -n "${source}" -- "$@"`
# 判定 getopt 的执行时候有错，错误信息输出到 STDERR
if [ $? != 0 ]; then
    echo "Terminating..." >&2
    exit 1
fi
# echo ${args}
# 重新排列参数的顺序
# 使用eval 的目的是为了防止参数中有shell命令，被错误的扩展。
eval set -- "${args}"
# 处理具体的选项
while true
do
    case "$1" in
        -h | --help | -help)
            echo "option -h|--help"
            arg_help=true
            shift
            ;;
        -u | --update | -update)
            echo "option -u|--update"
            arg_update=true
            shift
            ;;
        -c | --compose | -compose)
            echo "option -c|--compose"
            arg_compose=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Internal error!"
            exit 1
            ;;
    esac
done
#显示除选项外的参数(不包含选项的参数都会排到最后)
# arg 是 getopt 内置的变量 , 里面的值，就是处理过之后的 $@(命令行传入的参数)
for arg do
   echo '--> '"$arg";
done

# show usage
fun_usage() {
    fun_echo_yellow "Usage: `basename $0` [-h|--help] [-u|--update] [-c|--compose]"
    fun_echo_yellow "        [-h|--help]          : show help info."
    fun_echo_yellow "        [-u|--update]        : install packages."
    fun_echo_yellow "        [-c|--compose]       : install docker compose."
    return 0
}

# fun_log_echo
fun_log_echo() {
    l_arg=$1
    l_bs=`basename $0`
    l_time=`date "+%Y-%m-%d %H:%M:%S"`
    #echo "[$l_time]:[$l_bs]:$l_arg" >> "$LOG_FILE_NAME"
    fun_echo_green "$l_arg"
    return 0
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
    return 0
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
    yum update -y && \
    yum install -y passwd openssl wget net-tools gettext zip unzip && \
    yum clean all
    return 0
}

# install docker-compose
fun_install_compose() {
    fun_log_echo "\>\>\>install docker-compose from ${compose_url}"
    curl -L -o /usr/local/bin/docker-compose "${compose_url}" && \
    chmod +x /usr/local/bin/docker-compose
    return 0
}

##########################################################################

# show usage
if [ "x${arg_help}" == "xtrue" ]; then
    fun_usage;
    exit 1
fi

# update hosts for github and amazonaws
fun_update_hosts

# install packages
if [ "x${arg_update}" == "xtrue" ]; then
    fun_install_packages;
    exit 1
fi

# install docker-compose
if [ "x${arg_compose}" == "xtrue" ]; then
    fun_install_compose;
    exit 1
fi

fun_log_echo "complete."
fun_log_echo ""

exit $?
