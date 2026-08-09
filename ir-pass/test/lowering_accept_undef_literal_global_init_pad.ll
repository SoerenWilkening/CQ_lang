; lowering_accept_undef_literal_global_init_pad.ll — ACCEPT (bd xy9n).
; ARM: `slotCarriesUndef`'s GLOBAL-ADDRESS skip, and the only thing pinning it.
;
; *** THIS FIXTURE EXISTS BECAUSE THE FIRST DRAFT OF GUARD 1 DECLINED THIS
; WELL-DEFINED PROGRAM. *** `constantCarriesUndef` recurses through a Constant's
; operands, and a `GlobalVariable`'s operands ARE its initializer — so
; `ptrtoint (ptr @u to i32)` read as an undef leaf merely because `@u`'s padding is
; `undef`. The value in the slot is the global's ADDRESS, which is defined no matter
; what it is initialised to, and the SAME uniqued ConstantExpr appears in the
; forward gate and its adjoint: ONE link-time relocation, both reads agree, nothing
; to disagree at run time (the bu96 doctrine, verbatim).
;
; IT IS REACHABLE, not adversarial. `clang -O1` emits exactly this initializer shape
; for a partially-initialised union — measured on this machine:
;     union U2 { long double f; int i; };  union U2 v = { .i = 3 };
;   -> @v = local_unnamed_addr global { i32, [12 x i8] } { i32 3, [12 x i8] undef }
; which is the fp80-union idiom this whole project is built on (3c6m.51
; promoteFp80Union, the `ieee_extended_shape_type` reads, every `ld80` slice).
;
; SCOPE, so nobody "unifies" the two predicates: `PredMuxFlatten`'s cone proof keeps
; the UN-skipped `valueCarriesUndef` byte-for-byte as shipped. There the same
; over-decline is PRE-EXISTING, and removing it would be an accept WIDENING in a
; tightening commit (bd ajw7, filed with its own red-green pair owed). Guard 1 is
; NEW code, so at its call site there was no shipped behaviour to preserve — it gets
; the correct semantics from the start. Two predicates, one shared walk, one flag.
;
; GREEN ON BOTH plugins by design (BASE lowers it too), so it is absent from the
; differential; its power is arm-kill — point guard 1 back at `valueCarriesUndef`
; and this fixture goes red.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
;
; The address survives verbatim into BOTH the forward gate and its adjoint:
; CHECK: %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 ptrtoint (ptr @u to i32))
; CHECK: call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 ptrtoint (ptr @u to i32))

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%struct.S = type { i32, [4 x i8] }
@u = global %struct.S { i32 1, [4 x i8] undef }, align 4

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %d = add i32 %q, ptrtoint (ptr @u to i32)   ; dead terminal -> the spine adjoints it
  ret void
}
