/* slice_loop_hoisted_chain_exit_discharge.c — bd `test_C_libtooling-tu9q`, piece
   P2 (the loop-EXIT anchor), which also closes bd `test_C_libtooling-1m5p`.
   THE ROLLED HALF of the pair; the twin is `..._unrolled.c`.

   ⚠ THIS PROGRAM WAS A LIVE, SHIPPING, VERIFY-CLEAN Rule-8 OVER-ACCEPT. On the
   2026-09-18 session ORACLE `9bd01598d574b344` it compiled at `opt` exit 0 with
   the LICM-hoisted `sqrt((double)a + 3.0)` rail LEFT ALLOCATED and ENTANGLED
   across the trailing `cq_theta(a, 0.7)` on the register it copies — and that
   register is then measured. The leaked rail is an INJECTIVE function of `a`'s
   basis label, i.e. a perfect which-path record standing at a non-diagonal gate:
   rolled and hand-unrolled were DIFFERENT UNITARIES (CLAUDE.md Rule 8's last
   sentence, and §5's Q-R1-1 correction). 26 trace lines against the twin's 28,
   `cq_template_sqrt_f64_unc` count 0 against 1.

   ⚠ NOTHING IN THE TREE REFUSED IT, and the reason is worth carrying:
   `declineDephasingUnmarkedLoopRails`' conjunct (3) quantifies over `L`'s OWN
   blocks, and this rail is minted in the PREHEADER — so the fence built for this
   exact hazard class is structurally blind to the hoisted instance of it. The
   ONLY instrument that saw the divergence was a WARNING (`cq rotation lowering:
   non-diagonal gate over a live derived record`, emitted on the rolled form and
   SILENT on the twin).

   WHAT THE GOLDEN PINS. The whole hoisted chain (`sitofp → fadd → sqrt`) is
   adjointed LIFO in the LOOP-EXIT block and freed there, STRICTLY BEFORE
   `cqrt_ry_i32(h0, 0.7)`. That ordering is the entire correctness claim: a
   which-path record discharged before the interference cannot dephase it. On the
   subject `opt` stderr is 0 bytes — the warning goes silent BECAUSE the record is
   discharged, not because the warn stage stopped looking.

   ⚠ THE PAIR IS **MULTISET-IDENTICAL AND ORDER-DIVERGENT, BY CONSTRUCTION**, so
   there is deliberately NO `*-twin-identical` `compare_files` gate for it — such a
   gate would be RED, and a red gate is a gate people stop reading (CLAUDE.md L10).
   Measured at the landing: rolled 28 == unrolled 28, and the traces with handle
   numbers normalised are IDENTICAL as multisets. The rolled form discharges the
   chain at the loop exit; the twin discharges it at function scope after the last
   copy. They commute because everything between the two positions READS the
   chain's members and writes only its own ancillas — disjoint support, and reads
   commute with reads. The claim is COUNT + MULTISET + that argument, never byte
   identity (owner ruling S3, 2026-09-17: byte identity is an INSTRUMENT, not the
   target).

   ⚠ `--allow-unproven`, AND THE REASON IS STRUCTURAL RATHER THAN A CONCESSION.
   `tools/free_pairing_check.py` analyses per STREAM — a maximal chain of blocks
   joined by unconditional single-predecessor edges — so a discharge placed at a
   LOOP EXIT is `U3-extern-rail` UNPROVEN *by construction*, not because anything
   about the rail is unproven. Measured: this slice reports `1 verified, 0
   violation(s), 3 unproven` where its hand-unrolled twin, whose discharge is in
   the mint's own stream, reports `5 verified, 0 unproven`. The rail identities
   this slice would otherwise lose are pinned POSITIONALLY by
   `ir-pass/test/loop_pairing_accept_hoisted_chain_exit_discharge.ll` instead.
   ⚠ RETIREMENT TRIGGER: if `free_pairing_check.py` ever grows a cross-stream
   model, drop this flag and re-derive the count — do NOT leave it as insurance. */
#include <math.h>

volatile int off = 3;

int slice(void) {
    int a = 0;
    int r = 0;
    cq_theta(&a, 0.5);
    cq_theta(&r, 0.3);
    for (int i = 0; i < 2; ++i) {
        if (sqrt(a + 3.) <= (double)off) { cq_theta(&r, 0.9); }
    }
    cq_theta(&a, 0.7);               /* the interference the leak used to dephase */
    return cq_measure(a) + cq_measure(r);
}

int main(void) { (void)slice(); return 0; }
