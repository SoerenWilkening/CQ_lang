# GATES — session 2026-09-17 (socratic). Binary: build/ir-pass/cq-opt sha256 first 16 = 9bd01598d574b344

Fresh rebuild 2026-09-17 10:26 of main 79bd7af9 (pass source unchanged since 95949550).
libCQPass.so 3e3dc35d471aae6b. Per-probe pipeline as in the 2026-09-15 PROTOCOL (stage 1 at -O1, cq-opt, free_pairing_check STRICT, link, run).

gate | cq-opt | result | who | when
--- | --- | --- | --- | ---
example/grover/grover_oracle_uncompute.c (loop form) | 9bd01598 | DECLINE 91:15 `control flow inside a loop body under quantum control` (ArmClassify.cpp:5478) | claude | 2026-09-17 10:30
hand-unrolled twin of the same program | 9bd01598 | ACCEPT 45 lines; 11 rail mints / 8 left allocated, 3 template rails / 2 left dirty, 4 free sites 4 verified 0/0 | claude | 2026-09-17 10:30
p52og / phn29 / pleyd (the three beads' own probes) | 9bd01598 | ACCEPT exit 0, 7 / 14 / 14 `@cq`-family calls | claude | 2026-09-17 10:45
lit --filter 'acyclic_nondominated\|backedge_.*desc_collider' | 9bd01598 | 6 passed / 0 failed | claude | 2026-09-17 10:50
s1_live_shift / _un | 9bd01598 | 14 == 14, 2b 0/0 | claude | 2026-09-17 11:05
s2_live_derived_region / _un | 9bd01598 | DECLINE `rolled body leaks a rail entangled with a rotated register` / ACCEPT 25 | claude | 2026-09-17 11:05
s3_live_rootmint_region / _un | 9bd01598 | 22 == 22 | claude | 2026-09-17 11:05
w2k_noregion_invread / _un | 9bd01598 | 20 == 20 | claude | 2026-09-17 11:05
n1 / n2 / n3 nested (loopfix probes) | 9bd01598 | rolled DECLINE ×3 (same string as s2); twins ACCEPT 42 / 34 / 48 | claude | 2026-09-17 11:05
b10_inplace_volatile / _un | 9bd01598 | 7 == 7 | claude | 2026-09-17 11:05
b11_cmp_rail_data / _un | 9bd01598 | 14 == 14 | claude | 2026-09-17 11:05
b7_pertrip / b7b_w2k / b7c_w2h _interfered (+ _un) | 9bd01598 | 18 == 18, 24 == 24, 42 == 42 | claude | 2026-09-17 11:08
w2h_phase_inloop_invread, w2h3_select_iterlocal_invread (+ _un) | 9bd01598 | 38 == 38, 48 == 48 | claude | 2026-09-17 11:08
s4_inplace_accum_live | 9bd01598 | DECLINE `tainted value muxed by a classical-condition phi` (upstream, as IMPL_S2 §0 records) | claude | 2026-09-17 11:08

NOT run: any ctest layer, ir-pass-lit, e2e, the twin matrix, the equivalence sweep. No code changed this session.
