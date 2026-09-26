
# ================================================================ bd vsfp ROUND 3 entries
R3_NOTE = """; ⚠ ROUND 3 (bd tzfa; Rule-13 r2B F-WB-1). A slot the specializer RECORDED dead is now
; NEUTRALISED after `specialize()` (`resolvePhantomCloneArgReads`: the argument becomes `0`,
; the drop's rewrite), so the uncompute spine, M-C, M-A and stage 2b see the hand-inlined
; twin's consumer set. Round 2 instead ACCEPTED a phantom read whose operand had another
; reader and left the read in place — one consumer too many for the spine."""

# ---- rewrites of round-2 fixtures whose subject changed in round 3
E("spec_accept_phantom_arg_read_theta_source.ll", V / "ll/theta_source_branch.ll", "main",
  """; spec_accept_phantom_arg_read_theta_source.ll — ACCEPT (bd test_C_libtooling-vsfp — the
; phantom read of a `cq_theta` RESULT; r2A_9bhg probe `cv9S`). Re-spelled in round 2
; (branch-only read, below); subject changed in round 3.
;
; The built clone never reads its parameter 0, so the call becomes `h(0, m)`. The operand
; was `q`, a `cq_theta` RESULT — the user's own register, which the twin computes and keeps
; too — so nothing is declined: the one exemption (Rule-13 r1B, nine shapes). The drop
; does not fire (NODROP): `a` is live in the original `@h`.
""" + R3_NOTE + "\n;\n" + BRANCH_NOTE + "\n;\n; Caller: `int q = cq_theta(m, .5); int t = h(q, m); return cq_measure(t) * 100 + cq_measure(q);`\n;")

E("spec_accept_phantom_arg_read_theta_source_inplace_mc.ll", V / "ll/theta_source_inplace_branch.ll", "main",
  """; spec_accept_phantom_arg_read_theta_source_inplace_mc.ll — ACCEPT, IN PLACE like the
; hand-inlined twin (bd test_C_libtooling-vsfp / bd hgwx). Re-spelled in round 2
; (branch-only read, below); subject changed in round 3.
;
; `t = h(q, m)` passes `q` only in a slot the specializer RECORDED dead. Round 2 settled
; that call as a prior user of `q` through M-C arm (d0); since round 3 the slot is
; neutralised to `0` first, so the call is not a user of `q` at all and `u = t + q` lowers
; IN PLACE (`cqrt_addc_i32(q, t)`) exactly as in the twin (`int t = m + 1;`). (d0) stays the
; one spelling of the question for an inner clone call, where no neutralisation runs.
""" + R3_NOTE + "\n;\n" + BRANCH_NOTE + "\n;\n; Caller: `int q = cq_theta(m, .5); int t = h(q, m); int u = t + q; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r);`\n;")

E("spec_accept_phantom_arg_read_classical_slot.ll", V / "ll/classical_dead_slot.ll", "main",
  """; spec_accept_phantom_arg_read_classical_slot.ll — ACCEPT (bd test_C_libtooling-vsfp ROUND 2,
; subject changed in round 3 — the resolution declines QUANTUM operands only; hand IR).
;
; `@h` reads `a` and `b` only through one empty diamond: both are live in `@h`, both dead
; in its clone, and both slots are neutralised (`h(0, 0, m)`). Slot 0 held `q` (a
; `cq_theta` result — exempt), slot 1 `m * 5`, a CLASSICAL value that no rail represents:
; nothing to decline (mutant B4, which drops the "quantum" conjunct, declines).
""" + R3_NOTE + "\n;")

E("spec_accept_phantom_arg_read_kept_alive.ll", V / "ll/kept_alive.ll", "main",
  """; spec_accept_phantom_arg_read_kept_alive.ll — ACCEPT, the twin's stream (bd
; test_C_libtooling-vsfp; Rule-13 r1B F-VB-4's class; hand-written IR).
;
; `h`'s only read of `a` is branch-only, so the specializer records slot 0 dead and
; `h(p, m)` is a phantom read of `p`, a 4.4 `%out` rail that is ALSO measured. Round 3
; neutralises the slot (`h(0, m)`); `p` keeps its own reader (the measure), which the twin
; (`t = m + 1`) has too, so it is not declined. Round 1 declined this program (an
; over-decline); round 2 accepted it with the phantom read left in place.
""" + R3_NOTE + "\n;")

# ---- bd otam (Rule-13 r2A F-WA-1): the arm fold grows taint; the stage re-propagates
for key, twin, head in (
    ("r3_stale3c", "stale3cT", "the fenv STORE ERASURE empties the arm (`{ volatile int z = 1; r = 5; }`)"),
    ("r3_stale4", "stale3cT", "the volatile CONST-ALLOCA FOLD empties the arm (`{ volatile int k = 7; … (void)k; }`)"),
    ("r3_stale3b", "stale3bT", "the fenv STORE ERASURE empties the arm; the select feeds `r + cq_measure(q)`")):
    fname = {"r3_stale3c": "lowering_volatile_arm_fold_repropagate.ll",
             "r3_stale4": "lowering_volatile_constfold_arm_repropagate.ll",
             "r3_stale3b": "lowering_volatile_arm_fold_repropagate_addc.ll"}[key]
    E(fname, V / f"fx/{key}.s1.ll", "main",
      f"""; {fname} — ACCEPT with the fenv-intended twin's stream (bd
; test_C_libtooling-otam; bd vsfp Rule-13 r2A F-WA-1, probe `{key[3:]}`; red-green).
;
; A quantum-conditioned diamond whose merge has a two-entry φ; {head}.
; The stage's `deleteDeadCones` folds the emptied arm and turns the φ into
; `select (q > 3), 5, 9` — a NEW value, tainted through its condition. Round 2 ignored the
; stage's return and never re-propagated: control detection (keyed on the tainted
; condition) still claimed the select and RAUW'd it to its `%out` rail HANDLE, while every
; taint consumer saw it CLASSICAL — `f(r)` was not lifted (`f` got the handle as data) and
; the user's `cq_measure` lowered as a never-quantum measure and VANISHED (exit 0, 0 bytes of
; stderr, 2b STRICT clean). Round 3: every volatile stage re-propagates when it changed the
; IR, and `declineStaleTaintSet` checks the whole pre-pass window before
; `detectSpecializations` (drop either re-propagate and this file DECLINES loudly — the
; mutation rows). RED on round 2 (FileCheck), a decline on the oracle and on round 1.
{{src}}""", twin=twin, src=key)

E("lowering_volatile_arm_fold_repropagate_escape.ll", V / "fx/r3_stale3a.s1.ll", "main",
  """; lowering_volatile_arm_fold_repropagate_escape.ll — DECLINE with the twin's string (bd
; test_C_libtooling-otam; bd vsfp Rule-13 r2A F-WA-1, probe `stale3a`).
;
; The same arm fold with the select stored to a global (`g_sink = r`). Round 2 stored the
; `%out` rail HANDLE (stale taint: the escape guard saw a classical store). The fenv-intended
; twin declines `cq taint escape: tainted value stored to memory`; with the re-propagate
; this does too.
{src}""", kind="decline", src="r3_stale3a")

E("lowering_volatile_arm_fold_repropagate_loop.ll", V / "fx/r3_loop2.s1.ll", "main",
  """; lowering_volatile_arm_fold_repropagate_loop.ll — DECLINE with the twin's string (bd
; test_C_libtooling-otam; bd vsfp Rule-13 r2A F-WA-1, probe `loop2`).
;
; The arm fold inside a runtime-trip loop, the select accumulated across iterations. Round 2
; emitted classical arithmetic on `%out` rail handles across the back edge and dropped the
; measurement; the fenv-intended twin declines `cq loop lowering: loop-carried tainted value
; crosses iterations`, and with the re-propagate so does this.
{src}""", kind="decline", src="r3_loop2")

# ---- bd stl3 (Rule-13 r2B F-WB-2): the volatile GLOBAL fold folds the arm it empties
for key, twin, spell, fname in (
    ("r3_k1", "k1T", "`if (a > 3) (void)K;` (K a never-stored internal volatile global)", "spec_accept_dropped_arg_volatile_global_arm.ll"),
    ("r3_g9A", "gTA", "`if (__builtin_expect(a > 3, 1)) (void)K;`", "spec_accept_dropped_arg_volatile_global_expect.ll"),
    ("r3_g13A", "gTA", "`return k + 1 + ((a > 3) ? K : 0);` with `K == 0` (a two-entry φ of EQUAL incomings)", "spec_accept_dropped_arg_volatile_global_phi.ll")):
    E(fname, V / f"fx/{key}.s1.ll", "main",
      f"""; {fname} — ACCEPT with the fenv-intended twin's stream (bd
; test_C_libtooling-stl3; bd vsfp Rule-13 r2B F-WB-2, probe `{key[3:]}`).
;
; The callee's only read of `a` is {spell}. The volatile-const GLOBAL fold folds the load to
; the initializer; round 2 gave its three siblings the empty-arm fold and not this one, so
; the emptied diamond (or the φ of equal incomings) kept `a` branch-live, slot B could not
; drop it, the clone's own flatten killed the read, and the phantom-read backstop declined a
; program whose twin compiles (the oracle accepted it DEPHASED — the 4.4 `%out` rail copying
; `b` kept alive). Round 3: the global fold hands the blocks it empties to `deleteDeadCones`
; (for `g13` the φ of EQUAL incomings folds to its value and the dead compare keeps nothing live — the
; condition seed is cleanup there, see TRACK §R3.4), `a` is dead, slot B
; drops it: alloc; Ry(.5); Ry(.7); measure.
{{src}}""", twin=twin, src=key)

E("spec_accept_dropped_arg_volatile_global_oracle.ll", V / "fx/r3_k19.s1.ll", "main",
  """; spec_accept_dropped_arg_volatile_global_oracle.ll — ACCEPT with the hand-inlined twin's
; stream (bd test_C_libtooling-tzfa + stl3; bd vsfp Rule-13 r2B F-WB-1, probe `k19`).
;
; `p = q * 3` feeds `h`'s dead slot AND a phase oracle on `(p ^ q) == 10`. Round 2 let the
; phantom read through (the operand had another reader) and left it in place: the clone call
; was one consumer too many, the spine never uncomputed `p`'s rail, and `q` was fully
; dephased across the oracle (the ORACLE emits the same stream). Round 3's global-fold arm
; fold makes slot B drop the argument, so the stream is the twin's: `mul_i32_hl_unc` and
; `cqrt_free` of `p` before the second Ry, template census 0 dirty. The e2e twin-identical
; gate `e2e-spec-dropped-arg-volatile-global-twin-identical` pins the same program linked.
{src}""", twin="k19F", src="r3_k19")

# ---- bd tzfa (Rule-13 r2B F-WB-1): the IR-only route (branch-only read) to the resolution
E("spec_accept_phantom_arg_read_template_reader.ll", V / "ll/k19_branch.ll", "main",
  """; spec_accept_phantom_arg_read_template_reader.ll — ACCEPT with the hand-inlined twin's
; stream (bd test_C_libtooling-tzfa; bd vsfp Rule-13 r2B F-WB-1 `k19`, IR-only spelling).
;
; `@h`'s read of `a` is BRANCH-ONLY (an empty diamond, so the drop cannot predict the dead
; slot); the clone's flatten kills it and the specializer records slot 0 dead. The phantom
; operand is `p = q * 3`, a template rail the phase oracle `(p ^ q) == 10` also reads. Round
; 2 ACCEPTED because `p` "had another reader" and left `h(p, m)` in place: the spine saw two
; consumers of `p`'s rail and never uncomputed it — `q` fully dephased (a Rule-8 wrong
; unitary; round 1 declined). Round 3 neutralises the slot (`h(0, m)`), so the spine sees the
; twin's consumer set: `cq_template_mul_i32_hl_unc` + `cqrt_free` of `p` before the second
; Ry. Remove the neutralisation (mutant N1) and this file goes red.
""" + R3_NOTE + "\n;\n; Caller (r2B `k19`): `int q = cq_theta(m & 7, .5); int p = q * 3; int r = h(p, m); int u = p ^ q;\n;   if (u == 10) cq_phi(3.14159); q = cq_theta(q, .7); return r + cq_measure(q);`\n;")

E("spec_accept_phantom_arg_read_measured_record.ll", V / "ll/k5_branch.ll", "main",
  """; spec_accept_phantom_arg_read_measured_record.ll — ACCEPT with the twin's stream AND NO
; WARNING (bd vsfp Rule-13 r2B F-WB-3, `k5`, IR-only spelling).
;
; The phantom operand is `p = q * 3`, kept by a user `cq_measure(p)`. Round 2 accepted it
; with the read in place, and M-A's `cloneArgReachesResult` — a third, `use_empty()`
; spelling of "slot unread" — then called the dead clone slot a record hop and emitted a
; lyyf-(B) `non-diagonal gate over a live derived record` warning the twin does not. Round 3
; neutralises the slot (no read reaches M-A) and routes that predicate through the
; specializer's record (`isRecordedDeadSlot`, Rule 14). The NOWARN prefix pins warning parity.
""" + R3_NOTE + "\n;")

E("spec_reject_phantom_arg_read_unread_select.ll", V / "ll/k1_branch.ll", "main",
  """; spec_reject_phantom_arg_read_unread_select.ll — DECLINE (bd test_C_libtooling-tzfa; bd vsfp
; Rule-13 r2B's "B3-style decline for anything left"; hand-written IR, `k1` branch-only).
;
; The phantom operand is `p = b ? 9 : 4`, a 4.4 `%out` rail minted ONLY for the call. After
; the neutralisation nothing in the user program reads it; the twin never computes it, and
; what control emission already built for it (a which-path rail copying `b`, never
; uncomputed) cannot be taken back — kept, it would dephase the later Ry on `b`. Declined.
; An over-decline against the twin, IR-only: the C spelling (`(void)K`) now drops at slot B
; (spec_accept_dropped_arg_volatile_global_arm.ll). Remove the decline (mutant N2) and this
; file accepts the dephased stream.
""" + R3_NOTE + "\n;", kind="decline")

E("spec_reject_phantom_arg_read_unread_template.ll", V / "ll/k3_branch.ll", "main",
  """; spec_reject_phantom_arg_read_unread_template.ll — DECLINE (bd test_C_libtooling-tzfa;
; hand-written IR, r2B `k3` branch-only).
;
; The phantom operand is `p = q * 3`, a tainted op nothing else reads (`-O1` rewrote the
; oracle's `p + 1 == 7` to `q == 2`). After the neutralisation it is DEAD; the twin never
; computes it, and a dead template product is lowered forward and NOT uncomputed (a dirty
; rail across the later Ry on `q` — the CLAUDE.md fenv counter-example `f1`). Declined.
; IR-only (the C spelling drops at slot B). The deletion that would make this the twin is
; not done post-`specialize()` (plan structures hold raw pointers there) — named, not built.
""" + R3_NOTE + "\n;", kind="decline")

E("lowering_volatile_globalfold_equal_phi.ll", V / "fx/r3_eqphi.s1.ll", "main",
  """; lowering_volatile_globalfold_equal_phi.ll — ACCEPT with the fenv-intended twin's stream (bd
; test_C_libtooling-stl3; bd vsfp round 3 — the condition seed after a φ of EQUAL incomings).
; Single TU, no call.
;
; `int r = (q > 3) ? K : 0;` with `K` a never-stored internal volatile global whose initializer is
; 0. `-O1` keeps a diamond (a volatile load cannot be speculated). The volatile GLOBAL fold folds
; the load to 0 and, since round 3, folds the emptied arm: the φ's two incomings are EQUAL, so it
; becomes its value — and the tainted compare `q > 3` is dead. Round 2's `deleteDeadCones` seeded
; the condition only when NO φ remained, so the compare survived and was lowered as a forward
; template never uncomputed: a DIRTY which-path flag across `Ry(0.7)` on `q` (measured on mutant S2:
; TRACE-DIFF, 1 dirty template rail, a lyyf warning). The condition is now seeded after every fold,
; and the stream is the program `r = 0`: alloc; Ry(.5); Ry(.7); measure. The ORACLE and round 2
; declined (`condition predates a non-diagonal gate`) — an over-decline, not a hazard.
{src}""", twin="eqphiT", src="r3_eqphi")
