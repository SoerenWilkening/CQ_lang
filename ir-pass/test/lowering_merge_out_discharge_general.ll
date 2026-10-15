; lowering_merge_out_discharge_general.ll — ACCEPT, DISCHARGED: the GENERAL
; merge-rail discharge (bd test_C_libtooling-r2j3.32, R11 round-1 fix): every
; controlled-copy merge family, every reader placement, and the control-slot
; read. Companion of lowering_merge_out_discharge.ll (the select-merge core).
;
; Each function below states its ANALYTIC check (Rule 2: the argument is the
; evidence; these CHECK lines pin the stream that argument is about).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; SILENT-NOT: {{.}}

; ── 1. The 4.5 DATA-MUX: %out is born holding the default literal 2 (the
;       PRELOAD), not |0>. Forward: out ^= 7·[q==0] (2^5) then ^= 11·[q==1]
;       (2^9), so out = {5, 9, 2}. The adjoint re-applies the same two XORs
;       (reversed; both flags still live and q only read in the window), which
;       returns out to |2>, then `cqrt_xorc_i32(out, 2)` takes it to |0> and the
;       free is a proven-|0> free. No `cqrt_x`: the data-mux has no bracket.
; CHECK-LABEL: define i32 @datamux(
; CHECK:      %[[DOUT:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: %[[DF0:[0-9a-zA-Z_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[DQ:[0-9a-zA-Z_.]+]], i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[DF0]], i32 %[[DOUT]], i32 7)
; CHECK-NEXT: %[[DF1:[0-9a-zA-Z_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[DQ]], i32 1)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[DF1]], i32 %[[DOUT]], i32 11)
; bd r2j3.33 (dm7f.51 step 1): `p`'s old value is dead and `u` is measured, so the
; reader is the IN-PLACE `cqrt_add_i32(out, p)` on `p`'s rail. For `out` it is the
; same finished reader the template was (`isInteriorConsumer` (b‴) / `onlyReads`),
; so the discharge below is unchanged: `out` keeps its label across the add.
; CHECK-NEXT: call void @cqrt_add_i32(i32 %[[DOUT]], i32 %{{[0-9a-zA-Z_.]+}}), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[DF1]], i32 %[[DOUT]], i32 11)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[DF0]], i32 %[[DOUT]], i32 7)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[DF0]], i32 %[[DQ]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[DF0]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[DF1]], i32 %[[DQ]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[DF1]])
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[DOUT]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[DOUT]])

; ── 2. The SURVIVOR: a data-mux %rm read ONLY by a 4.4 select merge. The outer
;       select rail is undone first (it reads the data-mux rail as a copy
;       source), then the data-mux rail after that whole group (LIFO).
;       (The coordinator's full shape adds `cq_theta` on the scrutinee after the
;       reader; that declines UPSTREAM today, `condition predates a
;       non-diagonal gate`, so it is pinned here without the rotation.)
; CHECK-LABEL: define i32 @datamux_into_select(
; CHECK:      %[[SOUT:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK:      %[[SOUT2:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[SBF:[0-9a-zA-Z_.]+]], i32 %[[SOUT]], i32 %[[SOUT2]])
; CHECK:      call i32 @cq_template_add_i32(i32 %[[SOUT2]],
; CHECK-NEXT: call void @cqrt_x(i32 %[[SBF]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[SBF]], i32 %[[SOUT2]], i32 7)
; CHECK-NEXT: call void @cqrt_x(i32 %[[SBF]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[SBF]], i32 %[[SOUT]], i32 %[[SOUT2]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[SBF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[SBF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[SOUT2]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(
; CHECK:      call void @cqrt_xorc_i32(i32 %[[SOUT]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[SOUT]])

; ── 3. The 4.5 switch VALUE merge: an UNCONTROLLED preload copy of the default
;       base p, then per case out ^= [q==c_i]·(R_i(p) ^ p) from a KEPT XOR-delta
;       rail. Forward: out = p ^ Σ f_i·d_i. The adjoint replays every write of
;       out reversed — the deltas and p are only read in the window, the flags
;       live — so out = 0, a proven-|0> free. The hoisted chains and deltas
;       between the copies are NOT replayed (they never write out, and nothing
;       they write is read by an earlier copy).
; CHECK-LABEL: define i32 @switch_value(
; CHECK:      %[[VOUT:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[VP:[0-9a-zA-Z_.]+]], i32 %[[VOUT]])
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[VF0:[0-9a-zA-Z_.]+]], i32 %[[VD0:[0-9a-zA-Z_.]+]], i32 %[[VOUT]])
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[VF1:[0-9a-zA-Z_.]+]], i32 %[[VD1:[0-9a-zA-Z_.]+]], i32 %[[VOUT]])
; CHECK-NEXT: call i32 @cq_template_mul_i32_hl(i32 %[[VOUT]], i32 3)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[VF1]], i32 %[[VD1]], i32 %[[VOUT]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[VF0]], i32 %[[VD0]], i32 %[[VOUT]])
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[VP]], i32 %[[VOUT]])
; CHECK:      call void @cqrt_free(i32 %[[VF1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[VOUT]])

; ── 4. A per-TRIP merge inside a rolled loop (Dicke's `s = 2*q[m-1]+q[m-l]`):
;       the stream, its reader and its reversal are all in the trip's block, so
;       the free runs once per forward run; `a` is rotated only after the loop.
; CHECK-LABEL: define i32 @in_loop(
; CHECK:      loop:
; CHECK:      %[[LOUT:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call void @cq_template_or_i32_unc(i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[LOUT]],
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[LBF:[0-9a-zA-Z_.]+]], i32 %[[LOUT]], i32 2)
; CHECK-NEXT: call void @cqrt_cnot(i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[LBF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[LBF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[LOUT]])
; CHECK:      br i1 %e, label %exit, label %loop
; CHECK:      exit:
; CHECK-NEXT: call void @cqrt_ry_i1(

; ── 5. The reader sits in a block with TWO predecessors: the replay is placed
;       at the nearest common post-dominator (`j`), the stream's flag strip
;       moves there with it, and the region entry..j is single-entry.
; CHECK-LABEL: define i32 @diamond_reader(
; CHECK:      %[[XOUT:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      br i1 %c, label %l, label %r
; CHECK:      j:
; CHECK:      call i32 @cq_template_add_i32(i32 %[[XOUT]],
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(
; CHECK:      call void @cqrt_free(i32 %[[XOUT]])
; CHECK:      call void @cqrt_ry_i1(i32 %{{[0-9a-zA-Z_.]+}}, double -5.000000e-01)

; ── 6. A CONTROL-slot read of the condition register in the window: the
;       prep `cqrt_ry_i1_controlled(a, t, .7)` keeps a's label, so the record
;       and the strip are unaffected and the rail is still discharged.
; CHECK-LABEL: define i32 @control_read(
; CHECK:      %[[COUT:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call void @cqrt_ry_i1_controlled(i32 %[[CA:[0-9a-zA-Z_.]+]], i32 %{{[0-9a-zA-Z_.]+}}, double 0x3FE6666666666666)
; CHECK:      call i32 @cq_template_add_i32(i32 %[[COUT]],
; CHECK:      call void @cqrt_cnot(i32 %[[CA]], i32 %{{[0-9a-zA-Z_.]+}})
; CHECK-NEXT: call void @cqrt_free(
; CHECK-NEXT: call void @cqrt_free(i32 %[[COUT]])
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

; item 1: the condition register reaches the merge through a loop-carried phi
define i32 @datamux(i32 noundef %u0, i32 noundef %u1) {
entry:
  %q = tail call i32 @cq_theta_si32(i32 noundef %u0, double noundef 5.000000e-01) #0
  %p = tail call i32 @cq_theta_si32(i32 noundef %u1, double noundef 6.000000e-01) #0
  switch i32 %q, label %j [ i32 0, label %c0
                            i32 1, label %c1 ]
c0:
  br label %j
c1:
  br label %j
j:
  %rm = phi i32 [ 5, %c0 ], [ 9, %c1 ], [ 2, %entry ]
  %u = add i32 %rm, %p
  %r = tail call i32 @cq_measure_si32(i32 noundef %u)
  %m = tail call i32 @cq_measure_si32(i32 noundef %q)
  %t = add i32 %r, %m
  ret i32 %t
}

; item 2 survivor: a data-mux read only by a 4.4 select merge, then cq_theta on
; the scrutinee
define i32 @datamux_into_select(i32 noundef %u0) {
entry:
  %q = tail call i32 @cq_theta_si32(i32 noundef %u0, double noundef 5.000000e-01) #0
  %b = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #0
  switch i32 %q, label %j [ i32 0, label %c0
                            i32 1, label %c1 ]
c0:
  br label %j
c1:
  br label %j
j:
  %rm = phi i32 [ 5, %c0 ], [ 9, %c1 ], [ 2, %entry ]
  %s = select i1 %b, i32 %rm, i32 7
  %bz = zext i1 %b to i32
  %u = add i32 %s, %bz
  %r = tail call i32 @cq_measure_si32(i32 noundef %u)
  %m = tail call i32 @cq_measure_si32(i32 noundef %q)
  %t = add i32 %r, %m
  ret i32 %t
}

; item 2: a 4.5 switch VALUE merge (uncontrolled preload copy + XOR deltas)
define i32 @switch_value(i32 noundef %u0, i32 noundef %p0) {
entry:
  %q = tail call i32 @cq_theta_si32(i32 noundef %u0, double noundef 5.000000e-01) #0
  %p = tail call i32 @cq_theta_si32(i32 noundef %p0, double noundef 6.000000e-01) #0
  switch i32 %q, label %j [ i32 0, label %c0
                            i32 1, label %c1 ]
c0:
  %v0 = add i32 %p, 1
  br label %j
c1:
  %v1 = add i32 %p, 2
  br label %j
j:
  %rv = phi i32 [ %v0, %c0 ], [ %v1, %c1 ], [ %p, %entry ]
  %u = mul i32 %rv, 3
  %r = tail call i32 @cq_measure_si32(i32 noundef %u)
  %m = tail call i32 @cq_measure_si32(i32 noundef %q)
  %t = add i32 %r, %m
  ret i32 %t
}

; item 3: a per-TRIP merge inside a rolled loop (Dicke's `s = 2*a + b`)
define i32 @in_loop(i32 %n) {
entry:
  %a = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %b = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #0
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc1, %loop ]
  %s = select i1 %a, i32 2, i32 0
  %bz = zext i1 %b to i32
  %w = or disjoint i32 %s, %bz
  %u = add i32 %w, %i
  %r = tail call i32 @cq_measure_si32(i32 noundef %u)
  %acc1 = add i32 %acc, %r
  %i1 = add i32 %i, 1
  %e = icmp eq i32 %i1, 3
  br i1 %e, label %exit, label %loop

exit:
  %a2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %a, double noundef -5.000000e-01) #0
  %m = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %a2)
  %z = zext i1 %m to i32
  %q = add i32 %acc1, %z
  ret i32 %q
}

; item 3: the reader sits in a block with TWO predecessors (classical diamond)
define i32 @diamond_reader(i1 %c) {
entry:
  %a = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %b = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #0
  %s = select i1 %a, i32 2, i32 0
  br i1 %c, label %l, label %r

l:
  br label %j

r:
  br label %j

j:
  %bz = zext i1 %b to i32
  %u = add i32 %s, %bz
  %m = tail call i32 @cq_measure_si32(i32 noundef %u)
  %a2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %a, double noundef -5.000000e-01) #0
  %ma = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %a2)
  %z = zext i1 %ma to i32
  %q = add i32 %m, %z
  ret i32 %q
}

; item 8: a CONTROL-slot read of the condition register inside the window
define i32 @control_read(i32 %n) {
entry:
  %a = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %b = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #0
  %s = select i1 %a, i32 2, i32 0
  br i1 %a, label %rot, label %j

rot:
  %t1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 7.000000e-01) #0
  br label %j

j:
  %t = phi i1 [ %t1, %rot ], [ false, %entry ]
  %bz = zext i1 %b to i32
  %u = add i32 %s, %bz
  %m = tail call i32 @cq_measure_si32(i32 noundef %u)
  %a2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %a, double noundef -5.000000e-01) #0
  %ma = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %a2)
  %mt = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %t)
  %z = zext i1 %ma to i32
  %zt = zext i1 %mt to i32
  %q = add i32 %m, %z
  %q2 = add i32 %q, %zt
  ret i32 %q2
}


attributes #0 = { nomerge nounwind }
