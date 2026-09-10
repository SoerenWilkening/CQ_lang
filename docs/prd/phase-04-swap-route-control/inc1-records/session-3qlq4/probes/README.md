# session-3qlq4 probes — the plain-C `bool` probe family behind PRD §13 (bd `test_C_libtooling-3qlq.4`, 2026-09-10)

Single-TU programs, `clang -O1` → `cq-lowering` → stage 2b → link → run. Verdicts MEASURED on `main` 170ede1 (every `bool`-conditioned shape declined) and on branch `3qlq-inc1b-rail-cond` aee9212. `lines` = trace lines.

| file | shape | verdict on the branch |
|---|---|---|
| `p01_diamond.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(0.9); return cq_measure(b);…` | ACCEPT, 4 lines, 2b clean |
| `p02_negated.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); if (!b) cq_phi(0.9); return cq_measure(b)…` | ACCEPT, 4 lines, 2b clean |
| `p03_ifelse.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(0.9); else cq_phi(0.3); ret…` | ACCEPT, 5 lines, 2b clean |
| `p04_dead.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(0.9); return 0; }…` | ACCEPT, 3 lines, 2b clean |
| `p05_chained.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); b = cq_theta(b, 0.25); if (b) cq_phi(0.9)…` | ACCEPT, 5 lines, 2b clean |
| `p06_and_cmp.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); if (b && q == 5…` | ACCEPT, 14 lines, 2b clean |
| `p07_and_bb.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); bool c = cq_theta((bool)0, 0.3); if (b &&…` | ACCEPT, 11 lines, 2b clean |
| `p08_select_const.c` | `int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; return cq_measu…` | DECLINE `cq controlled lowering: bare i1 register condition` |
| `p09_value_arm.c` | `int main(void){ int a = cq_theta(5, 0.2); bool b = cq_theta((bool)0, 0.5); if (b) a = a + …` | DECLINE `cq controlled lowering: bare i1 register condition` |
| `p10_inplace_ry.c` | `int main(void){ int r = cq_theta(0, 0.2); bool b = cq_theta((bool)0, 0.5); if (b) r = cq_t…` | DECLINE `cq controlled lowering: control flow` |
| `p11_stateprep.c` | `int main(void){ int r = 1; bool b = cq_theta((bool)0, 0.5); if (b) r = cq_theta(1, 0.9); r…` | DECLINE `cq controlled lowering: control flow` |
| `p12_angle_select.c` | `int main(void){ int r = cq_theta(0, 0.2); bool b = cq_theta((bool)0, 0.5); if (b) r = cq_t…` | DECLINE `cq controlled lowering: bare i1 register condition` |
| `p13_loop_perbit.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); for (int i = 0; i < 3; ++i) { if (b) cq_p…` | DECLINE `cq controlled lowering: control flow` |
| `p14_nest.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); if (b) { cq_phi…` | ACCEPT, 15 lines, 2b clean |
| `p15_after_ry.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(0.9); b = cq_theta(b, 0.25)…` | ACCEPT, 5 lines, 2b clean |
| `p16_cascade_bool.c` | `int main(void){ int a = cq_theta(5, 0.0); bool b0 = 0; bool b1 = 0; if (a >= 3) b0 = cq_th…` | DECLINE `cq controlled lowering: state prep seed is proven equal to the condition register` |
| `p17_i8.c` | `int main(void){ char c = cq_theta((char)0, 0.5); if (c == 1) cq_phi(0.9); return cq_measur…` | ACCEPT, 7 lines, 2b clean |
| `p18_bool_eq_bool.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); bool c = cq_theta((bool)0, 0.3); if (b ==…` | ACCEPT, 15 lines, 2b clean |
| `p19_trunc.c` | `int main(void){ int q = cq_theta(0, 0.3); if (q & 1) cq_phi(0.9); return cq_measure(q); }…` | ACCEPT, 12 lines, 2b clean |
| `p20_tail.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); double t = 0.3; if (b) t = 0.9; cq_phi(t)…` | ACCEPT, 5 lines, 2b clean |
| `q01_loop_invariant_rail.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); for (int i = 0;…` | DECLINE `cq controlled lowering: control flow` |
| `q02_two_regions_one_rail.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(0.1); if (!b) cq_phi(0.2); …` | ACCEPT, 5 lines, 2b clean |
| `q03_cross_block_rail.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); if (g) q = cq_t…` | ACCEPT, 8 lines, 2b clean |
| `q04_anglesel_then_ry.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(0.9); else cq_phi(0.3); b =…` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` |
| `q05_rail_and_cmp_negated.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); if (!(b && q ==…` | ACCEPT, 16 lines, 2b clean |
| `q06_not_b_and_cmp.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); if (!b && q == …` | ACCEPT, 20 lines, 2b clean |
| `q07_rail_or_cmp.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); if (b \|\| q == 5…` | ACCEPT, 18 lines, 2b clean |
| `q08_measured_before.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int m = cq_measure(b); if (b) cq_phi(0.9)…` | DECLINE `cq controlled lowering: condition measured before the control route` |
| `q09_rail_used_in_arith.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); if (b) cq_phi(0…` | ACCEPT, 10 lines, 2b clean |
| `q10_grover_bool_loop.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); for (int i = 0; i < 2; ++i) { if (b) cq_p…` | DECLINE `cq controlled lowering: branch phase on a bare i1 condition` |
| `q11_grover_bool_flat.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(3.14159); b = cq_theta(b, -…` | ACCEPT, 11 lines, 2b clean |
| `q12_nest_inner_rail.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); if (q == 5) { c…` | ACCEPT, 15 lines, 2b clean |
| `q13_nest_outer_negated.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); if (!b) { cq_ph…` | DECLINE `cq controlled lowering: branch phase on a bare i1 condition` |
| `q14_rail_in_clone.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); f(b); return cq_measure(b); }…` | ACCEPT, 4 lines, 2b clean |
| `q15_bool_from_cmp.c` | `int main(void){ int q = cq_theta(0, 0.3); bool b = (q == 5); if (b) cq_phi(0.9); return cq…` | ACCEPT, 7 lines, 2b clean |
| `r01_loop_invariant_int_twin.c` | `int main(void){ int b = cq_theta(0, 0.5); int q = cq_theta(0, 0.3); for (int i = 0; i < 3;…` | DECLINE `cq controlled lowering: control flow` |
| `r02_loop_invariant_rail_const.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); for (int i = 0;…` | ACCEPT, 12 lines, 2b clean |
| `r03_loop_invariant_rail_const_unrolled.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); if (b) cq_phi(0…` | ACCEPT, 12 lines, 2b clean |
| `r04_loop_invariant_rail_negated.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); for (int i = 0;…` | ACCEPT, 12 lines, 2b clean |
