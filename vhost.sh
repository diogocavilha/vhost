#!/bin/bash
#
# Autor:    Diogo Alexsander Cavilha <diogocavilha@gmail.com>
# Data:     06/05/2014
#
# Management of virtual hosts for Apache and Nginx server.
#
#   - Creates a virtual host file.
#   - Removes a virtual host file.
#   - Restart the server automaticaly after the changes.
#   - Shows a list of created hosts and its status (Enabled/Disabled)
#==================================================================#

#==================================================================#
# Configuration
#==================================================================#
VHOST_SUPPORTED_SERVERS[0]="Apache"
VHOST_SUPPORTED_SERVERS[1]="Nginx"

readonly SITES_AVAILABLE_APACHE="/etc/apache2/sites-available"
readonly SITES_ENABLED_APACHE="/etc/apache2/sites-enabled"
readonly SITES_DIRECTLY_APACHE=""

readonly SITES_AVAILABLE_NGINX="/etc/nginx/sites-available"
readonly SITES_ENABLED_NGINX="/etc/nginx/sites-enabled"
readonly SITES_DIRECTLY_NGINX="/etc/nginx/conf.d"

readonly HOSTS_FILE="/etc/hosts"
readonly IP_ADDRESS="127.0.0.1"

IGNORE_HOSTS[0]="default"
IGNORE_HOSTS[1]="default-ssl"

#==================================================================#
# Internal variables, please don't change them.
#==================================================================#
VERSION="3.1"

DEFAULT_COLOR="\033[0m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
GREEN="\033[0;32m"

messageRed()
{
    echo -e "\033[0;31m$1\033[0m"
}

messageYellow()
{
    echo -e "\033[1;33m$1\033[0m"
}

messageBlue()
{
    echo -e "\033[0;34m$1\033[0m"
}

messageGreen()
{
    echo -e "\033[0;32m$1\033[0m"
}

#==================================================================#
# Checks whether or not the user who is running this
# script is root.
#==================================================================#
requireRoot()
{
    if [ ! "$USER" == "root" ]; then
        messageRed "\nVocê precisa estar logado como root.\n"
        quitProgram
    fi
}

#==================================================================#
# Requests the server which should be used to create
# the configuration file.
#==================================================================#
menuSelectServer()
{
    clear
    echo -e "Escolha o servidor para criar o host.\n"

    supportedServerId=0
    supportedServers=${VHOST_SUPPORTED_SERVERS[*]}

    for supportedServer in $supportedServers; do
        echo -e " [$supportedServerId] $supportedServer"
        supportedServerId=$((supportedServerId+1))
    done

    echo ""
    echo " [s] Sair."
    echo ""
    read -p " Opção: " option

    if [ "$option" == "s" ]; then
        quitProgram
    else
        SERVER_ID=$option

        $(isSupportedServer $SERVER_ID)
        if [ $? -eq 0 ] || [ -z $SERVER_ID ]; then
            menuSelectServer
        fi

        SERVER_NAME=$(getServerName $SERVER_ID)

        case $SERVER_ID in
            0) SITES_DIRECTLY=$SITES_DIRECTLY_APACHE;;
            1) SITES_DIRECTLY=$SITES_DIRECTLY_NGINX;;
        esac

        SITES_AVAILABLE=$(getSitesAvailablePath $SERVER_ID)
        SITES_ENABLED=$(getSitesEnabledPath $SERVER_ID)

        mainMenu
    fi
}

#==================================================================#
# Checks if the chosen server is supported.
# Returned value:
#   0 - Not supported.
#   1 - Supported.
#==================================================================#
isSupportedServer()
{
    supportedServerId=0
    supportedServers=${VHOST_SUPPORTED_SERVERS[*]}

    for supportedServer in $supportedServers; do
        if [ $1 -eq $supportedServerId ]; then
            return 1
        fi
        supportedServerId=$((supportedServerId+1))
    done

    return 0
}

#==================================================================#
# Receives a file name in order to check whether or not it exists.
# Returned value:
#   0 - File does not exist.
#   1 - File exists.
#==================================================================#
fileExists()
{
    if [ -e "$1" ]; then
        return 1
    else
        return 0
    fi
}

#==================================================================#
# This function receives a directory name in order to check whether
# or not it exists.
# Returned value:
#   0 - Diretory does not exist.
#   1 - Diretory exists.
#==================================================================#
folderExists()
{
    if [ -d "$1" ]; then
        return 1
    else
        return 0
    fi
}

#==================================================================#
# This function receives a port number in order to check whether
# or not it is available.
# Returned value:
#   0 - This port number is available.
#   1 - This port number is not available.
#==================================================================#
isUsedPort()
{
    $(nc -z -w5 $IP_ADDRESS $1)
    if [ $? -eq 0 ]; then
        return 1
    else
        return 0
    fi
}

#==================================================================#
# This function requests the environment variable name.
#==================================================================#
requireEnvironmentVarName()
{
    echo -n " Nome: "
    read evName
    if [ -z $evName ]; then
        requireEnvironmentVarName
    fi
}

#==================================================================#
# This function requests the environment variable value.
#==================================================================#
requireEnvironmentVarValue()
{
    echo -n " Valor: "
    read evValue
    if [ -z $evValue ]; then
        requireEnvironmentVarValue
    fi
}

#==================================================================#
# This function joins all environment variables to a single string.
#==================================================================#
appendEnvironmentVars()
{
    requireEnvironmentVarName
    requireEnvironmentVarValue

    environmentVars+="\tSetEnv $evName \"$evValue\"\n"

    echo -e -n "\n Adicionar mais uma? [S/N]: "
    read oneMore
    case $oneMore in
        "s"|"S") appendEnvironmentVars;;
            *) ;;
    esac
}

#==================================================================#
# This function requests the file name that will be created
# in order to store the configuration code.
#==================================================================#
requireFileName()
{
    local file

    echo -n -e "\n Nome do arquivo: "
    read vhFileName

    if [ ! -z $vhFileName ]; then
        $(fileNameEndUpWithConf "$vhFileName")
        if [ $? -eq 0 ]; then
            vhFileName=${vhFileName}.conf
        fi

        file=$SITES_DIRECTLY/$vhFileName

        if [ "$SITES_DIRECTLY" = "" ]; then
            file=$SITES_AVAILABLE/$vhFileName
        fi

        $(fileExists "$file")
        if [ $? -eq 1 ]; then
            messageRed "\n [$file] Arquivo já existe.\n"
            requireFileName
        fi
    else
        requireFileName
    fi
}

#==================================================================#
# This function requests the application directory.
#==================================================================#
requireApplicationFolder()
{
    echo -n " Caminho da aplicação (Ex: /diretorio/contendo/aplicacao): "
    read vhPath

    if [ ! -z $vhPath ]; then
        $(folderExists "$vhPath")

        if [ $? -eq 0 ]; then
            messageRed "\n [$vhPath] O diretório não existe.\n"
            requireApplicationFolder
        fi
    else
        requireApplicationFolder
    fi
}

#==================================================================#
# This function requires the port number on which the
# application will run.
#==================================================================#
requireApplicationPort()
{
    echo -n " Porta: "
    read vhPort

    if [ ! -z $vhPort ]; then
        $(isUsedPort "$vhPort")

        if [ $? -eq 1 ]; then
            messageRed "\n [$vhPort] Esta porta já está sendo utilizada.\n"
            requireApplicationPort
        fi
    fi
}

#==================================================================#
# This function requires the application's server name.
#==================================================================#
requireApplicationServerName()
{
    echo -n " Server Name: "
    read vhServerName

    if [ -z $vhServerName ]; then
        requireApplicationServerName
    fi
}

#==================================================================#
# Selects which configuration must be used.
#==================================================================#
writeConfigurationStrategy()
{
    local port=$1
    local serverName=$2

    case $SERVER_ID in
        0) writeConfigurationApache "$port" "$serverName";;
        1) writeConfigurationNginx "$port" "$serverName";;
    esac
}

#==================================================================#
# This function writes the host configuration code on its
# correspondent file.
#==================================================================#
writeConfigurationApache()
{
    vhPort=$1
    vhServerName=$2

    local configHeader
    local configServerName
    local file

    file=$SITES_DIRECTLY/$vhFileName

    if [ -z $SITES_DIRECTLY ]; then
        file=$SITES_AVAILABLE/$vhFileName
    fi

    configHeader="Listen $vhPort\n<VirtualHost *:$vhPort>"

    if [ -z $vhPort ]; then
        configHeader="<VirtualHost *:80>"
    fi

    if [ ! -z $vhServerName ]; then
        configServerName="ServerName $vhServerName"
    fi

    echo -e "$configHeader
    DocumentRoot $vhPath
    $configServerName
    $environmentVars
    <Directory $vhPath/>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
    </Directory>
</VirtualHost>" > $file
}

#==================================================================#
# This function writes the host configuration code on its
# correspondent file.
#==================================================================#
writeConfigurationNginx()
{
    vhPort=$1
    vhServerName=$2

    local listenOrServerName
    local file

    file=$SITES_DIRECTLY/$vhFileName

    if [ -z $SITES_DIRECTLY ]; then
        file=$SITES_AVAILABLE/$vhFileName
    fi

    if [ ! -z $vhPort ]; then
        listenOrServerName="listen $vhPort;"
    fi

    if [ ! -z $vhServerName ]; then
        listenOrServerName="server_name $vhServerName;"
    fi

    echo -e "server {
    $listenOrServerName

    location / {
        root $vhPath;

        index  index.php index.html index.htm;
        try_files \$uri \$uri/ @rewrite;
        fastcgi_connect_timeout 3000;
        fastcgi_send_timeout 3000;
        fastcgi_read_timeout 3000;
        client_max_body_size 128M;
        proxy_read_timeout 3000;
    }

    location @rewrite {
        rewrite ^/(.*)$ /index.php?_url=\$uri&\$args;
    }

    error_page  404              /404.html;
    location = /404.html {
        root   /usr/share/nginx/www;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/www;
    }

    location ~ \.php$ {
        root $vhPath;
        try_files \$uri =404;
        #fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;

        include fastcgi_params;

        $environmentVars
    }
}" > $file

}

restartServer()
{
    messageBlue " Reiniciando o $SERVER_NAME..."

    case $SERVER_ID in
        0) sudo service apache2 restart;;
        1) sudo service nginx restart;;
    esac
}

getServerName()
{
    echo ${VHOST_SUPPORTED_SERVERS[$1]}
}

getSitesAvailablePath()
{
    case $1 in
        0) echo $SITES_AVAILABLE_APACHE;;
        1) echo $SITES_AVAILABLE_NGINX;;
    esac
}

getSitesEnabledPath()
{
    case $1 in
        0) echo $SITES_ENABLED_APACHE;;
        1) echo $SITES_ENABLED_NGINX;;
    esac
}

mainMenu()
{
    clear
    header "MENU PRINCIPAL"

    tput cup 5 1
    echo "[0] Adicionar novo host."

    tput cup 6 1
    echo "[1] Deletar host."

    tput cup 7 1
    echo "[2] Listar hosts."

    tput cup 8 0
    printf "%*s" $(tput cols) | tr " " "-"

    tput cup 9 1
    echo "[r] Selecionar outro servidor."

    tput cup 10 1
    echo "[s] Sair."

    tput cup 12 1
    read -p "Opção: " option

    tput sgr0

    mainMenuStrategy $option
}

mainMenuStrategy()
{
    option=$1

    case $option in
        "r"|"R") menuSelectServer;;
        "s"|"S") quitProgram;;
        0) addHost;;
        1) menuRemoveHost;;
        2) listHosts;;
        *) mainMenu;;
    esac
}

#==================================================================#
# This function creates the files within sites-enabled and
# sites-available folders.
#==================================================================#
addHost()
{
    clear

    header "CRIAR HOST"

    requireRoot
    requireFileName
    requireApplicationFolder
    requireApplicationPort

    if [ ${#vhPort} -eq 0 ]; then
        requireApplicationServerName
    fi

    echo -e -n "\n Deseja adicionar variáveis de ambiente? [S/N]: "
    read addEnvironmentVar
    case $addEnvironmentVar in
        "s"|"S") appendEnvironmentVars;;
            *) ;;
    esac

    messageBlue "\n Criando host..."

    if [ ! -z $SITES_DIRECTLY ]; then
        sudo touch $SITES_DIRECTLY/$vhFileName
    else
        sudo touch $SITES_AVAILABLE/$vhFileName
    fi

    writeConfigurationStrategy "$vhPort" "$vhServerName"

    if [ -z $SITES_DIRECTLY ]; then
        messageBlue "\n Habilitando host..."
        sudo a2ensite $vhFileName
    fi

    if [ ${#vhServerName} -gt 0 ]; then
        messageBlue "\n Fazendo backup do arquivo $HOSTS_FILE"

        cp /etc/hosts /etc/hosts.backup

        messageBlue " Adicionando entrada no arquivo $HOSTS_FILE"
        `echo -e "$IP_ADDRESS $vhServerName" >> $HOSTS_FILE`
    fi

    restartServer
    address="http://"

    if [ ${#vhPort} -gt 0 ]; then
        address+="$IP_ADDRESS:$vhPort"
    else
        if [ ${#vhServerName} -gt 0 ]; then
            address+="$vhServerName"
        fi
    fi

    messageBlue "\n Host criado com sucesso. ($address)"

    echo ""
    echo " Precione qualquer tecla para retornar ao menu principal."
    echo ""

    read -p " Tecla: " option

    mainMenu
}

#==================================================================#
# Shows a header at the top of each screen of the program.
#==================================================================#
header()
{
    local headerOption=$1
    local width
    local length

    width=$(tput cols)
    length=${#headerOption}

    tput cup 1 $((($width / 2) - ($length / 2)))
    echo "$headerOption"

    tput cup 2 1
    echo "Servidor: $SERVER_NAME"
    printf "%*s" $(tput cols) | tr " " "="

    tput sgr0
}

#==================================================================#
# This function receives the file name and remove it from
# sites-enabled and sites-available folders.
#==================================================================#
menuRemoveHost()
{
    clear
    requireRoot

    header "REMOVER HOST"

    local iconEnabled="$GREEN✔$DEFAULT_COLOR"
    local iconDisabled="$RED✖$DEFAULT_COLOR"

    echo -e " $RED✖$DEFAULT_COLOR Hosts desabilitados. $GREEN✔$DEFAULT_COLOR Hosts habilitados."
    echo ""

    if [ ! -z $SITES_DIRECTLY ]; then
        hostsAvailable=''
        hostsAvailableId=0
        for hostName in $(ls $SITES_DIRECTLY); do
            $(isIgnoredHost "$hostName")
            if [ $? -eq 0 ]; then
                hostsAvailable[$hostsAvailableId]=$hostName
                hostsAvailableId=$(($hostsAvailableId+1))
            fi
        done

        for i in ${!hostsAvailable[*]}; do
            echo -e " $iconEnabled [$i] ${hostsAvailable[$i]}"
        done
    else
        hostsAvailable=''
        hostsAvailableId=0
        for hostName in $(ls $SITES_AVAILABLE); do
            $(isIgnoredHost "$hostName")
            if [ $? -eq 0 ]; then
                hostsAvailable[$hostsAvailableId]=$hostName
                hostsAvailableId=$(($hostsAvailableId+1))
            fi
        done

        for i in ${!hostsAvailable[*]}; do
            $(fileExists "$SITES_ENABLED/${hostsAvailable[$i]}")
            if [ $? -eq 1 ]; then
                echo -e " $iconEnabled [$i] ${hostsAvailable[$i]}"
            else
                echo -e " $iconDisabled [$i] ${hostsAvailable[$i]}"
            fi
        done
    fi

    echo ""
    echo " [m] Menu principal."
    read -p " Opção: " option

    if [ "$option" == "m" ]; then
        mainMenu
    else
        if [ $option -ge 0 ] && [ $option -le 1000 ]; then
            removeHostStrategy "$option"
        else
            menuRemoveHost
        fi
    fi
}

removeHostStrategy()
{
    local id=$1

    case $SERVER_ID in
        0) removeHostApache "$id";;
        1) removeHostNginx "$id";;
    esac
}

confirmationRemove()
{
    clear
    header "CONFIRMAÇÃO DE EXCLUSÃO"

    local id=$1
    local serverName=$2

    echo " Host: ${hostsAvailable[$id]}"

    if [ ! -z $SITES_DIRECTLY ]; then
        echo " Local: $SITES_DIRECTLY/"
    else
        echo " Local: $SITES_AVAILABLE/"
    fi

    echo ""
    echo " [c] Continuar"
    echo " [r] Voltar para o menu anterior."
    echo ""

    read -p " Opção: " option

    case $option in
        "c") removeHost "$id" "$serverName";;
        "r") menuRemoveHost;;
        *) confirmationRemove "$id";;
    esac
}

removeHostApache()
{
    local id=$1
    if [ ! -z $SITES_DIRECTLY ]; then
        local serverName=$(grep ServerName $SITES_DIRECTLY/${hostsAvailable[$id]} | awk '{print $2}')
    else
        local serverName=$(grep ServerName $SITES_AVAILABLE/${hostsAvailable[$id]} | awk '{print $2}')
    fi

    # local serverPort=$(grep Listen $SITES_AVAILABLE/${hostsAvailable[$id]} | awk '{print $2}')
    # local documentRoot=$(grep DocumentRoot $SITES_AVAILABLE/${hostsAvailable[$id]} | awk '{print $2}')

    confirmationRemove "$id" "$serverName"
}

removeHostNginx()
{
    local id=$1

    if [ ! -z $SITES_DIRECTLY ]; then
        local serverName=$(grep server_name $SITES_DIRECTLY/${hostsAvailable[$id]} | awk '{print $2}')
    else
        local serverName=$(grep server_name $SITES_AVAILABLE/${hostsAvailable[$id]} | awk '{print $2}')
    fi

    # local serverPort=$(grep Listen $SITES_AVAILABLE/${hostsAvailable[$id]} | awk '{print $2}')
    # local documentRoot=$(grep DocumentRoot $SITES_AVAILABLE/${hostsAvailable[$id]} | awk '{print $2}')

    confirmationRemove "$id" "$serverName"
}

sanitizeServerName()
{
    serverName=$1

    case $SERVER_ID in
        1) echo ${serverName::-1} ;;
    esac
}


fileNameEndUpWithConf()
{
    local fileName=$1
    local content=$(echo "$fileName" | grep ".conf$")

    if [ "$content" = "" ]; then
        return 0
    fi

    return 1
}

removeHost()
{
    clear
    header "CONFIRMAÇÃO DE EXCLUSÃO"

    local id=$1
    local serverName=$2

    if [ "$serverName" != "" ]; then
        # serverName=$(sanitizeServerName $serverName)

        # If there is a server name we need to remove it from hosts file.
        messageBlue " Removendo entrada do arquivo /etc/hosts"
        sed -i "s/$IP_ADDRESS $serverName//" /etc/hosts

        # Removing blank lines from hosts file.
        sed -i '/^$/d' /etc/hosts
    fi

    if [ ! -z $SITES_DIRECTLY ]; then
        $(fileExists "$SITES_DIRECTLY/${hostsAvailable[$id]}")
        if [ $? -eq 1 ]; then
            messageBlue " Removendo arquivo..."
            rm $SITES_DIRECTLY/${hostsAvailable[$id]}
        fi
    else
        $(fileExists "$SITES_ENABLED/${hostsAvailable[$id]}")
        if [ $? -eq 1 ]; then
            messageBlue " Removendo link..."
            rm $SITES_ENABLED/${hostsAvailable[$id]}
        fi

        $(fileExists "$SITES_AVAILABLE/${hostsAvailable[$id]}")
        if [ $? -eq 1 ]; then
            messageBlue " Removendo arquivo..."
            rm $SITES_AVAILABLE/${hostsAvailable[$id]}
        fi
    fi

    restartServer

    echo ""
    echo " Precione qualquer tecla para retornar ao menu principal."
    echo ""

    read -p " Tecla: " option

    mainMenu
}

#==================================================================#
# This function shows an available and enabled hosts list.
#==================================================================#
listHosts()
{
    clear
    header "TODOS OS HOSTS"

    local iconEnabled="$GREEN✔$DEFAULT_COLOR"
    local iconDisabled="$RED✖$DEFAULT_COLOR"

    echo -e " $RED✖$DEFAULT_COLOR Hosts desabilitados. $GREEN✔$DEFAULT_COLOR Hosts habilitados."
    echo ""

    if [ ! -z $SITES_DIRECTLY ]; then
        hostsAvailable=''
        hostsAvailableId=0
        for hostName in $(ls $SITES_DIRECTLY); do
            $(isIgnoredHost "$hostName")
            if [ $? -eq 0 ]; then
                hostsAvailable[$hostsAvailableId]=$hostName
                hostsAvailableId=$(($hostsAvailableId+1))
            fi
        done

        for i in ${!hostsAvailable[*]}; do
            echo -e " $iconEnabled ${hostsAvailable[$i]}"
        done
    else
        hostsAvailable=''
        hostsAvailableId=0
        for hostName in $(ls $SITES_AVAILABLE); do
            $(isIgnoredHost "$hostName")
            if [ $? -eq 0 ]; then
                hostsAvailable[$hostsAvailableId]=$hostName
                hostsAvailableId=$(($hostsAvailableId+1))
            fi
        done

        for i in ${!hostsAvailable[*]}; do
            $(fileExists "$SITES_ENABLED/${hostsAvailable[$i]}")
            if [ $? -eq 1 ]; then
                echo -e " $iconEnabled ${hostsAvailable[$i]}"
            else
                echo -e " $iconDisabled ${hostsAvailable[$i]}"
            fi
        done
    fi

    echo ""
    echo " [a] Adiciona um host."
    echo " [m] Menu principal."
    echo ""

    read -p " Opção: " option

    case $option in
        "m") mainMenu;;
        "a") addHost;;
        *) listHosts;;
    esac
}

isIgnoredHost()
{
    local host=$1

    for ignoredHost in ${IGNORE_HOSTS[*]}; do
        if [ "$host" == "$ignoredHost" ]; then
            return 1
        fi
    done

    return 0
}

#==================================================================#
# This function shows the script version.
#==================================================================#
showVersion()
{
    echo -e VirtualHostAutomat v.$VERSION"\n"
}

quitProgram()
{
    exit 1
}

#==================================================================#
# This function shows the script help.
#==================================================================#
helpScript()
{
    echo "Modo de usar: vhost [opções]"
    echo ""
    echo "Opções:"
    echo -e "  -a, --add\t\t\t                 Adiciona/Cria um host de forma interativa."
    echo -e "  -d, -r, --delete, --remove <nome do host>\t Deleta um host."
    echo -e "  -l, --list\t\t\t                 Exibe uma lista dos hosts criados."
    echo -e "  -h, --help\t\t\t                 Exibe este help ;)"
    echo -e "  -v, --version\t\t\t              Exibe a versão do script."
    echo ""
}

#==================================================================#
# This function manages this script call.
#==================================================================#
if [ -z $1 ]; then
    requireRoot
    menuSelectServer
else
    case $1 in
        "-a"|"--add") addHost;;
        "-d"|"-r"|"--delete"|"--remove") menuRemoveHost "$2";;
        "-l"|"--list") listHosts;;
        "-h"|"--help") helpScript;;
        "-v"|"--version") showVersion;;
    esac
fi
