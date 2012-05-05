#!/bin/bash

# Installed pkg php, phpmyadmin, mysql (service)

green='\E[32;40m'
red='\033[2;31;40m'

# Color-echo.
# Argument $1 = message
# Argument $2 = color
cecho () {
    local default_msg="No message passed."
    # Doesn't really need to be a local variable.
  
    message=${1:-$default_msg}   # Defaults to default message.
    color=${2:-$black}           # Defaults to black, if not specified.
  
    echo -ne "$color"
    echo "$message"
    tput sgr0                      # Reset to normal.
  
    return
}  

echo "Starting installation of phpmyadmin and all dependencies..."

# Install phpmyadmin
install_phpmyadmin() {
    echo -n "Installing phpmyadmin... "
    yum install phpmyadmin
    if [ $? -eq 0 ]; then
        cecho "[OK]" $green
    else
        cecho "[FAILED]" $red
    fi
}

# Start httpd
start_httpd() {
    echo -n "Restarting httpd... "
    service httpd restart
    
    if [ $? -eq 0 ]; then
        cecho "[OK]" $green
    else
        cecho "[FAILED]" $red
    fi
}

# Set iptables firewall open port 80 httpd
open_httpd() {
    echo -n "Open port 80 iptables firewall for httpd... "
    ipt_file='/etc/sysconfig/iptables'
    fwrule='-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT'

    grep -e "$fwrule" $ipt_file > /dev/null 2>&1 

    if [ $? -ne 0  ]; then
        sed -i --in-place=.bak "s/-A INPUT -j REJECT --reject-with icmp-host-prohibited/$fwrule\n&/" $ipt_file
  
        if [ $? -eq 0 ]; then
          cecho "[OK]" $green
        else
          cecho "[FAILED]" $red
        fi
    else
        cecho "[OK]" $green
    fi
}

# Set mysqld run at init
init_level_mysqld() {
    echo -n "Set mysqld run at init... "
    chkconfig --levels 235 mysqld on
    if [ $? -eq 0 ]; then
        cecho "[OK]" $green
    else
        cecho "[FAILED]" $red
    fi
}

# Start mysqld
start_mysqld() {
    echo -n "Starting mysqld... "
    service mysqld restart
    if [ $? -eq 0 ]; then
        cecho "[OK]" $green
    else
        cecho "[FAILED]" $red
    fi
}

# Set mysql
mysql_secure() {
    echo "Setup mysql..."
mysql_secure_installation << EOF

Y
mysqlpassword
mysqlpassword
Y
Y
Y
Y
EOF

    if [ $? -eq 0 ]; then
        cecho "[OK]" $green
    else
        cecho "[FAILED]" $red
    fi
}

# phpmyadmin use cookie auth
pma_auth_http() {
    echo -n "Replacing phpmyadmin auth with cookie method... "
    sed -i --in-place=.bak "s/= 'http';/= 'cookie';/" /etc/phpMyAdmin/config.inc.php
    if [ $? -eq 0 ]; then
        cecho "[OK]" $green
    else
        cecho "[FAILED]" $red
    fi
}

# Check php and mysql installation
check_php_mysql() {
    echo -n "Checking if php with mysql ext is successfuly installed... "

    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
    curl -s http://localhost/info.php | grep "MYSQL_SOCKET" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        cecho "[OK]" $green
    else
        cecho "[FAILED]" $red
    fi
}

install_phpmyadmin
start_httpd
open_httpd
init_level_mysqld
start_mysqld
mysql_secure
pma_auth_http
check_php_mysql
