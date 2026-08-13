; spec_accept_qrom_read_arm_coherent_escape.ll — bd 20xt.5.2 (the FINAL atan2l
; blocker: inner-atanl clone-control). A const-global tainted-index QROM read in a
; TAINTED DIAMOND ARM of a Phase-6 spec-clone body, whose loaded value ESCAPES to
; the clone's non-`main` `ret` with NO measure — EXACTLY the atanl
; `atanhi[id]`→fmuladd→ret shape.
;
; Pre-fix this DECLINED at `lowerCloneControl`'s post-flatten backstop ("callee
; contains tainted control flow under quantum lift"): the clone's scoped PredMux
; `ClaimAll` flatten LEFT at its E4-gep gate because
; `classifyQromReadUnderControl`'s coherent-escape no-cloning fence returned `No`
; for the read (its value reaches a non-`main` ret with no measure). The
; `inBennettClone` BYPASS — threaded from `ClaimAll`, whose sole
; `flattenPredMuxRegions(claimAll=true)` caller is `lowerCloneControl`, so it is
; exactly the "inside a Bennett clone" predicate — makes the read CLAIMABLE: the
; clone flattens, the region-internal phi-index (over constants {2, 2^32−1}) becomes
; a `cqrt_copy_i64_controlled` select-chain (`lowerCloneSelect`), `lowerQramReads`
; (inBennettClone=true, its own coherent-escape bypass) masks (`and idx, 3`, the
; pow2 NeedsMask row) + lowers the read, and the Bennett wrap COPIES the return out
; to a fresh basis rail then reverses the WHOLE forward stream (the qram-load `_unc`
; AND the index), so the coherent escape is SOUND by Bennett — the fence is vacuous
; inside a wrapped clone. The bypass is SCOPED to the clone: a top-level (non-clone)
; coherent escape still declines (lowering_reject_qram_read_under_control_cohescape.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

@tbl = internal unnamed_addr constant [4 x double] [double 1.0, double 2.0, double 3.0, double 4.0], align 16
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

; A pure-classical callee with an INTERNAL tainted diamond whose arm reads
; `tbl[id]` (id a region-internal PHI over constants) and whose merged value
; escapes to the ret with NO measure (the coherent-escape shape).
define internal double @lookup(double %x) {
entry:
  %c1 = fcmp ogt double %x, 1.000000e+00
  br i1 %c1, label %inner, label %base
inner:
  %c2 = fcmp olt double %x, 4.000000e+00
  br i1 %c2, label %ia, label %ib
ia:
  br label %join
ib:
  br label %join
join:
  %id = phi i64 [ 2, %ia ], [ 4294967295, %ib ]   ; {2, 2^32-1} — NeedsMask (pow2 tbl)
  %g = getelementptr inbounds [4 x double], ptr @tbl, i64 0, i64 %id
  %v = load double, ptr %g, align 8
  %s = fadd double %x, %v
  br label %exit
base:
  br label %exit
exit:
  %r = phi double [ %s, %join ], [ %x, %base ]
  ret double %r                                    ; coherent escape — no measure
}

define double @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @lookup(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; Caller: theta lowered to alloc+ry; the call retargets to the mangled clone; the
; result is measured.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u)
; CHECK:     call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_lookup_1(i32 %[[H]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[R]])
;
; Clone: array-handle birth at entry, the flattened phi-index masked (`and .., 3`)
; feeding the qram load, the fp arm-merge controlled copies, the copy-out, then the
; Bennett reverse (qram load `_unc`) and the scratch frees.
;
; NB the CHECK-NOTs are INTERLEAVED between adjacent positive CHECKs (not appended
; after the last one) so FileCheck scans them against the CLONE BODY — the dead
; un-lowered original `@lookup` (which still holds `br`/`phi`/`load double`) sits
; ABOVE the clone, and a trailing CHECK-NOT block would scan only the tail declares
; (a vacuous test). A `CHECK-LABEL` anchors the clone; the body-scoped negatives
; prove the tainted diamond is FLATTENED (no `br`/`phi`/`select` between the read and
; the merge) and — the Rule-6/8 safety property — that the entangled QROM array
; handle and the returned result rail are NEVER `cqrt_free`d (a dirty free of an
; entangled rail is a hidden measurement that collapses q).
; CHECK-LABEL: define internal {{.*}}i32 @__cq_q_lookup_1(i32 %x)
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 4)
; CHECK:     %[[IDX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %{{[a-zA-Z0-9_.]+}}, i64 3)
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_f64(i32 %[[ARR]], i32 %[[IDX]])
; the read is LOWERED and the diamond FLATTENED — no raw load / control between the
; read and the fp arm-merge:
; CHECK-NOT: load double
; CHECK-NOT: br i1
; CHECK-NOT: = phi
; CHECK-NOT: = select i1
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_qram_load_f64_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[IDX]])
; the reverse is the `_unc` form (never a fresh-minting `_inv`), and NEITHER the
; entangled array handle NOR the returned result rail is freed (Rule 6/8):
; CHECK-NOT: cqrt_qram_load_f64_inv
; CHECK-NOT: cqrt_free(i32 %[[ARR]])
; CHECK-NOT: cqrt_free(i32 %[[OUT]])
; CHECK:     ret i32 %[[OUT]]
