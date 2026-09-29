; spec_reject_callbr.ll — Phase 6.1 WI-1.3b: a tainted-arg `callbr` (a `CallBase`
; that is not a `CallInst`) is excluded by the same `dyn_cast<CallInst>`
; narrowing as `invoke`, so it never enters `plan6` and STILL fires
; `kMsgUnknownCallee`. (A valid `callbr` is asm-goto — its "callee" is inline
; asm; the point is the `CallBrInst` exclusion, like `InvokeInst`.)
;
;
; ── MERGED 2026-09-29 (bd test_C_libtooling-2dfk, exact-duplicate removal) ──
; `spec_overaccept_probe_callbr_visible.ll` was DELETED: it was this module with this
; file's RUN and CHECK lines byte-for-byte (every non-comment line and every
; directive identical, so it re-ran this exact test). Why: the probe (14663ad5, 2026-06-19) re-registered the exact module and RUN/CHECK lines of this older fixture (54f07819, 2026-06-18).
; Its unique header prose follows VERBATIM, because it carries the history (and
; any retirement trigger) of the shape it once pinned:
;
; │ spec_overaccept_probe_callbr_visible.ll — Phase 6.4 WI-4.3 over-accept probe.
; │ A `callbr` (asm-goto) is a `CallBase` that is not a `CallInst`, excluded by the
; │ same `dyn_cast<CallInst>` SHAPE narrowing as `invoke`. Its tainted operand never
; │ enters `plan6` and STILL fires `kMsgUnknownCallee`. Guards the `CallBrInst`
; │ exclusion against a future weakening that handles arbitrary `CallBase`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  callbr void asm sideeffect "", "r,!i"(i32 %q) to label %ok [label %bad]
ok:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
bad:
  ret i32 0
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
