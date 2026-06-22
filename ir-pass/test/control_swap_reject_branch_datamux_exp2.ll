; control_swap_reject_branch_datamux_exp2.ll — the `exp2` two-base value
; multiplexer: the ONLY `br`-diamond shape of "two independent computed value
; arms, no shared base" that SURVIVES `clang -O1` (Phase 7.2 Inc 1 / 65wb.1).
;
; Owner decision 65wb.5 = conservatively DECLINE (do NOT build the data-mux
; emitter); over-decline is always safe (Prime Directive). This fixture pins
; that decline so it can never silently regress to an accept (Rule 12).
;
; PROVENANCE (§2-D — captured from real clang -O1, never hand-shaped). Source:
;   int slice(int s, int v, int w) {
;     int q = cq_theta(s, 0.5), p = cq_theta(v, 0.25), r = cq_theta(w, 0.125);
;     int t;
;     if (q > 5) { t = ((p+3)*5)^(p<<2); t = (t*7+1)^(t<<3); }
;     else       { t = ((r*9)+11)^(r<<1); t = (t+13)*3^(t<<4); }
;     return cq_measure(t);
;   }
; At `-O1` clang keeps the `br`-diamond (select-count 0, cond-br 1, phi 1) only
; because each arm is a fan-out expression DAG that busts the branch-speculation
; cost budget — a LINEAR two-base early return folds to `select` (already
; 4.4-accepted; see control_swap_reject_value_ifelse_two_bases.ll's note).
;
; WHY IT DECLINES (and where): each arm reconverges to one soleMergePhi (it is
; NOT a non-reconverging exit — §2.10 reserves that string for uncondSucc==null),
; but the arm lineage FANS OUT (%a4 feeds both %a5 and %a7; %b4 feeds %b5/%b7),
; so it is a DAG, not the linear chain whole-chain reversal needs (Rule 8). The
; Rule-8 linearity gate (`valueArmIsPureChain`) fires FIRST — before the two-base
; base-identity check — so the real survivor declines `impure value arm`, not
; `non-routable value multiplexer`. Both are dedicated, loud, source-located
; conservative declines of the same exp2 surface; the message names whichever
; reversibility precondition the arm violates first. REOPENABLE per PRD-7.2
; §2.10/§5 if a real-world `-O1` survivor ever needs lowering.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}impure value arm under quantum control
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @slice(i32 %s, i32 %v, i32 %w) {
entry:
  %q = call i32 @cq_theta_si32(i32 %s, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v, double 2.500000e-01)
  %r = call i32 @cq_theta_si32(i32 %w, double 1.250000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:                                    ; arm over base %p (fan-out DAG)
  %a1 = mul i32 %p, 5
  %a2 = add i32 %a1, 15
  %a3 = shl i32 %p, 2
  %a4 = xor i32 %a2, %a3                  ; %a4 fans out: feeds %a5 AND %a7
  %a5 = mul nsw i32 %a4, 7
  %a6 = add nsw i32 %a5, 1
  %a7 = shl i32 %a4, 3                    ; second consumer of %a4 -> DAG
  %a8 = xor i32 %a6, %a7
  br label %merge
else:                                    ; arm over a DIFFERENT base %r
  %b1 = mul nsw i32 %r, 9
  %b2 = add nsw i32 %b1, 11
  %b3 = shl i32 %r, 1
  %b4 = xor i32 %b2, %b3                  ; %b4 fans out: feeds %b5 AND %b7
  %b5 = mul i32 %b4, 3
  %b6 = add i32 %b5, 39
  %b7 = shl i32 %b4, 4                    ; second consumer of %b4 -> DAG
  %b8 = xor i32 %b6, %b7
  br label %merge
merge:
  %tm = phi i32 [ %a8, %then ], [ %b8, %else ]
  %m  = call i32 @cq_measure_si32(i32 %tm)
  ret i32 %m
}
