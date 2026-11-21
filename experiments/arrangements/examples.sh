#!/bin/zsh
# usage: ex2.sh <plugin> <outdir> : every spec example fed straight in
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang
export OPT=/usr/local/opt/llvm@19/bin/opt PLUG=$1 OUT=$2
mkdir -p $2
ls $W/spec/examples/*/*.O1.ll | xargs -P4 -n1 sh -c 'b=$(basename "$0" .O1.ll); "$OPT" -load-pass-plugin="$PLUG" -passes=cq-lower -S "$0" -o "$OUT/$b.ll" 2>"$OUT/$b.err" || echo "FAIL $b"'
