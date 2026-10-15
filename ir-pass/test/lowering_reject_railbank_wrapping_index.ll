; lowering_reject_railbank_wrapping_index.ll — DECLINE (bd `test_C_libtooling-xdu2` / L-1a W1).
;
; clause C2′ — the cell index recurrence WRAPS. `{0,+,1}` with start 0 and step 1 is
; injective only MODULO no-self-wrap: an `i8` index over a 300-trip walk revisits
; cell 0 at trip 256, so cells 256…299 are never written and cells 0…43 are written
; TWICE — the second write's SEED load reading a previously-stored HANDLE, which is
; exactly what C2′ exists to prevent.
;
; ⚠ HAND IR, AND WHY. The C spelling (`H17_narrow_index.c`, `for (unsigned char i=0;
; i<200; ++i) b[i] = …`) does NOT reach this conjunct: MEASURED, `clang -O1` WIDENS
; the induction variable and stamps `nuw nsw`, so the recurrence SCEV sees is an i64
; one that provably cannot wrap, and the module classifies `Bank`. The conjunct is
; not dead — it is off the `-O1` floor, like C4's aliasing negative (SCOPE_L1a §8.1)
; and the `isStaticAlloca()` clause (`lowering_reject_railbank_dynamic_object.ll`).
;
; ⚠ THE ISOLATING CONTROL IS A MEASUREMENT, NOT A SECOND FIXTURE, AND IT IS A
; DOCUMENTED RESIDUAL. Adding `nuw nsw` to this module's `%inc = add i8 %i, 1` — and
; changing NOTHING else — flips it to `Bank` (measured on `cq-opt` bc886235…:
; `CQ_CTRL_DBG: railbank [Bank] cells=300 abi=i8 trips=300`), which proves the
; conjunct that fires here is `SCEVAddRecExpr::hasNoSelfWrap()` and not one of its
; neighbours. It is deliberately NOT shipped as an accept fixture, because that
; module is a program whose `nuw` flag is a PROMISE THE PROGRAM BREAKS: `add nuw i8
; 255, 1` is poison, so the input asserts a wrap that its own trip count forces. CQ
; reads the flag and believes it, exactly as every other SCEV consumer in this tree
; does (`hasFiniteClassicalTripBound`, `LoopUnrollPrepass`); pinning that as a
; DESIRED behaviour would be pinning a residual. Filed in `IMPL_A.md` §10 (R-2) as
; the one place a malformed input can still reach a `Bank` verdict.
;
; ⚠ RED-GREEN, AND THE RED HALF IS A BINARY. On the frozen 2026-09-14 ORACLE
; (`cq-opt` sha256 5c6f7490…) this module declines the GENERIC `cq taint escape:
; tainted value stored to memory`; on the shipped subject (bc886235…) it declines
; below.
;
; ⚠ A `DS_Error` decline writes ZERO BYTES TO STDOUT (Rule 12 hygiene (b)); the
; property is pinned by the `not` on the RUN line, the exact message and the
; `--implicit-check-not` proving the `Bank` anchor is GONE.
;
;
; ⚠ bd `test_C_libtooling-01po.19` S1-S3 (2026-10-15, owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15` and
; `owner-ruling-01po19-rolled-design-2026-10-15`): the rolled WINDOW model
; (RailWindow.h) now claims this array, because it is a well-formed quantum array
; the one-store rail bank does not own. The rail-bank clause this file used to
; decline on protects the one-store model only; the window model replaces it, and
; until S4-S7 land the array declines with the list of steps it still needs
; (DECLINE -> DECLINE; the message below is mirrored character-for-character).
; RETIREMENT TRIGGER: each of S4-S7 that lands drops its name from the list; when
; the list empties this file becomes an ACCEPT with an analytic trace check.

; ⚠ bd `test_C_libtooling-01po.19` S4 (2026-10-15): DECLINE -> ACCEPT. The window
; model now LOWERS this array (RailWindow.h: handle array materialized at the
; quantization point, cell reads are borrowed roots, a cell rail is never freed
; or reverse-played). Reviewed by trace, not by green:
; the i8 GEP index is SIGN-extended by GEP semantics, so trips 128..299 address before the object (poison in this hand IR, UB); the window redirect reproduces that address computation exactly (sext) and adds no fact of its own. Each in-bounds visit is an in-place Ry on the cell rail.
; The S4 prefix pins the whole emitted runtime stream and that no rail is freed.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not=cqrt_free --implicit-check-not='error:'
; S4-LABEL: define {{.*}} @slice(
; S4: %b.rails = alloca i32, i64 300, align 4, !cq.railwindow !0
; S4: %h = call i32 @cqrt_alloc_i1(i1 %1)
; S4: %seed.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %seed.rail, double 5.000000e-01)
; S4: store i32 %seed.rail, ptr %cq.rail.addr, align 4

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i64 %n) {
entry:
  %b = alloca [300 x i8], align 1
  call void @llvm.memset.p0.i64(ptr %b, i8 0, i64 300, i1 false)
  br label %walk

walk:
  %i = phi i8 [ 0, %entry ], [ %inc, %walk ]
  %c = phi i64 [ 0, %entry ], [ %cnext, %walk ]
  %g = getelementptr inbounds [300 x i8], ptr %b, i64 0, i8 %i
  %seed = load i8, ptr %g, align 1
  %t = trunc nuw i8 %seed to i1
  %q = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %z = zext i1 %q to i8
  store i8 %z, ptr %g, align 1
  %inc = add i8 %i, 1
  %cnext = add nuw nsw i64 %c, 1
  %done = icmp eq i64 %cnext, 300
  br i1 %done, label %exit, label %walk

exit:
  ret i32 0
}
declare i1 @cq_theta_i1(i1, double)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
