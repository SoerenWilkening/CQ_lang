; control_classical_call_arm_twin_accept_deep_chain.ll — ACCEPT (bd dm7f.21).
; A 20000-deep pure call chain whose LEAF returns `add nsw` under `noundef`: the
; poison reaches a `noundef` sink at the bottom, so every one of the 20001 levels is
; hoisted as its speculation-safe twin. The root call's argument is frozen by bd
; 9hea (its poison would flow to that sink), the leaf twin freezes its `ret`.
;
; WHY 20000: it is past the depth at which a RECURSIVE poison walk dies. Measured on
; main (db4cf60a, bwfp's recursive `poisonFlow`): 10000 deep rc=0, 20000 deep
; rc=132 (SIGILL on the 8MB stack, ZERO stderr: a crash, not a decline), and the
; same for a recursive twin builder (this unit's first draft). `solve` and
; the builder (SpeculationTwin.cpp, `TwinPlanner` with one memo per build) now use
; explicit stacks, bd ziuw's discipline. The R11 round-1 verification pass (each
; twin re-planned on its own body) must stay linear here: a fresh memo per twin
; made this chain quadratic (a measured >600s probe timeout before the fix). Measured cost on this machine: about
; 1.5s; the 60000-deep accept/decline pair is
; lowering_predmux_purecallee_deep_chain.ll, which the recursive walk also broke.
;
; This module is empty by construction; the input is generated (see the generator's
; header for why it is not committed as text).
; RUN: %python %S/Inputs/gen_deep_pure_chain.py 20000 twin > %t.in.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %t.in.ll > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define void @example(
; CHECK:       %[[FR:[a-zA-Z0-9_.]+]] = freeze i32 %arg
; CHECK-NEXT:  %r = call i32 @__cq_specsafe_f_0(i32 %[[FR]])
; CHECK:       define internal noundef i32 @__cq_specsafe_f_20000(i32 %a)
; CHECK-NEXT:    %s = add nsw i32 %a, 100
; CHECK-NEXT:    %s.fr = freeze i32 %s
; CHECK-NEXT:    ret i32 %s.fr
