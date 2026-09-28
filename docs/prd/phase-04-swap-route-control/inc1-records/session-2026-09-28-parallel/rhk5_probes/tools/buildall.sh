#!/bin/bash
# buildall.sh NAME... : build each NAME.c (+ NAME.lib.c) in src/ to NAME.s1.ll
R=$(cd $(dirname $0) && pwd)
cd $R/../src
for n in "$@"; do bash $R/build.sh $n; done
for n in "$@"; do printf '%s %s\n' "$(wc -c < $n.s1.ll | tr -d ' ')" "$n.s1.ll"; done
