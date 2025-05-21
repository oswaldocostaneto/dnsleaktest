#!/usr/bin/env bash
#==========================================================================================
# SCRIPT PARA TESTE DE VAZAMENTO DE DNS E CONSULTA DE IP PÚBLICO
#
# 🔧 Este script verifica se há vazamento de DNS (DNS Leak) e exibe informações do seu IP.
# 🔍 Ele faz consultas a servidores externos e compara quais servidores DNS estão sendo usados.
# 🌐 Útil para validar se sua VPN está funcionando corretamente e se não há vazamento de DNS.
#
# COMO UTILIZAR:
# ➤ Dê permissão de execução: chmod +x dnsleaktest.sh
# ➤ Execute: ./dnsleaktest.sh
# ➤ Para testar por uma interface específica (ex.: eth0 ou 192.168.1.100):
#    ./dnsleaktest.sh -i eth0
#
#==========================================================================================

# Cores para saída no terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # Reset de cor

# APIs utilizadas
api_domain='bash.ws'
ipinfo_domain='ipinfo.io'
error_code=1

# Recebe parâmetro opcional da interface
getopts "i:" opt
interface=$OPTARG

# Função para exibir texto em negrito
function echo_bold {
    echo -e "${BOLD}${1}${NC}"
}

# Verifica se interface foi informada
if [ -z "$interface" ]; then
    curl_interface=""
    ping_interface=""
else
    curl_interface="--interface ${interface}"
    ping_interface="-I ${interface}"
    echo_bold "${BLUE}Interface utilizada: ${interface}${NC}"
    echo ""
fi

# Controle de erros
function increment_error_code {
    error_code=$((error_code + 1))
}

# Exibe mensagens de erro
function echo_error {
    (>&2 echo -e "${RED}${1}${NC}")
}

# Verifica se comandos necessários estão instalados
function require_command {
    command -v $1 > /dev/null
    if [ $? -ne 0 ]; then
        echo_error "⚠️  Por favor, instale o comando \"$1\" antes de executar este script."
        exit $error_code
    fi
    increment_error_code
}

# Verifica conexão com a internet
function check_internet_connection {
    curl --silent --head ${curl_interface} --request GET "https://${api_domain}" | grep "200 OK" > /dev/null
    if [ $? -ne 0 ]; then
        echo_error "❌ Sem conexão com a internet."
        exit $error_code
    fi
    increment_error_code
}

# Checa dependências
require_command curl
require_command ping
check_internet_connection

if command -v jq &> /dev/null; then
    jq_exists=1
else
    jq_exists=0
fi

#===============================
# INFORMAÇÕES DO IP PÚBLICO
#===============================
echo -e "${BLUE}================ INFORMAÇÕES DO IP PÚBLICO ================${NC}"
echo ""

ipinfo=$(curl ${curl_interface} --silent https://${ipinfo_domain}/json)

if (( $jq_exists )); then
    ip=$(echo "$ipinfo" | jq -r '.ip')
    city=$(echo "$ipinfo" | jq -r '.city')
    region=$(echo "$ipinfo" | jq -r '.region')
    country=$(echo "$ipinfo" | jq -r '.country')
    org=$(echo "$ipinfo" | jq -r '.org')

    echo "Endereço IP:    $ip"
    echo "Localização:    $city, $region, $country"
    echo "Organização:    $org"
else
    ip=$(echo "$ipinfo" | grep '"ip"' | cut -d'"' -f4)
    city=$(echo "$ipinfo" | grep '"city"' | cut -d'"' -f4)
    region=$(echo "$ipinfo" | grep '"region"' | cut -d'"' -f4)
    country=$(echo "$ipinfo" | grep '"country"' | cut -d'"' -f4)
    org=$(echo "$ipinfo" | grep '"org"' | cut -d'"' -f4)

    echo "Endereço IP:    $ip"
    echo "Localização:    $city, $region, $country"
    echo "Organização:    $org"
fi

echo ""
echo -e "${BLUE}============================================================${NC}"
echo ""

#===============================
# TESTE DE DNS LEAK
#===============================

id=$(curl ${curl_interface} --silent "https://${api_domain}/id")

for i in $(seq 1 10); do
    ping -c 1 ${ping_interface} "${i}.${id}.${api_domain}" > /dev/null 2>&1
done

function print_servers {
    if (( $jq_exists )); then
        echo ${result_json} | \
            jq  --monochrome-output \
            --raw-output \
            ".[] | select(.type == \"${1}\") | \"\(.ip)\(if .country_name != \"\" and  .country_name != false then \" [\(.country_name)\(if .asn != \"\" and .asn != false then \" \(.asn)\" else \"\" end)]\" else \"\" end)\""
    else
        while IFS= read -r line; do
            if [[ "$line" != *${1} ]]; then
                continue
            fi
            ip=$(echo $line | cut -d'|' -f 1)
            code=$(echo $line | cut -d'|' -f 2)
            country=$(echo $line | cut -d'|' -f 3)
            asn=$(echo $line | cut -d'|' -f 4)

            if [ -z "${ip// }" ]; then
                 continue
            fi

            if [ -z "${country// }" ]; then
                 echo "$ip"
            else
                 if [ -z "${asn// }" ]; then
                     echo "$ip [$country]"
                 else
                     echo "$ip [$country, $asn]"
                 fi
            fi
        done <<< "$result_txt"
    fi
}

if (( $jq_exists )); then
    result_json=$(curl ${curl_interface} --silent "https://${api_domain}/dnsleak/test/${id}?json")
else
    result_txt=$(curl ${curl_interface} --silent "https://${api_domain}/dnsleak/test/${id}?txt")
fi

dns_count=$(print_servers "dns" | wc -l)

echo_bold "${BLUE}================ RESULTADO DO TESTE DE DNS =================${NC}"

echo_bold "IP detectado durante o teste de DNS:"
print_servers "ip"

echo ""
if [ ${dns_count} -eq "0" ];then
    echo_bold "⚠️ Nenhum servidor DNS encontrado."
else
    if [ ${dns_count} -eq "1" ];then
        echo_bold "✅ Você está utilizando ${dns_count} servidor DNS:"
    else
        echo_bold "✅ Você está utilizando ${dns_count} servidores DNS:"
    fi
    print_servers "dns"
fi

echo ""
echo_bold "✅ Script concluído com êxito."

echo ""
echo -e "${BLUE}======================= FIM DO TESTE =======================${NC}"

exit 0
