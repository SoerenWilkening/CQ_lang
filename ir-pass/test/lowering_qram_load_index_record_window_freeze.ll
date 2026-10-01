; lowering_qram_load_index_record_window_freeze.ll — bd test_C_libtooling-r2j3.3
; (a P1 silent miscompile; the COMPILER half — stage 2b's over-accept of the same
; free is a separate defect owned elsewhere).
;
; SOURCE (`tbl` a static const table with DISTINCT entries, non-main):
;     _Bool b = cq_theta(u, .5);
;     int v = tbl[b];                  // G: the load reads b as its index
;     b = cq_theta(b, -.5);            // N: a non-diagonal gate on that index
;     printf("%d %d\n", b, v);         // the tape records b's POST-N label
;
; THE DEFECT (@defect). The dead-terminal spine reverse-plays the whole DAG: it
; re-applies `ry_i1(b, +.5)` and then `qram_load_unc(v, tbl, b)`, and frees `v`.
; Reverse program order returns `b` to its load-time label only if nothing outside
; the DAG looked at `b` between N and N's adjoint — but the tape recorded `b`
; (through `zext b`) in exactly that window, so N's adjoint does not restore it
; (the tape distinguishes the post-N labels). The `_unc` then recomputes
; `tbl[b]` from the wrong label and `v` is NOT |0> at its `cqrt_free`: a hidden
; projective measurement (Rule 5). `opt` exit 0, verify-clean, and stage 2b
; certifies the free (its "operand unchanged" proof accepts Ry(+t)..Ry(-t) around
; a tape READ).
;
; THE RULE (`DagTraversal` step 3c, the record-window freeze). Clause (d) of the
; record-freeze invariant — every register an adjoint reads holds its forward-time
; value — fails for a gate G reading P exactly when some non-basis-preserving
; gate N on P runs after G and P's label AFTER N is recorded into a kept carrier.
; Then G's rail is FROZEN: its adjoint is still emitted (bd 261j: the freeze
; suppresses the free, never an adjoint), its `cqrt_free` is not. A record of P
; taken BEFORE N, or of a descendant minted before N, does not trip it: N and its
; adjoint then sandwich a copy that never touched P, and they cancel.
;
; THE CONTROL (@only_v): the same program printing only `v`. The tape now copies
; `v` (a function of b's PRE-N label) and never b's post-N label, so N's adjoint
; restores `b`, the `_unc` zeroes `v`, and `v` must still be freed — the freeze
; must not over-reach.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEV < %t.cqd0.ll
@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 7, i32 5, i32 9, i32 2, i32 6], align 16
@.str = private unnamed_addr constant [7 x i8] c"%d %d\0A\00", align 1
@.str.1 = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @printf(ptr nocapture readonly, ...)

define i32 @defect(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b = icmp ne i32 %q, 0
  %zb = zext i1 %b to i64
  %g = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %zb
  %v = load i32, ptr %g, align 4                             ; G
  %b2 = call i1 @cq_theta_i1(i1 %b, double -5.000000e-01)    ; N
  %pb = zext i1 %b2 to i32
  %c = call i32 (ptr, ...) @printf(ptr @.str, i32 %pb, i32 %v)  ; records b after N
  ret i32 0
}

define i32 @only_v(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b = icmp ne i32 %q, 0
  %zb = zext i1 %b to i64
  %g = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %zb
  %v = load i32, ptr %g, align 4
  %b2 = call i1 @cq_theta_i1(i1 %b, double -5.000000e-01)
  %c = call i32 (ptr, ...) @printf(ptr @.str.1, i32 %v)      ; records v only
  ret i32 0
}

; @defect: the whole forward stream and the whole reversal, adjoints included —
; only the load rail's free is gone.
; CHECK-LABEL: define i32 @defect(
; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 0)
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call void @cqrt_ry_i1(i32 %[[B]], double -5.000000e-01)
; CHECK:      call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[V]])
; CHECK:      call void @cqrt_ry_i1(i32 %[[B]], double 5.000000e-01)
; CHECK:      call void @cqrt_qram_load_i32_unc(i32 %[[V]],
; CHECK:      call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[B]],
; CHECK:      ret i32 0
; NOFREEV-LABEL: define i32 @defect(
; NOFREEV:      %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(
; NOFREEV-NOT:  call void @cqrt_free(i32 %[[V2]])
; NOFREEV-LABEL: define i32 @only_v(

; @only_v: the identical reversal, and the load rail IS freed, after its `_unc`.
; CHECK-LABEL: define i32 @only_v(
; CHECK:      %[[OB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 0)
; CHECK:      %[[OV:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call void @cqrt_ry_i1(i32 %[[OB]], double -5.000000e-01)
; CHECK:      call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OV]])
; CHECK:      call void @cqrt_ry_i1(i32 %[[OB]], double 5.000000e-01)
; CHECK:      call void @cqrt_qram_load_i32_unc(i32 %[[OV]],
; CHECK:      call void @cqrt_free(i32 %[[OV]])
; CHECK:      ret i32 0
