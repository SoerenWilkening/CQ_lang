# clearance_probes — the clearance reviewer's own 8 plain-C programs (2026-09-06, `clearance_eqpx.md` F-CL-2)

Two-TU programs (every `ext_f` user) take `../../session-82e6b530/eqpx_reproducers/tu_extf.c` as the extra TU.
Binaries: `main` = 16b15b3 (pre-fix), `fix` = the eqpx branch (code tip 1333278). `imm` = `immcheck.py`'s rails-in-immediate-slot count.

| file | immediate | main | fix | verdict |
|---|---|---|---|---|
| `p_k_cmp_zext_imm.c` | `(y > 6)` — a compare of the 6.5 `%out`, zext'd: a FLAG rail | ACCEPT 24 lines **imm=1** | DECLINE (mirrored) | **MEMBER** |
| `p_n_variant_plus_out.c` | `r ^= (w + i)` — a LOOP-VARIANT classical immediate mixed with `%out` | ACCEPT 24 lines **imm=1** | DECLINE (mirrored) | **MEMBER** |
| `p_a_measure_imm.c` | an in-loop `cq_measure` result | ACCEPT 11 | ACCEPT 11, trace byte-identical | control |
| `p_s_out_after_loop.c` | constant; the arm comes AFTER the loop | ACCEPT 20 | ACCEPT 20, identical | control |
| `p_t_out_imm_arg_rail.c` | Argument immediate beside an unused arm | ACCEPT 20 | ACCEPT 20, identical | control |
| `p_c_qram_imm.c` | through an alloca written in the arm | DECLINE | DECLINE, same string | control |
| `p_m_select_break.c` | a 4.4 select immediate in a W1 break loop | DECLINE | DECLINE, same string | control |
| `p_q_cond_is_rail.c` | the arm condition reads the rail | DECLINE | DECLINE, same string | control |
