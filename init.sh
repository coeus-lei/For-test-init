#!/bin/bash
#this is for disable ipv6 from kernel
disable_ipv6() {
    if [[ -n "$(ip a | awk '{if($1=="inet6")print}')" ]];then
        if [[ "7" == "$(awk -F "[. ]?" '{print $4}' /etc/centos-release)" ]];then
            if ! awk '/GRUB_CMDLINE_LINUX/' /etc/default/grub | grep "ipv6.disable=1";then
                sed -ri 's/(GRUB_CMDLINE_LINXU.*)(")$/\1 ipv6.disable=1\2/' /etc/default/grub
                grub2-mkconfig -o /boot/grub2/grub.cfg
            fi
         elif [[ "6" == "$(awk -F "[. ]?" '{print $3}' /etc/centos-release)" ]];then
             echo "NETWORKING_IPV6=no" >> /etc/sysconfig/network
             sed -ri 's/::1(.*)$/#::1\1/' /etc/hosts
             echo "alias net-pf-10 off\nalias ipv6 off" >>/etc/modprobe.d/dist.conf
         else
             echo 'Usage:"centos6 | centos7"'
         fi
     fi
}

#this is for sshd and turn on speed of sshd connection

ssh_config() {
    ssh_Port=22992
    sed -ri "s/#Port.*/Port $ssh_Port/" /etc/ssh/sshd_config
    sed -ri 's/#UseDNS.*/UseDNS yes/' /etc/ssh/sshd_config
}

#disable selinux
set_selinux() {
    [ -f /etc/sysconfig/selinux ] && { sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux;/usr/sbin/setenforce 0; }
    [ -f /etc/selinux/config ] && { sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config;/usr/sbin/setenforce 0; }
}

#this is for sync time
sync_time() {
    [ -x /usr/sbin/ntpdate ] || yum -y install ntpdate
    if [ ! -f /var/spool/cron/root ];then
        echo -e "\n*/5 * * * * /usr/sbin/ntpdate -u pool.ntp.org >/dev/null 2>&1" >>/var/spool/cron/root
        /usr/sbin/ntpdate -u pool.ntp.org
    fi
}
#optimization yum
add_yum_pulgins() {
    if [ "7" == "$(awk -F "[. ]?" '{print $4}' /etc/centos-release)" ];then
        yum -y install epel-release
    else
        rpm -ivh ftp://fr2.rpmfind.net/linux/dag/redhat/el6/en/x86_64/dag/RPMS/axel-2.4-1.el6.rf.x86_64.rpm
    fi
    curl -4Lk https://raw.githubusercontent.com/coeus-lei/init/master/yum_plugins/axelget.conf > /etc/yum/pluginconf.d/axelget.conf
    curl -4Lk https://raw.githubusercontent.com/coeus-lei/init/master/yum_plugins/axelget.py >/usr/lib/yum-plugins/axelget.py
}
#optimization tty colore
setPS1() {
    curl -Lks 'https://raw.githubusercontent.com/coeus-lei/centos_init/master/PS1' > /etc/profile
    for i in `find /home/ -name '.bashrc'` /etc/skel/.bashrc ~/.bashrc ;do
		cat >> $i <<-EOF
			xterm_set_tabs() {
				TERM=linux
				export \$TERM
				setterm -regtabs 4
				TERM=xterm
				export \$TERM
			}
			linux_set_tabs() {
				TERM=linux;
				export \$TERM
				setterm -regtabs 8
				LESS="-x4"
				export LESS
			}
			#[ \$(echo \$TERM) == "xterm" ] && xterm_set_tabs
			linux_set_tabs
			listipv4() {
				if [ "\$1" != "lo" ]; then
					which ifconfig >/dev/null 2>&1 && ifconfig | sed -rn '/^[^ \\t]/{N;s/(^[^ ]*).*addr:([^ ]*).*/\\1=\\2/p}' | \\
						awk -F= '\$2!~/^192\\.168|^172\\.(1[6-9]|2[0-9]|3[0-1])|^10\\.|^127|^0|^\$/{print}' \\
						|| ip addr | awk '\$1=="inet" && \$NF!="lo"{print \$NF"="\$2}'
				else
					which ifconfig >/dev/null 2>&1 && ifconfig | sed -rn '/^[^ \\t]/{N;s/(^[^ ]*).*addr:([^ ]*).*/\\1=\\2/p}' \\
					|| ip addr | awk '\$1=="inet" && \$NF!="lo"{print \$NF"="\$2}'
				fi
			}
			tmux_init() {
				tmux new-session -s "LookBack" -d -n "local"    # 开启一个会话
				tmux new-window -n "other"          # 开启一个窗口
				tmux split-window -h                # 开启一个竖屏
				tmux split-window -v "htop"          # 开启一个横屏,并执行top命令
				tmux -2 attach-session -d           # tmux -2强制启用256color，连接已开启的tmux
			}
			# 判断是否已有开启的tmux会话，没有则开启
			#if which tmux 2>&1 >/dev/null; then test -z "\$TMUX" && { tmux attach || tmux_init; };fi
		EOF
	done
}
    
#    for i in `find /home/ -name '.bashrc'` /etc/skel/.bashrc ~/.bashrc ;do
#        cat > $i <<-EOF
#            xterm_set_tabs() {
#                TERM=linux
#                export \$TERM
#                setterm -regtabs 4
#                TERM=xterm
#                export \$TERM
#            }
#            linux_set_tabs() {
#                TERM=linux;
#                export \$TERM
#                setterm -regtabs 8
#                LESS="-x4"
#                export LESS
#            }
#            #[ \$(echo \$TERM) == "xterm" ] && xterm_set_tabs
#            linux_set_tabs
#            listipv4() {
#                if [ "\$1" != "lo" ]; then
#                    which ifconfig >/dev/null 2>&1 && ifconfig | sed -rn '/^[^ \\t]/{N;s/(^[^ ]*).*addr:([^ ]*).*/\\1=\\2/p}' | \\
#                    awk -F= '\$2!~/^192\\.168|^172\\.(1[6-9]|2[0-9]|3[0-1])|^10\\.|^127|^0|^\$/{print}' \\ || ip addr | awk '\$1=="inet" && \$NF!="lo"{print \$NF"="\$2}'
#                else
#                    which ifconfig >/dev/null 2>&1 && ifconfig | sed -rn '/^[^ \\t]/{N;s/(^[^ ]*).*addr:([^ ]*).*/\\1=\\2/p}' \\|| ip addr | awk '\$1=="inet" && \$NF!="lo"{print \$NF"="\$2}'
#                fi
#            }
#            tmux_init() {
#                tmux new-session -s "LookBack" -d -n "local"    # 开启一个会话
#				        tmux new-window -n "other"          # 开启一个窗口
#				        tmux split-window -h                # 开启一个竖屏
#				        tmux split-window -v "htop"          # 开启一个横屏,并执行top命令
#				        tmux -2 attach-session -d           # tmux -2强制启用256color，连接已开启的tmux
#           }
#        EOF
#    done

#update yum
update_yum() {
    yum clean all && yum makecache
    yum -y install lshw vim tree bash-completion git xorg-x11-xauth xterm gettext axel tmux vnstat man vixie-cron screen vixie-cron crontabs wget curl iproute tar gdisk iotop iftop htop net-tools
    [ "6" == "$(awk -F '[. ]?' '{print $3}' /etc/centos-release)" ] && yum -y groupinstall "Development tools" "Server Platform Development"
    [ "7" == "$(awk -F '[. ]?' '{print $4}' /etc/centos-release)" ] && yum -y groups install "Development Tools" "Server Platform Development"
}
setSYSCTL() {
    cp /etc/sysctl.conf{,_$(date "+%Y%m%d_%H%M%S")_backup}
    curl -Lks https://raw.githubusercontent.com/coeus-lei/centos_init/master/sysctl_optimize_kernel >/etc/sysctl.conf
}
openFILE() {
    curl -Lks https://raw.githubusercontent.com/coeus-lei/init/master/open-files | bash 
}


disable_ipv6
ssh_config
set_selinux
sync_time
add_yum_pulgins
update_yum
setPS1
setSYSCTL
openFILE
reboot
