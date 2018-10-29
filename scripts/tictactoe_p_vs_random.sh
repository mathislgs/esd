#!/bin/bash

line_delimiter="---+---+---"
retry=true
restart=true
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
bold=`tput bold`
reset=`tput sgr0`

print_table () {
	echo " ${board:0:1}" "|" "${board:1:1}" "|" "${board:2:1}"
	echo "$line_delimiter"
	echo " ${board:3:1}" "|" "${board:4:1}" "|" "${board:5:1}"
	echo "$line_delimiter"
	echo " ${board:6:1}" "|" "${board:7:1}" "|" "${board:8:1}"
}

fill_cell () { # Takes cell and symbol
	if [ "$1" -ge 1 -a "$1" -le 9 ]; then
		if [ "${board:cell_number-1:1}" != '-' ]; then
			echo "${red}${bold}The cell MUST be empy, [Enter] to try again!${reset}" > /dev/stderr
			read
			retry=true
		else
			board="${board:0:cell_number-1}$2${board:cell_number}"
			retry=false
			player=$((player%2+1))
			depth=$((depth+1))
		fi
	else
		echo "${red}${bold}The cell number MUST be between 1 and 9, [Enter] to try again.${reset}" > /dev/stderr
		read
		retry=true
	fi
}

check_match () { # Takes cell1, cell2, cell3 and board
	local tmp_board=$4
	if [ ! -z "${tmp_board:$1:1}" ] && [ "${tmp_board:$1:1}" != '-' ] && [ "${tmp_board:$1:1}" == "${tmp_board:$2:1}" ] && [ "${tmp_board:$2:1}" == "${tmp_board:$3:1}" ]; then
		win=1
	fi
}

check_win () {
	check_match 0 1 2 $1
	check_match 3 4 5 $1
	check_match 6 7 8 $1
	check_match 0 4 8 $1
	check_match 2 4 6 $1
	check_match 0 3 6 $1
	check_match 1 4 7 $1
	check_match 2 5 8 $1
}

check_draw () {
	local tmp_board=$1
	if [[ "${tmp_board}" == *"-"* ]]; then
		draw=0
		return
	fi
	draw=1
}

end_game () {
	echo -n "Enter q to exit and r to restart: [q|r] "
	read mode
	case $mode in
		q)
			exit
			;;
		r)
			restart=true
			retry=false
			;;
		*)
			exit
			;;
	esac
}

play () {
	while $restart == true; do
		win=0
		draw=0
		board='---------'
		player=1
		clear

		echo "Tic Tac Toe"
		echo ""
		echo " 1 | 2 | 3 "
		echo "$line_delimiter"
		echo " 4 | 5 | 6 "
		echo "$line_delimiter"
		echo " 7 | 8 | 9 "
		echo ""
		echo "Press [Enter] to  start..."
		read

		while [ $win = 0 ]; do
			if [ "${player}" = 1 ]; then
				symbol="X"
			else
				symbol="O"
			fi
			retry=true
			while $retry == true; do
				clear
				print_table
				if [ "${symbol}" == "X" ]; then
					echo -n "(${symbol}) Enter the number of the cell you want to play in: [1-9] "
					read cell_number
				else
					cell_number=$(((RANDOM%9)+1))
					while [ ${board:$cell_number-1:1} != '-' ]; do
						cell_number=$(((RANDOM%9)+1))
					done
				fi

				fill_cell "${cell_number}" "${symbol}"
				check_win "${board}"
				check_draw "${board}"

				if [ $win == 1 ]; then
					print_table
					echo "${green}${bold}Player ${symbol} wins!${reset}"
					end_game
				fi

				if [ $draw == 1 ]; then
					print_table
					echo "${yellow}${bold}It's a draw...${reset}"
					end_game
				fi

				print_table
			done
		done
	done
}

play
