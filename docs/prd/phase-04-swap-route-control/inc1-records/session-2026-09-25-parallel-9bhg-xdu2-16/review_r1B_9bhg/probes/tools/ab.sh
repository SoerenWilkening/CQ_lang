#!/bin/bash
# ab.sh <tagA:env:bin> <tagB:env:bin> <file.ll>  -> "file\trcA\trcB\tsame|DIFF\terrA\terrB"
f=$3
run() { # env bin
  local envs=$1 bin=$2 o e rc
  o=$(mktemp); e=$(mktemp)
  env $envs "$bin" -passes=cq-lowering -S "$f" -o "$o" 2>"$e"; rc=$?
  h=$(shasum -a 256 "$o" | cut -c1-16)
  er=$(grep -o 'error: .*' "$e" | head -1 | sed 's/^error: [^:]*:[0-9:]* //' | cut -c1-120)
  rm -f "$o" "$e"
  printf '%s\t%s\t%s' "$rc" "$h" "$er"
}
IFS=: read -r ta ea ba <<< "$1"
IFS=: read -r tb eb bb <<< "$2"
A=$(run "$ea" "$ba"); B=$(run "$eb" "$bb")
IFS=$'\t' read -r rca ha era <<< "$A"
IFS=$'\t' read -r rcb hb erb <<< "$B"
st=same; [ "$rca" != "$rcb" -o "$ha" != "$hb" -o "$era" != "$erb" ] && st=DIFF
printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(basename $f .ll)" "$rca" "$rcb" "$st" "$era" "$erb"
