#!/bin/bash

# 1. Build the application using Maven
/home/shamit/maven/bin/mvn clean package

# 2. Start the local MariaDB database server in the background
/home/shamit/mariadb/bin/mariadbd-safe --datadir=/home/shamit/mariadb/data &

# 3. Copy the compiled WAR file to Tomcat webapps directory
cp target/attendance-management-system.war /home/shamit/tomcat9/webapps/

# 4. Start the Apache Tomcat server
/home/shamit/tomcat9/bin/startup.sh

echo "=========================================================="
echo "Build and startup commands executed successfully!"
echo "Please wait a few seconds for Tomcat and MariaDB to initialize."
echo "You can access the system at http://localhost:8080/attendance-management-system/"
echo "=========================================================="
