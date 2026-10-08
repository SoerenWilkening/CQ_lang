; dm7f.16.1 R11 round 3: an intrinsic declaration cannot prove a call-site range.
; ctpop can return 1..32. The false range makes that result poison; returning it
; as noundef causes immediate UB. An untaken source arm stays defined.
; ⚠ (review 2026-10-08) TWO clauses refuse this call, so it cannot pin either alone:
; `intrinsicContractHolds`' return-attribute clause, and `canCreateUndefOrPoison`, which
; in LLVM 19 counts return attributes as poison-generating. Deleting one is MISSED.
; For a SCALAR return every non-inert return attribute is poison-generating, so the
; first clause is redundant there; it pins the conjunction only.
; RUN: not %cq-opt -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.ctpop.i32(i32)
define noundef i32 @outer(i32 %x) noinline {
  %v = call range(i32 0, 1) i32 @llvm.ctpop.i32(i32 %x)
  ret i32 %v
}
define i32 @probe(i32 %seed, i32 noundef %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %seed, double 0.5)
  %qc = icmp sgt i32 %q, 0
  br i1 %qc, label %inner, label %merge
inner:
  %cc = icmp sgt i32 %n, 0
  br i1 %cc, label %arm, label %merge
arm:
  %v = call i32 @outer(i32 %n)
  %r = add i32 %q, %v
  br label %merge
merge:
  %out = phi i32 [ %r, %arm ], [ %q, %inner ], [ 5, %entry ]
  %m = call i32 @cq_measure_si32(i32 %out)
  ret i32 %m
}
