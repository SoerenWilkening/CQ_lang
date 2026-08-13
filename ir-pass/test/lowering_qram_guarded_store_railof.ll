; lowering_qram_guarded_store_railof.ll — ACCEPT (Phase 7.5). THE `railOf`
; ATTRIBUTION fixture for the guarded QRAM store (bd test_C_libtooling-uow0).
;
; `cqrt_qram_store_<W>_controlled(flag, arr, idx, val)` WRITES its arg-1 array. The
; plain store `cqrt_qram_store_<W>(arr, idx, val)` writes arg 0. `railOf` used to
; return arg 0 for BOTH — so on the guarded form it named the path-predicate FLAG,
; a register the gate only READS, while `isInPlaceGateOn` matched the arg-1 array of
; that same gate correctly. Two predicates, one gate, opposite answers; `railOf` is
; now DERIVED from `isInPlaceGateOn` so they cannot disagree again.
;
; WHAT THE MIS-ATTRIBUTION COST. `emitDagReversal` keys each rail's `cqrt_free` to
; the adjoint of that rail's EARLIEST forward gate (`Earliest`). Naming the flag as
; the store's rail put the STORE into the flag's gate list, so a flag with no
; earlier gate of its own had its free anchored to a gate that never wrote it.
;
; HAND-WRITTEN PROBE, deliberately, and the reason is worth stating because it is
; also this fix's honest blast radius: on EMITTER-produced IR the mis-attribution is
; INERT, and that was MEASURED, not assumed — the fixed pass is byte-identical to
; the old one across all 240 registered e2e slices and all ~1000 lit fixtures. The
; emitter always mints the flag as a `cq_template_icmp_*` producer that DOMINATES
; the store, so the flag's own mint always won `Earliest` first and the store's
; bogus entry was never consulted. The defect needs a flag whose first real gate
; does NOT precede the store, which no emitter mints today and hand-written IR does
; (every `cqrt_*` callee is carved out of `declineTaintEscapes`, so the pass accepts
; it). Pin it before an emitter reaches it — a fixture that can only fail on shapes
; we already ship is a fixture that proves nothing.
;
; MEASURED on the pre-fix pass, both defects at once: it emits `cqrt_free(%z)` on
; the FLAG — a rail whose forward chain the reversal never touched and which the
; trailing `cqrt_ry_i32(%z, 0.75)` leaves off |0>, so the free is a hidden
; measurement (Rules 5/6) — and it lands BEFORE that rotation, which
; `free_pairing_check.py` independently reports as
; `VIOLATION F2-use-after-free ... @cqrt_ry_i32 uses %z after its cqrt_free`.
; Post-fix the free is gone and stage 2b is clean (1 site, 1 verified).
;
; The flag is LEFT ALLOCATED, not freed: Rule 6's fallback for a rail that is not
; provably |0> is a leak, never a dirty free. No measurement is inserted (Rule 5).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEFLAG < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_qram_store_i32_controlled(i32, i32, i32, i32)

define void @guarded_railof(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %z = call i32 @cqrt_alloc_i32(i32 0)
  ; The tainted rail %q sits in the ARRAY slot (arg 1) — the register this gate
  ; mutates — and the independently minted %z sits in the FLAG slot (arg 0), which
  ; the gate only reads.
  call void @cqrt_qram_store_i32_controlled(i32 %z, i32 %q, i32 3, i32 4)
  ; A rotation on the flag AFTER the store: it is what makes the pre-fix free both
  ; a dirty free and a use-after-free, and it is why the flag's earliest own gate
  ; does not precede the store.
  call void @cqrt_ry_i32(i32 %z, double 7.500000e-01)
  ret void
}

; Forward stream, then the whole-DAG reversal. The store's `_unc` fires with the
; flag still LIVE (the pred-lifetime invariant), and the ARRAY-slot rail %H — the
; register the gate actually writes — reverses and frees. That free is the
; discrimination control: the fix re-attributes a rail, it does not suppress frees.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_qram_store_i32_controlled(i32 %[[Z]], i32 %[[H]], i32 3, i32 4)
; CHECK:     call void @cqrt_qram_store_i32_controlled_unc(i32 %[[Z]], i32 %[[H]], i32 3, i32 4)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
; CHECK-NOT: cqrt_measure

; The FLAG slot's rail is never freed, anywhere in the module. Its own prefix with a
; single anchor, so the window runs anchor -> EOF (a `CHECK-NOT` is bounded by the
; next positive directive OF ITS OWN PREFIX; `tools/fixture_guard_liveness.py`
; proves this one executes by injecting the exact free the pre-fix pass emitted):
; NOFREEFLAG:     %[[Z2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; NOFREEFLAG-NOT: call void @cqrt_free(i32 %[[Z2]])
