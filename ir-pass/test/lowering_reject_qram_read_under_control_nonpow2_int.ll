; lowering_reject_qram_read_under_control_nonpow2_int.ll — DECLINE (3c6m.14 L6
; Inc 3, Rule-13 coverage pin): the integer-DATA twin of
; lowering_reject_qram_read_under_control_nonpow2.ll (which pins the fp-DATA
; `[3 x double]` case). A `[3 x i32]` const table read under tainted control
; whose index is not provably in-bounds and whose size is not a power of two:
; no known-bits proof and no sound mask, so it declines with the precise Inc-3
; bounds signpost (the message keys on index/size, NOT element type — this
; pins that an INT cell decline says the same thing).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@t3i = internal unnamed_addr constant [3 x i32] [i32 7, i32 9, i32 11]
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp slt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %i = sext i32 %q to i64                  ; unprovable index
  %g = getelementptr inbounds [3 x i32], ptr @t3i, i64 0, i64 %i
  %v = load i32, ptr %g, align 4
  br label %merge
merge:
  %rm = phi i32 [ %v, %arm ], [ 99, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; CHECK: error{{.*}}cq QRAM access: const-global table read under tainted control: index not provably in-bounds (no known-bits proof; table size not a power of two)
