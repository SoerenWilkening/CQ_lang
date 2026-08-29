; lowering_reject_inloop_rail_alias_shared_mint.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 round 1). The ADVERSARIAL PROBE that fixes how
; the F1 rail-record fence GROUPS, and the reason it groups by ROOT MINT and not
; by chain.
;
;     q = cq_theta(q, .5);  int a = q, b = q;
;     for (…) { if (a == 5) a = cq_phi(a, PI); a = cq_theta(a, -.5);
;                                              b = cq_theta(b, .25); }
;     return cq_measure(a) + cq_measure(b);
;
; `int a = q, b = q;` is an ALIAS, never a copy (Rule 8 — there is no cloning), so
; `-O1` hands the pass TWO loop-carried header phis whose external incomings are
; the SAME `cq_theta` mint. Each phi on its own is a clean self-cycle rooted at a
; clean mint, and each has exactly ONE forward in-place consumer — so the Rule-8
; fan-out guard (`kMsgRailFanout`) does NOT fire: it counts in-place users PER
; VALUE, and the mint's two users here are the phis, which are not gates.
;
; A per-CHAIN fence would then admit both chains independently and emit
;
;     loop { … ; cqrt_ry_i32(%h, -0.5) ; cqrt_ry_i32(%h, 0.25) } ; measure(%h) ×2
;
; where `%h` is one register: `b`'s Ry relabels the very wire `a`'s record names,
; so `cq_measure(a)` reads a state one rotation past the one the source asks for.
; Grouping by the ROOT MINT — one root is one `cqrt_alloc`, one physical wire —
; merges the two chains and the fence sees it. Round 1 already grouped this way
; (`ByRoot` over `railRoot`); round 2 was changed to match, so the two rounds ask
; ONE predicate rather than two that happen to agree (Rule 14).
;
; THE OTHER DIRECTION IS PINNED TOO, and the pair is the whole point:
; control_swap_inloop_offwire_theta.ll has two registers from TWO DISTINCT mints
; and must keep lowering — merging by anything coarser than the root (say, "one
; fence per loop") would refuse it.
;
; SCOPE NOTE, so the next reader does not read more into this than it says: the
; STRAIGHT-LINE twin (`int a=q,b=q; a=cq_theta(a,-.5); b=cq_theta(b,.25);
; measure(a)+measure(b);`) still lowers to `ry(h,-0.5); ry(h,0.25); measure(h);
; measure(h)` and is NOT touched here. That is the pre-existing wire-alias
; reading, the M-A live-record guard's territory (owner ruling 2026-08-29: a
; leftover-record dephasing WARNS, it does not decline), and changing it is a
; different decision with a different owner.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double %g)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %a = phi i32 [ %q0, %entry ], [ %an, %merge ]        ; alias 1 of the register
  %bb = phi i32 [ %q0, %entry ], [ %bn, %merge ]       ; alias 2 — SAME root mint
  %c1 = icmp eq i32 %a, 5
  br i1 %c1, label %mid, label %merge
mid:
  %ph = call i32 @cq_phi_si32(i32 %a, double %b)
  br label %merge
merge:
  %am = phi i32 [ %ph, %mid ], [ %a, %loop ]
  %an = call i32 @cq_theta_si32(i32 %am, double -5.000000e-01)
  %bn = call i32 @cq_theta_si32(i32 %bb, double 2.500000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %m1 = call i32 @cq_measure_si32(i32 %an)
  %m2 = call i32 @cq_measure_si32(i32 %bn)
  %s = add i32 %m1, %m2
  ret i32 %s
}
