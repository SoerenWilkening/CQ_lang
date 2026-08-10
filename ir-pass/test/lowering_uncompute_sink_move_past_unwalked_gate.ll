; lowering_uncompute_sink_move_past_unwalked_gate.ll — SAFE LEAK (Phase 5). The
; CLAUSE-(d) fence on the bd 8gi5(3)/e4zs preserving-sink anchors.
;
; THE FALSE STEP IT PINS, in the words it was written in: "moving `At` LATER is the
; safe direction — it can only add reverse-reads that already happened". It can also
; move the reversal past a WRITE.
;
; Clause (d) of the record invariant (bd memory
; [record-freeze-invariant-2026-08-10]) requires every register an adjoint reads to
; hold the value it held WHEN THE FORWARD GATE RAN. Reverse program order delivers
; that only for gates the DAG actually WALKED, and `recoverDataDag` walks operands
; that are in `taint.Tainted` — so an in-place gate on a live but UNTAINTED register
; is invisible to it. Here `%idx` is exactly that: a hand-minted `cqrt_alloc_i32`
; rail the walk never enters, carrying a second `cqrt_ry_i32(%idx, 0.9)` between the
; old insertion point and the one the tape-write anchor moves to.
;
; MEASURED. At HEAD 1ec8c45 this module is CLEAN — the reversal sits before the
; second rotation, `cqrt_qram_load_i32_unc(%L, %arr, %idx)` recomputes from the
; `%idx` its forward load saw, and stage 2b reports `1 verified, 0 violations`. With
; the anchors and no fence, the reversal moves past `ry(%idx, 0.9)`, the `_unc` pops
; the WRONG cell, and `cqrt_free(%L)` is a hidden measurement — stage 2b
; `UNPROVEN T2-operand-mutated`. `opt` exits 0 and `opt -passes=verify` is clean
; either way; only stage 2b and this fixture see it.
;
; THE FENCE. When the sink anchors actually move the insertion point, every register
; the adjoints will read must carry no in-place gate this DAG does not own. The test
; is function-global rather than a span between two blocks — deliberately, because
; span reasoning is what this ticket's history says not to trust, and because the
; conservative direction here is a leak.
;
; THE BOUNDARY CONTROL is a sibling, not a comment: make `%idx` TAINTED (derive it
; from a `cq_theta`) and its rotations become recovered gates, reverse program order
; restores it, and the reversal is emitted and freed normally. That case is covered
; by the shipped QRAM fixtures (lowering_qram_read_*), which still emit their frees —
; MEASURED unchanged across all 240 registered e2e slices and every lit fixture.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=NOFREECLAUSED
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_qram_alloc_i32(i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_tape_write_i32(i32, i32)

define void @sink_move_past_unwalked_gate(i32 %u0) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %arr  = call i32 @cqrt_qram_alloc_i32(i32 %q)
  %idx  = call i32 @cqrt_alloc_i32(i32 7)      ; live, but UNTAINTED — never walked
  call void @cqrt_ry_i32(i32 %idx, double 2.500000e-01)
  %L    = call i32 @cqrt_qram_load_i32(i32 %arr, i32 %idx)
  %tape = call i32 @cqrt_tape_alloc()
  call void @cqrt_ry_i32(i32 %idx, double 9.000000e-01)   ; the unwalked WRITE
  %w    = call i32 @cqrt_tape_write_i32(i32 %tape, i32 %arr)
  ret void
}

; The forward stream survives untouched:
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[IDX:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK:     call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[IDX]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[IDX]], double 9.000000e-01)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[ARR]])

; NOTHING is reversed and NOTHING is freed. Its OWN prefix, one anchor, so both
; negatives run anchor -> EOF (bd memory filecheck-check-not-window-trap;
; `tools/fixture_guard_liveness.py` proves the free guard executes):
; NOFREECLAUSED:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; NOFREECLAUSED-NOT: call void @cqrt_free(
; NOFREECLAUSED-NOT: _unc(
