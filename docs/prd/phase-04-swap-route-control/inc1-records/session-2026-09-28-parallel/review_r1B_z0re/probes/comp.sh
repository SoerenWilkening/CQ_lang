#!/bin/bash
cmpp() { # name args
  ./run.sh S src/$1.c -- ${@:2} > out/$1.S.txt; ./run.sh ${TB:-S} src/$1_${TW:-twin}.c -- ${@:2} > out/$1.T.txt
  echo "== $1 vs ${TW:-twin}(${TB:-S})"; head -2 out/$1.S.txt; head -2 out/$1.T.txt
  if diff <(sed 1,2d out/$1.S.txt) <(sed 1,2d out/$1.T.txt) >/dev/null; then echo "TRACE-IDENTICAL ($(sed 1,2d out/$1.S.txt|wc -l) lines)"; else echo "TRACE-DIFF"; diff <(sed 1,2d out/$1.S.txt) <(sed 1,2d out/$1.T.txt) | head -20; fi
}
cmpp c1clone 6 4
TW=lit TB=O cmpp c2leaf 6 4
TW=lit TB=O cmpp c3cascade 6 4 9
TW=lit TB=O cmpp c4bool 1 1
echo "== c5inv S"; ./run.sh S src/c5inv.c -- 6 4 | head -5
