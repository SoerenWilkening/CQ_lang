#!/bin/bash
# census.sh S|M file.ll args -> "verdict | dirty-census | tracehash"
R=$(dirname $0)
o=$($R/run.sh $1 $2 ${3:-5})
v=$(echo "$o" | head -1)
c=$(echo "$o" | grep free_pairing | sed 's/.*mint(s) of which \([0-9]*\) left allocated, \([0-9]*\) template rail mint(s) of which \([0-9]*\) left dirty.*: \([0-9]*\) verified, \([0-9]*\) violation.*, \([0-9]*\) unproven/alloc-left=\1 tpl=\2 dirty=\3 viol=\5 unpr=\6/')
t=$(echo "$o" | grep -v "^opt\|^run\|free_pairing\|error\|warning" | shasum | cut -c1-10)
w=$(echo "$o" | grep -c warning)
echo "$v | $c | warn=$w | trace=$t"
