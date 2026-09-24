; lowering_reject_railbank_dynamic_object.ll — DECLINE (bd `test_C_libtooling-xdu2` / L-1a W1).
;
; Increment C boundary — the `alloca` sits in a LOOP BODY, so each outer trip
; allocates a fresh bank activation. That is physically valid, but the current
; bookkeeping cannot yet keep each activation's rail identities distinct or prove
; Rule-6 cleanup for every exit. It is an implementation over-decline, not a
; physics-based prohibition.
;
; ⚠ HAND IR, AND WHY — the C spelling of this program (`H13_alloca_in_loop.c`:
; `for (k<2) { bool b[3] = {0}; … }`) does not preserve this exact shape on the
; validated floor: clang -O1 hoists and reuses that fixed object. Hand IR therefore
; remains the direct instrument for the fresh-per-trip shape. But the old blanket
; claim that the non-entry gate was unreachable from C was false: Grover's
; constant-folded source VLA produces a fixed alloca after a preceding loop. xdu2.4
; now admits that acyclic non-entry allocation.
;
; ⚠ WHY THE CONJUNCT REMAINS WHILE INCREMENT C IS PENDING. The pass is a MODULE
; plugin, so its input is whatever `opt` is handed, including this valid fresh-bank
; shape. The replacement asks the actual implementation question: can the
; allocation's block cycle back and execute it again? Acyclic non-entry and
; runtime-sized stack banks pass this clause; this enclosing-cycle fixture does not.
;
; RETIREMENT TRIGGER: increment C may accept this only after the promoter models a
; fresh bank per outer activation, prevents cross-activation handle reuse, and
; discharges Rule 6 on every cleanup/exit path.
;
; ⚠ RED-GREEN, AND THE RED HALF IS A BINARY. On the frozen 2026-09-14 ORACLE
; (`cq-opt` sha256 5c6f7490…) this module declines the GENERIC `cq taint escape:
; tainted value stored to memory`; on the shipped subject (bc886235…) it declines
; below. On the FIRST subject (53d1a4b6…), before the conjunct existed, it
; classified `Bank`.
;
; ⚠ A `DS_Error` decline writes ZERO BYTES TO STDOUT (Rule 12 hygiene (b)); the
; property is pinned by the `not` on the RUN line, the exact message and the
; `--implicit-check-not` proving the `Bank` anchor is GONE. `LLVMContext::diagnose`
; EXITS on the first `DS_Error` (bd `br4a`) — ONE diagnostic.
;
; RUN: env CQ_CTRL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='railbank [Bank]'
; CHECK: cq rail bank: array allocation is re-executed by an enclosing cycle
; CHECK-NOT: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice() {
entry:
  br label %outer

outer:                                            ; preds = %done, %entry
  %k = phi i64 [ 0, %entry ], [ %knext, %done ]
  ; ⚠ NOT in the entry block: a fresh bank object per outer trip.
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr %b, i8 0, i64 3, i1 false)
  br label %walk

walk:                                             ; preds = %walk, %outer
  %i = phi i64 [ 0, %outer ], [ %inext, %walk ]
  %g = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %seed = load i8, ptr %g, align 1
  %t = trunc nuw i8 %seed to i1
  %q = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %z = zext i1 %q to i8
  store i8 %z, ptr %g, align 1
  %inext = add nuw nsw i64 %i, 1
  %idone = icmp eq i64 %inext, 3
  br i1 %idone, label %done, label %walk

done:                                             ; preds = %walk
  %knext = add nuw nsw i64 %k, 1
  %kdone = icmp eq i64 %knext, 2
  br i1 %kdone, label %exit, label %outer

exit:                                             ; preds = %done
  ret i32 0
}

declare i1 @cq_theta_i1(i1, double)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
