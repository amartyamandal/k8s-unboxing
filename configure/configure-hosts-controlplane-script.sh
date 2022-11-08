source ./configure/functions/utility.sh

sudo cp /etc/hosts /etc/hosts.bkup
sudo cp templates/hosts.template /etc/hosts
CPHOSTS=""
for (( instance = 1; instance <= $k8s_ncpnd; ++instance )); do
    INTERNAL_IP="$(getIP 'cp' 'k8s-master-'$instance)"

    echo $INTERNAL_IP
    CPHOSTS+="$INTERNAL_IP k8s-master-$instance.$k8s_domain\n"
done
sudo sed -i "s/@CPHOSTS@/$CPHOSTS/g" /etc/hosts

INTERNAL_LB_IP="$(getIP 'lb')"
echo $INTERNAL_LB_IP

sudo sed -i 's/'k8s-lb'-ip/'$INTERNAL_LB_IP'/g' /etc/hosts
sudo sed -i "s/@DOMAIN@/$k8s_domain/g" /etc/hosts

