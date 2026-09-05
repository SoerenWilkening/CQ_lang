; lowering_fp80_accept_blockaddress_markalive_live.ll — ACCEPT (bd 7udx).
; ARM: the reach control for lowering_fp80_reject_blockaddress_markalive.ll, and the
; proof that `removeUnreachableBlocksChecked` does not simply refuse every
; address-taken block in a function it touches.
;
; ONE token differs from that fixture: the UB `store i32 0, ptr null` becomes a
; store to a real global. So `markAliveBlocks` finds nothing to kill, `%live_ba`
; stays reachable and SURVIVES, and its `blockaddress` must come through intact —
; never the `inttoptr (i32 1 to ptr)` placeholder.
;
; GREEN ON BOTH the pre-change and post-change plugins, by design, so it does not
; appear in the differential; its power is arm-kill (make the guard refuse on
; `hasAddressTaken()` alone, or check the whole function up front, and it goes red).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; CHECK: store ptr blockaddress(@f, %live_ba), ptr @slot
;
; A NOT-only prefix so it scans the WHOLE input for the corrupted form:
; RUN: %filecheck %s --check-prefix=NOCORRUPT < %t.cqd0.ll
; NOCORRUPT-NOT: inttoptr (i32 1 to ptr)
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

@slot = global ptr null
@sink = global i32 0

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %foldme = add i32 1, 2
  store i32 %foldme, ptr @sink, align 4
  %cc = icmp eq i32 %u0, 999
  br i1 %cc, label %ub, label %qhead

ub:
  store i32 0, ptr @sink, align 4
  br label %live_ba

live_ba:
  br label %qhead

qhead:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge

arm:
  call void @cq_phi(double %a)
  br label %merge

merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

define void @cq_ba_holder() {
  store ptr blockaddress(@f, %live_ba), ptr @slot, align 8
  ret void
}
