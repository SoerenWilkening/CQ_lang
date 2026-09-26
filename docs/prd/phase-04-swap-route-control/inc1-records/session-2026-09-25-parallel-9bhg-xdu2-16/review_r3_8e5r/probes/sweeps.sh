#!/bin/bash
R=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r3rev
cd "$R"
echo "== uptime"; uptime
echo "== binaries"; shasum -a 256 bin/*
echo "== 1. NULL: head twice"
python3 ab3.py bin/cq-opt.head bin/cq-opt.head all.lst out/null.tsv -j 8
echo "== 2. POSITIVE comparator control: head twice with one perturbed"
python3 ab3.py bin/cq-opt.head bin/cq-opt.head probes.lst out/pos.tsv -j 4 --perturb p2_N.ll
echo "== 3. c416f04d vs head"
python3 ab3.py bin/cq-opt.c416 bin/cq-opt.head all.lst out/c416_head.tsv -j 8
echo "== 4. ba80 vs head (lit + e2e + probes)"
grep -v '/fam/' all.lst > le_probes.lst
python3 ab3.py bin/cq-opt.ba80 bin/cq-opt.head le_probes.lst out/ba80_head.tsv -j 8
echo "== 5. head vs head-debugalloc nofree / lifo"
python3 ab3.py bin/cq-opt.head bin/cq-opt-debugalloc.head all.lst out/head_nofree.tsv --env-b CQ_OPT_DEBUG_ALLOC=nofree -j 8
python3 ab3.py bin/cq-opt.head bin/cq-opt-debugalloc.head all.lst out/head_lifo.tsv --env-b CQ_OPT_DEBUG_ALLOC=lifo -j 8
echo "== uptime"; uptime
echo DONE
