#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export HOME=/root
export USER=root

# Set home server URL
if [ -f /root/host_url.txt ]; then
    url=$(</root/host_url.txt)
else
    url="daitest.leibcorp.com"
fi

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

curl -d "Instance=$(</root/instnum.txt)&Log=Localizing: $(</root/industry.txt)/$(</root/demo.txt) " -X POST https://$url/log
wget -O /root/secData.txt "https://$url/secData?company=$(</root/companytitle.txt)"
wget -O /root/finance_dte_model.zip https://ibm.box.com/shared/static/h7sca2gyrz0az58vicqlqijh1mvtl71u.zip

dvar=$(cat /root/secData.txt | grep -c 'none')
if [ $dvar -gt 0 ]; then
    tar -xvzf /root/10k.tgz -C /root
else
    mkdir /root/10k
    (node /root/da/sec.js "$(</root/secData.txt)" >/var/log/secData.log 2>&1) &
fi
# downgrade node and npm
npm install --location=global npm@6

# need to move flows to proper folder
mv /root/flows.json /root/.node-red/flows_$(</root/resourceGroup.txt)-vsi.json
tar -xvzf /root/discovery.tgz -C /root
npm --prefix /root/discoveryService install /root/discoveryService

# get WA info from DB
curl -d "Instance=$(</root/instnum.txt)&Log=Getting Assistant info for demo: $(</root/instnum.txt) " -X POST https://$url/log
curl -X POST -d "instance=$(</root/instnum.txt)" https://$url/getAssistant >waids.txt

curl -d "Instance=$(</root/instnum.txt)&Log=Starting Services" -X POST https://$url/log
systemctl enable nodered.service
systemctl start nodered.service
node /root/da/pmw.js "https://$(</root/instnum.txt)-target.$url/" "$(</root/companyurl.txt)" &
