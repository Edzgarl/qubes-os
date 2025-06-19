à copier dans les AppVM qui utilisent les AppVM avec Network = VPN-CORP, pour utiliser les DNS

cd /rw/config/
sudo mkdir rc.local.d
cd rc.local.d/
sudo nano 50-dns.rc
sudo chmod +x 50-dns.rc
