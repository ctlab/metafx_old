#!/bin/bash
a=$(grep "of them is good" ${1} | grep -o -E ", [0-9']+ \(")
a=$(echo "$a" | sed "s/'//g" | grep -o -E "[0-9]+")

cnt=${2}
for line in ${a//\\n/ }
do
    if [[ $line -gt 100000 ]]; then
        cnt=$((cnt+1))
    else
        echo $cnt
        exit 0
    fi
done
echo $cnt
exit 0
