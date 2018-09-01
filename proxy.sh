#!/usr/bin/env bash

##########################################################################
#
# proxy.sh
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
# proxy settings
#proxy_server=http://192.168.180.160:6969
ftp_proxy=${proxy_server}
http_proxy=${proxy_server}
https_proxy=${proxy_server}

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
arg_proxy=

##########################################################################
# parse parameter
# echo $@
# ����ѡ� -o ��ʾ��ѡ�� -a ��ʾ֧�ֳ�ѡ��ļ�ģʽ(�� - ��ͷ) -l ��ʾ��ѡ�� 
# a ��û��ð�ţ���ʾû�в���
# b ���һ��ð�ţ���ʾ��һ����Ҫ����
# c �������ð�ţ���ʾ��һ����ѡ����(��ѡ�����������ѡ��)
# -n ����ʱ����Ϣ
# -- Ҳ��һ��ѡ����� Ҫ����һ������Ϊ -f ��Ŀ¼����ʹ�� mkdir -- -f ,
#    ������������ʾ���һ��ѡ��(�����ж� while �Ľ���)
# $@ ��������ȡ�������б�(�������� $* ���棬��Ϊ $* �����еĲ������ͳ�һ���ַ���
#                         �� $@ ��һ����������)
# args=`getopt -o ab:c:: -a -l apple,banana:,cherry:: -n "${source}" -- "$@"`
args=`getopt -o hp: -a -l help,proxy: -n "${source}" -- "$@"`
# �ж� getopt ��ִ��ʱ���д�������Ϣ����� STDERR
if [ $? != 0 ]; then
    echo "Terminating..." >&2
    exit 1
fi
# echo ${args}
# �������в�����˳��
# ʹ��eval ��Ŀ����Ϊ�˷�ֹ��������shell������������չ��
eval set -- "${args}"
# ��������ѡ��
while true
do
    case "$1" in
        -h | --help | -help)
            echo "option -h|--help"
            arg_help=true
            shift
            ;;
        -p | --proxy | -proxy)
            echo "option -p|--proxy $2"
            arg_proxy=true
	    proxy_server=$2
            shift 2
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
#��ʾ��ѡ����Ĳ���(������ѡ��Ĳ��������ŵ����)
# arg �� getopt ���õı��� , �����ֵ�����Ǵ����֮��� $@(�����д���Ĳ���)
for arg do
   echo '--> '"$arg";
done

# show usage
fun_usage() {
    fun_echo_yellow "Usage: `basename $0` [-h|--help] [-p|--proxy]"
    fun_echo_yellow "        [-h|--help]          : show help info."
    fun_echo_yellow "        [-p|--proxy]         : set proxy info."
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

# update /etc/profile
fun_update_profile() {
    fun_log_echo "\>\>\>update /etc/profile."
    sed -i '/proxy/d' /etc/profile && \
    cp -f /etc/profile /etc/profile.back

    if [ "x${proxy_server}" != "x" ]; then
    cat << EOF >> /etc/profile;
# proxy settings
ftp_proxy=${proxy_server}
http_proxy=${proxy_server}
https_proxy=${proxy_server}
export ftp_proxy
export http_proxy
export https_proxy
EOF
    fi
    return 0
}

# update /etc/yum.conf
fun_update_yumconf() {
    fun_log_echo "\>\>\>update /etc/yum.conf."
    sed -i '/proxy/d' /etc/yum.conf && \
    cp -f /etc/yum.conf /etc/yum.conf.back

    if [ "x${proxy_server}" != "x" ]; then
    cat << EOF >> /etc/yum.conf;
# proxy settings
proxy=${proxy_server}
EOF
    fi
    return 0
}

# update /etc/wgetrc
fun_update_wgetrc() {
fun_log_echo "\>\>\>update /etc/wgetrc."
    sed -i '/proxy/d' /etc/wgetrc && \
    cp -f /etc/wgetrc /etc/wgetrc.back

    if [ "x${proxy_server}" != "x" ]; then
cat << EOF >> /etc/wgetrc
# proxy settings
ftp_proxy=${proxy_server}
http_proxy=${proxy_server}
https_proxy=${proxy_server}
EOF
    fi
    return 0
}

##########################################################################

# show usage
if [ "x${arg_help}" == "xtrue" ]; then
    fun_usage;
    exit 1
fi

if [ "x${arg_proxy}" != "xtrue" ]; then
    proxy_server="";
fi

# update /etc/profile
fun_update_profile
source /etc/profile

# update /etc/yum.conf
fun_update_yumconf

# update /etc/wgetrc
fun_update_wgetrc

fun_log_echo "complete."
fun_log_echo ""

exit $?
