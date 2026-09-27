/* spec_classical_return_caller.c — bd test_C_libtooling-9bhg e2e smoke: a function
   that RETURNS a specialization-classical call result, read by its caller, through
   the full multi-TU pipeline (clang -O1 per TU -> llvm-link -> opt cq-lowering ->
   link -> run; the ONLY layer that LINKS, Rule 2/16).

   `f` returns `h2(q, k + z)` with `z = cq_measure(q)`: the call is a Phase-6 site
   whose clone `__cq_q_h2_01` proves the classical `k + z + 1`, so `f` returns a
   CLASSICAL integer. bd 3jru's refusal (`quantum value returned across a function
   boundary`) ran on the pre-specialize conservative taint and declined this module;
   bd 9bhg does not let that provisional taint cross `f`'s return and re-asks the
   refusal after `specialize()`. `main` at bd vsfp's landing (c1136be2) DECLINES this
   module with the 3jru string; this branch accepts it (measured).

   ⚠ RE-SPELLED AT THE bd vsfp MERGE (2026-09-27), and why. The first spelling had
   `h(a, k) { return k + 1; }`. `h` ignores `a`, so vsfp's `dropDeadCallArguments`
   replaced `q` by a constant before propagation (`CQ_DEADARG_DBG: drop arg 0 of @h
   in @f`, measured). That left no Phase-6 site and no provisional return: the module
   was the hand-inlined twin, the golden still matched (the clone call emits no
   gate), and the slice had silently stopped witnessing 9bhg.
   - 7 other C spellings of a callee that keeps `a` live were tried (TRACK_9BHG §12:
     a conditional or unconditional `putchar`/`printf`/global store of `a`, a call
     `g(a)`, a volatile-guarded select). Every one declines at `scanBody`, on every
     binary.
   - The spelling that reaches 9bhg's path is r5/r6_vsfp's `mt2`/`mm1` shape: a
     `musttail` call (the drop keeps a `musttail` call's operands) to a callee whose
     read of `a` is a branch over a volatile load of a never-written static global.
     vsfp's global fold removes that read in the clone only. The clone records slot
     0 dead, and `resolvePhantomCloneArgReads` neutralises it; `q` is a `cq_theta`
     result, the neutraliser's one exemption.
   - The golden is UNCHANGED, byte for byte. It is also the trace of the hand-inlined
     twin (`return k + z + 1;`), measured.
   RETIREMENT TRIGGER: if the drop starts dropping `musttail` operands, or `scanBody`
   stops admitting the volatile-guarded read, this slice collapses to the twin again,
   still green. Re-check with `CQ_DEADARG_DBG=1` and a `main` binary (it must decline).

   TRACE CONTRACT (analytically audited): `main` rotates its own register `q2`
   (`cqrt_alloc_i32(5) -> h0` + `cqrt_ry_i32`), then calls `f(3, 3)`, which rotates
   `q` (`cqrt_alloc_i32(3) -> h1` + `cqrt_ry_i32`) and measures it
   (`cqrt_measure_i32`, which the trace runtime answers 0). It then tail-calls the
   classical clone with slot 0 neutralised (no gate). `f` returns 3 + 0 + 1 = 4, a
   CLASSICAL value, and `main`'s `q2 + f(3, 3)` is therefore a MIXED add with the
   value 4 as its literal. It is lowered IN PLACE (M-C, `q2` is dead after it) as
   `cqrt_addc_i32(h0, 4)`. The literal 4 IS the witness: had the provisional taint
   crossed `f`'s return, the call result would have been a "handle" and the add a
   Q+Q add over the integer 4 used as a register id. The sum is measured; neither
   rail is freed (both are measured — Rule 6). */
int h2(int a, int k);

__attribute__((noinline)) int f(int m, int k) {
    int q = cq_theta(m, .5);
    int z = cq_measure(q);
    __attribute__((musttail)) return h2(q, k + z);
}

int main(void) {
    int q2 = cq_theta(5, .25);
    int s = q2 + f(3, 3);
    (void) cq_measure(s);
    return 0;
}
