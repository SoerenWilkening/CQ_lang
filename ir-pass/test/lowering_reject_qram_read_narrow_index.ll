; lowering_reject_qram_read_narrow_index.ll — DECLINE (3c6m.14 L6 Inc 3,
; Rule-13 clearance hardening pin, LENS-3): a const-global QROM read under
; tainted control whose gep trailing index is a NARROW type (`i8`) used
; directly, into a `[256 x i8]` table. An LLVM gep index is a SIGNED offset
; sign-extended to the pointer-index width, so a sign-bit-set narrow index
; (`i8 0x80`) sign-extends to a NEGATIVE offset — reading before the table —
; and the `and idx, N-1` mask built in the index's own i8 type would be
; `and i8 idx, -1` (a no-op that leaves the sign bit set). The claim predicate
; therefore requires the index to ALREADY be at the pointer-index width (what
; clang -O1 always emits); a narrower index is OVER-DECLINED (safe — Prime
; Directive). This shape is unreachable from clang -O1 (it widens every gep
; index to i64) but the gate closes the latent over-accept in the shared
; predicate. Before the fix this read was accepted UNMASKED (silent OOB on
; negative basis states); now it declines loudly.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@t256 = internal unnamed_addr constant [256 x i8] zeroinitializer
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %idx = trunc i32 %q to i8                ; narrow (i8) gep index — not i64
  %c = icmp slt i32 %q, 100
  br i1 %c, label %arm, label %merge
arm:
  %g = getelementptr inbounds [256 x i8], ptr @t256, i64 0, i8 %idx
  %v = load i8, ptr %g, align 1
  %ve = sext i8 %v to i32
  br label %merge
merge:
  %rm = phi i32 [ %ve, %arm ], [ 99, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; CHECK: error{{.*}}const-global table read under tainted control: index not provably in-bounds
