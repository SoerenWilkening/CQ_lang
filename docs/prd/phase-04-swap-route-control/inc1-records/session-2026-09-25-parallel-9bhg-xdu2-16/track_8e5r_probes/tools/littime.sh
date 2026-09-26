#!/bin/bash
# littime.sh — full lit wall time, oracle vs FINAL subject, alternating, 2 rounds,
# with the load average printed before each run (never quote one without it).
T=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r
cd "$T"
python3 mklit.py oracleT ./cq-opt.oracle_ba80 ./ba80_debugalloc_wrapper.sh > /dev/null
python3 mklit.py subjT ./cq-opt.fin ./cq-opt.find > /dev/null
for i in 1 2; do
  for tag in oracleT subjT; do
    ld=$(uptime | sed 's/.*averages: //')
    s=$(python3 -c 'import time; print(time.time())')
    lit "lit_$tag" -s > "lit_time_$tag.$i.txt" 2>&1
    e=$(python3 -c 'import time; print(time.time())')
    echo "$tag run$i: $(python3 -c "print(round($e-$s,1))") s  [load before: $ld]  $(grep -E '^ *(Passed|Failed|Expectedly Failed) *:' "lit_time_$tag.$i.txt" | tr -s ' ' | tr '\n' ' ')"
  done
done
