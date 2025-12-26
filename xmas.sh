#!/usr/bin/env bash
# xmas tree on the terminal {/}

# colors
COLOR_TREE=$(tput setaf 2)
COLOR_STAR=$(tput setaf 228)
COLOR_RST=$(tput sgr0)

# from theme
COLOR1=$'\e[38;5;87m' # cyan
COLOR2=$'\e[38;5;211m' # magenta
COLOR3=$'\e[38;5;120m' # green
COLOR4=$'\e[38;5;241m' # dim
COLOR5=$'\e[38;5;223m' # offset-white [text]

# light - "christmas light"
COLOR_LIGHT=(
	"$(tput setaf 111)"
	"$(tput setaf 208)"
	"$(tput setaf 198)"
	"$(tput setaf 155)"
)
COLOR_LIGHT_LEN=${#COLOR_LIGHT[@]}

# tree numbers represents a specific "light" color
IFS= read -r -d '' TREE <<-"EOF"
          *
         / \
        / 0 \
       / 1   \
      /       \
     /_ 2  1  _\
      /       \
     /  1  2   \
    /           \
   /   0  3  0   \
  /_        1    _\
   /    2        \
  /  1   0   0    \
 /    3         3  \
/  2        1       \
---------------------
         |||
        /|||\
EOF
TREE_HEIGHT=18
TREE_WIDTH=20

c=$(tput setaf 130)
IFS= read -r -d '' SIGN <<- EOF
$c  ┌──────────────────────────────────────┐
$c  │$COLOR5 Merry Christmas!$c                     │
$c  │$COLOR5 From STLAJAY $c                        │
$c  │$COLOR3 $ cd xmas$COLOR5 $ ./xmas.sh $c               │
$c  └─────────────┬──┬─────────────────────┘
$c                │  │
$c                │  │
$c               /└──┘\\

EOF
SIGN_HEIGHT=8

# taken from asciiart site
MOON_COLOR=$(tput setaf 224)
IFS= read -r -d '' MOON <<- "EOF"
   _.._
 .' .-'`
/  /
|  |
\  '.___.;
 '._  _.'
    ``
EOF

TIMER=-1
SNOWS=('*' .)
SNOW_COLORS=(
	"$(tput sgr0)"
	"$(tput setaf 238)"
	"$(tput setaf 99)"
	"$(tput setaf 241)"
	"$(tput setaf 96)"
)

SLEEP_TIME=.3

tput() {
	local VERSION='bash tput (1.0.0)'

	local opt OPTIND OPTARG
	while getopts 'ST:V' opt; do
		case "$opt" in
			S) command tput "$@"; return $?;;
			T) true;;
			V) echo "$VERSION"; return 0;;
		esac
	done
	shift "$((OPTIND - 1))"

	local ESC=$'\x1b'
	case "$1" in
		bel) echo -n $'\x7';;
		sgr0 | me) echo -n "$ESC[0m";;
		bold) echo -n "$ESC[1m";;
		dim) echo -n "$ESC[2m";;
		rev) echo -n "$ESC[7m";;
		blink) echo -n "$ESC[5m";;
		setaf | AF) echo -n "$ESC[38;5;$2m";;
		setab | AB) echo -n "$ESC[48;5;$2m";;
		sc) echo -n "${ESC}7";;
		rc) echo -n "${ESC}8";;
		cnorm) echo -n "$ESC[?25h";;
		civis) echo -n "$ESC[?25l";;
		smcup) echo -n "$ESC[?1049h";;
		rmcup) echo -n "$ESC[?1049l";;
		clear) echo -n "$ESC[H$ESC[2J";;
		home) echo -n "$ESC[H";;
		cuu) echo -n "$ESC[$2A";;
		cud) echo -n "$ESC[$2B";;
		cuf) echo -n "$ESC[$2C";;
		cub) echo -n "$ESC[$2D";;
		cup)
		  local row=$(($2 + 1))
		  local col=$(($3 + 1))
		  echo -n "$ESC[$row;${col}H";;
		*) command tput "$@"; return $?;;
	esac
}

get-msecs() {
	local secs usecs
	IFS=. read -r secs usecs <<< "$EPOCHREALTIME"
	local msecs=$((10#$usecs / 1000))
	printf '%d%03d' "$secs" "$msecs"
}

start-timer() {
	TIMER=${ get-msecs; }
}

end-timer() {
	local now=${ get-msecs; }
	local then=$TIMER
	local delta=$((now - then))

	echo "took $delta" >> times.txt
}

cleanup() {
	tput rmcup
	tput cnorm
}

usage() {
	local IFS=
	cat <<-EOF
	Usage: ./xmas [options]
	Usage: curl xmas.sh/2025 | bash -s -- [options]
	Options:
	-h print this message and exit
	-s <num> time between frames in seconds, default is $SLEEP_TIME
	-c <chars> character(s) to use for snows, defaults to ${SNOWS[*]}
	
	Credits:
	- Moon ascii art by asciiart site
	EOF
}

main() {
	local OPTIND OPTARG opt i
	while getopts 'c:hs:' opt; do
		case "$opt" in
		c)
			SNOWS=()
			for ((i = 0; i < ${#OPTARG}; i++)); do
			local c=${OPTARG:i:1}
			SNOWS+=("$c")
			done
			;;
		s) SLEEP_TIME=$OPTARG;;
		h) usage; exit 0;;
		*) usage >&2; exit 1;;
	esac
	done

	# draw and configure terminal
	trap cleanup EXIT
	tput smcup
	tput civis

	# shape figure out
	COLUMNS=$(tput cols)
	LINES=$(tput lines)

	local middle_y=$((LINES / 2 - (TREE_HEIGHT / 2)))
	local middle_x=$((COLUMNS / 2 - (TREE_WIDTH / 2)))
	local lightidx=0
	local snows=()
	local t x y c i col
	local snow
	local frames=0
	while true; do
		# start-timer
		# clear snows
		for ((i = 0; i < "${#snows[@]}"; i++)); do
			snow=${snows[i]}
			read -r x y col c <<< "$snow"
			tput cup "$y" "$x"
			echo -n ' '
		done

		# styling and coloring tree
		t=$COLOR_TREE$TREE
		t=${t// \*/ ${COLOR_STAR}*${COLOR_TREE} }
		t=${t// 0 / ${COLOR_LIGHT[lightidx % COLOR_LIGHT_LEN]}o${COLOR_TREE} }
		t=${t// 1 / ${COLOR_LIGHT[(lightidx + 1) % COLOR_LIGHT_LEN]}o${COLOR_TREE} }
		t=${t// 2 / ${COLOR_LIGHT[(lightidx + 2) % COLOR_LIGHT_LEN]}o${COLOR_TREE} }
		t=${t// 3 / ${COLOR_LIGHT[(lightidx + 3) % COLOR_LIGHT_LEN]}o${COLOR_TREE} }
		
		# show tree
		x=5
		y=$((LINES - TREE_HEIGHT - 1))
		while IFS= read -r line; do
			tput cup "$y" "$x"
			echo -n "$line"
		((y++))
		done <<< "$t"

		# show text
		x=$((5 + TREE_WIDTH + 5))
		y=$((LINES - SIGN_HEIGHT - 1))
		while IFS= read -r line; do
			tput cup "$y" "$x"
			echo -n "$line"
			((y++))
		done <<< "$SIGN"

		# show moon
		x=$((COLUMNS - 20))
		y=3
		while IFS= read -r line; do
			tput cup "$y" "$x"
			echo -n "$MOON_COLOR$line"
			((y++))
		done <<< "$MOON"

		# snowfall simulation
		for ((i = 0; i < "${#snows[@]}"; i++)); do
			snow=${snows[i]}
			read -r x y col c <<< "$snow"
			((y++))
			tput cup "$y" "$x"
			echo -n "$col$c$COLOR_RST"
			if ((y > LINES)); then
				unset snows[i]
				continue
			fi
			snows[i]="$x $y $col $c"
		done
		snows=("${snows[@]}")

		# add snow
		snows+=(
			"$((RANDOM % COLUMNS)) \
			0 \
			${SNOW_COLORS[RANDOM % ${#SNOW_COLORS[@]}]} \
			${SNOWS[RANDOM % ${#SNOWS[@]}]}"
		)

		# increase animation play and pause of light
		((frames++))
		((frames %= 10))
		if ((frames == 0)); then
			((lightidx++))
		fi
		
		sleep "$SLEEP_TIME"
	done
}

main "$@"…
