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
; changing NOTHING else — flips it to `Bank` (measured on `cq-opt` f2a9c0a4…:
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
; tainted value stored to memory`; on the shipped subject (f2a9c0a4…) it declines
; below.
;
; ⚠ A `DS_Error` decline writes ZERO BYTES TO STDOUT (Rule 12 hygiene (b)); the
; property is pinned by the `not` on the RUN line, the exact message and the
; `--implicit-check-not` proving the `Bank` anchor is GONE.
;
; RUN: env CQ_CTRL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='railbank [Bank]'
; CHECK: cq rail bank: cell index is not an injective per-iteration index
; CHECK-NOT: tainted value stored to memory

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
