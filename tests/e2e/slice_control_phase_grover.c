/* slice_control_phase_grover.c — bd test_C_libtooling-3qlq Increment 1 (PRD §6.5):
   GROVER WITH A CORRECT ORACLE, flat, two iterations written out.

   SOURCE INTENT:
       cq_theta(&q, 0.3);            state preparation / diffusion half
       if (q == 5) cq_phi(PI);          O  — the oracle: mark |5>
       cq_theta(&q, 0.3);
       if (q == 0) cq_phi(PI);          R0 — reflect about |0>
       ... the four lines again ...
       measure q

   WHY THIS SLICE EXISTS. Every `slice_control_*grover*` golden that PRE-DATED
   3qlq encoded a CONTROLLED TENSORED Rz — `cqrt_rz_<W>` is "Rz on each qubit of
   the register" (docs/backend.md:995), so the phase it put on the marked branch
   was (-1)^popcount(target) — +1 for |5> — and a per-qubit DIAGONAL gate fixes
   |0..0>, so the reflection could never put -1 there. Those goldens were
   self-consistent traces OF THE IDENTITY ON q (PRD §1, measured 2026-09-05 at
   HEAD 52d7764). This slice was the first whose trace is an oracle; every Grover
   golden in the tree now carries only `cqrt_rz_i1` (no wider Rz, no cswap).

   TRACE SHAPE (written before the lowering existed; the golden now shows exactly
   this): per region, in source order —
       ONE flag mint   cq_template_icmp_{eq}_i32_hl(h_q, k) -> h_f
       ONE gate        cqrt_rz_i1(h_f, PI)          UNCONTROLLED, on the FLAG
       ONE strip       cq_template_icmp_{eq}_i32_hl_unc(h_f, h_q, k)
       ONE free        cqrt_free(h_f)
   and NOTHING else: no cqrt_cswap, no work rail, no `_controlled` symbol of any
   family, no `phi i32`, no added measure. Four such regions, interleaved with the
   four `cqrt_ry_i32` of the theta chain. The ONLY Rz width in the trace is i1.

   PRE-INCREMENT DISPOSITION: the ORACLE (pre-3qlq, commit 52d7764,
   $SP/wt/pre-3qlq/build/ir-pass/cq-opt) DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control`
   Measured 2026-09-05 with a `void cq_phi(double)` header. `opt` exit code and
   diagnostic are verbatim.
   Expected post-increment class: PRD §6.2 P1 (flat diamond, single-compare
   tainted condition, arm = ONE cq_phi) ×4. */

#define CQ_PI 3.14159265358979323846

int slice(void) {
    int q = 0;

    cq_theta(&q, 0.3);
    if (q == 5) cq_phi(CQ_PI);
    cq_theta(&q, 0.3);
    if (q == 0) cq_phi(CQ_PI);

    cq_theta(&q, 0.3);
    if (q == 5) cq_phi(CQ_PI);
    cq_theta(&q, 0.3);
    if (q == 0) cq_phi(CQ_PI);

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
