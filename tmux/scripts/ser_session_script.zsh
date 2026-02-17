#!/bin/zsh

sess=$(tmux display-message -p '#S')
win=$(tmux display-message -p '#I')

file=$1
# echo "file: $file"
if [ -z "$file" ]; then
  echo "no arg file found."
  file="$(echo $sess | cut -c 3-).txt"
fi

# file="$(echo $sess | cut -c 3-).txt"
# echo "debug file: $file"

INPUT_FILE="$HOME/tmux-config/scripts/sess_cmd/$file"

# Check if the file exists
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Error: File '$INPUT_FILE' not found."
  exit 1
fi

lines_array=("${(@f)$(<$INPUT_FILE)}")

n_lines=${#lines_array[@]}
n_pane=$(tmux list-panes | wc -l | xargs)

if [[ $n_pane -lt $n_lines ]]; then
  echo "Error: $n_pane panes is lt $n_lines commands."
  exit 1
fi

# echo "debug new ${sess// /_}"
lock="${sess// /_}-$win"

# hold="tmux wait-for -L $lock"
unlock="tmux wait-for -U $lock"
# echo "debug lock: $lock"

eval $unlock
eval ${lines_array[1]}
for ((i = 1; i < $n_pane; i++)); do 
  pane="$sess.$i"; 
  n_cmd="${lines_array[i + 1]}; $unlock"
  tmux wait-for -L $lock\; \
    send-keys -t $pane $n_cmd Enter\;
done
