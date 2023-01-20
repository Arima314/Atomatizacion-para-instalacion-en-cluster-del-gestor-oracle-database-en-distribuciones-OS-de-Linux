#!/bin/bash

IPs=()
Nodos=()
GetIP=$(ip route get 1.2.3.4 | awk '{print $7}')
Reporte=()

ObtenerIPNodos(){
  while true; do
    echo -e  "\n\033[43;30mDigite el nombre del archivo que contiene las IPs de los nodos (En el formato nombre.txt - debe estar en la ruta desde donde ejecuta este archivo.):\033[0m\n "
    read -r -p "Nombre del archivo: " FileName
    if test -f "$FileName"; then
      break
    else
      echo -e "\n\033[43;30mEl nombre del archivo ingresado no existe en el sistema, intentelo de nuevo.\033[0m\n"
    fi
  done 
}

ValidarEstadoNodos() {
  echo -e "\n\033[43;30mValidando estado de los nodos...\033[0m\n"
  while IFS= read -r line
  do
    if ping -c 2 $line; then
      IPs=("${IPs[@]}" "\033[1;33m$line\033[0m - \033[1;34mUP\033[0m")
      Nodos=("${Nodos[@]}" "$line")
    else
      IPs=("${IPs[@]}" "\033[1;33m$line\033[0m - \033[1;31mDOWN\033[0m") 
    fi
  done < "$FileName"

  echo -e "\n\033[43;30mEl estado de los nodos es:\033[0m\n"
  echo -e "\033[37;7;1m|     IP     |  Estado  |\033[0m"
  for i in "${IPs[@]}"; do
    echo -e "$i"
  done
}

ObtenerVersionOralce() {
  while true; do
    echo -e  "\n\033[43;30mDigite la opción para la versión de Oracle Database que desea instalar (1, 2 o 0):\033[0m\n"
    echo -e "\033[37;7;1m1. Oracle Database 21c\033[0m"
    echo -e "\033[37;7;1m2. Oracle Database 19c\033[0m"
    echo -e "\033[37;7;1m0. Cancelar proceso\033[0m\n"
    read -r -p "Su opción: " OracleV
    if [[ $OracleV == "1" || $OracleV == "2" ]]; then
      break
    elif [[ $OracleV == "0" ]]; then
      echo -e "\n\033[43;30mDeteniendo ejecución del proceso...\033[0m\n"
      exit
    else
      echo -e "\n\033[43;30mOpción no válida, intentelo de nuevo.\033[0m\n"
    fi
  done
} 

GenerarArchivo() {
  Ejecutable='#!/bin/bash
OS=(apt yum dnf pacman)
OV=""
Version() {
  while IFS= read -r line
  do
    OV=$line
  done < Version.txt
  rm -I Version.txt
}

ValidarOS() {
  Ruta="$(pwd)"
  cd /etc/
  if test -f os-release; then 
      source /etc/os-release
      cd "$Ruta"
      echo -e "\n\033[43;30mEl OS es $ID_LIKE\033[0m\n"
  else
      echo -e "\n\033[43;30mEl OS es GNU/Linux\033[0m\n"
      cd "$Ruta"
  fi
}

Oracle21c() {
  dnf -y install https://yum.oracle.com/repo/OracleLinux/OL8/appstream/x86_64/getPackage/oracle-database-preinstall-21c-1.0-1.el8.x86_64.rpm
  rpm -Uvh oracle-database-ee-21c-1.0-1.ol8.x86_64.rpm

  rm -I oracle-database-ee-21c-1.0-1.ol8.x86_64.rpm

  /etc/init.d/oracledb_ORCLCDB-21c configure 

  VariablesEntorno="umask 022
export ORACLE_SID=ORCLCDB
export ORACLE_BASE=/opt/oracle/oradata
export ORACLE_HOME=/opt/oracle/product/21c/dbhome_1"

  echo "$VariablesEntorno" >> /home/oracle/.bash_profile
  source /home/oracle/.bash_profile

  echo "export PATH=$PATH:$ORACLE_HOME/bin" >> /home/oracle/.bash_profile
  source /home/oracle/.bash_profile

  if which sed; then
    sed "s/:N/:Y/g" "/etc/oratab"
  else
    dnf install sed
    sed "s/:N/:Y/g" "/etc/oratab"
  fi

  VariablesEntorno="ORACLE_BASE=/opt/oracle/oradata
ORACLE_HOME=/opt/oracle/product/21c/dbhome_1
ORACLE_SID=ORCLCDB"

  echo "$VariablesEntorno" >> /etc/sysconfig/ORCLCDB.oracledb 

 DataService="[Unit]
Description=Oracle Database service
After=network.target

[Service]
Type=forking
EnvironmentFile=/etc/sysconfig/ORCLCDB.oracledb
ExecStart=/opt/oracle/product/21c/dbhome_1/bin/dbstart $ORACLE_HOME
ExecStop=/opt/oracle/product/21c/dbhome_1/bin/dbshut $ORACLE_HOME
User=oracle

[Install]
WantedBy=multi-user.target"

  echo "$DataService" >> /usr/lib/systemd/system/ORCLCDB@oracledb.service

  systemctl daemon-reload 
  systemctl enable ORCLCDB@oracledb 
}

Oracle19c() {
  dnf -y install https://yum.oracle.com/repo/OracleLinux/OL8/appstream/x86_64/getPackage/oracle-database-preinstall-19c-1.0-1.el8.x86_64.rpm
  rpm -Uvh oracle-database-ee-19c-1.0-1.x86_64.rpm

  rm -I oracle-database-ee-19c-1.0-1.x86_64.rpm

  /etc/init.d/oracledb_ORCLCDB-19c configure

  VariablesEntorno="umask 022
export ORACLE_SID=ORCLCDB
export ORACLE_BASE=/opt/oracle/oradata
export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1"

  echo "$VariablesEntorno" >> /home/oracle/.bash_profile
  source /home/oracle/.bash_profile

  echo "export PATH=$PATH:$ORACLE_HOME/bin" >> /home/oracle/.bash_profile
  source /home/oracle/.bash_profile

  #cp -a -p $ORACLE_HOME/dbs/orapwORCLCDB $ORACLE_HOME/dbs/orapwORCLCDB_OLD
  #orapwd file=$ORACLE_HOME/dbs/orapwORCLCDB password=rootadmin0* force=y

  if which sed; then
    sed "s/:N/:Y/g" "/etc/oratab"
  else
    dnf install sed
    sed "s/:N/:Y/g" "/etc/oratab"
  fi

  VariablesEntorno="ORACLE_BASE=/opt/oracle/oradata
ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
ORACLE_SID=ORCLCDB"

  echo "$VariablesEntorno" >> /etc/sysconfig/ORCLCDB.oracledb

  DataService="[Unit]
Description=Oracle Database service
After=network.target

[Service]
Type=forking
EnvironmentFile=/etc/sysconfig/ORCLCDB.oracledb
ExecStart=/opt/oracle/product/19c/dbhome_1/bin/dbstart $ORACLE_HOME
ExecStop=/opt/oracle/product/19c/dbhome_1/bin/dbshut $ORACLE_HOME
User=oracle

[Install]
WantedBy=multi-user.target"

  echo "$DataService" >> /usr/lib/systemd/system/ORCLCDB@oracledb.service

  systemctl daemon-reload
  systemctl enable ORCLCDB@oracledb  
}

InstalarOracle() {
  case $1 in
  "1") 
    echo -e "\n\033[43;30mInstalando Oracle Database 21c...\033[0m\n"
    Oracle21c
  ;;
  "2")
    echo -e "\n\033[43;30mInstalando Oracle Database 19c...\033[0m\n"
    Oracle19c
  ;;
  *)
    echo -e "\n\033[43;30mHa ocurrido un error. Por favor, intentelo luego.\033[0m\n"
    echo -e "\n\033[43;30mDeteniendo ejecución del proceso...\033[0m\n"
    exit
  ;;
esac
}

InstalarRPM() {
case $1 in
  apt) 
    echo -e "\n\033[43;30mInstalando RPM con apt\033[0m\n"
    sudo apt update
    sudo apt install rpm
  ;;
  yum)
    echo -e "\n\033[43;30mInstalando RPM con yum\033[0m\n"
  ;;
  dnf)
    echo -e "\n\033[43;30mInstalando RPM con dnf\033[0m\n"
  ;;
  pacman)
    echo -e "\n\033[43;30mInstalando RPM con pacman\033[0m\n"
  ;;
  *)
    echo -e "\n\033[43;30mAún no es compatible para esta distribución del sistema operativo Linux. Por favor, intentelo luego.\033[0m\n"
    echo -e "\n\033[43;30mDeteniendo ejecución del proceso...\033[0m\n"
    exit
  ;;
esac
}

InstalarDNF() {
case $1 in
  apt)
    echo -e "\n\033[43;30mInstalando dnf con apt...\033[0m\n"
    sudo apt update
    sudo apt install dnf
  ;;
  yum)
    echo -e "\n\033[43;30mInstalando dnf con yum\033[0m\n"
    yum install dnf
  ;;
  pacman)
    echo -e "\n\033[43;30mInstalando dnf con pacman...\033[0m\n"
    sudo pacman -Sy
    sudo pacman -S dnf
  ;;
  *)
    echo -e "\n\033[43;30mAún no es compatible para esta distribución del sistema operativo Linux. Por favor, intentelo luego.\033[0m\n"
    echo -e "\n\033[43;30mDeteniendo ejecución del proceso...\033[0m\n"
    exit
  ;;
esac
}

GestorPaquetes() {
  for i in $1; do
    which "$i"
    out="${?}"
    if [ "${out}" -eq 0 ]; then
      if $2 == "rpm"; then
        InstalarRPM "$i"
        break
      else
          InstalarDNF "$i"
        break
      fi
      break
    else
      echo -e "\n\033[43;30mAún no es compatible para esta distribución del sistema operativo Linux. Por favor, intentelo luego.\033[0m\n"
      echo -e "\n\033[43;30mDeteniendo ejecución del proceso...\033[0m\n"
      exit
    fi
  done
}

ValidarPaquetes() {
  if which rpm; then
  #output="${?}"
  #if [ "${output}" -eq 0 ]; then
    echo -e "\n\033[43;30mExiste rpm\033[0m\n"
    if which dnf; then
      echo -e "\n\033[43;30mExiste dnf\033[0m\n"
      InstalarOracle "$OV"
    else
      echo -e "\n\033[43;30mNo existe dnf\033[0m\n"
      GestorPaquetes "${OS[@]}" "dnf"
      InstalarOracle "$OV"
    fi
  else
    echo -e "\n\033[43;30mNo existe rpm\033[0m\n"
    echo -e "\n\033[43;30mValidando gestor de paquetes instalado...\033[0m\n"
    GestorPaquetes "${OS[@]}" "rpm"
    InstalarOracle "$OV"
  fi
}

Reporte() {
  while IFS= read -r line
  do
    IPM=$line
  done < IPMaster.txt

  while IFS= read -r line
  do
    IPN=$line
  done < Nodo.txt

  if which oracle && which sqlplus && sqlplus -V; then
    echo "\033[1;33m$IPN\033[0m - \033[1;34mOK\033[0m" >> Reporte.txt
  else
    echo "\033[1;33m$IPN\033[0m - \033[1;31mERROR\033[0m" >> Reporte.txt
  fi
  scp Reporte.txt root@"$IPM":/home
  rm -I Reporte.txt
  rm -I IPMaster.txt
  rm -I Nodo.txt
}

Main() {
  ValidarOS
  Version
  ValidarPaquetes
  Reporte
}

Main
'
  echo "$Ejecutable" >> Ejecutable.sh
  echo "$OracleV" >> Version.txt 
  echo "$GetIP" >> IPMaster.txt
}

ConectarNodo() {
  case $OracleV in
    "1") 
      for i in "${Nodos[@]}"; do 
        echo -e "\n\033[43;30mConectado a nodo con IP $i...\033[0m\n"
        echo "$i" >> Nodo.txt
        scp Ejecutable.sh Version.txt IPMaster.txt Nodo.txt oracle-database-ee-21c-1.0-1.ol8.x86_64.rpm root@"$i":./
        rm -I Nodo.txt
        ssh -tt root@"$i" "chmod 777 Ejecutable.sh; bash Ejecutable.sh; rm -I Ejecutable.sh" 
        while IFS= read -r line
          do
            Reporte=("${Reporte[@]}" "$line")
          done < /home/Reporte.txt
        sudo rm -I /home/Reporte.txt
      done
    ;;
    "2")
      for i in "${Nodos[@]}"; do 
        echo -e "\n\033[43;30mConectado a nodo con IP $i...\033[0m\n"
        echo "$i" >> Nodo.txt
        scp Ejecutable.sh Version.txt IPMaster.txt Nodo.txt oracle-database-ee-19c-1.0-1.x86_64.rpm root@"$i":./
        rm -I Nodo.txt
        ssh -tt root@"$i" "chmod 777 Ejecutable.sh; bash Ejecutable.sh; rm -I Ejecutable.sh" 
        while IFS= read -r line
          do
            Reporte=("${Reporte[@]}" "$line")
          done < /home/Reporte.txt
        sudo rm -I /home/Reporte.txt
      done
    ;;
    "0")
      echo -e "\n\033[43;30mDeteniendo ejecución del proceso...\033[0m\n"
      exit
    ;;
    *)
      echo -e "\n\033[43;30mHa ocurrido un error. Por favor, intentelo luego.\033[0m\n"
      echo -e "\n\033[43;30mDeteniendo ejecución del proceso...\033[0m\n"
      exit
    ;;
  esac
}

ConfiguracionInicial(){
  ObtenerIPNodos
  ValidarEstadoNodos
  ObtenerVersionOralce 
}

EliminarArchivos() {
  rm -I Ejecutable.sh
  rm -I Version.txt
  rm -I IPMaster.txt
}

GenerarReporte() {
  echo -e "\n\033[43;30mAcorde a las IPs correspondientes a los nodos para realizar el proceso, se tiene el sigueinte reporte:\033[0m\n"
  echo -e "\033[37;7;1m|     IP     |  Resultado  |\033[0m"
  for i in "${Reporte[@]}"; do
    echo -e "$i"
  done
}

Main(){
  ConfiguracionInicial
  GenerarArchivo
  ConectarNodo
  EliminarArchivos
  GenerarReporte
}

Main

echo -e "\n\033[43;30mDeteniendo ejecución del proceso...\033[0m\n"
exit