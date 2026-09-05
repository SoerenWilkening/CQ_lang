; lowering_i128_intermediate_mulhi.ll — Phase 7.1 follow-up n0ui, Tier-1: a
; 128-bit INTERMEDIATE lowers. The classic use is a widening "mulhi" — square a
; quantum i64, take the high 64 bits of the 128-bit product:
;   w  = zext i64 q to i128 ; sq = mul i128 w, w ; hi = lshr i128 sq, 64 ;
;   r  = trunc i128 hi to i64
; The source/sink stay i64 (clean ABI: cqrt_alloc_i64 / cqrt_measure_i64); i128
; appears ONLY as single clean ops lowered to the FROZEN cq_template_*_i128
; producers (zext/mul/lshr/trunc). NO cqrt_*_i128 core symbol, NO {i64,i64}
; aggregate — i128 SOURCE/SINK (the __int128 ABI shred) is Tier-2, deferred.
;
; (A) a MEASURED mulhi chain pins the forward producers; (B) a DEAD i128 lineage
; kept alive by cq_phi pins that the i128 ops participate in the whole-DAG _unc
; reversal (mul_i128_hl_unc / trunc_i128_to_i64_unc / zext_i64_to_i128_unc each
; recompute-and-XOR from the live source), then each rail is freed |0>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)

define void @ex(i64 %u0) {
  ; (A) measured 128-bit mulhi
  %q  = call i64 @cq_theta_sll(i64 %u0, double 0.25)
  %w  = zext i64 %q to i128
  %sq = mul i128 %w, %w
  %hi = lshr i128 %sq, 64
  %r  = trunc i128 %hi to i64
  %z  = call i64 @cq_measure_sll(i64 %r)
  ; (B) dead i128 op kept alive by cq_phi — exercises the i128 _unc twins
  %q2 = call i64 @cq_theta_sll(i64 %u0, double 0.10)
  %w2 = zext i64 %q2 to i128
  %d  = mul i128 %w2, 7
  %dt = trunc i128 %d to i64
  ret void
}

; (A) forward: i64 source -> zext to i128 -> single clean i128 ops -> trunc to i64.
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %u0)
; CHECK:     %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i64_to_i128(i32 %[[Q]])
; CHECK:     %[[SQ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i128(i32 %[[W]], i32 %[[W]])
; CHECK:     %[[HI:[a-zA-Z0-9_.]+]] = call i32 @cq_template_lshr_i128_hl(i32 %[[SQ]], i128 64)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i128_to_i64(i32 %[[HI]])
; CHECK:     call i64 @cqrt_measure_i64(i32 %[[R]])
;
; (B) the dead i128 lineage is reversed by its void _unc twins (recompute-and-XOR
; from the live source), then each rail freed |0> — the i128 ops ride the existing
; whole-DAG uncompute spine with no i128-specific uncompute code.
; CHECK:     %[[W2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i64_to_i128(
; CHECK:     %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i128_hl(i32 %[[W2]], i128 7)
; CHECK:     call void @cq_template_mul_i128_hl_unc(i32 %[[D]], i32 %[[W2]], i128 7)
; CHECK:     call void @cq_template_zext_i64_to_i128_unc(i32 %[[W2]], i32 %{{[a-zA-Z0-9_.]+}})
;
; The source/sink are i64 — NO i128 core ABI is minted.
; CHECK-NOT: cqrt_alloc_i128
; CHECK-NOT: cqrt_measure_i128
; CHECK-NOT: cqrt_copy_i128
; CHECK-NOT: cq taint escape
