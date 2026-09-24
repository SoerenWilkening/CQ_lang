; lowering_reject_railbank_seed_forged.ll — DECLINE (bd test_C_libtooling-xdu2.4, Rule-13 finding 4).
; 
; `!cq.railbank.seed` is compiler-owned provenance minted by the rail-bank promoter
; for a conditional runtime-i32 preparation. Here it is FORGED on a hand-written
; `cqrt_alloc_i32(0)` whose handle ALSO feeds host arithmetic (`%bad`). Before the
; reserved-name fence this accepted at exit 0 with `add i32 %seed, 1` on a rail
; handle in the lowered IR. clang never emits the marker, so its presence in the
; input is a loud decline before the promoter runs.
; ⚠ A DS_Error decline writes 0 bytes to stdout, so the property is pinned by the `not` inversion; there are no IR-text CHECK-NOTs by design (Rule 12 (b)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq rail bank: reserved compiler-owned seed marker present in input
; CHECK-NOT: tainted value stored to memory

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cqrt_alloc_i32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 0), !cq.railbank.seed !0
  %bad = add i32 %seed, 1
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %seed, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %seed, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mbad = call i32 @cq_measure_si32(i32 %bad)
  %s0 = add i32 %mq, %mr
  %s = add i32 %s0, %mbad
  ret i32 %s
}

!0 = !{}
