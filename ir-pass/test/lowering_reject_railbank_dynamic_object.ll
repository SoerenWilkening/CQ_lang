; lowering_reject_railbank_dynamic_object.ll — DECLINE (bd `test_C_libtooling-xdu2` / L-1a W1).
;
; clause C1 — the bank object is NOT a single function-lifetime allocation: the
; `alloca` sits in a LOOP BODY, so each outer trip allocates a fresh object and "the
; bank" is not one object at all. Every per-cell statement C2′ and C6 make is about
; ONE object, so none of them means anything here.
;
; ⚠ HAND IR, AND WHY — the C spelling of this program (`H13_alloca_in_loop.c`:
; `for (k<2) { bool b[3] = {0}; … }`) is NOT this shape on the validated floor.
; MEASURED: `clang -O1` HOISTS the alloca to the entry block and reuses the object,
; so the C program becomes byte-for-byte the `H1_nested_outer_rewrite.c` shape and
; declines at `lowering_reject_railbank_nested_walk.ll`'s clause instead. The
; `isStaticAlloca()` conjunct is therefore not reachable from C — it is not dead
; code, it is OFF THE `-O1` FLOOR, and hand IR is the only instrument that reaches
; it. (SCOPE_L1a §8.1 records the same limit for C4's aliasing negative.)
;
; ⚠ WHY THE CONJUNCT IS KEPT EVEN THOUGH `-O1` NEVER PRODUCES ITS SUBJECT. The pass
; is a MODULE plugin: its input is whatever `opt` is handed, and the tree's own
; fixtures are hand IR more often than not. `walkPtrOrigin`'s `isArrayAllocation()`
; clause covers the VLA half of "not a static object" and says nothing about the
; ENTRY-BLOCK half; `isStaticAlloca()` is exactly both halves, which is why the
; clause is spelled with it rather than with a second `isArrayAllocation()` test.
;
; ⚠ RED-GREEN, AND THE RED HALF IS A BINARY. On the frozen 2026-09-14 ORACLE
; (`cq-opt` sha256 5c6f7490…) this module declines the GENERIC `cq taint escape:
; tainted value stored to memory`; on the shipped subject (f2a9c0a4…) it declines
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
; CHECK: cq rail bank: array object is not a single function-lifetime allocation
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
