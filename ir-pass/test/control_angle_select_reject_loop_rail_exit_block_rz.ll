; control_angle_select_reject_loop_rail_exit_block_rz.ll — DECLINE (S7, the RAIL
; CLOSURE prong), `cq_phi` STEM. Read
; `control_angle_select_reject_loop_rail_exit_block.ll`'s header for the round-1
; Rule-13 finding (lens L2-1) and for why the twin cannot be posed here.
;
; THIS FILE IS THE ONE THAT PINS THE "BOTH STEMS" HALF OF THE FIX. Before the
; round-1 repair the Rz stem computed NO rail closure at all — `classifyAngleSelect`
; returned `Accepted` for `cq_phi` immediately after S6, so S8's and S9's
; `railWireClosure` calls were on the Ry path only. The fix moves the closure
; computation UP to S7, where both stems reach it, and reuses the SAME closure for
; S8/S9 rather than recomputing it (Rule 14, and the 8h7d.5 "what OTHER set is
; computed over this closure" discipline: the answer is S8's intersection, S9's
; member enumeration and S9's skip set, and none of them changed).
;
; The Rz stem's §12.1 diagonal exemption is about BASIS LABELS — it says nothing
; about a loop, so extending the loop question to it is not a narrowing of that
; exemption.
;
; TWO ASYMMETRIES THE PRONG DOES NOT COVER, recorded here because this is one of
; the two fixtures a reader reaches for when asking what S7's rail prong means
; (bd drbq Inc 2b, ROUND-2 Rule-13 review, lens R1 item 2):
;   (1) it asks the ROTATED register's closure ONLY, never the CONDITION
;       register's. The mirror shape — the condition register is the loop rail,
;       read in the exit block, the rotated register outside — ACCEPTS
;       (`review2b_r2/R1/probes/s7/oa2_condrail_loop_{ry,rz}.ll`) and is
;       byte-identical to its manual twin on the pre-2b oracle. Sound; unasked.
;   (2) the closure carries `Exclude = T`, so the rail FORWARD of the consumer is
;       asked by no prong at all — see the accept fixture
;       `control_angle_select_forward_rail_cycle_frozen.ll`, which pins that gap
;       and the byte-identity argument that makes it sound.
; AND ONE CONTINGENCY, which is the mechanism this very fixture rests on (lens R1
; item 3): the prong sees `%qn` only because `lowerLoops`' Case-A persistent-rail
; COLLAPSE (`CQLoweringPass.cpp:310`, before detection) has already rewritten the
; header phi and re-anchored the in-loop gate onto the base. Without such a phi the
; identical forward read ACCEPTS (`nat_sel_rz.ll`). A future change to Case-A's
; collapse therefore silently NARROWS S7, and no fixture here would notice.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control
; 3qlq: migrated from register cq_phi (mixed sites: see the migration report)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p  = call i32 @cq_theta_si32(i32 %u1, double 1.250000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %qn = call i32 @cq_theta_si32(i32 %q, double -5.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %c2 = icmp eq i32 %p, 7
  %ang = select i1 %c2, double 9.000000e-01, double 3.000000e-01
  call void @cq_phi(double %ang)
  %m0 = call i32 @cq_measure_si32(i32 %qn)
  %m1 = call i32 @cq_measure_si32(i32 %p)
  %s = add i32 %m0, %m1
  ret i32 %s
}
