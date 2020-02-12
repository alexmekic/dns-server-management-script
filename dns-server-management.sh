#!/usr/local/bin/bash

function ip_validity {
        ip=${1:-$1}
        re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}'
        re+='0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))$'
        if [[ $ip =~ $re ]]; then
                return 0
        else
                return 1
        fi
}

function ip_network_validity {
        ip=${1:-$1}
        re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){2}'
        re+='0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))$'
        if [[ $ip =~ $re ]]; then
                return 0
        else
                return 1
        fi
}

function add_forward_zone {
       	touch $1
       	echo "\$TTL 2d
@       IN SOA          $HOSTNAME.$1. root.$1. (
1 ; serial
3h ; refresh
1h ; retry
1w ; expiry
1d ) ; minimum
	IN NS           $HOSTNAME.$1." >> $1
	if [[ ! -z $2 ]]; then
		echo "		IN NS		$2.$1." >> $1
	fi
	echo "$HOSTNAME		IN A		$main_ip" >> $1
	if [[ ! -z $3 ]]; then
		echo "$2	IN A		$3" >> $1
	fi
}

function add_reverse_zone {
	last_octet=$(ifconfig | grep -A 6 $main_int | grep 'inet' | cut -d ' ' -f 2 | cut -d '.' -f 4)
	if [[ ! -z $4 ]]; then
		sec_DNS_last_octet=$(echo $4 | cut -d '.' -f 4)
	fi
        touch $1.in-addr.arpa
        echo "\$TTL 2d
@       IN SOA          $HOSTNAME.$2. root.$HOSTNAME.$2. (
1 ; serial
3h ; refresh
1h ; retry
1w ; expiry
1d ) ; minimum
		IN NS           $HOSTNAME.$2." >> $1.in-addr.arpa
	if [[ ! -z $3 ]]; then
		echo "@         IN NS           $3.$2." >> $1.in-addr.arpa
	fi
	echo "$last_octet	IN PTR		$HOSTNAME.$2." >> $1.in-addr.arpa
	if [[ ! -z $sec_DNS_last_octet ]]; then
                echo "$sec_DNS_last_octet        IN PTR            $3.$2." >> $1.in-addr.arpa
        fi
}

function add_new_zone {
	while true; do
		read -e -p "Enter new domain zone (0 to exit): " forward_zone
		if [[ $forward_zone == "0" ]]; then
			return 1
		elif find /usr/local/etc/namedb/dynamic $forward_zone > /dev/null ; then
			echo "Domain already exists"
		else
			break
		fi
	done
	while true; do
        	read -e -p "Enter IP network (0 to exit): " reverse_zone
                if [[ $reverse_zone == "0" ]]; then
                        return 1
                elif ip_network_validity $reverse_zone; then
			reverse_ip=$(echo "$reverse_zone" | awk -F. '{print $3"."$2"."$1}')
			break
                else
                        echo "Invalid IP Network"
		fi
	done
	while true; do
		read -e -p "Enter hostname of secondary DNS server (or hit Enter to skip): " sec_DNS
		if [[ ! -z $sec_DNS ]]; then
			while true; do
				read -e -p "Enter IP address of secondary DNS server: " sec_DNS_IP
				if ip_validity $sec_DNS_IP; then
					echo "Checking connectivity for $sec_DNS_IP"
					ping -c 5 $sec_DNS_IP
					if [ $? -eq 0 ]; then
                                		echo "Backup DNS server reachable."
                                		break
					else
						echo "Backup DNS server not reachable."
						break
					fi
				else
					echo "Invalid IP Address"
				fi
			done
			break
		else
			echo "Skipping secondary DNS server setup"
			break
                fi
        done
        echo "Creating forward zone $forward_zone"
        add_forward_zone $forward_zone $sec_DNS $sec_DNS_IP
        echo "Creating reverse zone for $reverse_zone network"
        add_reverse_zone $reverse_ip $forward_zone $sec_DNS $sec_DNS_IP
        while true; do
                read -p "Enter hostname (0 to exit): " hostname
                if [[ $hostname == "0" ]]; then
                        break
                fi
                read -e -p "Enter IP Address: " -i "$reverse_zone." ip_address
                if ! ip_validity $ip_address ; then
                        echo "Invalid IP Address"
                elif [[ ! -z $hostname && ! -z $ip_address ]]; then
			if grep -q -w "$ip_address" $forward_zone; then
	                        echo "IP address $ip_address already exists"
                        elif grep -q -w "$hostname" $forward_zone; then
        	                echo "Hostname $hostname already exists"
                        else
	                        echo "$hostname		IN A            $ip_address" >> $forward_zone
        	                echo "$(echo $ip_address | cut -d . -f 4)       IN PTR          $hostname.$forward_zone." >> $reverse_ip.in-addr.arpa
                	        echo "Forward and Reverse Entry $hostname for $ip_address added"
			fi
                else
                        echo "Entries missing"
                fi
        done
}

function remove_zone {
        while true; do
                read -e -p "Enter domain to remove (0 to exit): " zone_remove
                if [[ $zone_remove == "0" ]]; then
                        break
                else
                        if [[ -f $zone_remove ]]; then
                                for remove_domain in $(find . -type f -print0 | xargs -0 grep -l "$zone_remove"); do
                                        rm $remove_domain
					sed -i '' '/$remove_domain/,+4d;' /usr/local/etc/namedb/named.conf.local
                                done
                                echo "Domain $zone_remove removed"
				break
                        else
                                echo "Domain not found"
                        fi
                fi
        done
}

function domain_entry_edit {
	local flag="0"
        while true; do
		read -e -p "Enter domain to $1 entry (0 to exit, 1 to save changes): " zone_entry
		if [[ $zone_entry == "1" ]]; then
			if [[ -f $forward_zone.bak && -f $reverse_zone.bak && $flag == "1" ]]; then
				echo "Incrementing serial"
				awk '{if ($3 == "serial") printf("%d %s %s\n", $1 + 1, $2, $3); else print $0;}' $forward_zone.bak > $forward_zone
				awk '{if ($3 == "serial") printf("%d %s %s\n", $1 + 1, $2, $3); else print $0;}' $reverse_zone.bak > $reverse_zone
				echo "Removing Temp Files"
				rm $forward_zone.bak
				rm $reverse_zone.bak
				echo "Applying changes"
				rndc reload
				break
			else
				echo "Nothing to save changes. Exiting"
				break
			fi
		elif [[ $zone_entry == "0" ]]; then
			if [[ -f $forward_zone.bak && -f $reverse_zone.bak ]]; then
				echo "Reverting Changes"
				rm $forward_zone.bak
                                rm $reverse_zone.bak
				break
			else
				break
			fi
                elif [[ -f $zone_entry && -f $(find . -type f -print0 | xargs -0 grep -l $zone_entry | cut -d "/" -f 2 |  grep '^[0-9]') ]]; then
			forward_zone=$zone_entry
			forward_zone_entry=$forward_zone
			reverse_zone=$(find . -type f -print0 | xargs -0 grep -l $zone_entry | cut -d "/" -f 2 |  grep '^[0-9]')
			cp $forward_zone $forward_zone.bak
			cp $reverse_zone $reverse_zone.bak
                        while true; do
                                read -p "Enter hostname to $1 (0 to go back): " hostname
                                if [[ $hostname == "0" && $flag == "0" ]]; then
					rm $forward_zone.bak
                                	rm $reverse_zone.bak
                                        break
				elif [[ $hostname == "0" && $flag == "1" ]]; then
					echo "Domain entries changed"
					break
                                elif [[ -z $hostname ]]; then
                                        echo "Hostname missing"
                                elif [[ $1 = "remove" ]]; then
                                        if grep -q -w "$hostname" $forward_zone; then
                                                sed -i "" "/$hostname/d" $forward_zone.bak
                                                sed -i "" "/$hostname/d" $reverse_zone.bak
                                                echo "$hostname removed from domain $forward_zone_entry"
						local flag="1"
                                        else
                                                echo "Hostname does not exist in domain $forward_zone_entry"
                                        fi
                                elif [[ $1 = "add" ]]; then
                                        read -e -p "Enter IP Address: " -i "$(find . -type f -print0 | xargs -0 grep -l $forward_zone | grep .bak | cut -d "/" -f 2 | cut -d "." -f 1-3 | grep '^[0-9]' | awk -F. '{print $3"."$2"."$1}')." ip_address
                                        if ! ip_validity $ip_address ; then
                                                echo "Invalid IP Address"
                                        else
                                                if grep -q -w "$ip_address" $forward_zone; then
                                                        echo "IP address $ip_address already exists"
                                                elif grep -q -w "$hostname" $forward_zone; then
                                                        echo "Hostname $hostname already exists"
                                                else
							echo "$hostname         IN A            $ip_address" >> $forward_zone.bak
                                                        echo "$(echo $ip_address | cut -d . -f 4)       IN PTR          $hostname.$forward_zone_entry." >> $reverse_zone.bak
                                                        echo "Forward and Reverse Entry $hostname for $ip_address added to domain $forward_zone_entry"
							local flag="1"
                                                fi
                                        fi
                                else
                                        continue
                                fi
                        done
                elif [[ ! -f $zone_entry ]]; then
                        echo "Domain does not exist or invalid entry"
		elif [[ ! -f $reverse_zone ]]; then
			echo "Reverse zone missing. Cannot proceed"
		else
			echo "Unknown error"
                fi
        done
}

function update_conf_new_master {
        while true; do
                read -e -p "Enter domain (0 to exit): " forward_zone
		reverse_zone=$(find . -type f -print0 | xargs -0 grep -l $forward_zone | cut -d "/" -f 2 |  grep '^[0-9]')
                if [[ $forward_zone == "0" ]]; then
                        return 1
                elif [[ ! -f $forward_zone ]]; then
                        echo "Domain does not exist"
                elif [[ -z $reverse_zone ]]; then
                        echo "Reverse lookup zone of domain $forward_zone does not exist"
		else
			break
                fi
	done
	while true; do
		read -e -p "Enter IP Address of Secondary DNS Server (Enter to skip, 0 to exit): " secondary_ip
		if [[ $secondary_ip == "0" ]]; then
                        return 1
		elif [[ ! -z $secondary_ip ]] && ! ip_validity $secondary_ip; then
			echo "Invalid IP Address"
		elif [[ -z $secondary_ip ]]; then
			break
		else
			echo "Checking connectivity for $secondary_ip"
                	ping -c 5 $secondary_ip
                        if [ $? -eq 0 ]; then
                        	echo "Secondary DNS server found. Adding to conf file."
				break
			else
				echo "Secondary DNS server unreachable"
			fi
		fi
	done
	echo "Updating zone configuration"
	echo "zone \"$forward_zone\" {
        type master;
        file \"/usr/local/etc/namedb/dynamic/$forward_zone\";
	allow-transfer { $secondary_ip; };
};
zone \"$reverse_zone\" {
        type master;
        file \"/usr/local/etc/namedb/dynamic/$reverse_zone\";
	allow-transfer { $secondary_ip; };
};" >> /usr/local/etc/namedb/named.conf.local
	echo "name.conf.local file updated for domain $forward_zone"
	if ! grep allow-transfer /usr/local/etc/namedb/named.conf.local | grep [0-9] > /dev/null; then
		sed -i '' 's#allow-transfer#//allow-transfer#g' /usr/local/etc/namedb/named.conf.local
	fi
	echo "Done"
}

function update_conf_new_slave {
        while true; do
                read -e -p "Enter domain (0 to exit): " forward_zone
                if [[ $forward_zone == "0" ]]; then
                       return 1
                fi
                read -e -p "Enter network: " ip_network
                if ! ip_network_validity $ip_network ; then
                        echo "Invalid IP Network"
                else
                        reverse_ip=$(echo "$ip_network" | awk -F. '{print $3"."$2"."$1}')
                        while true; do
                                read -e -p "Enter primary master IP of DNS sever: " primary_ip
                                if ! ip_validity $primary_ip ; then
                                        echo "Invalid IP address"
                                else
                                        echo "Checking connectivity for $primary_ip"
                                        ping -c 5 $primary_ip
                                        if [ $? -eq 0 ]; then
                                                echo "Primary DNS server is reachable. Adding to conf file."
                                                echo "zone \"$forward_zone\" {
        type slave;
        file \"/usr/local/etc/namedb/dynamic/$forward_zone\";
        masters { $primary_ip; };
};
zone \"$reverse_ip.in-addr.arpa\" {
        type slave;
        file \"/usr/local/etc/namedb/dynamic/$reverse_ip.in-addr.arpa\";
        masters { $primary_ip; };
};" >> /usr/local/etc/namedb/named.conf.local
                                                break
                                        else
                                                echo "Primary DNS server is not reachable"
                                        fi
                                fi
                        done
                fi
		break
        done
}

function view_conf {
	cat /usr/local/etc/namedb/named.conf.local
}

function view_zone {
        cd "/usr/local/etc/namedb/dynamic/"
        while true; do
                read -e -p "Enter domain to view (0 to exit): " zone_view
                if [[ $zone_view == "0" ]]; then
                        break
                elif [[ -f $zone_view && -f $(find . -type f -print0 | xargs -0 grep -l $zone_view | cut -d "/" -f 2 | grep '^[0-9]') ]]; then
                        reverse_zone=$(find . -type f -print0 | xargs -0 grep -l $zone_view | cut -d "/" -f 2 |  grep '^[0-9]')
                        echo ""
                        echo "Forward Lookup zone for $zone_view"
                        echo ""
                        cat $zone_view
                        echo ""
                        echo ""
                        echo "Reverse Lookup zone for $zone_view"
                        echo ""
                        cat $reverse_zone
                        break
                elif [[ ! -f $zone_view ]]; then
                        echo "Domain does not exist"
                else
                        echo "Reverse zone missing. Cannot proceed"
                fi
        done
}

function restart_bind {
	service named restart
}

main_int=$(ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active' | egrep -o -m 1 '^[^\t:]+')
main_ip=$(ifconfig | grep -A 6 $main_int | grep 'inet' | cut -d ' ' -f 2)
#main_ip=$(ip a | grep -A 1 'eth0' | grep 'inet' | cut -d ' ' -f 6 | cut -d '/' -f 1)

if ! ip_validity $main_ip; then
	echo "ERROR: No active IP address found on interface $main_int. Cannot continue"
	exit 1;
fi

cd "/usr/local/etc/namedb/dynamic/"
while true; do
	echo ""
	echo "DNS Server Menu"
	echo ""
	echo "Active IP Address on $main_int: $main_ip"
	echo ""
	echo "1) Add New Domain Zone"
	echo "2) Remove Domain Zone"
	echo ""
	echo "3) Add entry to Domain Zone"
	echo "4) Remove entry from Domain Zone"
	echo ""
	echo "5) View Domain Zone"
	echo ""
	echo "6) Add master zone to named.conf.local file"
	echo "7) Add slave zone to named.conf.local file"
	echo "8) View name.conf.local conf"
	echo ""
	echo "9) Restart DNS BIND Service"
	echo ""
	echo "0) Exit"
	echo ""
	read -p "LOAD > " load
	case $load in
		1) add_new_zone;;
		2) remove_zone;;
		3) domain_entry_edit add;;
		4) domain_entry_edit remove;;
		5) view_zone;;
		6) update_conf_new_master;;
		7) update_conf_new_slave;;
		8) view_conf;;
		9) restart_bind;;
		0) exit 0;;
		*) echo "Invalid Selection";;
	esac
done
