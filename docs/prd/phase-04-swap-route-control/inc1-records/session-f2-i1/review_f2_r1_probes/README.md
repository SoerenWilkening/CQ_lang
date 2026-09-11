# review_f2_r1_probes — independent Rule-13 round-1 probes for bd `drbq.14`

`./run_all.sh [NEW_WORKTREE] [OLD_WORKTREE]` runs every probe on BOTH binaries and prints
`NEW rc=<n> [diag] | OLD rc=<n> [diag]`. `rc=0` ACCEPT, `rc=1` loud decline. No rebuild needed;
nothing here is a ctest entry. Defaults: NEW `…/CQ_f2`, OLD `…/CQ_lang` (main `0c7380c`).

## `ll/` — the two artefacts that carry the review's conclusions

* **`{on,off}wire_{rival,folded}.ll` — the α 2×2** (report F-2). One module, two axes. The
  discriminating result: the OFF-wire unfolded rival **lowers** (`rc=0`, both binaries) while its
  folded image still declines at F2; the ON-wire rival **declines** (2c, both binaries) while its
  folded image is the accept the ruling adds. That pair is the measured form of "the exclusion
  removes only declines whose rival has no lowering".
* **`beta_post_{add,xor}.ll` + `…_R.ll` — β downstream observability** (report F-4). The accepted
  module puts the post-region in-place `cqrt_addc_i32` on the PREPPED rail; the `_R` variants
  (merge incoming restored to `%q`) decline F1 on both binaries.
* **`fp_fwd_{fneg,fabs}.ll`** (report F-5): an fp register ON `CondWire` whose `fneg`/`llvm.fabs`
  one hop forward equals the seed — both still decline, which is what proves the exclusion sits at
  the TEST and still seeds the forward evaluation.

## `rival/` — the α/β rivals of the FOUR NEW accepts (not in `probes/alt/`)

`r_condwire_alias{,_beta}`, `r_selfctl_alpha`, `r_mux_beta`, `r_bool_{alpha,beta}` — all six
decline on the narrowed binary. With IMPL's 21 `probes/alt/*.ll` that is 27/27.

## `c/` — plain C at `-O1`

* `x1..x5` — the α attack through other classifiers (angle select ×2, switch, loop, opaque
  threshold): all decline, both binaries.
* `z1..z3` — the `i1` flag-arm family. `z3` is the drbq round-3 "live plain-C miscompile" module
  and is the ruling's disclosed α trade at `i1` (NEW `rc=0`, OLD `rc=1`); `z1` keeps the flag live
  (`cq_measure(c)`) so no fold happens and it declines `rotation arm shares the condition flag` on
  both binaries.
* `b1..b3` — β with a post-region mutation: all decline `control flow` from plain C (`-O1` sinks
  the op into the arm), which is why F-4 is hand IR.
* `k1..k5` — compound / loop / if-else. ⚠ `k1` (`q==5 && q>1`) is NOT compound after `-O1`; `k4`,
  `k5` are.
* `n*`, `o*` — accept-class shapes and the measured over-decline residuals (report I-4).

## `tools/`

* `one.sh` + `corpus_sweep_result.txt` — my independent whole-corpus sweep (1784 fixtures, both
  binaries, rc + stdout + stderr): **1761 SAME / 23 RCDIFF (all DECLINE→ACCEPT) / 0 OUTDIFF /
  0 DIAGDIFF**. Re-run: `ls <NEW>/ir-pass/test/*.ll | xargs -n1 -P4 ./one.sh`.
* `matrix.py` + `injection_matrix_result.txt` — 57 state-prep accept fixtures × 6 output mutations
  re-checked through every declared FileCheck prefix. The 23 flipped/new accepts catch all six.
  ⚠ Two harness limits, both accounted for in the report: the `seed_literal` mutation is a no-op on
  an fp `cqrt_alloc`, and the harness feeds stdout to the stderr-reading `WARN` prefix.
