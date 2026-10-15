; control_angle_select_reject_literal_seed_callee_nomerge.ll — DECLINE (bd
; test_C_libtooling-dm7f.54; the bd 4e4p function-pointer route): a LITERAL-seed
; Ry angle select whose CALLEE is declared `nomerge` but whose CALL SITE is not.
;
;     typedef int (*thf)(int, double); thf f = cq_theta_si32;
;     int r = f(6, b ? .7 : .3);           // measured: the call site lacks nomerge
;
; SimplifyCFG ran on an INDIRECT call (no callee, no attribute), so it may have
; sunk two thetas into this one; `-O1` devirtualized it afterwards. The
; witness `angleSelectLiteralSeedAdmissible` asks is the CALL-SITE attribute
; list (`getAttributes()`), never `hasFnAttr`, which would read the callee's
; `nomerge` and admit this module. The decline keeps the drbq.13 string.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: rotation angle under quantum control

declare i1 @cq_theta_i1(i1, double) #0
declare i32 @cq_theta_si32(i32, double) #0
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 4.000000e-01) #0
  %ang = select i1 %b, double 0x3FE6666666666666, double 3.000000e-01
  %r = call i32 @cq_theta_si32(i32 6, double %ang) #1
  %mr = call i32 @cq_measure_si32(i32 %r)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %zb = zext i1 %mb to i32
  %s = add i32 %mr, %zb
  ret i32 %s
}

attributes #0 = { nomerge nounwind }
attributes #1 = { nounwind }
