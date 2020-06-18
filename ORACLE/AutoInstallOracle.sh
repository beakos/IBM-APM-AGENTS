################################ DEV + ORACLE
clear
rm -fr /opt/ibm/apm/APMADV*
rm -fr /opt/ibm/apm/depura_espacio_apm*
rm -fr /opt/ibm/apm/linux*
rm -fr /opt/ibm/apm/salida*
rm -fr /opt/ibm/apm/file1*
rm -fr /opt/ibm/apm/lost+found
#########################################################
echo "---> Validando Instalaciones Previas de APM"
sleep 2
if [ $(ls -la /opt/ibm/apm/ | grep -c agent) -gt 0 ]; then
	echo "Existe una instalación de APM en el equipo"
	echo "----> Desinstalando..."
	/opt/ibm/apm/agent/bin/smai-agent.sh uninstall_all
else
    echo "No hay instalaciones de APM en el equipo"
fi
##########################################################
	echo "----> Iniciando Instalacion..."
sleep 3
clear
set -e
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR
#################
echo "--- Valida Agentes corriendo"
sleep 2
if [ $(ps -fea | grep k..agent | grep -cv grep) -gt 0 ]; then
	echo "Mantando processo de agentes corriendo.."
	kill $(ps -fea | grep k..agent  | awk '{print $2}')

else
    echo "No hay agentes ejuectando"
fi
######## iniicia
echo "----> Inicia con Descarga de Instaladores para Agentes APM Oracle"
sleep 2
sudo chmod 404 /sys/class/dmi/id/product_uuid
sudo su - tivmon -c "curl http://${IP1}/agentes/AGENTES_PRODUCCION/APM_OS_Oracle_Dev_v10.tar --output /opt/ibm/apm/APM_OS_Oracle_Dev_v10.tgz"
sudo su - tivmon -c "mkdir /opt/ibm/apm/tmp/"
sudo su - tivmon -c "curl http://${IP1}/agentes/AGENTES_PRODUCCION/smai-oracle_database-custom-01.03.00.00.tgz --output /opt/ibm/apm/tmp/smai-oracle_database-custom-01.03.00.00.tgz"
echo "---> Desempaquetando archivos de Instalación"
sudo su - tivmon -c "tar -C /opt/ibm/apm/ -xf APM_OS_Oracle_Dev_v10.tgz"
echo "---> Creando Archivo de Configuración silenciosa"
echo 'License_Agreement="I agree to use the software only in accordance with the installed license."' > silentinstall.txt
echo "INSTALL_AGENT=os" >> silentinstall.txt
echo "INSTALL_AGENT=oracle" >> silentinstall.txt
echo "AGENT_HOME=/opt/ibm/apm/agent" >> silentinstall.txt
echo "MIGRATE_CONF=yes" >> silentinstall.txt
echo ""
chown tivmon:tivmon /opt/ibm/apm/silentinstall.txt
echo "---> Validando Pre-requisitos"
if [ $(rpm -qa|grep -c bc-1.06) -gt 0 ]; then
    echo "paquete bc ya instalado!"
else
		echo "---> Instalando bc"
    sudo su - tivmon -c "curl http://${IP1}/agentes/AGENTES_PRODUCCION/bc-1.06.95-13.el7.x86_64.rpm --output /opt/ibm/apm/bc-1.06.95-13.el7.x86_64.rpm"
    sudo rpm -ivh /opt/ibm/apm/bc-1.06.95-13.el7.x86_64.rpm
fi
rm -fr APM_OS_Oracle_Dev_v10.tgz
rm -fr bc-1.06.95-13.el7.x86_64.rpm
echo "---> Instalando APM..."
sudo su - tivmon -c "/opt/ibm/apm/APM_OS_Oracle_Dev_v10/installAPMAgents.sh -p /opt/ibm/apm/silentinstall.txt"
sudo su - tivmon -c "/opt/ibm/apm/agent/bin/cinfo -r "
sudo /opt/ibm/apm/agent/bin/UpdateAutoRun.sh
sudo su - tivmon -c "cat agent/logs/lz_ServerConnectionStatus.txt"
rm -fr APM_OS_Oracle_Dev_v10* bc-1.06.95-13.el7.x86_64.rpm silentinstall.txt dev


sudo su - tivmon -c "curl http://${IP1}/silenconfig.sh --output /opt/ibm/apm/silenconfig.sh"
sudo su - tivmon -c "curl http://${IP1}/grants.sql --output /opt/ibm/apm/grants.sql"
sudo su - tivmon -c "curl http://${IP1}/ora.sh --output /opt/ibm/apm/ora.sh"
#Corrige Permisos para Tivmon

. /herramientas/oracle/.bash_profile

ORA_SID=$(echo "$ORACLE_SID" | tr '[:upper:]' '[:lower:]')

chmod 775 /herramientas/oracle/diag/rdbms/${ORA_SID}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
chmod 775 /herramientas/oracle/diag/rdbms/${ORA_SID}/${ORACLE_SID}/trace
chmod 775 /herramientas/oracle/diag/rdbms/${ORA_SID}/${ORACLE_SID}
chmod 775 /herramientas/oracle/diag/rdbms/${ORA_SID}
chmod 775 ${ORACLE_HOME}/network/admin/tnsnames.ora

sleep 3
echo "----> Ejecutar GRANTS"
read
### Ejecutar GRANTS #####################################################
sudo su - oracle -c "sh /opt/ibm/apm/ora.sh"
echo "----> Iniciando Silent Config..."

sudo su - tivmon -c "mkdir /opt/ibm/apm/agent/config/oracle"
sudo su  - tivmon -c "sh silenconfig.sh"

echo "----> Ejecutando Scripts automaticos de inicio..."

/opt/ibm/apm/agent/bin/UpdateAutoRun.sh

rm -fr /opt/ibm/apm/grants.sql /opt/ibm/apm/ora.sh /opt/ibm/apm/silenconfig.sh /opt/ibm/apm/silent_config.txt /opt/ibm/apm/tmp

#######################################
