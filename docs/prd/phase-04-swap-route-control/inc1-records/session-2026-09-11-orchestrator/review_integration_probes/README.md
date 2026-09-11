# `review_integration_probes` — the INTEGRATION Rule-13 corpus (session 2026-09-11)

99 probes (97 single-TU + 2 two-TU under `multi/`). ORACLE = `CQ_lang/build` at `main`
0c7380c; SUBJECT = `CQ_l4x4/build` (source byte-identical to `main` e96f89c).

Runners (all read-only, none rebuilds):

```
./ab.sh   <p.c|p.ll>      # one probe on BOTH binaries -> "name|ORACLE|SUBJECT"
./full.sh <p.c>           # SUBJECT pipeline: lower, stage 2b, link, run (the trace)
./multi/run_multi.sh <caller.c>...   # the two-TU 6.5 recipe (caller + multi/lib.c, llvm-link)
./corpus.sh <out.txt>     # the 770-row sweep over all twelve session probe corpora
./twob.sh  < list-of-rels # STRICT stage 2b over a list of corpus-relative probe paths
```

`verdicts.txt` — all 99 probes, `name|ORACLE|SUBJECT` (md5s embed a temp path and are
comparable only WITHIN a row, which is how `corpus.sh` compares them).
`corpus_oracle_vs_subject.txt` — the 770-row sweep; see `../review_integration.md` §6.

Families: `V0/A/B/C` the owner's file and its three spellings · `N*` its neighbourhood ·
`U0/U1` the commented-out block · `O*/Q*/Y*/W5/Z3` the emission-order attack · `P*/HP_*` the
peel × F2 bisection (finding I-1: `HP_f_nopeel` ACCEPTS, `HP_g_sel_only` = the same module plus
ONE `icmp` clone DECLINES) · `R*`/`multi/W*` the round-2 window through a peeled mux
(`R6`/`R7`: oracle ACCEPT-and-wrong, subject DECLINE) · `S*/X*` the whole-DAG spine ·
`L*` loops and fence order · `F1*` non-finite angles · `T*/G*/M*/E*/Z*` the rest.
