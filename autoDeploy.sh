#!/bin/bash
################################################
#   Todo:自动部署项目代码。  
#   Author:归根落叶
#   Blog:http://www.trongeek.com             
################################################

#Function:  printLog()
#Author:    归根落叶
#Todo:  打印日志
#Usage: logInfo(日志信息)
logPath="`pwd`"
function printLog(){
    errorCode=$?
    if [ $# -ne 1 ];then
        echo `date +"%Y-%m-%d %H:%M:%S"` "Usage:printLog logInfo" | tee --append ${logPath}/svnRuntimeLog.txt
        exit 1
    fi
    logInfo=$1
    if [ $errorCode -ne 0 ];then
        echo `date +"%Y-%m-%d %H:%M:%S"` "[ERROR]#${logInfo}" | tee --append ${logPath}/svnRuntimeLog.txt
        return 1
    else
        echo `date +"%Y-%m-%d %H:%M:%S"` "${logInfo}" >> ${logPath}/svnRuntimeLog.txt
    fi
}

#Function:  backup()
#Author:    归根落叶
#Todo:  备份部署包
#Usage: fileName(备份文件名),backupPath(备份路径)
function backup(){
    if [ $# -ne 2 ];then
        printLog "Usage:backup fileName backupPath"
        exit 1
    fi
    fileName=$1
    backupPath=$2
    bakDate=`date +'%Y%m%d'`
    bakTime=`date +'%H%M'`
    delTime=`date -d -7day +'%Y%m%d'`
    echo "备份文件[${fileName}]至[${backupPath}/${bakDate}/${bakTime}-${fileName}]"
    if [ -d ${backupPath}/${bakDate} ];then
        mv ${fileName} ${backupPath}/${bakDate}/${bakTime}-${fileName}
        printLog "备份文件[${fileName}]至[${backupPath}/${bakDate}/${bakTime}-${fileName}]"
    else
        mkdir -p ${backupPath}/${bakDate}
        mv ${fileName} ${backupPath}/${bakDate}/${bakTime}-${fileName}
        printLog "备份文件[${fileName}]至[${backupPath}/${bakDate}/${bakTime}-${fileName}]"
    fi
    echo "删除7天前的备份文件[${backupPath}/${delTime}]"
    rm -rf ${backupPath}/${delTime}    
    printLog "删除7天前的备份文件[${backupPath}/${delTime}]"
}

#Function:  deploy()
#Author:    归根落叶
#Todo:  部署项目
#Usage: packageFile(.tar.gz部署包名),delFile(删除文件列表),projectPath(项目路径)
function deploy(){
    if [ $# -ne 3 ];then
        printLog "Usage:deploy packageFile delFile projectPath"
        exit 1
    fi
    packageFile=$1
    delFile=$2
    projectPath=$3
    if [ -f ${packageFile}.tar.gz ];then
        rm -rf ${packageFile}_* 
        tar zxvf ${packageFile}.tar.gz
        if [ -f ${delFile} ];then
            cat ${delFile} |
            while read row; do
                if [ "${row}" == "noneLine" ];then
                    exit
                elif [ "${row}" != "" ];then 
                    rm -rfv ${projectPath}/${row}
                    printLog "删除 ${projectPath}/${row}"
                fi
            done
        fi
        echo "部署升级包[${packageFile}_*/]至[${projectPath}]"
        chown -R www.www ${packageFile}_*/
        printLog "更改[${packageFile}_*/]权限为www.www"
        \cp -rfv ${packageFile}_*/* ${projectPath}
        printLog "部署升级包[${packageFile}_*/]至[${projectPath}]"
        rm -rf ${packageFile}_*
        printLog "删除升级包[${packageFile}_*]"
    else
    	printLog "升级包[${packageFile}.tar.gz]不存在!"
    	exit 1
    fi
}

#Function:  updateSql()
#Author:    归根落叶
#Todo:  更新数据库
#Usage: host(数据库主机地址),username(数据库用户名),password(数据库密码),dbname(数据库名),sqlFile(数据库sql文件)
function updateSql(){
    if [ $# -ne 5 ];then
        printLog "Usage:updateSql host username password dbname sqlFile"
        exit 1
    fi
    host=$1
    username=$2
    password=$3
    dbname=$4
    sqlFile=$5
    if [ -f ${sqlFile} ];then
        row=`cat ${sqlFile}`
        if [ "${row}" != "noneLine" ];then
            mysql -u"${username}" -p"${password}" -h"${host}" --default-character-set=utf8 ${dbname} < ${sqlFile}
            printLog "自动更新数据库[${host}:${dbname}]"
        fi
    fi 
}

   
#数据库主机地址
host="127.0.0.1"
#数据库用户名                                 
username="username"     
#数据库密码                              
password="password"
#数据库名
dbname="testdb"
#数据库sql文件
sqlFile="auto.sql"
#环境(test|pre|PRO)                                   
env="test"
#服务器部署绝对路径                                  
envURL="/website/html"  

deploy "upgrade${env}" "delList${env}Up.txt" "${envURL}"
updateSql "${host}" "${username}" "${password}" "${dbname}" "${sqlFile}"
backup "upgrade${env}.tar.gz" "/home/www/backup"
backup "delList${env}Up.txt" "/home/www/backup"
backup "downgrade${env}.tar.gz" "/home/www/backup"
backup "delList${env}Down.txt" "/home/www/backup"