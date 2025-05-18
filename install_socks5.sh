#!/bin/bash

echo "📦 安装依赖中..."
yum install -y epel-release gcc make wget firewalld

echo "📂 下载 Dante 源码..."
cd /usr/local/src
wget -q https://www.inet.no/dante/files/dante-1.4.2.tar.gz
tar zxvf dante-1.4.2.tar.gz && cd dante-1.4.2

echo "🔧 编译安装 danted..."
./configure && make && make install

echo "🧱 创建配置文件 /etc/sockd.conf"
cat > /etc/sockd.conf <<EOF
logoutput: /var/log/sockd.log

internal: 0.0.0.0 port = 1080
external: eth0

method: username
user.notprivileged: nobody

client pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: connect disconnect error
}

socks pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: connect disconnect error
  command: connect
}
EOF

echo "🚀 创建 systemd 启动文件"
cat > /etc/systemd/system/sockd.service <<EOF
[Unit]
Description=Dante SOCKS5 Server
After=network.target

[Service]
ExecStart=/usr/local/sbin/sockd -f /etc/sockd.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "👤 创建 socks 用户名和密码"
useradd socksuser
echo "socks1234" | passwd --stdin socksuser

echo "🔥 开启防火墙端口 1080"
systemctl start firewalld
firewall-cmd --permanent --add-port=1080/tcp
firewall-cmd --reload

echo "🔄 启动并设置开机启动"
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable sockd
systemctl start sockd

echo "✅ SOCKS5 安装完成"
echo "-----------------------------------------"
echo "📌 连接信息："
echo "IP地址：$(curl -s ifconfig.me)"
echo "端口：1080"
echo "用户名：socksuser"
echo "密码：socks1234"
echo "协议：SOCKS5"
echo "-----------------------------------------"
