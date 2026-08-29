; lowering_live_record_tape_ctrl_observed_accept.ll — ACCEPT: the CTRL slot of a
; GUARDED 7.6 tape write is an OBSERVING SINK, not only its written slot (M-A, bd
; test_C_libtooling-6uqc; round 2 of the Increment-3 Rule-13 round, 2026-08-28).
;
; SOURCE (the reviewer's d5 witness, verbatim in structure):
;     static volatile int k = 3;
;     int a = cq_theta(u0, 0.5);
;     int c = a * k;                     // the ONLY record (volatile k so -O1 keeps
;                                        //   the multiply; the pass sees the folded
;                                        //   literal, written directly here)
;     a = cq_theta(a, 0.25);             // T — chained, IN PLACE on the alloc rail
;     if (c > 3) printf("%d", a);        // c -> the CTRL of the guarded tape write
;
; WHAT STANDS AT THE GATE — and note the module is deliberately CLEAN. Because the
; chained theta is in place on `%h` itself, the WIRE is the alloc rail, so `%h` is
; excluded by clause 5 and there is exactly ONE record to judge: `%h_op` (`c`).
; `%h_cmp` is minted after `T` (clause-6 skip). No other rail exists. The verdict
; is `c`'s alone, with nothing else able to carry or mask it.
;
; WHY IT LOWERS. `%h_op`'s post-gate lineage is
;     c --(cq_template_icmp_sgt, a HOP)--> %h_cmp
;       --(the CTRL slot of cqrt_tape_write_i32_controlled)--> the OBSERVING SINK.
;
; WHY THE CTRL SLOT IS A SINK. `cqrt_tape_write_<W>_controlled(ctrl, tape, src)`
; writes an entry IFF `ctrl` is set, so whoever reads the output tape learns the
; flag from the PRESENCE OR ABSENCE of the entry — an observation of `c` just as
; surely as a write of `c` itself would be. Before this round only the last
; (written) slot counted, so this program declined while its one-line twin
; `printf("%d", c)` — the same `c`, in the SRC slot — accepted. Same physics at the
; gate, opposite verdicts, decided by which slot the flag landed in.
;
; HEAD (d2828e3) `opt` exit 0. PRE-ROUND-2 TREE `opt` exit 1 — a C-REACHABLE
; OVER-DECLINE, measured on the C above through the real pipeline.
;
; NO MEASUREMENT ANYWHERE (Rule 5: the compiler never inserts one). Like
; lowering_live_record_sibling_read_taped_accept.ll, every exemption here is
; carried by the 7.6 output tape, whose `out_handle` is a KEPT output rail
; (`taint.OutputRails`) — never uncomputed, never freed.
;
; THE TAPE TOKEN IS STILL NOT A SINK. Only slots 0 (ctrl) and 2 (src) of the
; 3-argument form observe; slot 1 is the tape handle, a classical resource token
; and not a rail at all, and the 2-argument form has no ctrl slot to consider.
; ARITY is the discriminator, not the `_controlled` suffix — see
; `reachesObservingSink` for the signature citations.
;
; `mul` is the vehicle (information-losing => never M-C-converted in place), so `c`
; really is a separate rail and not a second name for the wire.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c  = mul i32 %q, 3                                          ; the ONLY record
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)   ; T — in place on %h
  %cc = icmp sgt i32 %c, 3
  br i1 %cc, label %emit, label %done
emit:
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q2)
  br label %done
done:
  ret void
}

; The record, the in-place gate on the alloc rail, the compare that reads the
; record, and the GUARDED tape write whose CTRL slot is that compare's flag:
; CHECK:      %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[C]], i32 3)
; CHECK:      call i32 @cqrt_tape_write_i32_controlled(i32 %[[FLAG]], i32 %[[TAPE]], i32 %[[H]])
; CHECK-NOT:  cq rotation lowering
; CHECK-NOT:  cqrt_measure

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
