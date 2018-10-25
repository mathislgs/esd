#!/bin/bash

line_delimiter="---+---+---"
retry=true
restart=true
debug=0
timer=0
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
bold=`tput bold`
reset=`tput sgr0`

while [ "$1" != "" ]; do
	case $1 in
		-d | --debug )
			debug=1
			shift
			;;
		-t | --timer )
			timer=1
			shift
			;;
		@)
			debug=0
			timer=0
	esac
	shift
done

print_table () {
	local tmp_board=$1
	echo " ${tmp_board:0:1}" "|" "${tmp_board:1:1}" "|" "${tmp_board:2:1}"
	echo "$line_delimiter"
	echo " ${tmp_board:3:1}" "|" "${tmp_board:4:1}" "|" "${tmp_board:5:1}"
	echo "$line_delimiter"
	echo " ${tmp_board:6:1}" "|" "${tmp_board:7:1}" "|" "${tmp_board:8:1}"
}

check_match () { # Takes cell1, cell2, cell3 and board
	local tmp_board=$4
	if [ ! -z "${tmp_board:$1:1}" ] && [ "${tmp_board:$1:1}" != '-' ] && [ "${tmp_board:$1:1}" == "${tmp_board:$2:1}" ] && [ "${tmp_board:$2:1}" == "${tmp_board:$3:1}" ]; then
		win=1
		draw=0
		winner=${tmp_board:$1:1}
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
	if [ $win = 1 ]; then
		return 1
	else
		return 0
	fi
}

check_draw () {
	local tmp_board=$1
	if [[ "${tmp_board}" == *"-"* ]]; then
		draw=0
		return 0
	elif [ $win != 1 ]; then
		draw=1
		return 1
	fi
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
		@)
			exit
			;;
	esac
}

evaluate () { # takes a board, a depth and a symbol
  local tmp_board=$1
	local tmp_depth=$2
	local tmp_symbol=$3

	check_draw $tmp_board
	check_win $tmp_board

	if [ "${winner}" == "X" ]  && [ $win = 1 ]; then # Player wins
		eval_score=$(($tmp_depth-30))
	elif [ "${winner}" == "O" ] && [ $win = 1 ]; then # Opponent wins
		eval_score=$((30-$tmp_depth))
	elif [ $draw = 1 ]; then # Draw
		eval_score=0
	fi
}

minimax () { # takes the board, the depth and the player
  local current_depth=$1
	current_player=$(get_player $3)
	local current_board=$3

	evaluate $current_board $current_depth $current_player
	result=$eval_score
	current_depth=$((current_depth+1))

	if [ $win = 1 ] || [ $draw = 1 ]; then
		echo $result
		return
	else
		local alpha=$4
		local beta=$5
		if [ "${current_player}" == "X" ]; then # Maximize
			best=-1000
			for b in `possible_boards $current_board "X"`; do
				temp_player=$(get_player $b)
				if [[ $debug = 1 ]]; then
					echo "maximize for $b" > /dev/stderr
				fi
				value=$(minimax ${current_depth} $temp_player $b $alpha $beta)
				best=$( (( $best >= $value )) && echo "$best" || echo "$value" )
				alpha=$( (( $best >= $alpha )) && echo "$best" || echo "$alpha" )
				if [ $beta -le $alpha ]; then
					break
				fi
			done
			echo $best
			return
		else # Minimize
			best=1000
			for b in `possible_boards $current_board "O"`; do
				temp_player=$(get_player $b)
				if [[ $debug = 1 ]]; then
					echo "minimize for $b" > /dev/stderr
				fi
				value=$(minimax ${current_depth} $temp_player $b $alpha $beta)
				best=$( (( $best <= $value )) && echo "$best" || echo "$value" )
				beta=$( (( $best <= $beta )) && echo "$best" || echo "$beta" )
				if [ $beta -le $alpha ]; then
					break
				fi
			done
			echo $best
			return
		fi
	fi
}

possible_boards () { # Takes a board and a symbol
	local tmp_board=$1
	local tmp_symbol=$2

	for i in `seq 0 8`; do
		if [ "${tmp_board:$i:1}" == "-" ]; then
			rest=$((i+1))
			echo ${tmp_board:0:$i}$tmp_symbol${tmp_board:$rest}
		fi
	done
}

get_player () { # Takes a board
	local empty=`echo $1 | sed -e 's/[XO]//g'`
	local count_empty=${#empty}
	if [ $((count_empty%2)) = 1 ]; then
		echo "X"
	else
		echo "O"
	fi
}

play () {
	while $restart == true; do
		win=0
		draw=0
		depth=0
		eval_score=0
		board='---------'
		best_board=''
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
		echo "You can start the script with the -d option to show debug lines or -t to show timer lines."
		echo "Press [Enter] to  start..."
		read

		while [ $win = 0 ]; do
			symbol=$(get_player $board)
			retry=true
			while $retry == true; do
				best_value=-1000
				clear
				print_table $board
				if [ "${symbol}" == "X" ]; then
					echo -n "(${symbol}) Enter the number of the cell you want to play in: [1-9] "
					read cell_number
					if [ "$cell_number" -ge 1 -a "$cell_number" -le 9 ]; then
						if [ "${board:cell_number-1:1}" == "X" ] || [ "${board:cell_number-1:1}" == "O" ]; then
							echo "${red}${bold}The cell MUST be empy, [Enter] to try again!${reset}" > /dev/stderr
							read
							retry=true
						else
							board="${board:0:cell_number-1}X${board:cell_number}"
							retry=false
						fi
					else
						echo "${red}${bold}The cell number MUST be between 1 and 9, [Enter] to try again.${reset}" > /dev/stderr
						read
						retry=true
					fi
				else
					start_ai_turn=$SECONDS
					for i in `seq 0 8`; do
						start_sim_loop=$SECONDS
						if [ ${board:$i:1} = '-' ]; then
							local rest=$((i+1))
							local sim_board="${board:0:$i}O${board:$rest}"
							if [[ $debug = 1 ]]; then
								echo "${green}[D] sim_board for i = $i ${reset}" > /dev/stderr
								sleep 1
							fi
							clear
							print_table $board
							echo "Thinking... $((9-i))" > /dev/stderr
							value=$(minimax ${depth+1} "O" ${sim_board} -1000 1000)
							if [[ $value -gt $best_value ]]; then
								best_value=$value
								best_board=$sim_board
								retry=false
							fi
						fi
						end_sim_loop=$((SECONDS-start_sim_loop))
						clear
						if [[ $timer = 1 ]]; then
							echo "[T] Loop $((i+1))/9 took $end_sim_loop seconds." > /dev/stderr
						fi
					done
					end_ai_turn=$((SECONDS-start_ai_turn))
					board=$best_board
					retry=false
					if [[ $timer = 1 ]]; then
						echo "[T] AI turn took $end_ai_turn seconds to complete!" > /dev/stderr
					fi
				fi
				depth=$((depth+1))

				evaluate $board $depth $symbol
				retry=false

				if [ $win = 1 ]; then
					print_table $board
					echo "${green}${bold}Player ${symbol} wins!${reset}"
					end_game
				fi

				if [ $draw = 1 ]; then
					print_table $board
					echo "${yellow}${bold}It's a draw...${reset}"
					end_game
				fi

				print_table $board
			done
		done
	done
}

play
