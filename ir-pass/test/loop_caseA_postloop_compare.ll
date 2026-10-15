; loop_caseA_postloop_compare.ll — ACCEPT (bd test_C_libtooling-8h7d.16).
; `clang -O1` output (attributes and metadata dropped) of
;
;     int brk(int x, int y, int n) {          // the issue's P3 (d_8h7d16b.c)
;       int q = x; cq_theta(&q, .5);
;       int r = y; cq_theta(&r, .25);
;       cq_theta(&r, (q == 5) ? .9 : .3);      // T: the angle select
;       for (int i = 0; i <= n; i++) cq_theta(&r, .1);
;       int a = x + 1; cq_theta(&a, .7);
;       for (int i = 0; i < n; i++) { a ^= 9; if (a == r) break; }
;       return cq_measure(a) + cq_measure(q);
;     }
;     int flag(int x, int y, int n) {
;       int q = x; cq_theta(&q, .5);
;       int r = y; cq_theta(&r, .25);
;       for (int i = 0; i < n; i++) cq_theta(&r, .1);
;       int c = (r == 3);
;       int d = c + q;
;       return cq_measure(d) + cq_measure(r);
;     }
;
; and `@flag_then_gate`, `@flag` with `cq_theta(&r, .2);` between `c` and `d`.
;
; THE DEFECT (main 7b4e6359). `tryCaseA`'s CLOSURE refused every consumer of a
; rail value but an in-place gate, a measure or a `ret`, so a COMPARE reading r
; after the loop (the 7.4 break's comparand, a data flag) left the loop
; unclaimed, and its `-O1` zero-trip exit φ `phi [%pre, guard], [%gate, latch]`
; declined at `declineClassicalMuxes` (`tainted value muxed by a
; classical-condition phi`) — all three functions.
;
; THE FIX. CLOSURE admits a compare outside `L` that cannot reach `L`'s header
; (`isPostLoopRailCompare`). After the collapse it reads r's one handle at its
; own position; the record-liveness fence asks that read positionally (the
; zero-trip neighbour declines there:
; `loop_caseA_postloop_compare_reject_zero_trip.ll`), and no gate of this loop
; can run between the compare and its flag's adjoint. A compare that can reach
; the loop is still refused here (unpinned: its adjoint-after-the-loop hazard
; is declined first by the stale-record pre-pass,
; `loop_caseA_postloop_compare_reject_stale_record.ll`).
;
; TRACE ARGUMENT (h_q, h_r, h_a the registers):
;   @flag: Ry(h_r,.25); Ry(h_r,.1) x n; f = [h_r == 3]; z = zext f;
;     d = h_q + z; then the spine's adjoints z⁻¹, f⁻¹ with the frees — h_r is
;     untouched between f and f⁻¹, so f returns to |0> before its free (R5);
;     measure(d); measure(h_r). The flag reads h_r after every loop Ry: the
;     source's `r` after the loop, on both the zero-trip and the n >= 1 path.
;   @flag_then_gate: the same f and z are computed BEFORE `Ry(h_r,.2)`, the
;     source's order. The Ry separates f from any adjoint, so the spine leaves f
;     and z allocated (never freed dirty) — the no-loop twin's stream exactly.
;   @brk: one handle for r (no φ survives); the break body's two-quantum compare
;     reads (h_a, h_r) in the forward loop and again in the reverse play; no
;     gate touches h_r after its loop, so every read of the comparand sees the
;     same register state, which is the source's r after its loop.
; Each function also prints `non-diagonal gate over a live derived record` at
; r's loop Ry: SPURIOUS for @flag and @brk (the record is minted after the last
; trip and the Ry cannot run again; `recordAbsentAt` asks "the gate already ran"
; and the zero-trip path refutes that). Not pinned here; @flag_then_gate's
; warning at `Ry(h_r,.2)` is the real one.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @brk(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01)
  %6 = icmp eq i32 %4, 5
  %7 = select i1 %6, double 9.000000e-01, double 3.000000e-01
  %8 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %7)
  %9 = icmp slt i32 %2, 0
  br i1 %9, label %10, label %15

10:
  %11 = phi i32 [ %8, %3 ], [ %18, %15 ]
  %12 = add nsw i32 %0, 1
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 0x3FE6666666666666)
  %14 = icmp sgt i32 %2, 0
  br i1 %14, label %21, label %29

15:
  %16 = phi i32 [ %19, %15 ], [ 0, %3 ]
  %17 = phi i32 [ %18, %15 ], [ %8, %3 ]
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 1.000000e-01)
  %19 = add nuw i32 %16, 1
  %20 = icmp eq i32 %16, %2
  br i1 %20, label %10, label %15

21:
  %22 = phi i32 [ %26, %21 ], [ 0, %10 ]
  %23 = phi i32 [ %24, %21 ], [ %13, %10 ]
  %24 = xor i32 %23, 9
  %25 = icmp eq i32 %24, %11
  %26 = add nuw nsw i32 %22, 1
  %27 = icmp eq i32 %26, %2
  %28 = select i1 %25, i1 true, i1 %27
  br i1 %28, label %29, label %21

29:
  %30 = phi i32 [ %13, %10 ], [ %24, %21 ]
  %31 = tail call i32 @cq_measure_si32(i32 noundef %30)
  %32 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %33 = add nsw i32 %32, %31
  ret i32 %33
}

define i32 @flag(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01)
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %15, label %7

7:
  %8 = phi i32 [ %5, %3 ], [ %18, %15 ]
  %9 = icmp eq i32 %8, 3
  %10 = zext i1 %9 to i32
  %11 = add nsw i32 %4, %10
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %8)
  %14 = add nsw i32 %13, %12
  ret i32 %14

15:
  %16 = phi i32 [ %18, %15 ], [ %5, %3 ]
  %17 = phi i32 [ %19, %15 ], [ 0, %3 ]
  %18 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 1.000000e-01)
  %19 = add nuw nsw i32 %17, 1
  %20 = icmp eq i32 %19, %2
  br i1 %20, label %7, label %15
}

define i32 @flag_then_gate(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01)
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %16, label %7

7:
  %8 = phi i32 [ %5, %3 ], [ %19, %16 ]
  %9 = icmp eq i32 %8, 3
  %10 = zext i1 %9 to i32
  %11 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01)
  %12 = add nsw i32 %4, %10
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %15 = add nsw i32 %14, %13
  ret i32 %15

16:
  %17 = phi i32 [ %19, %16 ], [ %5, %3 ]
  %18 = phi i32 [ %20, %16 ], [ 0, %3 ]
  %19 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 1.000000e-01)
  %20 = add nuw nsw i32 %18, 1
  %21 = icmp eq i32 %20, %2
  br i1 %21, label %7, label %16
}

; CHECK-LABEL: define i32 @brk(
; CHECK-NEXT: %[[BQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[BQ]], double 5.000000e-01)
; CHECK-NEXT: %[[BR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[BR]], double 2.500000e-01)
; CHECK-NEXT: %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[BQ]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[BF]], i32 %[[BR]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[BF]], i32 %[[BR]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[BF]], i32 %[[BQ]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF]])
; CHECK: %[[BA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[BA]], double 0x3FE6666666666666)
; CHECK: call void @cqrt_ry_i32(i32 %[[BR]], double 1.000000e-01)
; CHECK: call void @cqrt_xorc_i32(i32 %[[BA]], i32 9)
; CHECK-NEXT: %[[BC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32(i32 %[[BA]], i32 %[[BR]])
; CHECK: call void @cq_template_icmp_eq_i32_unc(i32 %[[BC]], i32 %[[BA]], i32 %[[BR]])
; CHECK: {{^}}cq.brk.rev:
; CHECK: %[[BC2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32(i32 %[[BA]], i32 %[[BR]])
; CHECK: call void @cq_template_icmp_eq_i32_unc(i32 %[[BC2]], i32 %[[BA]], i32 %[[BR]])
; CHECK: {{^}}cq.brk.tail:
; CHECK-NOT: cqrt_ry_i32(i32 %[[BR]],
; CHECK: call i32 @cqrt_measure_i32(i32 %[[BQ]])
; CHECK-NEXT: add nsw i32
; CHECK-NEXT: ret i32
;
; CHECK-LABEL: define i32 @flag(
; CHECK-NEXT: %[[FQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[FQ]], double 5.000000e-01)
; CHECK-NEXT: %[[FR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[FR]], double 2.500000e-01)
; CHECK-NEXT: %[[FG:[a-zA-Z0-9_.]+]] = icmp sgt i32 %2, 0
; CHECK-NEXT: br i1 %[[FG]], label %[[FLOOP:[a-zA-Z0-9_.]+]], label %[[FEXIT:[a-zA-Z0-9_.]+]]
; CHECK: {{^}}[[FEXIT]]:
; CHECK-NEXT: %[[FF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[FR]], i32 3)
; CHECK-NEXT: %[[FZ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[FF]])
; bd r2j3.33 (dm7f.51 step 1): `q`'s old value is dead at the add and the sum is
; measured, so the add lowers IN PLACE on `q`'s rail (the flag's zext as source).
; CHECK-NEXT: call void @cqrt_add_i32(i32 %[[FZ]], i32 %[[FQ]]), !cq.inplace.qq
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[FZ]], i32 %[[FF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[FZ]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[FF]], i32 %[[FR]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[FF]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[FQ]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[FR]])
; CHECK: {{^}}[[FLOOP]]:
; CHECK-NEXT: phi i32
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[FR]], double 1.000000e-01)
; CHECK-NEXT: add nuw nsw i32
; CHECK-NEXT: icmp eq i32
; CHECK-NEXT: br i1
; CHECK-NEXT: {{^}}}
;
; CHECK-LABEL: define i32 @flag_then_gate(
; CHECK-NEXT: %[[GQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[GQ]], double 5.000000e-01)
; CHECK-NEXT: %[[GR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[GR]], double 2.500000e-01)
; CHECK-NEXT: %[[GG:[a-zA-Z0-9_.]+]] = icmp sgt i32 %2, 0
; CHECK-NEXT: br i1 %[[GG]], label %[[GLOOP:[a-zA-Z0-9_.]+]], label %[[GEXIT:[a-zA-Z0-9_.]+]]
; CHECK: {{^}}[[GEXIT]]:
; CHECK-NEXT: %[[GF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[GR]], i32 3)
; CHECK-NEXT: %[[GZ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[GF]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[GR]], double 2.000000e-01)
; bd r2j3.33: in place on `q`'s rail, as in @flag.
; CHECK-NEXT: call void @cqrt_add_i32(i32 %[[GZ]], i32 %[[GQ]]), !cq.inplace.qq
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[GQ]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[GR]])
; CHECK: {{^}}[[GLOOP]]:
; CHECK-NEXT: phi i32
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[GR]], double 1.000000e-01)
; CHECK-NEXT: add nuw nsw i32
; CHECK-NEXT: icmp eq i32
; CHECK-NEXT: br i1
; CHECK-NEXT: {{^}}}
