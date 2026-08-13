; lowering_fp80_union_reconstruct_pack.ll — ACCEPT (bd 3c6m.55 Inc 1, Lever
; A.1d): the INTEGER-SEEDED SET_LDBL reconstruct pack. openlibm floorl builds
; `u.e` from scratch — NO fp80 seed store: an RMW of the offset-8 expsign word
; (`load i64 @8; and -65536` keeps only the would-be padding junk; `or` the new
; 16-bit expsign), plus full manh/manl word stores, then `return u.e` reloads
; the whole value (the pack terminal). analyzeStructure accepts the no-fp80-
; seed shape iff the §4.4 definedness proof holds (packDefinednessOk):
;   P1 — every fp80 reload's significant bits [0,80) are covered by DOMINATING
;        word inserts (expsign@8 [64,80) + manh@4 [32,64) + manl@0 [0,32));
;   P2 — the RMW pre-load's uncovered significant bits [0,16) die in the
;        `and -65536` mask in its only user.
; The pack promotes and lowers as the tainted i80 field-insert stream (the
; 3c6m.51 Inc-2 zext/shl/or family); the model's unwritten-padding read
; constant-folds to the literal 0 the walk proved unobservable. Packs are
; ALWAYS classified opportunistic — a walk failure drops them silently.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare i64 @cq_theta_sll(i64, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @packcell(i64 %w0) {
entry:
  %q = call i64 @cq_theta_sll(i64 %w0, double 5.000000e-01)
  %manl64 = and i64 %q, 4294967295
  %manl = trunc i64 %manl64 to i32
  %hi = lshr i64 %q, 32
  %manh = trunc i64 %hi to i32
  %u = alloca %union.IEEEl2bits, align 16
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  %old = load i64, ptr %p8, align 8
  %keep = and i64 %old, -65536
  %es = and i64 %q, 65535
  %w = or disjoint i64 %keep, %es
  store i64 %w, ptr %p8, align 8
  %p4 = getelementptr inbounds i8, ptr %u, i64 4
  store i32 %manh, ptr %p4, align 4
  store i32 %manl, ptr %u, align 16
  %e = load x86_fp80, ptr %u, align 16
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %e)
  ret x86_fp80 %m
}

; the pack promotes (no alloca, no stores survive) and the field-inserts lower
; as the i80 insert stream, terminal bitcast back to f80 into the measure:
; CHECK:     define x86_fp80 @packcell(
; CHECK-NOT: alloca
; CHECK:     call i32 @cq_template_zext_i64_to_i80(
; CHECK:     call i32 @cq_template_shl_i80_hl(i32 %{{[a-z0-9_]+}}, i80 64)
; CHECK:     call i32 @cq_template_zext_i32_to_i80(
; CHECK:     call i32 @cq_template_shl_i80_hl(i32 %{{[a-z0-9_]+}}, i80 32)
; CHECK:     call i32 @cq_template_or_i80(
; CHECK:     call i32 @cq_template_bitcast_i80_to_f80(
; CHECK:     call x86_fp80 @cqrt_measure_f80(
; CHECK-NOT: store
