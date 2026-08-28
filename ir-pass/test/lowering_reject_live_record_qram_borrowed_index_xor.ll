; lowering_reject_live_record_qram_borrowed_index_xor.ll — DECLINE, and it is a
; KNOWN, DELIBERATE OVER-DECLINE (M-A Increment 1, bd test_C_libtooling-6uqc).
; This file carries the ORIGINAL body of lowering_io_tape_qram_borrowed_index.ll
; verbatim; that fixture keeps the same shape with the xor leg dropped, so each
; file now pins exactly one thing.
;
; WHAT CARRIES THE DECLINE: the xor rail `%h_op2` —
; `cq_template_xor_i32_hl(%IDX, 1)`, the index used to address the STORE. It is a
; descendant record of the index wire; its only reader is the `cqrt_qram_store`
; that precedes the gate; and the spine's discharge for it (`_unc` + `cqrt_free`)
; is emitted AFTER the gate, so clause 2 does not exempt it. It is therefore
; undischarged and entangled with `%IDX` at the instant `cqrt_ry(%IDX, 0.25)`
; fires, which is precisely what the guard declines.
;
; WHY IT IS AN OVER-DECLINE, and the argument is specific to this module rather
; than a general excuse. The guard's predicate is a LOCAL one — "a record is
; standing at the gate" — and it cannot see that here the dephasing PROVABLY
; CANCELS. Read the emitted stream in order: `cqrt_ry(%IDX, +0.25)` fires with
; `%h_op2` standing, and the very next thing to touch that wire is the spine's
; own `cqrt_ry(%IDX, -0.25)`, emitted as the adjoint at the reversal point.
; NOTHING BETWEEN THEM TOUCHES THE INDEX WIRE. The one intervening gate is
; `cqrt_tape_write_i32(%TAPE, %U)`, and that acts on registers DISJOINT from
; `%IDX` — so it commutes with a rotation on `%IDX`, entanglement between `%U`
; and `%IDX` notwithstanding (operators on disjoint tensor factors commute
; regardless of the state). The composite acting on `%IDX` is therefore
; `Ry(-0.25) · Ry(+0.25) = I`. A rotation that is exactly undone before anything
; acts on that wire again dephases nothing, whatever was entangled with it
; meanwhile. The very ORDER that makes this true is what the positive twin exists
; to pin.
;
; SO WHY NOT CARVE IT OUT? Because proving "the gate is exactly undone before any
; observation" is a WHOLE-STREAM property, and the mechanism that will own it is
; M-B (interior-rail uncompute, bd 6uqc option (b)) — not a special case bolted
; onto a local predicate. Until M-B ships, over-declining is the safe direction
; (Prime Directive) and this fixture is the record of what it costs. It is a
; PINNED COST, not a latent bug: no user program is miscompiled by it, and the
; capability it blocks is a QRAM store through a derived index followed by an
; in-place rotation on that same index.
;
; IF THIS STARTS TO ACCEPT, that is M-B landing (or a carve-out someone added).
; Either way, re-derive the cancellation above before believing the new verdict,
; and move this file back to a positive fixture rather than deleting it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0, i32 %k) {
entry:
  %arr = alloca [4 x i32], align 16
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %arr, i8 0, i64 16, i1 false)
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %idx = and i32 %q, 3
  %j   = xor i32 %idx, 1
  %je  = zext nneg i32 %j to i64
  %pj  = getelementptr inbounds [4 x i32], ptr %arr, i64 0, i64 %je
  store i32 %k, ptr %pj, align 4
  %ie  = zext nneg i32 %idx to i64
  %pi  = getelementptr inbounds [4 x i32], ptr %arr, i64 0, i64 %ie
  %u   = load i32, ptr %pi, align 4
  %q2  = call i32 @cq_theta_si32(i32 %idx, double 2.500000e-01)
  %z   = call i32 (ptr, ...) @printf(ptr @.str, i32 %u)
  ret void
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
