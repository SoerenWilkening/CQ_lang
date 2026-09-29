echo "== L2arr_lit S"; ./run.sh S src/L2arr_lit.c -- 6 -2 9 | head -2
echo "== L2arr_lit O"; ./run.sh O src/L2arr_lit.c -- 6 -2 9 | head -2
echo "== L2b S"; ./run.sh S src/L2b.c -- 6 -2 9 > out/L2b.S.txt; head -2 out/L2b.S.txt
./run.sh S src/L2b_unr.c -- 6 -2 9 > out/L2bu.S.txt; head -2 out/L2bu.S.txt
diff <(sed 1,2d out/L2b.S.txt) <(sed 1,2d out/L2bu.S.txt) && echo "L2b TWIN-IDENTICAL traces ($(sed 1,2d out/L2b.S.txt | wc -l) lines)"
echo "== L2b_k1000 S"; ./run.sh S src/L2b_k1000.c -- 6 -2 9 | sed -n 2p
echo "== L2b O"; ./run.sh O src/L2b.c -- 6 -2 9 | head -2
