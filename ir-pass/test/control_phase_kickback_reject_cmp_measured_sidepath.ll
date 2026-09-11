; control_phase_kickback_reject_cmp_measured_sidepath.ll — DECLINE (Track A.1,
; bd test_C_libtooling-r903 item (b)): the `br`-path twin of
; `control_swap_reject_select_cmp_measured_sidepath.ll`. The measurement is on a
; classically guarded side path that REACHES the branch, so it neither precedes
; the branch positionally nor dominates it — and on that path the flag is minted
; from a collapsed register. VERBATIM `clang -O1` (probe
; `d4_kick_cmp_measured_sidepath.c`), ACCEPT on `main` 0c7380c.

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ext(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %g = call i32 @ext(i32 1)
  %gz = icmp eq i32 %g, 0
  br i1 %gz, label %join, label %side

side:
  %m = call i32 @cq_measure_si32(i32 %q)
  br label %join

join:
  %s = phi i32 [ %m, %side ], [ 0, %entry ]
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %ph, label %done

ph:
  call void @cq_phi(double 3.000000e-01)
  br label %done

done:
  ret i32 %s
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
