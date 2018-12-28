#!/bin/bash
set -e
#set -x

JASPERPATH=/opt/jasper

function usage {
cat << EOT
Install Abiquo Reports

Database connection options:

-h [DATABASEHOST] - defaults localhost
-u [DATABASEUSER] - defaults root
-p [DATABASEPASSWORD] - default nil
-P [DATABASEPORT] - default 3306

Installation options
-r [report] - find and installs this particular report
EOT
}

while getopts "h:u:p:P:r:" OPTION
do
  case $OPTION in
  (h) PARAMHOST=$OPTARG ;;
  (u) PARAMUSER=$OPTARG ;;
  (p) PARAMPASS=$OPTARG ;;
  (P) PARAMPORT=$OPTARG ;;
  (r) PARAMREPORT=$OPTARG ;;
  (*) usage;  exit 1 ;;
  esac
done

DBHOST=${PARAMHOST:-localhost}
DBUSER=${PARAMUSER:-root}
DBPASS=${PARAMPASS:-}
DBPORT=${PARAMPORT:-3306}

MYSQLCMD="mysql -u$DBUSER -h$DBHOST -P$DBPORT ${DBPASS:+-p$DBPASS} "

$MYSQLCMD -e '' || {
  echo "Cannot connect to database."
  usage
  exit 1
}

if [ ! -d $JASPERPATH ]; then
  cat << EOT
Cannot find jasperserver installation, please make sure you are using
Jasper Server Community 6.2.0 and it is located under $JASPERPATH
EOT
fi

echo "Importing schema"
$MYSQLCMD < reports/Schema/kinton_reporting.sql || {
  echo "Could not import schema kinton_reporting"; exit 1
}

$MYSQLCMD < reports/Schema/kinton_reports.sql || {
  echo "Could not import schema kinton_reports"; exit 1
}

$MYSQLCMD kinton < $(find ./reports/ -iname '*sql'|grep Common) || {
  echo "Could not import Common procs into kinton" ; exit 1
}

for report in $(find ./reports/ -iname '*sql'|grep -v Common|grep -v Schema);
do
  $MYSQLCMD < $report
done

: Update database connection values on DataSource.xml
for configfile in $(find . -iname 'Abiquo_Database.xml');
do
  sed -i "s/192.168.56.10:3306/$DBHOST:$DBPORT/" $configfile
  sed -i "s/reporter/$DBUSER/" $configfile
  sed -i "s/Password>.*<\/conn/Password>$DBPASS<\/conn/" $configfile
done

SCRIPTPATH=$(pwd -P)
pushd $JASPERPATH/buildomatic

for report in $(find $SCRIPTPATH -iname 'index.xml' -printf '%h\n');
do
  echo "Importing $report"
  ./js-import.sh --input-dir $report
done

popd

echo "Installing authentication"

#
# Copy the template authentication XML and change it to include the correct data
#
# Remove old backup copy, and make an existing file the backup
rm -f ./auth/applicationContext-externalAuth-abiquo-db.xml.pop.bak

if [ -e ./auth/applicationContext-externalAuth-abiquo-db.xml.pop ]; then
    mv ./auth/applicationContext-externalAuth-abiquo-db.xml.pop ./auth/applicationContext-externalAuth-abiquo-db.xml.pop.bak
fi

# Copy the template and populate it correctly
cp ./auth/applicationContext-externalAuth-abiquo-db.xml ./auth/applicationContext-externalAuth-abiquo-db.xml.pop

sed -i "s/<DBMS_HOST>/${DBHOST}/g" ./auth/applicationContext-externalAuth-abiquo-db.xml.pop
sed -i "s/<DBMS_USER>/${DBUSER}/g" ./auth/applicationContext-externalAuth-abiquo-db.xml.pop
sed -i "s/<DBMS_PASS>/${DBPASS}/g" ./auth/applicationContext-externalAuth-abiquo-db.xml.pop
sed -i "s/<DBMS_PORT>/${DBPORT}/g" ./auth/applicationContext-externalAuth-abiquo-db.xml.pop

# Now delete any ‘old’ files from JasperServer
rm -f /opt/abiquo/tomcat/webapps/jasperserver/WEB-INF/lib/abiquo-jasperserver-auth.jar
rm -f /opt/abiquo/tomcat/webapps/jasperserver/WEB-INF/applicationContext-externalAuth-abiquo-db.xml

# Put the new files in place
cp ./auth/abiquo-jasperserver-auth.jar /opt/abiquo/tomcat/webapps/jasperserver/WEB-INF/lib/abiquo-jasperserver-auth.jar
cp ./auth/applicationContext-externalAuth-abiquo-db.xml.pop /opt/abiquo/tomcat/webapps/jasperserver/WEB-INF/applicationContext-externalAuth-abiquo-db.xml

echo "Restarting abiquo-tomcat"
systemctl restart abiquo-tomcat
