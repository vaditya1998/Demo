# sh backup_restore_oracle.sh dummy_host 1521 system 'MyStrongPass123@' XEPDB1
# sqlplus system/MyStrongPass123@localhost:1521/XEPDB1


# we are restoring the database to a new docker oracle database container hence we are using the docker network ip as a remote host ip

host=$1
port=$2
username=$3
password=$4
dbServiceName=$5

echo "Host- $host Port- $port Username- $username Password- $password Oracle DB Service Name - $dbServiceName"
echo "waiting for database docker container to get start"

if [ "$host" = "dummy_host" ]; then
  
  docker_network_gateway_ip=$(docker network inspect i2b2-net -f '{{range .IPAM.Config}}{{.Gateway}}{{end}}') 
  host=$ip
  docker run --name oracle18 \
  -p 1522:1521 -p 5501:5500 \
  -e ORACLE_PWD=MyStrongPass123 \
-d container-registry.oracle.com/database/express:latest
#new oracle docker container for restore process outside docker network

fi

sleep 180 #waiting for source docker container to get started
echo "creating backup "

docker exec -u 0 i2b2-data-oracle expdp system/MyStrongPass123@//localhost:1521/XEPDB1 \
  full=y \
  directory=DATA_PUMP_DIR \
  dumpfile=full_backup_2025.dmp \
  logfile=full_backup_2025.log

echo "backup completed"
echo "starting the oracle docker database container outside i2b2 docker network"
sleep 120

docker cp i2b2-data-oracle:/opt/oracle/admin/XE/dpdump/01F61DF5197F090CE06307FEA8C03EE4/full_backup_2025.dmp .

ls -la
sleep 10

docker exec  -i oracle18 sqlplus -S system/MyStrongPass123@//localhost:1521/XEPDB1 <<EOF
SELECT * FROM dba_directories;
EXIT;
EOF


docker cp full_backup_2025.dmp oracle18:/opt/oracle/admin/XE/dpdump/01F61DF5197F090CE06307FEA8C03EE4/full_backup_2025.dmp

docker exec -u 0 oracle18 chmod -R a+r /opt/oracle/admin/XE/dpdump/
 
echo "restoring backup"
docker exec -u 0 oracle18 impdp system/MyStrongPass123@//localhost:1521/XEPDB1 \
  full=y \
  directory=DATA_PUMP_DIR \
  dumpfile=full_backup_2025.dmp \
  logfile=full_backup_2025.log




default_host="_IP=i2b2-data-oracle"
default_port="_PORT=1521"
default_username="_USER=i2b2"
default_password="_PASS=demouser"
default_service_name="_SERVICE_NAME=XEPDB1"


#updating the .env file

sed -i "s/${default_host}/_IP=${host}/g" .env
sed -i "s/${default_port}/_PORT=${port}/g" .env
# sed -i "s/${default_username}/_USER=${username}/g" .env
# sed -i "s/${default_password}/_PASS=${password}/g" .env
sed -i "s/${default_service_name}/_SERVICE_NAME=${dbServiceName}/g" .env


docker rm -f i2b2-core-server i2b2-webclient
docker compose up -d i2b2-core-server i2b2-webclient
# #docker rm -f i2b2-data-oracle #uncomment this line if you have space issue

echo "Started i2b2-core-server & i2b2-webclient Docker containers"
echo "logs of i2b2-core-server container    - "
docker logs -f i2b2-core-server
