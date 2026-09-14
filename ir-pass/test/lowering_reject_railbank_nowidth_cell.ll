; lowering_reject_railbank_nowidth_cell.ll — DECLINE (bd `test_C_libtooling-xdu2` / L-1a W1).
;
; clause C3, the OTHER half of the width axis — a cell type for which
; `abiWidthFromType` returns "" (NO width at all), as opposed to the `f64` cell of
; `lowering_reject_railbank_fp_cell.ll`, which HAS a width and no reversible copy.
; The two files together pin that the clause is `abiWidthFromType(T).empty() ||
; !widthHasReversibleCopy(...)` and NEVER `.empty()` alone — the trap
; `OpcodeSupport.h` states in writing for i128.
;
; ⚠ HAND IR, AND WHY. `_BitInt(96)` is NOT reachable on the `clang -O1` floor for
; this clause: `CQ.h`'s `cq_theta` is a 14-type `_Generic`, and a `_BitInt(96)`
; controlling expression is a COMPILE ERROR ("not compatible with any generic
; association type") — measured, not assumed. So the i96 rail is minted the only way
; a real program could mint one, by widening a supported rail: a `cq_theta_si32`
; result `zext`ed to i96 and stored into an `[3 x i96]` bank. The `zext` is a
; `CastInst` and rides the escape guard's known-consumer skip, so the STORE is still
; the first instruction to decline — which is what this fixture measures.
;
; ⚠ ALSO PINNED HERE BY CONSTRUCTION: the bank has NO initializer at all, which is
; OWNER RULING D1's admitted shape. If D1 were ever reverted, this module would
; decline at C1 instead and the C3 clause would go UNPINNED while the fixture stayed
; green — so its verdict is the `_nowidth_cell` string and nothing else, checked
; character-for-character.
;
; ⚠ RED-GREEN, AND THE RED HALF IS A BINARY. On the frozen 2026-09-14 ORACLE
; (`cq-opt` sha256 5c6f7490…) this module declines the GENERIC `cq taint escape:
; tainted value stored to memory`; on the subject (bc886235…) it declines the
; per-clause string below.
;
; ⚠ A `DS_Error` decline writes ZERO BYTES TO STDOUT, so an IR-text `CHECK-NOT` here
; would be VACUOUS (Rule 12 hygiene (b)); the property is pinned by the `not` on the
; RUN line plus the exact message. `LLVMContext::diagnose` EXITS on the first
; `DS_Error` (bd `br4a`) — ONE diagnostic, never two.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq rail bank: array element is not a reversible rail cell
; CHECK-NOT: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice() {
entry:
  %b = alloca [3 x i96], align 16
  br label %loop

loop:                                             ; preds = %loop, %entry
  %i = phi i64 [ 0, %entry ], [ %inc, %loop ]
  %g = getelementptr inbounds [3 x i96], ptr %b, i64 0, i64 %i
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %w = zext i32 %q to i96
  store i96 %w, ptr %g, align 16
  %inc = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %inc, 3
  br i1 %done, label %out, label %loop

out:                                              ; preds = %loop
  ret i32 0
}

declare i32 @cq_theta_si32(i32, double)
