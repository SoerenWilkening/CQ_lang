/* 3qlq Inc 1: migrated to register-free cq_phi -- every oracle / reflection arm's `q = cq_phi(q, PI)` -> `cq_phi(PI)`.

   FINDING (PRD S1, measured 2026-09-05 at HEAD 52d7764): the PRE-3qlq golden of
   this slice encoded a CONTROLLED TENSORED Rz, which is the IDENTITY on q --
   `cqrt_rz_<W>` is "Rz on each qubit", so the marked phase is (-1)^popcount(target)
   (= +1 for |5>) and a per-qubit diagonal gate FIXES |0..0>, so the |0> reflection
   can never put -1 there. Any claim in the prose below that the oracle marks |5>,
   or that the reflection reflects about |0>, was TRUE OF THE SOURCE and FALSE OF
   THE EMITTED CIRCUIT. It becomes true only from 3qlq Inc 1 on, where the phase is
   a BRANCH phase by kickback (rz_i1 on the minted flag), not a register Rz. The
   older prose is left verbatim rather than silently corrected; read it with this.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_grover_2iter.c — bd test_C_libtooling-lom0 Increment 4 e2e:
   TWO COMPLETE GROVER ITERATIONS. The customer the increment was built for.

   SOURCE INTENT — the loop body written out twice, plus the final re-prep:
       S      q = cq_theta(q, 0.5); q += off;         state preparation
       O      if (q == 5) cq_phi(PI);          oracle: mark |5>
       S†     q -= off; q = cq_theta(q, -0.5);        un-prepare
       R0     if (q == 0) cq_phi(PI);          reflect about |0>
       S      q = cq_theta(q, 0.5); q += off;         RE-PREPARE  <-- the wall
       O      if (q == 5) cq_phi(PI);
       S†     q -= off; q = cq_theta(q, -0.5);
       R0     if (q == 0) cq_phi(PI);
       S      q = cq_theta(q, 0.5); q += off;         final re-prep
       M      measure q

   WHY THIS SLICE EXISTS BESIDE slice_control_seq_grover.c. That one stops at
   `q += off` — the half of state preparation that already lowered — because the
   Ry half declined. This one is the whole thing: FOUR chained `cq_theta`s and
   FOUR sequential tainted-condition regions. At HEAD b4e329b this exact program
   exits 1 with
       cq controlled lowering: condition predates a non-diagonal gate
   and with nothing else; that single diagnostic was the entire wall between CQ
   and a repeatable Grover iteration.

   WHY THIS SHAPE, and not a `for` loop. A loop over S-O-S†-R0 is the natural
   spelling and it DECLINES today for an unrelated reason — a flat tainted
   region whose entry is on a CFG cycle is `control flow inside a loop body`
   (the d8jl guard), and the M-A record guard has its own in-loop over-decline
   (bd test_C_libtooling-58tc). Unrolling two iterations by hand is what isolates
   THIS increment's change; the loop spelling is the next frontier and is marked
   as such in example/grover/grover_loop_frontier.c.

   WHY `off` IS `volatile`, and it is load-bearing (Rule 9). Written as literal
   `q += 3; … q -= 3;` pairs, clang -O1 reassociates and cancels them on the
   straight-through edge, folding the `+3` into the compare and SINKING the `-3`
   into the oracle arm — the arm then rewrites a register the condition reads and
   the compiler correctly refuses with `arm rewrites a condition operand`. Two
   volatile loads are two values LLVM cannot prove equal, so the pair survives
   canonicalization and reaches the pass as real reversible arithmetic on the
   quantum register.

   WHAT THE GOLDEN WITNESSES, and — say this plainly — WHAT IT DOES NOT.

   It witnesses ORDER: for each of the four regions the flag is minted, routed,
   Rz'd, routed back, the work rail freed, the flag `_unc`-STRIPPED and FREED,
   and only THEN does the next `cqrt_ry_i32` fire. That is the increment's whole
   soundness claim in emitted form — the position-aware accept says the region
   holds no live record of the wire once its strip has run, and the trace shows
   the strip and the free preceding every non-diagonal gate.

   It also witnesses the ONE-RAIL property: `cqrt_alloc_i32` appears exactly five
   times (the register `h0`, plus one work rail per region) and every reassignment
   is an in-place `cqrt_addc_i32`, so no ancestor rail is ever minted. When any of
   the four Ry gates fires there is no other allocated rail entangled with `h0`
   except the region ancillas, which are freed before it.

   IT IS NOT, BY ITSELF, CORRECTNESS EVIDENCE. A cleared golden encoded a
   dephased circuit once already (bd test_C_libtooling-nepx: the shipped
   seq-grover trace kept `h0`/`h1` live across the S† Ry, and the byte-diff was
   perfectly happy). The evidence is this trace PLUS the rail-liveness reading
   above PLUS strict stage-2b free-pairing (no `--allow-unproven`) PLUS the
   independent adversarial round. Read the four together or not at all.

   The runtime is trace-only and all four diamonds are flattened to straight-line
   code, so every emitted gate fires unconditionally and the trace is
   deterministic regardless of q. */
volatile int off = 3;

#define CQ_PI 3.14159265358979323846

int slice(void) {
    int q = 0;

    q = cq_theta(q, 0.5);                    /* S  — iteration 1 */
    q += off;
    if (q == 5) {                            /* O  */
        cq_phi(CQ_PI);
    }
    q -= off;                                /* S† */
    q = cq_theta(q, -0.5);
    if (q == 0) {                            /* R0 */
        cq_phi(CQ_PI);
    }

    q = cq_theta(q, 0.5);                    /* S  — iteration 2 (THE line) */
    q += off;
    if (q == 5) {                            /* O  */
        cq_phi(CQ_PI);
    }
    q -= off;                                /* S† */
    q = cq_theta(q, -0.5);
    if (q == 0) {                            /* R0 */
        cq_phi(CQ_PI);
    }

    q = cq_theta(q, 0.5);                    /* final re-prep */
    q += off;
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
