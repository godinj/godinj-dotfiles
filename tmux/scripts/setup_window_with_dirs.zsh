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

INPUT_FILE="$HOME/tmux-config/scripts/sess_dir/$file"

# Check if the file exists
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Error: File '$INPUT_FILE' not found."
  exit 1
fi

lines_array=("${(@f)$(<$INPUT_FILE)}")

n_lines=${#lines_array[@]}

for ((i = 1; i < $n_lines; i++)); do 
  tmux split-window -v
done
tmux select-layout even-vertical

lock="${sess// /_}-$win"

for ((i = 0; i < $n_lines; i++)); do 
  pane="$sess.$i";
  n_cmd="cd ${lines_array[i + 1]}"
  tmux send-keys -t $pane $n_cmd Enter\;
done
