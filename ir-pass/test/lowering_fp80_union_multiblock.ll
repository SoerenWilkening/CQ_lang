; lowering_fp80_union_multiblock.ll — bd 3c6m.51 Inc 3 ACCEPT: the MULTI-BLOCK
; fp80 union (the scalbnl skeleton, compacted): one union alloca threaded across
; four blocks — seed store in entry, an fp80 RE-SEED (`u.e *= 0x1p+128`) plus a
; second straddle read in the subnormal arm, and a shared field-insert PACK +
; reload after the tainted merge. canonicalize + PromoteMemToReg rewrites every
; access to a full-width x86_fp80 load/store on a fresh promotable alloca and
; lets LLVM's own mem2reg build the merge phi (`phi x86_fp80` — NEVER an i80
; phi; the i80 extract/insert stays intra-block). PredMux then claims the
; tainted diamond (two merge phis: the i64 exponent + the mem2reg f80 value),
; flattens it to selects, and the kjd1 fp-select copy family lowers the f80
; merge via cqrt_copy_f80_controlled — the same downstream that already carries
; scalbn.f64.
;
; THE `COMP` PREFIX IS THE M-B INCREMENT-6a PIN (bd test_C_libtooling-160a
; Rule-13 round, finding F1a). This module is the LARGEST single lit behaviour
; change of the per-component interior anchor: it gains NINETEEN `_unc`/free
; pairs in THREE groups (4 in `entry`, 4 more in `entry`, 11 in `ins`) that the
; one-`At`-per-function placement could not emit — one function-wide insertion
; point put a `cqrt_copy_f80_controlled` reader inside the interval, so clause
; (d) refused and the whole function leaked. The `CHECK-DAG`s below are
; symbol-PRESENCE assertions and PASS on the pre-6a plugin's output unchanged
; (measured against a 439dae3 build: 2 `_unc` + 2 free there, 21 + 21 here), so
; they pin none of it. `COMP` is adjacency: each component's forward chain, then
; its LIFO adjoint chain with every free immediately after its own `_unc`, in
; the exact order emitted — which is what makes "per COMPONENT, not per
; function" observable to a test at all.
;
; WHY THE THREE GROUPS ARE INDEPENDENT (the argument the adjacency encodes).
; Component 1 owns {bitcast,lshr,trunc,zext} off `%h` and borrows `%h`; its only
; non-producer reader of `%h` is the `cqrt_copy_f80_controlled` below, which is
; to the RIGHT of its discharge. Component 2 owns the same four shapes off the
; `fmul` rail and borrows that rail, likewise read only to the right. The `ins`
; component owns 11 rails off `%out`/`%out14`, whose controlled-copy writers are
; all to its LEFT. No component's borrowed parent is another component's owned
; rail (a shared operand would have been LINKED into one component), so emitting
; them back to back cannot relabel anything a later one reads. The `and_i64`
; exponent rails (`%h_op17`, the fmul rail `%h_op19`) are deliberately NOT
; discharged here — they are live past every group. The two MERGE rails `%out`
; and `%out14` were in that list until bd r2j3.32: they are now reversed after
; their last `ins` reader by MergeRailDischarge (not by this partition) and freed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2>&1
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COMP < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @mb() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca %union.IEEEl2bits, align 16
  store x86_fp80 %q, ptr %u, align 16
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  %hi = load i64, ptr %p8, align 8              ; straddle read #1
  %exp = and i64 %hi, 32767
  %c0 = icmp eq i64 %exp, 0                     ; tainted condition
  br i1 %c0, label %sub, label %norm

sub:                                            ; subnormal: rescale + re-extract
  %e0 = load x86_fp80, ptr %u, align 16
  %e1 = fmul x86_fp80 %e0, 0xK407F8000000000000000   ; u.e *= 0x1p+128
  store x86_fp80 %e1, ptr %u, align 16          ; fp80 RE-SEED in a non-entry block
  %hi2 = load i64, ptr %p8, align 8             ; straddle read #2
  %x2 = and i64 %hi2, 32767
  %k2 = add i64 %x2, 128
  br label %ins

norm:
  %k1 = add i64 %exp, 2
  br label %ins

ins:                                            ; shared field-insert + reload
  %k = phi i64 [ %k2, %sub ], [ %k1, %norm ]
  %hi3 = load i64, ptr %p8, align 8             ; RMW read
  %keep = and i64 %hi3, -32768
  %fld = and i64 %k, 32767
  %w = or i64 %keep, %fld
  store i64 %w, ptr %p8, align 8                ; field-insert store-back
  %e = load x86_fp80, ptr %u, align 16          ; reload (`return u.e`)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %e)
  ret x86_fp80 %m
}

; Promoted + flattened + lowered: no memory, no branches survive; the f80 merge
; goes through the kjd1 controlled-copy family and the RMW pack through the i80
; write surface.
; CHECK-NOT: alloca
; CHECK-NOT: store
; CHECK: call i32 @cq_template_bitcast_f80_to_i80
; CHECK-DAG: call i32 @cq_template_fmul_f80_hl
; CHECK-DAG: call void @cqrt_copy_f80_controlled
; CHECK-DAG: call i32 @cq_template_zext_i64_to_i80
; CHECK-DAG: call i32 @cq_template_shl_i80_hl
; CHECK-DAG: call i32 @cq_template_or_i80
; CHECK: call i32 @cq_template_bitcast_i80_to_f80
; CHECK: call x86_fp80 @cqrt_measure_f80
; CHECK-NOT: error
; CHECK-NOT: alloca
; CHECK-NOT: store x86_fp80

; ── the three interior components, pinned by ADJACENCY (the COMP prefix) ───
; Component 1 (entry): the straddle-read chain off the source rail. Its adjoint
; runs LIFO immediately after the last forward gate that reads it, and the
; `bitcast_f80_to_i80_unc` reading %[[H]] lands BEFORE the `fmul` — i.e. before
; anything else touches the borrowed parent:
; COMP-LABEL: define x86_fp80 @mb(
; COMP:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(
; COMP-NEXT: call void @cqrt_ry_f80(i32 %[[H]], double 5.000000e-01)
; COMP-NEXT: %[[A1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_bitcast_f80_to_i80(i32 %[[H]])
; COMP-NEXT: %[[A2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_lshr_i80_hl(i32 %[[A1]], i80 64)
; COMP-NEXT: %[[A3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i80_to_i16(i32 %[[A2]])
; COMP-NEXT: %[[A4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i16_to_i64(i32 %[[A3]])
; COMP-NEXT: %[[EXP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[A4]], i64 32767)
; COMP-NEXT: call void @cq_template_zext_i16_to_i64_unc(i32 %[[A4]], i32 %[[A3]])
; COMP-NEXT: call void @cqrt_free(i32 %[[A4]])
; COMP-NEXT: call void @cq_template_trunc_i80_to_i16_unc(i32 %[[A3]], i32 %[[A2]])
; COMP-NEXT: call void @cqrt_free(i32 %[[A3]])
; COMP-NEXT: call void @cq_template_lshr_i80_hl_unc(i32 %[[A2]], i32 %[[A1]], i80 64)
; COMP-NEXT: call void @cqrt_free(i32 %[[A2]])
; COMP-NEXT: call void @cq_template_bitcast_f80_to_i80_unc(i32 %[[A1]], i32 %[[H]])
; COMP-NEXT: call void @cqrt_free(i32 %[[A1]])

; Component 2 (entry): the same four shapes off the rescaled `fmul` rail, its
; own LIFO block, immediately after ITS last forward gate — not merged with
; component 1's and not deferred to a shared function-wide point:
; COMP-NEXT: %[[K1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i64_hl(i32 %[[EXP]], i64 2)
; COMP-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f80_hl(i32 %[[H]], x86_fp80 0xK407F8000000000000000)
; COMP-NEXT: %[[B1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_bitcast_f80_to_i80(i32 %[[F]])
; COMP-NEXT: %[[B2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_lshr_i80_hl(i32 %[[B1]], i80 64)
; COMP-NEXT: %[[B3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i80_to_i16(i32 %[[B2]])
; COMP-NEXT: %[[B4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i16_to_i64(i32 %[[B3]])
; COMP-NEXT: %[[X2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[B4]], i64 32767)
; COMP-NEXT: call void @cq_template_zext_i16_to_i64_unc(i32 %[[B4]], i32 %[[B3]])
; COMP-NEXT: call void @cqrt_free(i32 %[[B4]])
; COMP-NEXT: call void @cq_template_trunc_i80_to_i16_unc(i32 %[[B3]], i32 %[[B2]])
; COMP-NEXT: call void @cqrt_free(i32 %[[B3]])
; COMP-NEXT: call void @cq_template_lshr_i80_hl_unc(i32 %[[B2]], i32 %[[B1]], i80 64)
; COMP-NEXT: call void @cqrt_free(i32 %[[B2]])
; COMP-NEXT: call void @cq_template_bitcast_f80_to_i80_unc(i32 %[[B1]], i32 %[[F]])
; COMP-NEXT: call void @cqrt_free(i32 %[[B1]])
; COMP-NEXT: call void @cqrt_addc_i64(i32 %[[X2]], i64 128)

; The two flag strips are the PRE-EXISTING pairs (they were the only two on the
; pre-6a plugin). Since bd r2j3.32 both are DEFERRED into `ins`: each merge rail
; (`%out14`, then `%out`) is reversed right after its last reader there — its
; core re-emitted in reverse under the still-live flag, then the strip, then the
; free — and both borrowed parents are still live across them.

; The `ins` component: 11 pairs, LIFO, every one of them BEFORE the measure —
; the component's borrowed parents are `%out`/`%out14`, whose controlled-copy
; writers are all to the left of this block:
; COMP:      %[[I1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_bitcast_f80_to_i80(i32 %[[OUT:[a-zA-Z0-9_.]+]])
; COMP-NEXT: %[[I2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_lshr_i80_hl(i32 %[[I1]], i80 64)
; COMP-NEXT: %[[I3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i80_to_i16(i32 %[[I2]])
; COMP-NEXT: %[[I4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i16_to_i64(i32 %[[I3]])
; COMP-NEXT: %[[I5:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[I4]], i64 -32768)
; COMP-NEXT: %[[I6:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[OUT14:[a-zA-Z0-9_.]+]], i64 32767)
; COMP-NEXT: %[[I7:[a-zA-Z0-9_.]+]] = call i32 @cq_template_or_i64(i32 %[[I5]], i32 %[[I6]])
; COMP-NEXT: %[[I8:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i80_hl(i32 %[[I1]], i80 18446744073709551615)
; COMP-NEXT: %[[I9:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i64_to_i80(i32 %[[I7]])
; COMP-NEXT: %[[I10:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i80_hl(i32 %[[I9]], i80 64)
; COMP-NEXT: %[[I11:[a-zA-Z0-9_.]+]] = call i32 @cq_template_or_i80(i32 %[[I8]], i32 %[[I10]])
; COMP-NEXT: %[[RES:[a-zA-Z0-9_.]+]] = call i32 @cq_template_bitcast_i80_to_f80(i32 %[[I11]])
; COMP-NEXT: call void @cq_template_or_i80_unc(i32 %[[I11]], i32 %[[I8]], i32 %[[I10]])
; COMP-NEXT: call void @cqrt_free(i32 %[[I11]])
; COMP-NEXT: call void @cq_template_shl_i80_hl_unc(i32 %[[I10]], i32 %[[I9]], i80 64)
; COMP-NEXT: call void @cqrt_free(i32 %[[I10]])
; COMP-NEXT: call void @cq_template_zext_i64_to_i80_unc(i32 %[[I9]], i32 %[[I7]])
; COMP-NEXT: call void @cqrt_free(i32 %[[I9]])
; COMP-NEXT: call void @cq_template_and_i80_hl_unc(i32 %[[I8]], i32 %[[I1]], i80 18446744073709551615)
; COMP-NEXT: call void @cqrt_free(i32 %[[I8]])
; COMP-NEXT: call void @cq_template_or_i64_unc(i32 %[[I7]], i32 %[[I5]], i32 %[[I6]])
; COMP-NEXT: call void @cqrt_free(i32 %[[I7]])
; COMP-NEXT: call void @cq_template_and_i64_hl_unc(i32 %[[I6]], i32 %[[OUT14]], i64 32767)
; COMP-NEXT: call void @cqrt_x(i32 %[[CMPB:[a-zA-Z0-9_.]+]])
; COMP-NEXT: call void @cqrt_copy_i64_controlled(i32 %[[CMPB]], i32 %[[K1]], i32 %[[OUT14]])
; COMP-NEXT: call void @cqrt_x(i32 %[[CMPB]])
; COMP-NEXT: call void @cqrt_copy_i64_controlled(i32 %[[CMPB]], i32 %[[X2]], i32 %[[OUT14]])
; COMP-NEXT: call void @cq_template_icmp_eq_i64_hl_unc(i32 %[[CMPB]], i32 %[[EXP]], i64 0)
; COMP-NEXT: call void @cqrt_free(i32 %[[CMPB]])
; COMP-NEXT: call void @cqrt_free(i32 %[[OUT14]])
; COMP-NEXT: call void @cqrt_free(i32 %[[I6]])
; COMP-NEXT: call void @cq_template_and_i64_hl_unc(i32 %[[I5]], i32 %[[I4]], i64 -32768)
; COMP-NEXT: call void @cqrt_free(i32 %[[I5]])
; COMP-NEXT: call void @cq_template_zext_i16_to_i64_unc(i32 %[[I4]], i32 %[[I3]])
; COMP-NEXT: call void @cqrt_free(i32 %[[I4]])
; COMP-NEXT: call void @cq_template_trunc_i80_to_i16_unc(i32 %[[I3]], i32 %[[I2]])
; COMP-NEXT: call void @cqrt_free(i32 %[[I3]])
; COMP-NEXT: call void @cq_template_lshr_i80_hl_unc(i32 %[[I2]], i32 %[[I1]], i80 64)
; COMP-NEXT: call void @cqrt_free(i32 %[[I2]])
; COMP-NEXT: call void @cq_template_bitcast_f80_to_i80_unc(i32 %[[I1]], i32 %[[OUT]])
; COMP-NEXT: call void @cqrt_x(i32 %[[CMPA:[a-zA-Z0-9_.]+]])
; COMP-NEXT: call void @cqrt_copy_f80_controlled(i32 %[[CMPA]], i32 %[[H]], i32 %[[OUT]])
; COMP-NEXT: call void @cqrt_x(i32 %[[CMPA]])
; COMP-NEXT: call void @cqrt_copy_f80_controlled(i32 %[[CMPA]], i32 %[[F]], i32 %[[OUT]])
; COMP-NEXT: call void @cq_template_icmp_eq_i64_hl_unc(i32 %[[CMPA]], i32 %[[EXP]], i64 0)
; COMP-NEXT: call void @cqrt_free(i32 %[[CMPA]])
; COMP-NEXT: call void @cqrt_free(i32 %[[OUT]])
; COMP-NEXT: call void @cqrt_free(i32 %[[I1]])
; COMP-NEXT: call x86_fp80 @cqrt_measure_f80(i32 %[[RES]])
