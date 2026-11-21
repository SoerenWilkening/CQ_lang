#!/bin/zsh
# usage: cmpdirs.sh A B  -> lists differing .ll files
n=0
for f in $1/*.ll; do b=${f:t}; cmp -s $f $2/$b || { echo "DIFF $b"; n=$((n+1)); }; done
echo "files=$(ls $1/*.ll | wc -l) diffs=$n"
cat $2/*.err | sort | uniq -c | head
