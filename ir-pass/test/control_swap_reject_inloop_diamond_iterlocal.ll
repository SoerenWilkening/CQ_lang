; control_swap_reject_inloop_diamond_iterlocal.ll — DECLINE + BROKEN-MODULE
; REGRESSION GUARD (test_C_libtooling-d8jl). The ITERATION-LOCAL sibling of
; control_swap_reject_inloop_diamond.ll: a flat tainted-condition phase diamond
; inside a loop whose gated value is FRESH each iteration (a per-trip `cq_theta`),
; MEASURED in-body, with NOTHING tainted loop-carried (the loop phis `%i`/`%acc`
; are classical). This is the real clang -O1 shape of:
;
;     for (int i = 0; i < n; i++) {
;         int q = cq_theta(x, 0.5);
;         if (q > 5) q = cq_phi(q, b);
;         acc += cq_measure(q);
;     }
;
; WHY THIS IS A REGRESSION GUARD, NOT JUST A DIAGNOSTIC: before the d8jl
; `flatControlInLoop` guard, `detectControlRegions` ACCEPTED this diamond and
; `lowerControlRegions`/`RegionFlatten` ERASED the merge block `%cont` — which is
; the loop LATCH / backedge source — leaving the loop-header phi `%i = phi [0,
; entry], [%inext, <badref>]` dangling. Because nothing tainted is loop-carried,
; NO surviving classical-mux phi remained for `declineClassicalMuxes` to catch,
; so the corruption was NOT contained: `opt` aborted with `PHI node entries do
; not match predecessors! … LLVM ERROR: Broken module found` (SIGABRT, exit 134)
; on VALID clang -O1 input. The guard declines BEFORE any mutation (Rule 9), so
; the CFG is never touched. A regression that re-accepts this would crash `opt`
; (not a clean `not`-wrapper exit) — caught by this fixture.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control
; CHECK-NOT: Broken module
; CHECK-NOT: PHI node entries do not match predecessors
; CHECK-NOT: cqrt_cswap

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
