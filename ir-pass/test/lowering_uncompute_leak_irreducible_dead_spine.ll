; lowering_uncompute_leak_irreducible_dead_spine.ll — LOUD DECLINE (Phase 5
; §2.9). RE-DISPOSITIONED from SILENT LEAK to LOUD DECLINE by bd
; test_C_libtooling-4p7j's Rule-13 RE-review (finding G1); the file keeps its
; name because it keeps its SHAPE and its history, and the history is the point.
;
; THE DEFECT IT WAS WRITTEN FOR. `%h_op` is minted once in `entry`;
; `cqrt_addc_i32(%h_op, 7)` sits in `%A`, which executes K >= 1 times
; (`entry -> A -> B -> A -> …`). `%h_op` is a DEAD TERMINAL (its only other user
; was a diagonal `cqrt_rz`, deleted by the 3qlq migration), so the whole-DAG spine
; recovered {mul, addc, rz} and reversed them ONCE in `%exit`:
;
;     cqrt_rz_i32(%h_op, -1.0); cqrt_addc_i32(%h_op, -7)      ; ONE adjoint …
;     cq_template_mul_i32_hl_unc(%h_op, %h, 5); cqrt_free(%h_op)
;     cqrt_ry_i32(%h, -0.5); cqrt_free(%h)                    ; … for K addcs
;
; `opt` rc=0 and verify-clean. For K > 1 the freed rail holds `5h + 7(K-1)`, so
; both `cqrt_free`s were resets of non-|0> rails — hidden measurements (Rule 6).
; Root cause: the §2.9 acyclic backstop asked `LoopInfo::getLoopFor` per
; recovered gate, and `%A`/`%B` form an IRREDUCIBLE cycle (two entries, no
; dominating header) that `LoopInfo` does not see.
;
; WHY THE DISPOSITION CHANGED, AND WHY THE CHANGE IS THE FIX RATHER THAN A
; REGRESSION. The 4p7j fix round moved the spine's per-gate backstop onto
; `blockCanRepeat` (a reachable-from-itself DFS, a strict superset of the
; natural-loop test), which stopped the miscompile — by LEAKING, matching what
; the backstop already did for a natural-loop gate. That left the project with
; ONE hazard and TWO answers: `FreePoint`'s `kMsgLoopBackedge` guard — the
; LOUDNESS owner for a backedge-crossing live range — was still on `LoopInfo`,
; so the NATURAL-loop spelling of this exact program declined loudly while the
; IRREDUCIBLE spelling lowered silently. `FreePoint::blockInLoop` is now
; `LoopInfo || blockCanRepeat` and both spellings decline loudly. Loud is the
; safe direction and it is the answer the tree already gave for a natural loop
; (`lowering_uncompute_loop_backedge.ll`); its irreducible twin over the SAME
; program shape is `lowering_uncompute_loop_backedge_irreducible.ll`.
;
; DISPOSITION: LOUD DECLINE. `FreePoint` owns the exact string; this CHECK
; mirrors it character-for-character. Nothing is lowered, `opt` exits non-zero.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq uncompute: tainted handle live range crosses a loop backedge
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare void @cqrt_addc_i32(i32, i32)

define void @dead_spine_irreducible(i32 %u0, i1 %c0, i1 %c1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = mul i32 %q, 5
  br i1 %c0, label %A, label %B
A:                                        ; preds = %entry, %B — irreducible
  call void @cqrt_addc_i32(i32 %r, i32 7)
  br i1 %c1, label %B, label %exit
B:                                        ; preds = %entry, %A
  br label %A
exit:
  ret void
}
