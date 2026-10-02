; lowering_uncompute_compare_icmp.ll — Phase 6 WI-0 ACCEPT (§6.0; the compare
; `_unc` grid). A DEAD, source-derived, tainted DATA-position integer compare
; (`icmp` — ordinary C `int w = (q < 5)`) reaching the whole-DAG uncompute spine.
;
; The compare lowers to a `cq_template_icmp_slt_i32_hl` flag-handle producer.
; PRE-WI-0 the uncompute axis was binary + unary + cast ONLY — compares had NO
; `_unc` grid (tools/opcode_table.yaml), and `EmitInverse` declined a recovered
; compare gate as un-invertible (the WI-7 over-decline that PINNED this fixture to
; `kMsgUninvertible`). WI-0 adds the `unc_qq`/`unc_hl` compare grid and drops the
; `isCompareTemplate` exclusion, so a compare-as-data flag now reverses in place:
; the embedded compare `|a,b,c⟩ → |a,b, c ⊕ (a<b)⟩` is a self-inverse permutation,
; and `cq_template_icmp_slt_i32_hl_unc(out, src, lit)` recomputes-and-XORs the flag
; rail to |0⟩ from the STILL-LIVE root (whole-DAG LIFO guarantees source liveness),
; never a phase (a permutation, no dephasing). The rail is then a proven-|0⟩ free.
;
; The dead `zext` widen-flag terminal off the compare keeps a real `cq_template_*`
; lineage; both the `zext` and the `icmp` are now invertible, so the whole dead DAG
; reverses cleanly (leaf-first: zext_unc reads the live compare rail; the compare
; adjoint reads the live root; the root is then un-rotated and KEPT — Ry-dagger
; restores its runtime seed |x>, not |0>, bd 5c5b / libcqops vmz9).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEROOT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %c = icmp slt i32 %q, 5      ; tainted data-position compare -> flag (HL: handle, lit 5)
  %w = zext i1 %c to i32       ; DEAD widened-flag terminal off the compare lineage
  ret void
}

; Forward chain: theta -> alloc + ry, the HL compare flag, then the zext widen.
; CHECK:     call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 2.500000e-01)
; CHECK:     %[[CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H]], i32 5)
; CHECK:     %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[CMP]])
; Reversed adjoint (LIFO): zext_unc(out=%w, src=%c) BEFORE the compare adjoint
; icmp_..._hl_unc(out=%c, src=%q, lit 5) reading the still-live root — DD-3 slots
; (out, then forward operands in original order), then the proven-|0> rail free,
; then un-rotate the root (kept, see above). All handles i32; void `_unc`, no
; fresh mint.
; CHECK:     call void @cq_template_zext_i1_to_i32_unc(i32 %[[CAST]], i32 %[[CMP]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[CMP]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[CMP]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; CHECK-NOT: call void @cqrt_free(i32 %[[H]])
;
; The adjoint is the VOID `_unc`, never the fresh-minting `_inv`; the theta is lowered.
; CHECK-NOT: cq_template_icmp_slt_i32_hl_inv
; CHECK-NOT: cq_template_icmp_slt_i32_inv
; CHECK-NOT: cq_theta_si32

; bd 5c5b review r2: the root is never freed ANYWHERE after its birth — own prefix,
; one anchor (the alloc), so the window runs alloc -> EOF and also covers a free
; slipped in BEFORE the root's un-rotation; `tools/fixture_guard_liveness.py`
; checks the window by injection.
; NOFREEROOT:     %[[RT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; NOFREEROOT-NOT: call void @cqrt_free(i32 %[[RT]])
