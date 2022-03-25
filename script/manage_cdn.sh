#!/bin/bash
[[ $(id -u) != 0 ]] && echo -e "该脚本需要在root权限下运行" && exit 1

cmd="apt-get"
if [[ $(command -v apt-get) || $(command -v yum) ]] && [[ $(command -v systemctl) ]]; then
    if [[ $(command -v yum) ]]; then
        cmd="yum"
    fi
else
    echo "该脚本无法在当前系统运行" && exit 1
fi

screen_start() {
    screen -dmS MinerProxyPlus
    screen -r MinerProxyPlus -p 0 -X stuff "cd /root/minerproxyplus"$'\n'
    screen -r MinerProxyPlus -p 0 -X stuff "./MinerProxyPlus"$'\n'
    sleep 1s
}

install() {
    if [ -d "/root/minerproxyplus" ]; then
        echo -e "已检测到安装目录存在. 如果确定没有安装, 请输入rm -rf /root/minerproxyplus删除目录后再重新安装" && exit 1
    fi
    if screen -list | grep -q "MinerProxyPlus"; then
        echo -e "MinerProxyPlus已启动, 请关闭后再安装" && exit 1
    fi

    $cmd update -y
    $cmd install curl wget screen -y
    mkdir /root/minerproxyplus

    echo "正在安装MinerProxyPlus. 请稍候"
    wget https://cdn.jsdelivr.net/gh/8x3090/MinerProxyPlus@master/bin/MinerProxyPlus_linux_amd64 -O /root/minerproxyplus/MinerProxyPlus
    chmod 777 /root/minerproxyplus/MinerProxyPlus
    echo "正在启动...如果无报错则启动成功"
    screen_start
    echo
    echo "当前默认配置为: "
    cat /root/minerproxyplus/config.yml
    echo
    echo "输入cat /root/minerproxyplus/config.yml可随时查看当前配置, 包括端口号与登录密码"
    echo "也可手动修改/root/minerproxyplus/config.yml中的配置信息. 注意手动修改后需重启应用方生效"
    echo "web后台启动成功: 可使用screen -r MinerProxyPlus查看程序输出, 退出程序输出界面键入ctrl + a + d"
}

start() {
    if screen -list | grep -q "MinerProxyPlus"; then
        echo -e "MinerProxyPlus已启动, 请勿重复启动" && exit 1
    fi
    if [ ! -d "/root/minerproxyplus" ]; then
        echo -e "没有检测到安装目录. 请重新安装" && exit 1
    fi

    screen_start

    echo "MinerProxyPlus启动成功"
    echo "可使用screen -r MinerProxyPlus查看程输出"
}

restart() {
    if screen -list | grep -q "MinerProxyPlus"; then
        screen -X -S MinerProxyPlus quit
    fi
    if [ ! -d "/root/minerproxyplus" ]; then
        echo -e "没有检测到安装目录. 请重新安装" && exit 1
    fi

    screen_start

    echo "MinerProxyPlus重新启动成功"
    echo "可使用screen -r MinerProxyPlus查看程序输出"
}

stop() {
    if screen -list | grep -q "MinerProxyPlus"; then
        screen -X -S MinerProxyPlus quit
    fi
    if [ ! -d "/root/minerproxyplus" ]; then
        echo -e "没有检测到安装目录. 请重新安装" && exit 1
    fi

    echo "MinerProxyPlus已停止"
}

uninstall() {
    if [ ! -d "/root/minerproxyplus" ]; then
        echo -e "没有检测到安装目录, 无需卸载" && exit 1
    fi

    read -p "是否确认删除MinerProxyPlus[yes/no]: " flag
    if [ -z $flag ]; then
        echo "输入错误" && exit 1
    else
        if [ "$flag" = "yes" -o "$flag" = "ye" -o "$flag" = "y" ]; then
            screen -X -S MinerProxyPlus quit
            rm -rf /root/minerproxyplus
            echo "卸载MinerProxyPlus成功"
        fi
    fi
}

check_limit() {
    echo -n "当前连接数限制: "
    ulimit -n
}

change_limit() {
    num="n"
    if [ $(grep -c "root soft nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root soft nofile 102400" >>/etc/security/limits.conf
        num="y"
    fi

    if [[ "$num" = "y" ]]; then
        echo "连接数限制已修改为102400, 重启服务器后生效"
    else
        check_limit
    fi
}

echo " __  __ _                 ____                      ____  _"
echo "|  \/  (_)_ __   ___ _ __|  _ \ _ __ _____  ___   _|  _ \| |_   _ ___"
echo "| |\/| | | '_ \ / _ \ '__| |_) | '__/ _ \ \/ / | | | |_) | | | | / __|"
echo "| |  | | | | | |  __/ |  |  __/| | | (_) >  <| |_| |  __/| | |_| \__ \\"
echo "|_|  |_|_|_| |_|\___|_|  |_|   |_|  \___/_/\_\\\\__, |_|   |_|\__,_|___/"
echo "                                              |___/"
echo "MinerProxyPlus一键管理工具"
echo "  1. 安装并启动(默认安装到/root/minerproxyplus)"
echo "  2. 启动"
echo "  3. 重启"
echo "  4. 停止"
echo "  5. 卸载"
echo "  6. 修改linux系统连接数限制为102400(需要重启服务器生效)"
echo "  7. 查看当前系统连接数限制"
read -p "$(echo -e "请选择[1-7]: ")" choose
case $choose in
1)
    install
    ;;
2)
    start
    ;;
3)
    restart
    ;;
4)
    stop
    ;;
5)
    uninstall
    ;;
6)
    change_limit
    ;;
7)
    check_limit
    ;;
*)
    echo "输入错误, 请重新输入!"
    ;;
esac
