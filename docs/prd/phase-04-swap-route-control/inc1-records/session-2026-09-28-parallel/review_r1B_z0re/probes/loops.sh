#!/bin/bash
echo "== L1as_exit S"; ./run.sh S src/L1as_exit.c -- 5 4 2
echo "== L2arr S"; ./run.sh S src/L2arr.c -- 6 -2 9 > out/L2arr.S.txt; cat out/L2arr.S.txt | head -3
echo "== L2arr_unr S"; ./run.sh S src/L2arr_unr.c -- 6 -2 9 > out/L2arr_unr.S.txt; head -3 out/L2arr_unr.S.txt
diff <(sed 1,2d out/L2arr.S.txt) <(sed 1,2d out/L2arr_unr.S.txt) && echo "L2 TWIN-IDENTICAL traces"
echo "== L2arr_k1000 S"; ./run.sh S src/L2arr_k1000.c -- 6 -2 9 | head -3
echo "== L3carry S"; ./run.sh S src/L3carry.c -- 5 7 > out/L3.S.txt; cat out/L3.S.txt
echo "== L3carry_unr S"; ./run.sh S src/L3carry_unr.c -- 5 7 > out/L3u.S.txt; cat out/L3u.S.txt
echo "== L3carry O"; ./run.sh O src/L3carry.c -- 5 7 | head -3
echo "== L4guard S"; ./run.sh S src/L4guard.c -- 5 7 3
echo "== L4guard_lit S"; ./run.sh S src/L4guard_lit.c -- 5 7 3 | head -4
echo "== L4guard_lit O"; ./run.sh O src/L4guard_lit.c -- 5 7 3 | head -4
echo "== L5as_in S"; ./run.sh S src/L5as_in.c -- 5 7
