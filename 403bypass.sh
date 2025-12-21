#!/bin/bash

red='\e[31m'
green='\e[32m'
blue='\e[34m'
BOLD_WHITE='\033[1;97m'
cyan='\e[96m'
yellow='\e[33m'
end='\e[0m'
BOLD='\033[1m'
termwidth="$(tput cols)"
default_method="GET"
method=""
max_jobs=5  # Adjust this to change speed (parallel requests)


banner() {

        echo -e "$cyan$BOLD
  ______                       ___        ____  
 |  ____|                     / _ \      |___ \ 
 | |__ ___  _   _ _ __ ______| | | |______ __) |
 |  __/ _ \| | | | '__|______| | | |______|__ < 
 | | | (_) | |_| | |         | |_| |      ___) |
 |_|  \___/ \__,_|_|          \___/      |____/ 
                                     Bypass :D $end"
    
    echo -e "             ${cyan}${BOLD}Coded By (mugh33ra)$NC"
    echo -e "            ${BOLD_WHITE}https://x.com/mugh33ra"
    echo -e "          ${BOLD_WHITE}https://github.com/mugh33ra"
    echo ""
}

help_usage() {
    echo "Usage: $0 -u <url> [options]"
    echo "Options:"
    echo "  -u, --url        Specify <Target_Url>"
    echo "  -m, --method     Specify Method <POST, PUT, PATCH> (Default, GET)"
    echo "  -h, --help       Display help and exit"
}

if [[ $# -eq 0 ]]; then
        banner
        echo "[!] Error: use -h/--help for help menu"
        exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url)
            [[ -n $2 && $2 != -* ]] && {
                target=${2%/};
                pat=$(echo $2 | cut -d "/" -f4- );
                shift 2;
            } || { echo "[!] Url is missing"; exit 1; } ;;
        -m|--method)
            [[ -n $2 && $2 != -* ]] && { method=$2; shift 2; } || { echo "[!] Method missing"; exit 1; } ;;
        -h|--help)
            banner; help_usage; exit 0; shift ;;

        *) echo "[!] Unknown flag $1"; exit 1 ;;
    esac
done

method=${method:-$default_method}
[[ ! -f "payloads.txt" ]] && { echo -e "${red}[!] payloads.txt not found${end}"; exit 1; }


run_check() {
    local p="$1"
    local current_p=$(echo "$p" | sed "s|\${pat}|$pat|g")
    local path_is_is_flag=""

    # --path-as-is if payload contains normalization-sensitive characters
    if [[ "$current_p" =~ ".." || "$current_p" =~ ";" || "$current_p" =~ "//" ]]; then
        path_is_is_flag="--path-as-is"
    fi

    local res=$(curl -k -s $path_is_is_flag -o /dev/null -w "%{http_code}|%{size_download}" "${target}${current_p}" -X "$method" -H "User-Agent: Mozilla/5.0")
    local st=$(echo "$res" | cut -d'|' -f1)
    local len=$(echo "$res" | cut -d'|' -f2)

    if [[ "$st" =~ ^4 ]]; then
        echo -e "Payload [ ${yellow}${current_p}${end} ]: ${red}Status: $st, Length : $len${end}"
    else
        echo -e "Payload [ ${yellow}${current_p}${end} ]: ${green}Status: $st, Length : $len${end}"
        local line=$(printf '%.0s─' $(seq 1 $((termwidth - 2))))
        echo -e "╭${line}╮"
        echo -e " Payload [ ${yellow}${current_p}${end} ]:"
        echo -e " METHOD: '${cyan}${method}${end}'"
        echo -e " COMMAND: ${cyan}curl -k -s $path_is_is_flag -X $method '${target}${current_p}' -H 'User-Agent: Mozilla/5.0'${end}"
        echo -e "╰${line}╯"
    fi
}

encode_bypass() {

    banner
    echo -e "${blue}----------------------${end}"
    echo -e "${cyan}[+] URL Encode Bypass (Parallel)${end}"
    echo -e "${blue}----------------------${end}"

    set -f
    while IFS= read -r p || [[ -n "$p" ]]; do
        [[ -z "$p" ]] && continue

        run_check "$p" &

        
        if [[ $(jobs -r | wc -l) -ge $max_jobs ]]; then
            wait -n
        fi
    done < "payloads.txt"

    wait
    set +f
}

encode_bypass
