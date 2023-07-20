#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export HOME=/root
export USER=root

# Set home server URL
if [ -f /root/host_url.txt ]; then
    url=$(< /root/host_url.txt)
else
    url="daitest.leibcorp.com"
fi

while [ ! -f /root/instnum.txt ]; do
    sleep 1
done
while [ ! -f /root/companysafe.txt ]; do
    sleep 1
done
while [ ! -f /root/company.txt ]; do
    sleep 1
done
while [ ! -f /root/companyurloverride.txt ]; do
    sleep 1
done
while [ ! -f /root/companycompact.txt ]; do
    sleep 1
done

curl -d "Instance=$(< /root/instnum.txt)&Log=Booting VSI" -X POST https://$url/log

mkdir /root/demo
mkdir /root/da

# download necessary files for build
wget -O /root/flows.json https://raw.githubusercontent.com/ch0pper1/demo-scripts/master/flowsV4.7.json
wget -O /root/10k.tgz https://raw.githubusercontent.com/ch0pper1/demo-scripts/master/10k.tgz
wget -O /root/discovery.tgz https://raw.githubusercontent.com/ch0pper1/demo-scripts/master/discoV2.tgz
wget -O /root/tsend https://raw.githubusercontent.com/ch0pper1/demo-scripts/master/tsend
wget -O /root/upsell.zip https://raw.githubusercontent.com/ch0pper1/demo-scripts/master/upsell.zip
wget -O /tmp/medprocedure-table.csv https://raw.githubusercontent.com/ch0pper1/demo-scripts/master/medprocedure-table.csv
wget -O /tmp/zipcodes-table.csv https://raw.githubusercontent.com/ch0pper1/demo-scripts/master/zipcodes-table.csv
wget -O /root/da/package.json https://raw.githubusercontent.com/ch0pper1/demo-scripts/master/dataAggregator/package.json
wget -O /root/da/data_aggregator.js https://raw.githubusercontent.com/ch0pper1/demo-scripts/master/dataAggregator/data_aggregator.js
wget -O /root/da/pmw.js https://raw.githubusercontent.com/ch0pper1/demo-scripts/master/dataAggregator/pmw.js
wget -O /root/da/bg.js https://raw.githubusercontent.com/ch0pper1/demo-scripts/master/dataAggregator/bg.js
wget -O /root/da/sec.js https://raw.githubusercontent.com/ch0pper1/demo-scripts/master/dataAggregator/sec.js

# TODO: change this to API call
wget -O /root/logosmall.png https://$url/static/img/$(< /root/companycompact.txt).small.png
wget -O /root/logo.png https://$url/static/img/$(< /root/companycompact.txt).png
wget -O /root/ip.txt icanhazip.com

echo "$(< /root/ip.txt)  https://$(< /root/instnum.txt).daitest.leibcorp.com" >> /etc/hosts

apt-get update
curl -d "Instance=$(< /root/instnum.txt)&Log=Patching VSI" -X POST https://$url/log
apt-get -y -o Dpkg::Options::="--force-confnew" upgrade
curl -d "Instance=$(< /root/instnum.txt)&Log=Installing Core Packages" -X POST https://$url/log
apt-get -y -o Dpkg::Options::="--force-confnew" install libcurl4 libssl3 build-essential fdupes libgbm-dev libpangocairo-1.0-0 libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6 libnss3 libcups2 libxss1 libxrandr2 libgconf-2-4 libasound2 libatk1.0-0 libgtk-3-0 postgresql postgresql-contrib imagemagick

curl -d "Instance=$(< /root/instnum.txt)&Log=Installing postgreSQL" -X POST https://$url/log
# getting postgres version or defaulting to 14
sed -i 's/\#listen_addresses/listen_addresses/g' /etc/postgresql/14/main/postgresql.conf
sed -i 's/localhost/\*/g' /etc/postgresql/14/main/postgresql.conf
sed -i 's/5432/16002/g' /etc/postgresql/14/main/postgresql.conf
sed -i 's/\# TYPE/host  all  all 0.0.0.0\/0 md5\# TYPE/g' /etc/postgresql/14/main/pg_hba.conf
service postgresql restart

sudo -u postgres -H -- psql -c 'CREATE TABLE medprocedure (procedure varchar (2555), about varchar (2555), state varchar (255), in_network_cost decimal (16), out_of_network_cost decimal (16), medical_code varchar (255) ); CREATE TABLE zipcode (zip varchar (15), city varchar (255), county varchar (255), state varchar (255) ); CREATE TABLE "SEGMENT" ("ID" varchar (155), "ANONYMOUS_ID" varchar (155), "S_TIMESTAMP" timestamp, "EVENT" varchar (155),"EVENT_NAME" varchar (255),"CAMPAIGN_ID" varchar (155),"CAMPAIGN_NAME" varchar (255),"EVENT_DETAIL" varchar (999),"EVENT_BLOB" varchar (99999),"EVENT_LINK" varchar (999)); CREATE TABLE "SENTIMENT" ("USER" varchar (15), "ETIME" timestamp, "SCORE" decimal (8) ); CREATE TABLE "CALL_CLASSIFICATION" ("USER" varchar (15), "CLASS_NAME" varchar (255), "CONFIDENCE" decimal (16) ); CREATE TABLE "CALL_CLASSIFICATION_FINE" ("USER" varchar (15), "CLASS_NAME" varchar (255), "CONFIDENCE" decimal (16) ); CREATE TABLE "CALL_TONE" ("USER" varchar (15), "TONE_NAME" varchar (255), "SCORE" decimal (16) ); CREATE TABLE "CALL_RISK" ("USER" varchar (15), "RISK" decimal (8) ); CREATE TABLE "USERS" ("ID" varchar (11), "GENDER" varchar (1), "AGE" smallint, "MAIDEN_NAME" varchar (255), "LNAME" varchar (255), "FNAME" varchar (255), "ADDRESS" varchar (255), "CITY" varchar (255),"STATE" varchar (255), "ZIP" integer, "COUNTRY" varchar (255), "PHONE" bigint, "EMAIL" varchar (255), "CC_NUMBER" varchar (19), "MONTHLY_PAYMENT" smallint, "TOTAL_PAYMENTS" smallint, "LATITUDE" decimal (16), "LONGITUDE" decimal (16) ); CREATE TABLE "WIDGET_DATA" ("USER" varchar (15), "WIDGET_TYPE" varchar (50), "DATA_VALUE" varchar (10000), "DATA_ORDER" integer); CREATE VIEW "CALL_CLASSIFICATION_AVG_VW" AS SELECT "USER", "CLASS_NAME", sum("CONFIDENCE") as "CONFIDENCE" FROM "CALL_CLASSIFICATION" group by "USER", "CLASS_NAME" LIMIT 5;CREATE VIEW "CALL_CLASSIFICATIONFG" AS SELECT "USER", "CLASS_NAME", sum("CONFIDENCE") as "CONFIDENCE" FROM "CALL_CLASSIFICATION_FINE" group by "USER", "CLASS_NAME" LIMIT 5;'
sudo -u postgres -H -- psql -c "ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'md5909938b1443eb2d22ecfb40fa5a37199';"


sudo -u postgres -H -- psql -c "COPY zipcode(zip, city, county, state) FROM '/tmp/zipcodes-table.csv' DELIMITER ',' CSV HEADER;"
sudo -u postgres -H -- psql -c "COPY medprocedure(procedure, about, state, in_network_cost, out_of_network_cost, medical_code) FROM '/tmp/medprocedure-table.csv' DELIMITER ',' CSV HEADER;"

# Update Apt to provide nodejs version 16
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -

curl -d "Instance=$(< /root/instnum.txt)&Log=Installing Node" -X POST https://$url/log
wget https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered
bash update-nodejs-and-nodered --node16 --confirm-root --confirm-install --skip-pi
npm install --prefix /root/.node-red node-red-node-watson
npm install --prefix /root/.node-red node-red-contrib-startup-trigger
openssl req -nodes -newkey rsa:2048 -keyout /root/.node-red/node-key.pem -out /root/.node-red/node-csr.pem -subj "/C=US/ST=Dallas/L=Dallas/O=Global Security/OU=IT Department/CN=$(curl -s ipinfo.io/ip)"
openssl x509 -req -in /root/.node-red/node-csr.pem -signkey /root/.node-red/node-key.pem -out /root/.node-red/node-cert.pem

curl -d "Instance=$(< /root/instnum.txt)&Log=Starting Data Aggregator" -X POST https://$url/log

# removed download of files as they will be downloaded during TF script
chmod +x /root/tsend
npm --prefix /root/da install /root/da
wget -O /root/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt-get -y -o Dpkg::Options::="--force-confnew" install /root/google-chrome-stable_current_amd64.deb
curl -iILs -o /dev/null -w %{url_effective} $( < /root/companyurl.txt ) > /root/companyurl.txt
node /root/da/bg.js "$(< /root/companyurl.txt)"  "$(< /root/proxyhigh.txt)" &
(node /root/da/data_aggregator.js "$(< /root/companyurl.txt)"  "$(< /root/proxylow.txt)" > /var/log/dataaggregator.log 2>&1 ) &
echo $! > /root/dapid

# create file for WA info
touch /root/waids.txt
touch /root/wadialog
