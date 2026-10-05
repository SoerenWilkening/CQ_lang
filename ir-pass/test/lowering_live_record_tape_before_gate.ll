; lowering_live_record_tape_before_gate.ll — M-A clause 4, the TAPE spelling
; (bd test_C_libtooling-gl3x, owner ruling 2026-10-05): a record written to the
; 7.6 output tape by an UNGUARDED write that runs PROVABLY BEFORE the gate is
; exempt from the live-record warning, the way a measurement before the gate is.
; Three functions are silent; three twins still warn.
;
; SOURCE (each function is the clang -O1 IR of its C; attributes trimmed, and
; @park_negated_then_gate hand-swapped to the FALSE-successor orientation that
; control_swap_abort_park_negated.ll pins):
;
;     int park_then_gate(int u) {               // the gl3x probe — SILENT
;       int q = u; cq_theta(&q, 0.5);
;       if (q > 5) abort();
;       cq_theta(&q, 0.3);                       // T
;       return 0;
;     }
;     int park_negated_then_gate(int u)          // same, abort on the FALSE edge — SILENT
;     int sib_taped_before_gate(int u) {         // non-park — SILENT
;       int q = u; cq_theta(&q, 0.5);
;       int c = q ^ 9; int w = q * 2;
;       printf("%d", c);                         // c taped BEFORE T
;       cq_theta(&w, 0.3);                       // T, on the wire w
;       return cq_measure(q * 5);                // observes q after T (clause 3)
;     }
;     int park_beside_dead_record(int u) {       // TWIN — WARNS
;       int q = u; cq_theta(&q, 0.5);
;       int t = q ^ 9; cq_theta(&t, 0.2);        // a dead record, never taped
;       if (q > 5) abort();
;       cq_theta(&q, 0.3);                       // T
;       return 0;
;     }
;     int sib_rotated_taped_one_path(int u, int n) {   // TWIN — WARNS
;       int q = u; cq_theta(&q, 0.5);
;       int c = q ^ 9; cq_theta(&c, 0.1);        // the Ry keeps c in the entry block
;       int w = q * 2;
;       if (n) printf("%d", c);                  // taped on ONE classical path
;       cq_theta(&w, 0.3);                       // T
;       return cq_measure(q * 5);
;     }
;     int sib_guarded_taped_before_gate(int u) {    // TWIN — WARNS
;       int q = u; cq_theta(&q, 0.5);
;       int c = q ^ 9; cq_theta(&c, 0.1);
;       int w = q * 2;
;       if (q > 5) printf("%d", c);              // GUARDED write, before T
;       cq_theta(&w, 0.3);                       // T
;       return cq_measure(q * 5);
;     }
;
; TRACE ARGUMENT FOR THE PARK (@park_then_gate). After `ry(h, .5)`,
; h = sum_v a_v |v>. The park mints f = (h > 5), cswaps h into a |0> grave under
; f, and writes f to the tape (an unguarded CNOT copy into a KEPT output rail o):
;     sum_{v<=5} a_v |v>_h |0>_f |0>_g |0>_o  +  sum_{v>5} a_v |0>_h |1>_f |v>_g |1>_o
; `ry(h, .3)` then fires. On the surviving branch f is |0>, a product factor, so
; the Ry rotates sum_{v<=5} a_v |v> coherently, which is the source's meaning.
; Across the two branches f is a basis copy of o, and o is the tape: kept, never
; touched again, and measured at inspection (cq_runtime.h, "the measurement is
; DEFERRED to tape inspection"). By the deferred-measurement principle that is the
; same as measuring o, hence f, right at the write, which is clause 4's case
; verbatim. The flag adds no dephasing the user's own abort has not already caused.
; The FALSE-successor orientation writes NOT f inside a `cqrt_x` bracket: the tape
; still holds a bijection of f, so the argument is unchanged.
;
; WHY THE TAPE COUNTS ONLY WHEN UNGUARDED. `cqrt_tape_write_<W>(tape, src)` copies
; src in full. The guarded `..._controlled(ctrl, tape, src)` commits ctrl ? src : 0,
; which determines neither operand: on the ctrl = 0 branch src's value is on no
; tape. Clause 3 (an observation AFTER the gate) is satisfied by partial
; information, the program's own data; clause 4 (collapsed BEFORE it) needs the
; record determined, so the 3-argument spelling stays out.
; @sib_guarded_taped_before_gate pins it (the Ry on `c` keeps the xor out of the
; arm; without it `clang -O1` sinks the xor and the diamond declines at the I/O
; sink, "conditional output is not a lowerable single-sink if(q) diamond").
;
; THE NON-PARK FUNCTION. The owner ruled on the park's flag; the physics above
; never used the park. A record taped by an unguarded write before the gate is
; deferred-measured, and @sib_taped_before_gate pins that the exemption is that
; one spelling, not a park special case. Its other records: `q`'s rail is exempt
; by clause 3 (the post-gate `q * 5` read is measured), and the `q * 5` rail is
; minted after the gate (absent).
;
; THE TWINS.
;   * @park_beside_dead_record: the gate on `q` counts two records, the park flag
;     (taped before the gate: exempt) and `t`'s rail (a rotated basis record of `q`,
;     never taped, never observed: dead). The exemption is PER RECORD, so the
;     gate still warns, and it should: `t` dephases the Ry on `q`.
;   * @sib_rotated_taped_one_path: `c`'s only tape write sits in a classical arm
;     that does not dominate the gate. On the n == 0 path `c` stands untaped and
;     dead at the gate, a real dephasing, so the position test must hold.
;     (Without the Ry on `c`, `clang -O1` sinks the xor into the arm and `c` does
;     not exist on the other path; that spelling would pin the known dominance
;     over-warning instead of a hazard.)
;   * @sib_guarded_taped_before_gate: `c`'s only tape write is the GUARDED
;     `cqrt_tape_write_i32_controlled(flag, tape, c)`, before the gate and
;     dominating it. On the q <= 5 branch the entry holds 0, `c` reaches no tape,
;     and it stands dead at the gate. So the arity test must hold.
;
; bd x61g: `... if (q > 5) abort(); cq_theta(&q, .3); return cq_measure(q);`
; declines today at the park's sole-live-register guard. Once it lowers it reaches
; this exemption the same way @park_then_gate does; nothing here assumes `return 0`.
;
; RETIREMENT TRIGGER (L7): if a tape entry ever gains an `_unc`, is freed, or is
; read again after its write, the deferred-measurement step above fails and this
; clause must go. The same holds if a pass writes a record IN PLACE between its
; tape write and the gate (an `xorc`/`addc` keeps the bijection, a quantum-operand
; write does not); `cqrt_measure_*` in the same clause has the same exposure.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=WARN < %t.err

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr
declare void @abort() local_unnamed_addr #1

define noundef i32 @park_then_gate(i32 noundef %0) local_unnamed_addr {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #0
  %3 = icmp sgt i32 %2, 5
  br i1 %3, label %4, label %5

4:
  tail call void @abort() #1
  unreachable

5:
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #0
  ret i32 0
}

define noundef i32 @park_negated_then_gate(i32 noundef %0) local_unnamed_addr {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #0
  %3 = icmp sgt i32 %2, 5
  br i1 %3, label %5, label %4          ; abort is the FALSE successor

4:
  tail call void @abort() #1
  unreachable

5:
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #0
  ret i32 0
}

define i32 @sib_taped_before_gate(i32 noundef %0) local_unnamed_addr {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #0
  %3 = xor i32 %2, 9
  %4 = shl nsw i32 %2, 1
  %5 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %3)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 3.000000e-01) #0
  %7 = mul nsw i32 %2, 5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2
  ret i32 %8
}

define noundef i32 @park_beside_dead_record(i32 noundef %0) local_unnamed_addr {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #0
  %3 = xor i32 %2, 9
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 2.000000e-01) #0
  %5 = icmp sgt i32 %2, 5
  br i1 %5, label %6, label %7

6:
  tail call void @abort() #1
  unreachable

7:
  %8 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #0
  ret i32 0
}

define i32 @sib_rotated_taped_one_path(i32 noundef %0, i32 noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #0
  %4 = xor i32 %3, 9
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 1.000000e-01) #0
  %6 = icmp eq i32 %1, 0
  br i1 %6, label %9, label %7

7:
  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %5)
  br label %9

9:
  %10 = shl nsw i32 %3, 1
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 3.000000e-01) #0
  %12 = mul nsw i32 %3, 5
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2
  ret i32 %13
}

define i32 @sib_guarded_taped_before_gate(i32 noundef %0) local_unnamed_addr {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #0
  %3 = xor i32 %2, 9
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.000000e-01) #0
  %5 = icmp sgt i32 %2, 5
  br i1 %5, label %6, label %8

6:
  %7 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %4)
  br label %8

8:
  %9 = shl nsw i32 %2, 1
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 3.000000e-01) #0
  %11 = mul nsw i32 %2, 5
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  ret i32 %12
}

attributes #0 = { nomerge nounwind }
attributes #1 = { cold noreturn nounwind }
attributes #2 = { nounwind }

; The park: flag mint, grave, cswap, the flag's tape write, THEN the gate.
; CHECK-LABEL: define {{.*}}@park_then_gate(
; CHECK:      %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[G]])
; CHECK-NEXT: call i32 @cqrt_tape_write_i1(i32 %[[TAPE]], i32 %[[F]])
; CHECK-NOT:  @abort
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: ret i32 0

; FALSE-successor orientation: the write sits inside its `cqrt_x` bracket, and the
; gate follows the bracket.
; CHECK-LABEL: define {{.*}}@park_negated_then_gate(
; CHECK:      %[[NTAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK-NEXT: %[[NH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[NH]], double 5.000000e-01)
; CHECK-NEXT: %[[NF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[NH]], i32 5)
; CHECK-NEXT: %[[NG:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[NF]])
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[NF]], i32 %[[NH]], i32 %[[NG]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[NF]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[NF]])
; CHECK-NEXT: call i32 @cqrt_tape_write_i1(i32 %[[NTAPE]], i32 %[[NF]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[NF]])
; CHECK-NOT:  @abort
; CHECK:      call void @cqrt_ry_i32(i32 %[[NH]], double 3.000000e-01)
; CHECK-NEXT: ret i32 0

; Non-park: `c` is taped (unguarded, written slot) before the Ry on the wire `w`.
; CHECK-LABEL: define {{.*}}@sib_taped_before_gate(
; CHECK:      %[[STAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:      %[[SH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK:      %[[SC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[SH]], i32 9)
; CHECK-NEXT: %[[SW:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i32_hl(i32 %[[SH]], i32 1)
; CHECK-NEXT: call i32 @cqrt_tape_write_i32(i32 %[[STAPE]], i32 %[[SC]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[SW]], double 3.000000e-01)

; Twin 1: the park's flag is taped before the gate, but `t`'s rotated rail is not.
; CHECK-LABEL: define {{.*}}@park_beside_dead_record(
; CHECK:      %[[BH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK:      %[[BT:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[BH]], i32 9)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[BT]], double 2.000000e-01)
; CHECK:      %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[BH]], i32 5)
; CHECK:      call i32 @cqrt_tape_write_i1(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[BF]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[BH]], double 3.000000e-01)

; Twin 2: `c`'s tape write is confined to the classical arm; the gate is after the
; merge.
; CHECK-LABEL: define {{.*}}@sib_rotated_taped_one_path(
; CHECK:      %[[OC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 9)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[OC]], double 1.000000e-01)
; CHECK:      br i1
; CHECK:      call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OC]])
; CHECK-NEXT: br label
; CHECK:      %[[OW:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i32_hl(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[OW]], double 3.000000e-01)

; Twin 3: the GUARDED write of `c` dominates the gate, and the gate follows the
; flag's strip.
; CHECK-LABEL: define {{.*}}@sib_guarded_taped_before_gate(
; CHECK:      %[[GC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 9)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[GC]], double 1.000000e-01)
; CHECK-NEXT: %[[GF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK-NEXT: call i32 @cqrt_tape_write_i32_controlled(i32 %[[GF]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[GC]])
; CHECK:      call void @cqrt_free(i32 %[[GF]])
; CHECK-NEXT: %[[GW:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i32_hl(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[GW]], double 3.000000e-01)

; Exactly three warnings, one per twin, in module order; nothing for the first three.
; WARN-NOT: in function park_then_gate
; WARN-NOT: in function park_negated_then_gate
; WARN-NOT: in function sib_taped_before_gate
; WARN:     warning: {{.*}}in function park_beside_dead_record i32 (i32): cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: warning
; WARN:     warning: {{.*}}in function sib_rotated_taped_one_path i32 (i32, i32): cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: warning
; WARN:     warning: {{.*}}in function sib_guarded_taped_before_gate i32 (i32): cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: warning
