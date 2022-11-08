# ./destroy.sh
provider=libvirt
domain=vindpro.de

ip_start=192.168.121.128
ip_end=192.168.121.254
ncpnd=3
nwrknd=3

./setup-controlplane.sh $ncpnd $domain
./setup-workers.sh $ncpnd $nwrknd $domain
