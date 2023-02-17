#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export HOME=/root
export USER=root

# Set home server URL
url="daitest.leibcorp.com"

while [ ! -f /root/instnum.txt ]; do
    sleep 1
done
while [ ! -f /root/resourceGroup.txt ]; do
    sleep 1
done
while [ ! -f /root/companytitle.txt ]; do
    sleep 1
done
while [ ! -f /root/industry.txt ]; do
    sleep 1
done
while [ ! -f /root/demo.txt ]; do
    sleep 1
done
while [ ! -f /root/watsondiscoveryInst.txt ]; do
    sleep 1
done

curl -d "Instance=$(< /root/instnum.txt)&Log=Localizing: $(< /root/industry.txt)/$(< /root/demo.txt) " -X POST https://$url/log
wget -O /root/secData.txt "https://$url/secData?company=$(< /root/companytitle.txt)"

dvar=`cat /root/secData.txt | grep -c 'none'`
if [ $dvar -gt 0 ]
then
tar -xvzf /root/10k.tgz -C /root
else
mkdir /root/10k
(node /root/da/sec.js "$(< /root/secData.txt)"  > /var/log/secData.log 2>&1 ) &
fi
# downgrade node and npm
npm install --location=global npm@6

# need to move flows to proper folder
mv /root/flows.json /root/.node-red/flows_$(< /root/resourceGroup.txt)-vsi.json
tar -xvzf /root/discovery.tgz -C /root
npm --prefix /root/discoveryService install /root/discoveryService

curl -d "Instance=$(< /root/instnum.txt)&Log=Starting Services" -X POST https://$url/log
systemctl enable nodered.service
systemctl start nodered.service
node /root/da/pmw.js "https://$(< /root/instnum.txt)-target.$url/" "$(< /root/companyurl.txt)" &

