; lowering_mc_late_grover2_offset.ll — ACCEPT (M-C Increment 7a, bd
; test_C_libtooling-x67f). WAS lowering_reject_live_record_mc_grover2_offset.ll,
; a LOUD DECLINE at the M-A live-record guard; renamed and re-dispositioned
; because the increment fixed the PROGRAM, not because the guard moved.
;
; THIS IS THE CAMPAIGN SHAPE, and it is the reason the two smaller siblings
; exist at all: TWO Grover iterations, each S — derived oracle — S† — R0, with
; the `+= off` / `-= off` offset trick carried across both. bd memory
; [mc-cannot-see-mb-discharge-2026-08-29] told slice authors to keep the offset
; trick OUT of a derived-oracle Grover, and named the reason precisely — "it is
; not a compiler bug to chase in M-B; it is a pipeline-ORDER fact about M-C".
; Increment 7a changes the pipeline order, so the advice is retired and this
; file is its receipt. The e2e twin is
; tests/e2e/slice_control_grover_derived_oracle_offset.c, which additionally
; LINKS and byte-diffs a trace.
;
; THE PHYSICS CLAIM, and it is the only one worth checking on a Grover slice:
; at EVERY `cqrt_ry_i32` — the five S/S† rotations across two iterations — the
; ONLY allocated rail is `%h`. Each iteration's oracle chain (`ashr` rail, QQ
; `add` rail), its flag, and its work rail are all freed on the lines above,
; and neither offset step mints a rail at all. A record standing at any one of
; those rotations would dephase the interference the algorithm depends on; that
; is what the M-A guard used to say, loudly and about the wrong cause.
;
; CHECKING IT IS DELIBERATELY SPLIT ACROSS TWO PREFIXES rather than written as a
; 60-line CHECK-NEXT transcript. The default prefix walks the stream in order and
; pins the FOUR offset steps and the two oracle discharges; the NOMINT prefix
; re-reads the SAME file (one `%cq-opt` spawn — the lit cost note) with nothing
; but CHECK-NOTs, which is the only way to say "no data-template rail for an
; offset step ANYWHERE in the function", including before the first CHECK. A full
; adjacency chain would additionally pin the two regions' interleaving — churn
; with no physics in it; that pinning lives in the two smaller siblings, whose
; streams are the same shape.
;
; RED STATE: RED on every plugin built before Increment 7a (non-zero exit at the
; M-A guard, so the RUN line fails before any CHECK is read).
;
; `%off` is a volatile load so nothing folds it away. The oracle predicate is
; `((a*5)>>2) == 5`, i.e. `a == 4` — SATISFIABLE, per bd 160a's Rule-13 finding
; F2 (the earlier `((a*37)>>3) == 5` had no integer solution without `nsw`
; overflow, so a demo that sold itself as marking a computed predicate marked
; nothing a C program may legally reach).
;
; SHAPE (`clang -O1` output of two iterations of):
;     a += off;
;     if (((a * 5) >> 2) == 5) a = cq_phi(a, PI);
;     a -= off;
;     a = cq_theta(a, -0.5);
;     if (a == 0) cq_phi(0, PI);
;     a = cq_theta(a, 0.5);
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOMINT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @mc_grover2_offset(ptr noundef %0) {
  %2 = load volatile i32, ptr %0, align 4
  %3 = call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %4 = add nsw i32 %3, %2
  %5 = ashr i32 %4, 2
  %6 = add nsw i32 %5, %4
  %7 = icmp eq i32 %6, 5
  br i1 %7, label %8, label %10
8:
  %9 = call i32 @cq_phi_si32(i32 noundef %4, double noundef 0x400921FB54442D18)
  br label %10
10:
  %11 = phi i32 [ %9, %8 ], [ %4, %1 ]
  %12 = sub nsw i32 %11, %2
  %13 = call i32 @cq_theta_si32(i32 noundef %12, double noundef -5.000000e-01)
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %17
15:
  %16 = call i32 @cq_phi_si32(i32 noundef 0, double noundef 0x400921FB54442D18)
  br label %17
17:
  %18 = phi i32 [ %16, %15 ], [ %13, %10 ]
  %19 = call i32 @cq_theta_si32(i32 noundef %18, double noundef 5.000000e-01)
  %20 = add nsw i32 %19, %2
  %21 = ashr i32 %20, 2
  %22 = add nsw i32 %21, %20
  %23 = icmp eq i32 %22, 5
  br i1 %23, label %24, label %26
24:
  %25 = call i32 @cq_phi_si32(i32 noundef %20, double noundef 0x400921FB54442D18)
  br label %26
26:
  %27 = phi i32 [ %25, %24 ], [ %20, %17 ]
  %28 = sub nsw i32 %27, %2
  %29 = call i32 @cq_theta_si32(i32 noundef %28, double noundef -5.000000e-01)
  %30 = icmp eq i32 %29, 0
  br i1 %30, label %31, label %33
31:
  %32 = call i32 @cq_phi_si32(i32 noundef 0, double noundef 0x400921FB54442D18)
  br label %33
33:
  %34 = phi i32 [ %32, %31 ], [ %29, %26 ]
  %35 = call i32 @cq_theta_si32(i32 noundef %34, double noundef 5.000000e-01)
  %36 = call i32 @cq_measure_si32(i32 noundef %35)
  ret i32 %36
}

; ONE alloc for the register, and the four offset steps are all in place: two
; `+= off` (Phase 1) and two `-= off` (the LATE round, each with its classical
; negation). The stream is walked in emitted order, one iteration at a time.
; CHECK-LABEL: define i32 @mc_grover2_offset(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; iteration 1 — `+= off`, the oracle chain, its discharge, then `-= off`
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %2)
; CHECK:      call void @cq_template_add_i32_unc(
; CHECK-NEXT: call void @cqrt_free(
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(
; CHECK:      %[[N1:.*]] = sub i32 0, %2
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[N1]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; iteration 2 — the same four steps on the SAME rail
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %2)
; CHECK:      call void @cq_template_add_i32_unc(
; CHECK-NEXT: call void @cqrt_free(
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(
; CHECK:      %[[N2:.*]] = sub i32 0, %2
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[N2]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; the last S rotation and the measurement are on that same rail
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; NO offset step mints a data rail, ANYWHERE — this is the whole increment, and
; a `_hl` symbol would also appear as an orphaned `declare` if a call were ever
; emitted and then converted, so the absence covers both.
; NOMINT-NOT: cq_template_sub_i32_hl
; NOMINT-NOT: cq_template_add_i32_hl

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. This file's physics claim is that the conversion leaves the guard
; NOTHING TO NAME — which, while the guard was a `DS_Error`, the RUN line's own
; exit code pinned. It now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a future regression in the M-A walk would print a warning on this very
; program and the file would stay green: the CHECK-NEXT chain pins the emitted
; STREAM, and the M-A analysis is keyed on emitter-recorded sets no stream line
; shows. `SILENT` reads the pass's stderr and is the pin that replaces the exit
; code (Increment 7 Rule-13 round, finding F3; same spelling as the 28 accept
; fixtures 7b re-pinned).
; SILENT-NOT: non-diagonal gate over a live derived record
