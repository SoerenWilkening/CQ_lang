; control_swap_inloop_diamond_iterlocal.ll — ACCEPT (bd test_C_libtooling-8h7d.5,
; Phase 7.3 Increment 3). The ITERATION-LOCAL sibling of
; control_swap_inloop_diamond.ll: a flat tainted-condition phase diamond inside a
; classically-bounded loop whose gated value is FRESH each iteration (a per-trip
; `cq_theta`), MEASURED in-body, with NOTHING tainted loop-carried (`%i`/`%acc`
; are classical). The real clang -O1 shape of:
;
;     for (int i = 0; i < n; i++) {
;         int q = cq_theta(x, 0.5);
;         if (q > 5) q = cq_phi(q, b);
;         acc += cq_measure(q);
;     }
;
; THIS FILE WAS A DECLINE + BROKEN-MODULE REGRESSION GUARD UNTIL 2026-08-29, and
; the second half of that job is UNCHANGED — read this carefully before touching
; it. Before the d8jl guard, `RegionFlatten` erased the merge `%cont` (the loop
; LATCH) and left `%i = phi [0, entry], [%inext, <badref>]` dangling: `opt`
; aborted with `PHI node entries do not match predecessors! … Broken module`
; (SIGABRT, exit 134) on VALID clang -O1 input, and because nothing tainted is
; loop-carried there was no surviving classical-mux phi to contain it.
;
; The flatten REPAIRS that today — `Pred->replaceSuccessorsPhiUsesWith(Merge,
; Pred)` (bd dugh, 2026-07-04, added AFTER d8jl was written) repoints exactly
; that incoming, and `%loop` becomes its own latch. So the fixture keeps its
; CHECK-NOTs: a regression that breaks the repair does not fail with a clean
; `not`-wrapper exit, it CRASHES `opt` — and the `Broken module` /
; `PHI node entries` guards below are what turn that into a readable failure.
;
; `%h` is minted fresh EVERY iteration and MEASURED in-body, so it is the
; measurement's to own: never freed by the compiler (Rule 6), exactly as in the
; hand-unrolled spelling.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %x, double %b, i32 %n) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %cont ]       ; classical induction
  %acc = phi i32 [ 0, %entry ], [ %accn, %cont ]      ; classical accumulator
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)  ; FRESH each iter
  %c = icmp sgt i32 %q, 5                             ; TAINTED (quantum) condition
  br i1 %c, label %arm, label %cont
arm:
  %g = call i32 @cq_phi_si32(i32 %q, double %b)
  br label %cont
cont:
  %qm = phi i32 [ %g, %arm ], [ %q, %loop ]           ; iteration-local merge
  %m = call i32 @cq_measure_si32(i32 %qm)             ; measured in-body
  %accn = add i32 %acc, %m
  %inext = add i32 %i, 1
  %done = icmp slt i32 %inext, %n                      ; classical loop bound
  br i1 %done, label %loop, label %exit
exit:
  ret i32 %acc
}

; ONE rolled stream inside the intact loop; the classical phis kept their
; predecessor (the flatten repointed `%cont` -> `%loop`):
; CHECK:     loop:
; CHECK:     %{{.*}} = phi i32 [ 0, %entry ], [ %{{.*}}, %loop ]
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[R]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R]], double %b)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[R]])
; CHECK:     call void @cqrt_free(i32 %[[R]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK:     br i1 %{{.*}}, label %loop, label %exit
;
; THE REGRESSION GUARD, unchanged in intent: a flatten that stops repairing the
; header phi crashes `opt` rather than failing cleanly.
; CHECK-NOT: Broken module
; CHECK-NOT: PHI node entries do not match predecessors
