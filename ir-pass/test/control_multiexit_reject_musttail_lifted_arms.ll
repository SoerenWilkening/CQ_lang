; control_multiexit_reject_musttail_lifted_arms.ll — DECLINE, a GAP fixture (bd
; test_C_libtooling-dm7f.5): the bd's own reproducer,
;     int q = u; cq_theta(&q, .5);
;     if (q > 5) __attribute__((musttail)) return g(q);
;     __attribute__((musttail)) return h(q);
; (`clang -O1` output, cleaned). Before dm7f.5 it declined `non-reconverging value
; exit under quantum control` (measured, main 7b4e6359). The multi-exit half is now
; built: the `musttail`s are demoted, the `ret`s merge, and the module is the IR clang
; emits for the same source WITHOUT the attribute — which declines today for a reason
; that has nothing to do with exits: both arms are calls of LIFTED (Phase-6) functions
; with a TAINTED argument, and a lifted call inside a tainted value arm has no
; lowering yet. This file pins that the `musttail` spelling now reaches EXACTLY the
; plain-return twin's verdict (measured on main: `value-arm swap-route`, the same
; string). It is a compiler gap, not a physics decline (R1), reported with dm7f.5.
; Retirement trigger: when a lifted call in a tainted value arm lowers (Bennett: run
; both clones, mux the results — what a clone body already does with the same arms
; via PredMux), this file flips to an ACCEPT; re-derive it then, do not delete it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: value-arm swap-route under quantum control

declare i32 @cq_theta_si32(i32, double)

define i32 @g(i32 %x) #0 {
  %m = mul nsw i32 %x, 3
  %a = add nsw i32 %m, 1
  ret i32 %a
}

define i32 @h(i32 %x) #0 {
  %r = xor i32 %x, 5
  ret i32 %r
}

define i32 @f(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %b
a:
  %r1 = musttail call i32 @g(i32 %q)
  ret i32 %r1
b:
  %r2 = musttail call i32 @h(i32 %q)
  ret i32 %r2
}

attributes #0 = { noinline nounwind willreturn memory(none) }
