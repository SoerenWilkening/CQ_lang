; lowering_icmp_qq_stale_width_probe.ll — Phase 7.1 Increment A width-changing-
; lineage POSITIVE (the live-width recovery through a re-mint chain).
;
; HEADER HONESTY (downgraded 2026-06-20 after adversarial review): this fixture
; was originally claimed to "pin that the HandleWidth.erase scrub keeps a stale
; entry from selecting a wrong symbol." It does NOT, and cannot. Independent
; review rebuilt the plugin with `HandleWidth.erase(orig)` REMOVED from
; `ArithLowering::promote` and this fixture STILL PASSED — because the Q+Q
; compare looks up the LIVE `%d` (the zext result), and the erased `%d16`'s i16
; entry is never read again. The erase is only load-bearing if LLVM's allocator
; RECYCLES the freed `Value*` address of `%d16` onto a NEW instruction that then
; lands as a compare operand; that address reuse is non-deterministic and cannot
; be forced from a `.ll`. The `HandleWidth.erase(orig)` scrub is therefore
; CORRECT but UN-FIXTURE-PINNABLE defense-in-depth (it mirrors the long-standing
; `Tainted.erase` for exactly the same Value*-reuse hazard class).
;
; WHAT THIS FIXTURE ACTUALLY PINS (a genuine positive): the Q+Q data compare
; recovers the LIVE logical width across a WIDTH-CHANGING lineage —
;   `add i16` (records i16 on its result `%d16`)
;     -> `zext i16 -> i32` (records the NEW width i32 on the zext result `%d`).
; The compare against an i32 theta handle must select `cq_template_icmp_slt_i32`
; (the zext result's CURRENT record), not `_i16` (the pre-zext width). A bug that
; recorded the cast's FROM-width, or re-keyed the add's i16 entry onto the zext
; result, would select `_i16` here — so the pinned `_i32` is a real regression
; anchor for the width-recovery direction (which width the compare reads), even
; though it does not exercise the erase scrub itself.
;
; M-C NOTE (bd test_C_libtooling-6uqc, Increment 2a): the `q + c` here lowers
; IN PLACE to the frozen `cqrt_addc_<W>` — its parent handle has no data use
; after it — so no fresh ancestor rail is minted. Nothing else about what this
; file pins has moved.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call void @cqrt_addc_i16(i32 %{{[a-zA-Z0-9_.]+}}, i16 3)
; CHECK:     call i32 @cq_template_zext_i16_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_icmp_slt_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
;
; The compare must use the LIVE i32 width, NEVER the intermediate i16.
; CHECK-NOT: cq_template_icmp_slt_i16
; CHECK-NOT: = icmp slt

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i16 @cq_theta_si16(i16, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a16 = call i16 @cq_theta_si16(i16 9, double 5.000000e-01)
  ; i16 producer: records i16 on `%d16`.
  %d16 = add i16 %a16, 3
  ; width-changing re-mint: records the LIVE width i32 on `%d` (the zext result).
  %d = zext i16 %d16 to i32
  %b = call i32 @cq_theta_si32(i32 4, double 5.000000e-01)
  ; Q+Q data compare must recover the LIVE i32 (the zext result's record).
  %c = icmp slt i32 %d, %b
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
