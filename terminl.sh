#!/bin/bash

# ==============================
# Terminal Welcome Script
# Left: Info panel | Right: ASCII art
# ==============================

RESET="\033[0m"; BOLD="\033[1m"; DIM="\033[2m"; ITALIC="\033[3m"
G="\033[92m\033[1m"   # green label
C="\033[96m\033[1m"   # cyan heading
W="\033[97m\033[1m"   # white
R="\033[0m"           # reset
CYAN="\033[36m"
MAGENTA="\033[35m"

draw_bar() {
    local used="$1" total="$2" width="${3:-16}"
    local cf="${4:-\033[96m}" ce="${5:-\033[2m}"
    local pct=0
    [ "$total" -gt 0 ] 2>/dev/null && pct=$(( used * 100 / total ))
    local filled=$(( pct * width / 100 )); local empty=$(( width - filled ))
    local bar="${cf}"; local i=0
    while [ $i -lt $filled ]; do bar+="█"; i=$(( i+1 )); done
    bar+="${ce}"; i=0
    while [ $i -lt $empty ];  do bar+="░"; i=$(( i+1 )); done
    bar+="${R} ${BOLD}${pct}%${R}"
    printf '%b' "$bar"
}

# ── Gather info ────────────────────────────────────────────────────────────────
OS=$(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"'); [ -z "$OS" ] && OS="Unknown"
KERNEL=$(uname -r); ARCH=$(uname -m)
UPTIME_RAW=$(uptime -p 2>/dev/null | sed 's/up //'); [ -z "$UPTIME_RAW" ] && UPTIME_RAW="unknown"
SHELL_NAME=$(basename "$SHELL"); USER_NAME=$(whoami); HOSTNAME_S=$(hostname)
CPU=$(lscpu 2>/dev/null | awk -F: '/Model name/{gsub(/^[ \t]+/,"",$2);print $2;exit}'); [ -z "$CPU" ] && CPU="Unknown"
CPU=$(echo "$CPU" | sed 's/(R)//g;s/(TM)//g;s/CPU //g;s/ @.*//;s/  */ /g' | xargs)
CPU_CORES=$(nproc 2>/dev/null || echo "?")
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
MEM_USED_MB=$(free -m 2>/dev/null | awk '/Mem:/{print $3}'); [ -z "$MEM_USED_MB" ] && MEM_USED_MB=0
MEM_TOTAL_MB=$(free -m 2>/dev/null | awk '/Mem:/{print $2}'); [ -z "$MEM_TOTAL_MB" ] && MEM_TOTAL_MB=1
MEM_USED_H=$(free -h 2>/dev/null | awk '/Mem:/{print $3}'); MEM_TOTAL_H=$(free -h 2>/dev/null | awk '/Mem:/{print $2}')
DISK_USED_H=$(df -h / 2>/dev/null | awk 'NR==2{print $3}'); DISK_TOTAL_H=$(df -h / 2>/dev/null | awk 'NR==2{print $2}')
DISK_USED_P=$(df / 2>/dev/null | awk 'NR==2{print $3}'); [ -z "$DISK_USED_P" ] && DISK_USED_P=0
DISK_TOTAL_P=$(df / 2>/dev/null | awk 'NR==2{print $2}'); [ -z "$DISK_TOTAL_P" ] && DISK_TOTAL_P=1
IP_LOCAL=$(hostname -I 2>/dev/null | awk '{print $1}'); [ -z "$IP_LOCAL" ] && IP_LOCAL="n/a"
IP_PUBLIC=$(curl -s --max-time 2 https://api.ipify.org 2>/dev/null); [ -z "$IP_PUBLIC" ] && IP_PUBLIC="unavailable"
PKGS="?"
command -v dpkg  &>/dev/null && PKGS=$(dpkg --get-selections 2>/dev/null | grep -c 'install$')
command -v rpm   &>/dev/null && [ "$PKGS" = "?" ] && PKGS=$(rpm -qa 2>/dev/null | wc -l)
command -v pacman &>/dev/null && [ "$PKGS" = "?" ] && PKGS=$(pacman -Qq 2>/dev/null | wc -l)
TERM_NAME="${TERM:-unknown}"
LAST_LOGIN=$(last -1 -F "$USER_NAME" 2>/dev/null | awk 'NR==1&&/pts|tty/{print $4,$5,$6,$7,$8}')
[ -z "$LAST_LOGIN" ] && LAST_LOGIN="first session"
NOW_DATE=$(date '+%A, %B %-d, %Y'); NOW_TIME=$(date '+%H:%M %Z')
HOUR=$(date '+%H')
if   [ "$HOUR" -ge 5  ] && [ "$HOUR" -lt 12 ]; then GREETING="Good morning"
elif [ "$HOUR" -ge 12 ] && [ "$HOUR" -lt 17 ]; then GREETING="Good afternoon"
elif [ "$HOUR" -ge 17 ] && [ "$HOUR" -lt 21 ]; then GREETING="Good evening"
else GREETING="Burning the midnight oil"; fi

mem_bar=$(draw_bar "$MEM_USED_MB" "$MEM_TOTAL_MB" 16 "\033[96m" "\033[2m")
disk_bar=$(draw_bar "$DISK_USED_P" "$DISK_TOTAL_P" 16 "\033[95m" "\033[2m")

# ── Build left panel lines (ANSI included) ─────────────────────────────────────
mapfile -t LEFT < <(printf '%b\n' \
    "" \
    "${C}  ╔══════════════════════════════════╗${R}" \
    "${C}  ║  ${W}${GREETING}, ${USER_NAME}${C}  ║${R}" \
    "${C}  ╚══════════════════════════════════╝${R}" \
    "" \
    "  ${DIM}${NOW_DATE}  ·  ${NOW_TIME}${R}" \
    "" \
    "  ${C}── SYSTEM ──────────────────────────${R}" \
    "" \
    "  ${G}OS          ${R}  ${OS}" \
    "  ${G}Kernel      ${R}  ${KERNEL} ${DIM}(${ARCH})${R}" \
    "  ${G}Hostname    ${R}  ${HOSTNAME_S}" \
    "  ${G}Shell       ${R}  ${SHELL_NAME}" \
    "  ${G}Terminal    ${R}  ${TERM_NAME}" \
    "  ${G}Packages    ${R}  ${PKGS} installed" \
    "  ${G}Uptime      ${R}  ${UPTIME_RAW}" \
    "  ${G}Load        ${R}  ${CPU_LOAD} ${DIM}(${CPU_CORES} cores)${R}" \
    "  ${G}Last Login  ${R}  ${LAST_LOGIN}" \
    "" \
    "  ${C}── HARDWARE ────────────────────────${R}" \
    "" \
    "  ${G}CPU         ${R}  ${CPU}" \
    "" \
    "  ${G}Memory      ${R}  ${mem_bar}  ${DIM}${MEM_USED_H}/${MEM_TOTAL_H}${R}" \
    "  ${G}Disk        ${R}  ${disk_bar}  ${DIM}${DISK_USED_H}/${DISK_TOTAL_H}${R}" \
    "" \
    "  ${C}── NETWORK ─────────────────────────${R}" \
    "" \
    "  ${G}Local IP    ${R}  ${IP_LOCAL}" \
    "  ${G}Public IP   ${R}  ${IP_PUBLIC}" \
    "" \
    "  ${DIM}${ITALIC}Have a great session, hacker.${R}" \
    "" \
)

# ── ASCII art lines ────────────────────────────────────────────────────────────
mapfile -t ART << 'ARTEOF'
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣀⣀⠀⢀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⡇⠈⣩⠛⠻⠥⣄⣉⢩⠙⠛⣛⣷⣤⣀⢀⠀⣀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠴⣿⠀⢰⠇⠀⡴⠄⠉⠁⡜⠐⠊⣩⡥⢾⣿⡻⠻⢯⡳⣤⡀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡴⠞⢋⣠⠴⢾⠀⡏⠀⣼⠀⢠⠀⢠⡇⠀⠛⠁⠀⠀⠙⣿⢦⡀⠙⢮⠻⣦⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠞⢉⡴⠛⠉⢁⣀⣸⢠⠁⢠⠇⢀⡏⠀⢸⠁⡤⠒⠛⠉⠳⣄⡈⢳⣝⢦⠈⠳⡘⢷⡀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⠞⠁⢠⠞⣠⠴⠊⣩⡴⢿⡾⠀⢸⠀⢸⠃⠀⡎⠀⣿⠶⠭⠭⢥⣬⣿⣆⠹⣆⠳⣄⠈⠈⢿⡄
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣴⠟⠁⠀⣠⡵⠚⣀⡴⠛⠁⠀⢸⠃⠀⡏⠀⣾⠀⠀⡇⢸⡇⠀⠀⠈⠛⠷⢤⣝⣧⡘⣇⠈⣷⠀⠈⢻
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠋⠀⡟⠀⠀⡴⠋⢠⡴⠋⠀⠀⠀⠀⣾⠀⢸⡇⠀⡇⠀⠀⠇⢸⠀⠀⠀⠀⠀⠀⠀⠘⢯⣷⡘⣆⢸⡆⠀⠈
⠀⠀⠀⠀⠀⠀⠀⠀⢀⡟⠀⢸⠁⠀⡼⠁⣰⠏⠀⠀⠀⠀⠀⣀⣾⡄⢸⡇⠀⡇⠀⢸⠀⢸⠀⣶⣄⣀⡀⠀⠀⠀⠀⠉⢿⡜⣌⡇⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⡞⠀⡼⠁⣰⠋⠀⠀⠀⣤⣴⡿⠟⠉⣿⢸⡇⠀⡇⠀⢸⡇⢸⠀⠈⠙⠻⠿⠷⣦⡀⠀⠀⠈⢻⠈⡧⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣴⣿⡇⠐⡇⣰⠃⣰⠇⠀⠀⠀⠘⠋⠁⠀⠀⠀⠙⣾⡇⠀⢿⠀⣼⡇⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣧⣷⠀⠀
⠀⠀⠀⠀⠀⣠⡾⣹⢿⡇⠀⢁⡟⢠⡏⠀⠀⠀⠀⣀⣀⠀⠀⢀⣀⠀⢹⣇⠀⢸⡄⣿⣇⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⠀⠀
⠀⠀⠀⢀⡾⣻⢀⡏⣼⡇⠀⡞⠃⣸⠁⠀⣠⠴⡋⠉⢀⣀⣤⠀⡉⠓⠦⢿⡄⢸⡇⢻⢻⣸⠀⠴⢚⠛⠀⠀⠀⢀⡓⠶⣤⣀⠀⣿⠀⠀
⠀⠀⣴⣿⢸⡇⣼⡼⢃⡇⠀⡇⠀⣿⣠⠞⢥⣀⣽⣿⣿⡿⠿⣿⣷⣦⡀⠀⡟⠈⣿⢸⠸⣿⡄⠀⠀⣀⣤⣿⣶⣿⣧⣤⣄⣭⡓⣿⠀⠀
⠀⠸⣷⣿⢀⡰⠋⠀⣸⡅⠀⡇⠀⡿⠡⣤⣴⡿⠛⢁⡠⠤⢤⣀⣈⠛⢷⡄⢿⡀⠸⣿⡄⠻⠃⢠⠾⠛⠉⠀⣀⡈⠙⠻⢿⣿⣿⣿⡇⠀
⠀⠀⢻⡇⠉⠀⢀⡼⠋⣧⠀⣧⠀⡇⢰⣷⠟⠁⡴⠋⠀⠀⠀⠀⠉⢷⡀⠙⠋⢷⡀⢻⣇⠀⠀⠀⠀⢀⡴⠛⠉⠙⠛⠒⢦⣌⢻⣮⣧⢠
⠀⠀⠀⠻⣦⡴⠛⠁⠀⢻⡄⢹⡀⣷⣿⡏⠀⡸⠁⠀⠀⠀⠀⠀⠀⠀⢻⡄⠀⠈⢷⡄⢻⡄⠀⠀⢰⠋⠀⠀⠀⠀⠀⠀⠀⠙⣷⢻⡇⢸
⠀⠀⠀⠀⢙⣷⣄⣀⣀⣈⢷⡸⣧⣿⠘⠇⠀⡇⠀⠀⣿⣿⣿⡷⠆⠀⢸⡇⠀⠀⠀⠙⠚⠇⠀⠀⠿⠀⢠⣶⣶⣤⣤⡦⠀⠀⢸⡇⡇⢸
⠀⠀⠀⣴⠋⠸⡇⠀⢠⠏⢸⣧⢿⣿⠀⠀⠀⢰⣄⠀⠉⠉⠀⠀⠀⣠⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀⠈⠉⠉⠉⠀⠀⢀⡾⢰⣧⣿
⠀⢠⡞⣿⠀⠀⢿⡰⠃⠀⡸⠻⣎⣇⠀⠀⠀⠀⠉⠛⠲⠶⠚⠋⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢦⣀⠀⠀⠀⣀⡴⠟⢁⡾⢿⠁
⢠⣯⡆⠘⣇⠀⢸⡇⠀⣠⠃⢀⡿⢻⡀⠀⠀⠀⢀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⢉⠛⠉⠁⢀⡴⢿⠀⠸⡇
⣾⠘⣇⠀⢹⡆⠁⢻⡐⠃⢀⡞⢀⡼⡇⠀⣠⠖⣩⠶⣋⠔⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⢖⡣⠾⣯⡀⠀⢀⣾⡇⠸⡄⠀
⢿⣄⠘⣦⠀⢹⡀⠘⣇⢀⠞⠀⡾⠀⡇⠈⠁⠀⠀⠘⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠋⠀⠀⠁⠀⠀⡾⠈⡇⠀⢷⠀
⠀⢻⣆⠈⢧⡀⢳⡀⢹⡏⠀⣰⠁⢀⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⣄⡀⠀⠀⠀⠀⠀⣠⡄⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⢹⡀⠸⣆
⠀⠀⠹⣦⡀⠁⠀⠁⠀⠉⠸⠃⣠⠏⠈⢷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⠶⣤⡤⠴⠞⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣇⠀⠈⣧⠀⠸
⠀⠀⠀⠈⠳⣟⢦⣀⣠⠤⠞⢋⣡⠔⠀⠈⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡄⠀⠘⣇⠀
⠀⠀⠀⣠⣤⣼⠚⢻⡇⢠⠶⠋⠀⠀⣠⡄⠻⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡟⣿⣆⠀⠈⠁⠀
⠀⠀⣸⢯⠀⠈⠳⡄⠹⣦⣀⡴⠖⠋⠁⠀⠀⢘⡇⠙⢷⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡴⠾⢉⡾⢠⠇⠈⣳⣦⢤⡴
⠀⣸⣇⠈⢧⡀⠀⠈⢦⡈⠳⣄⡠⢴⠋⠐⠀⣼⠇⠀⠀⠈⠛⢻⣶⣤⣄⣀⠀⠀⠀⠀⢀⣀⣤⡤⠶⢿⣯⠞⣠⠞⣠⣯⡴⢿⠁⢻⡀⠀
⠀⣿⡙⣆⠈⢳⣄⠀⠀⠙⢦⡈⠀⠉⣉⣥⠞⠁⠀⠀⠀⠀⢀⣼⡇⠀⠉⠉⠙⠒⠖⠚⠋⠉⠁⠀⠀⠸⣿⣿⣧⣮⡿⢹⠀⢸⠀⠈⢷⠋
⠀⠘⢷⣌⠳⣄⠙⠦⣄⠀⠀⠀⠘⠻⢧⣤⡀⠀⠀⢀⣠⡴⢋⣽⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⢟⣿⡄⠘⡆⠈⣇⠀⠸⣆
⠀⢀⣴⠟⢷⣮⣤⣠⣬⠀⠀⠀⠀⢀⠴⠊⠻⣶⡜⠋⢹⣷⣚⣽⡷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠖⠋⢀⣾⠙⣇⠀⢧⠀⠹⡄⠀⢹
⠀⡾⠁⢷⠈⢳⡄⠈⠙⣦⠀⣠⠞⠁⢀⠀⠀⠈⠻⡆⢸⡏⠉⢿⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡴⠋⠁⣠⠴⢫⡇⠀⠸⡄⠘⣇⠀⠻⡄⠀
⠀⢷⡀⠈⢷⡀⠙⣆⡀⠈⢿⣅⣀⠔⢃⡀⠀⠀⢠⡇⠈⣧⠀⢸⡦⠀⠀⠀⠀⠀⢄⣴⠟⣁⣀⡴⢞⠋⡣⢨⣧⠀⠀⠹⣄⡹⠆⠀⣙⡀
ARTEOF

# ── Render with Python for correct visual-width padding ────────────────────────
clear
export COLUMNS=$(tput cols 2>/dev/null || echo 120)

python3 - "${LEFT[@]}" << PYEOF
import sys, os, re, unicodedata

# The shell passes LEFT lines as argv and ART is read via heredoc substitution.
# Instead we read them from environment / passed args differently.
# Actually: LEFT lines passed as args, ART embedded here.

ART = r"""⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣀⣀⠀⢀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⡇⠈⣩⠛⠻⠥⣄⣉⢩⠙⠛⣛⣷⣤⣀⢀⠀⣀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠴⣿⠀⢰⠇⠀⡴⠄⠉⠁⡜⠐⠊⣩⡥⢾⣿⡻⠻⢯⡳⣤⡀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡴⠞⢋⣠⠴⢾⠀⡏⠀⣼⠀⢠⠀⢠⡇⠀⠛⠁⠀⠀⠙⣿⢦⡀⠙⢮⠻⣦⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠞⢉⡴⠛⠉⢁⣀⣸⢠⠁⢠⠇⢀⡏⠀⢸⠁⡤⠒⠛⠉⠳⣄⡈⢳⣝⢦⠈⠳⡘⢷⡀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⠞⠁⢠⠞⣠⠴⠊⣩⡴⢿⡾⠀⢸⠀⢸⠃⠀⡎⠀⣿⠶⠭⠭⢥⣬⣿⣆⠹⣆⠳⣄⠈⠈⢿⡄
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣴⠟⠁⠀⣠⡵⠚⣀⡴⠛⠁⠀⢸⠃⠀⡏⠀⣾⠀⠀⡇⢸⡇⠀⠀⠈⠛⠷⢤⣝⣧⡘⣇⠈⣷⠀⠈⢻
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠋⠀⡟⠀⠀⡴⠋⢠⡴⠋⠀⠀⠀⠀⣾⠀⢸⡇⠀⡇⠀⠀⠇⢸⠀⠀⠀⠀⠀⠀⠀⠘⢯⣷⡘⣆⢸⡆⠀⠈
⠀⠀⠀⠀⠀⠀⠀⠀⢀⡟⠀⢸⠁⠀⡼⠁⣰⠏⠀⠀⠀⠀⠀⣀⣾⡄⢸⡇⠀⡇⠀⢸⠀⢸⠀⣶⣄⣀⡀⠀⠀⠀⠀⠉⢿⡜⣌⡇⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⡞⠀⡼⠁⣰⠋⠀⠀⠀⣤⣴⡿⠟⠉⣿⢸⡇⠀⡇⠀⢸⡇⢸⠀⠈⠙⠻⠿⠷⣦⡀⠀⠀⠈⢻⠈⡧⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣴⣿⡇⠐⡇⣰⠃⣰⠇⠀⠀⠀⠘⠋⠁⠀⠀⠀⠙⣾⡇⠀⢿⠀⣼⡇⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣧⣷⠀⠀
⠀⠀⠀⠀⠀⣠⡾⣹⢿⡇⠀⢁⡟⢠⡏⠀⠀⠀⠀⣀⣀⠀⠀⢀⣀⠀⢹⣇⠀⢸⡄⣿⣇⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⠀⠀
⠀⠀⠀⢀⡾⣻⢀⡏⣼⡇⠀⡞⠃⣸⠁⠀⣠⠴⡋⠉⢀⣀⣤⠀⡉⠓⠦⢿⡄⢸⡇⢻⢻⣸⠀⠴⢚⠛⠀⠀⠀⢀⡓⠶⣤⣀⠀⣿⠀⠀
⠀⠀⣴⣿⢸⡇⣼⡼⢃⡇⠀⡇⠀⣿⣠⠞⢥⣀⣽⣿⣿⡿⠿⣿⣷⣦⡀⠀⡟⠈⣿⢸⠸⣿⡄⠀⠀⣀⣤⣿⣶⣿⣧⣤⣄⣭⡓⣿⠀⠀
⠀⠸⣷⣿⢀⡰⠋⠀⣸⡅⠀⡇⠀⡿⠡⣤⣴⡿⠛⢁⡠⠤⢤⣀⣈⠛⢷⡄⢿⡀⠸⣿⡄⠻⠃⢠⠾⠛⠉⠀⣀⡈⠙⠻⢿⣿⣿⣿⡇⠀
⠀⠀⢻⡇⠉⠀⢀⡼⠋⣧⠀⣧⠀⡇⢰⣷⠟⠁⡴⠋⠀⠀⠀⠀⠉⢷⡀⠙⠋⢷⡀⢻⣇⠀⠀⠀⠀⢀⡴⠛⠉⠙⠛⠒⢦⣌⢻⣮⣧⢠
⠀⠀⠀⠻⣦⡴⠛⠁⠀⢻⡄⢹⡀⣷⣿⡏⠀⡸⠁⠀⠀⠀⠀⠀⠀⠀⢻⡄⠀⠈⢷⡄⢻⡄⠀⠀⢰⠋⠀⠀⠀⠀⠀⠀⠀⠙⣷⢻⡇⢸
⠀⠀⠀⠀⢙⣷⣄⣀⣀⣈⢷⡸⣧⣿⠘⠇⠀⡇⠀⠀⣿⣿⣿⡷⠆⠀⢸⡇⠀⠀⠀⠙⠚⠇⠀⠀⠿⠀⢠⣶⣶⣤⣤⡦⠀⠀⢸⡇⡇⢸
⠀⠀⠀⣴⠋⠸⡇⠀⢠⠏⢸⣧⢿⣿⠀⠀⠀⢰⣄⠀⠉⠉⠀⠀⠀⣠⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀⠈⠉⠉⠉⠀⠀⢀⡾⢰⣧⣿
⠀⢠⡞⣿⠀⠀⢿⡰⠃⠀⡸⠻⣎⣇⠀⠀⠀⠀⠉⠛⠲⠶⠚⠋⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢦⣀⠀⠀⠀⣀⡴⠟⢁⡾⢿⠁
⢠⣯⡆⠘⣇⠀⢸⡇⠀⣠⠃⢀⡿⢻⡀⠀⠀⠀⢀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⢉⠛⠉⠁⢀⡴⢿⠀⠸⡇
⣾⠘⣇⠀⢹⡆⠁⢻⡐⠃⢀⡞⢀⡼⡇⠀⣠⠖⣩⠶⣋⠔⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⢖⡣⠾⣯⡀⠀⢀⣾⡇⠸⡄⠀
⢿⣄⠘⣦⠀⢹⡀⠘⣇⢀⠞⠀⡾⠀⡇⠈⠁⠀⠀⠘⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠋⠀⠀⠁⠀⠀⡾⠈⡇⠀⢷⠀
⠀⢻⣆⠈⢧⡀⢳⡀⢹⡏⠀⣰⠁⢀⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⣄⡀⠀⠀⠀⠀⠀⣠⡄⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⢹⡀⠸⣆
⠀⠀⠹⣦⡀⠁⠀⠁⠀⠉⠸⠃⣠⠏⠈⢷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⠶⣤⡤⠴⠞⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣇⠀⠈⣧⠀⠸
⠀⠀⠀⠈⠳⣟⢦⣀⣠⠤⠞⢋⣡⠔⠀⠈⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡄⠀⠘⣇⠀
⠀⠀⠀⣠⣤⣼⠚⢻⡇⢠⠶⠋⠀⠀⣠⡄⠻⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡟⣿⣆⠀⠈⠁⠀
⠀⠀⣸⢯⠀⠈⠳⡄⠹⣦⣀⡴⠖⠋⠁⠀⠀⢘⡇⠙⢷⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡴⠾⢉⡾⢠⠇⠈⣳⣦⢤⡴
⠀⣸⣇⠈⢧⡀⠀⠈⢦⡈⠳⣄⡠⢴⠋⠐⠀⣼⠇⠀⠀⠈⠛⢻⣶⣤⣄⣀⠀⠀⠀⠀⢀⣀⣤⡤⠶⢿⣯⠞⣠⠞⣠⣯⡴⢿⠁⢻⡀⠀
⠀⣿⡙⣆⠈⢳⣄⠀⠀⠙⢦⡈⠀⠉⣉⣥⠞⠁⠀⠀⠀⠀⢀⣼⡇⠀⠉⠉⠙⠒⠖⠚⠋⠉⠁⠀⠀⠸⣿⣿⣧⣮⡿⢹⠀⢸⠀⠈⢷⠋
⠀⠘⢷⣌⠳⣄⠙⠦⣄⠀⠀⠀⠘⠻⢧⣤⡀⠀⠀⢀⣠⡴⢋⣽⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⢟⣿⡄⠘⡆⠈⣇⠀⠸⣆
⠀⢀⣴⠟⢷⣮⣤⣠⣬⠀⠀⠀⠀⢀⠴⠊⠻⣶⡜⠋⢹⣷⣚⣽⡷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠖⠋⢀⣾⠙⣇⠀⢧⠀⠹⡄⠀⢹
⠀⡾⠁⢷⠈⢳⡄⠈⠙⣦⠀⣠⠞⠁⢀⠀⠀⠈⠻⡆⢸⡏⠉⢿⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡴⠋⠁⣠⠴⢫⡇⠀⠸⡄⠘⣇⠀⠻⡄⠀
⠀⢷⡀⠈⢷⡀⠙⣆⡀⠈⢿⣅⣀⠔⢃⡀⠀⠀⢠⡇⠈⣧⠀⢸⡦⠀⠀⠀⠀⠀⢄⣴⠟⣁⣀⡴⢞⠋⡣⢨⣧⠀⠀⠹⣄⡹⠆⠀⣙⡀""".strip().split('\n')

def vwidth(s):
    s = re.sub(r'\x1b\[[0-9;]*[mK]', '', s)
    w = 0
    for c in s:
        ea = unicodedata.east_asian_width(c)
        w += 2 if ea in ('W', 'F') else 1
    return w

def pad_to(s, width):
    v = vwidth(s)
    return s + ' ' * max(0, width - v)

cols = int(os.environ.get("COLUMNS", 120))

left_w = cols // 2

# LEFT lines come from shell args
left_lines = sys.argv[1:]

total = max(len(left_lines), len(ART))

CYAN = '\033[36m'
RESET = '\033[0m'

for i in range(total):
    ll = left_lines[i] if i < len(left_lines) else ''
    ar = (CYAN + ART[i] + RESET) if i < len(ART) else ''
    print(pad_to(ll, left_w) + ar)
PYEOF
