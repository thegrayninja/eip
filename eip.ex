#### EIP - External IP Detector - v1.1 ####
#created by thegrayninja

#tool created to automate process of identifying active IP Addresses
#validates against both ip address and webhosts
#full paths are used as I have crontab running daily
#too lazy to condense the code XD


#START OF TOOL#

#pings external hostnames. Pulls data from external_websites.txt. Creates a backup file first
mv /opt/eip/v1.1/tmp/ehosts_ping_results.txt /opt/eip/v1.1/tmp/ehosts_ping_results_01.txt
nmap -iL "/opt/eip/v1.1/external_hosts.txt" -sn  > "/opt/eip/v1.1/tmp/ehosts_ping_results.txt"


#pings external IP addresses. Pulls data from external_ip.txt. Creates a backup file first
mv /opt/eip/v1.1/tmp/eip_ping_results.txt /opt/eip/v1.1/tmp/eip_ping_results_01.txt
nmap -iL "/opt/eip/v1.1/external_ip.txt" -sn  > "/opt/eip/v1.1/tmp/eip_ping_results.txt"



#filters out only the up hosts, removing uncessary lines, such as port state
#pulls data from eip_nmap_results, which means eip_nmap.ex must run first
#use -A 1 to also show host status. all should be up, so this is not needed

#creates a backup of the resulting file
mv "/opt/eib/v1.1/tmp/eip_ping_alive_results.txt" "/opt/eib/v1.1/tmp/eip_ping_alive_results_01.txt"

#combines ehosts and eip files
cat /opt/eip/v1.1/tmp/ehosts_ping_results.txt >> /opt/eib/v1.1/tmp/eip_ping_results.txt

#filters out only lines that contain Nmap scan
grep "Nmap scan" /opt/eip/v1.1/tmp/eip_ping_results.txt > "/opt/eip/v1.1/tmp/eip_ping_alive_results.txt"

#filters out only the ip addresses
awk 'NF>1{print $NF}' /opt/eip/v1.1/tmp/eip_ping_alive_results.txt > /opt/eip/v1.1/tmp/eip_ping_alive_ip.txt

#identifies only unique values
mv "/opt/eip/v1.1/eip_final.txt" "/opt/eip/v1.1/tmp/eip_final_01.txt"
grep "" "/opt/eip/v1.1/tmp/eip_ping_alive_ip.txt" | tr -d '(' | tr -d ')' | sort -u > /opt/eip/v1.1/eip_final.txt


#performing nslookup, backing file up first. more info can be found in 
#nslookup.pl, but it ingests data from eip_final.txt
mv /opt/eip/v1.1/tmp/nslookup_results.txt /opt/eip/v1.1/tmp/nslookup_results01.txt
/opt/eip/v1.1/nslookup.pl > /opt/eip/v1.1/tmp/nslookup_results.txt

#grep and sed it to look pretty :)...sed is pointless in this case, but keeping
#it for future reference
#grep "name =" ./tmp/nslookup_results.txt | sed -n -e 's/^.*name = //p' > eip_final_hostnames.txt
grep "name =" /opt/eip/v1.1/tmp/nslookup_results.txt > /opt/eip/v1.1/eip_final_hostnames.txt



#compare r7_active_ip.txt (as source) to eip_final.txt
#this will show any new ips that exist due to this tool, that are missing
#from rapid7 asv. 
#NOTE: rapid7 active IP is ACTIVE ONLY. IPs may already be configured in
#va2.rapid7.com -you'll need to verify.
#IF ip address doesn't exist in va2.rapid7.com, send e-mail to rapid7 support
#and ask them to add new IPs to the site for future scanning

mv /opt/eip/v1.1/r7_missing_ip.txt /opt/eip/v1.1/tmp/r7_missing_ip.txt
awk 'FNR==NR {a[$0]++; next} !a[$0]' /opt/eip/v1.1/r7_active_ip.txt /opt/eip/v1.1/eip_final.txt > /opt/eip/v1.1/r7_missing_ip.txt

#to view from the web:
mv /opt/eip/v1.1/r7_missing_ip.txt /var/www/<name>
mv /opt/eip/v1.1/eip_final_hostnames.txt /var/www/<name>
