; lowering_reject_decl_prototype_unused.ll — DECLINE: a wrong-prototype
; @cq_measure_f64 declaration with NO call sites (the passthrough boundary,
; test_C_libtooling-pn2).
;
; DELIBERATE choice pinned by this fixture: the 42 cq_theta_*/cq_phi_*/
; cq_measure_* names are RESERVED by convention (cf. FreePoint's cq_invert_
; prefix escapes), so a declaration carrying one of those names with the
; wrong type is a user error whether or not it is currently called — gating
; the decline on "has calls" would make the diagnostic depend on DCE
; happenstance, and over-declining is always safe (Prime Directive).
; Previously this module passed through byte-identical (the malformed decl
; was collected by name into the FnSets, no call sites found, early-out).
; An UNRECOGNIZED suffix (e.g. @cq_measure_xyz999) is NOT in the 42-name
; surface, stays out of collection entirely, and still passes through —
; only the reserved names are validated.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_measure_f64(double)            ; WRONG: must be double(double)

define i32 @example(i32 %u) {
entry:
  ret i32 %u
}

; CHECK: error{{.*}}cq measure lowering: unsupported declared prototype for cq_measure_f64
