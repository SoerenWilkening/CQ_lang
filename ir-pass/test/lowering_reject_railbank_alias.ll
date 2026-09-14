; lowering_reject_railbank_alias.ll — DECLINE (bd `test_C_libtooling-xdu2` / L-1a W1).
;
; clause C4 — ALIASING FAN-OUT: the cell address has a user that is not a simple
; load/store of the cell type through that address. Here it is a `ptrtoint`, i.e.
; the address of one rail cell becomes a VALUE.
;
; ⚠ HAND IR, AND WHY — SCOPE_L1a §8.1 states it as a measured limit of a scoping
; agent's instrument: "C4's aliasing negative has no `-O1`-floor spelling … `-O1`
; CSEs or sinks every two-user GEP I tried." That remains true and this file is the
; consequence, not a shortcut. The SIBLING clause that IS reachable from C — a
; SECOND STORE SITE into one bank — is `lowering_reject_railbank_two_stores.ll`,
; built from real `clang -O1` output; the two share the `RejectAlias` verdict and
; carry DIFFERENT messages so neither can go green for the other's reason.
;
; ⚠ WHAT THIS FIXTURE IS NOT. It is NOT a re-statement of `matchQramAccess`'s
; `GEP->hasOneUse()`. That conjunct answers the TAINTED-INDEX aliasing question (two
; superposed addresses the tape cannot keep coherent) and would also refuse the rail
; bank's own read-modify-write cell address — which C4 DELIBERATELY ADMITS, and which
; `lowering_railbank_bank_anchor_n3.ll` pins as a `Bank`. The two fixtures are the
; two sides of that deviation; changing either without the other is the finding.
;
; ⚠ RED-GREEN, AND THE RED HALF IS A BINARY. On the frozen 2026-09-14 ORACLE
; (`cq-opt` sha256 5c6f7490…) this module declines the GENERIC `cq taint escape:
; tainted value stored to memory`; on the subject (f2a9c0a4…) it declines below.
;
; ⚠ A `DS_Error` decline writes ZERO BYTES TO STDOUT (Rule 12 hygiene (b)); the
; property is pinned by the `not` on the RUN line plus the exact message, and
; `LLVMContext::diagnose` EXITS on the first one (bd `br4a`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq rail bank: cell address has aliasing fan-out
; CHECK-NOT: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(ptr %out) {
entry:
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr %b, i8 0, i64 3, i1 false)
  br label %loop

loop:                                             ; preds = %loop, %entry
  %i = phi i64 [ 0, %entry ], [ %inc, %loop ]
  %g = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %seed = load i8, ptr %g, align 1
  %t = trunc nuw i8 %seed to i1
  %q = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %z = zext i1 %q to i8
  store i8 %z, ptr %g, align 1
  %addr = ptrtoint ptr %g to i64
  store i64 %addr, ptr %out, align 8
  %inc = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %inc, 3
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %loop
  ret i32 0
}

declare i1 @cq_theta_i1(i1, double)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
