/* slice_loop_bank_derived_cond.c — bd `test_C_libtooling-zujr`, THE WITNESS FOR
 * THE ONE WIDENING IN THAT INCREMENT THAT IS NOT GATED ON ITS OWN PREDICATE:
 * `railLocalQualifies`' (L3) clause now exempts a store that PARKS A RAIL IN A
 * PROVEN `!cq.railbank` ALLOCA with an UNTAINTED pointer operand.
 *
 * WHY IT HAD TO BE WIDENED: `bool k[3]` promoted by `RailBankPromote` (bd
 * `xdu2`) leaves `store i32 %h, ptr %cq.bank.addr` in the body, whose VALUE
 * operand is a tainted HANDLE by construction — so the blanket form refused
 * EVERY banked loop, `markIfRailLocal` never marked one, and
 * `declineUnmarkedRolledIterLocal`'s conjunct 2 then refused the module.
 *
 * WHY THIS PROGRAM IS THE WITNESS AND A BANK-WITH-A-COMPARE IS NOT. `(q >> i) & 1`
 * is the ONLY condition kind in this family that mints `cq_template_*` rails in
 * the body per trip, so it is the only one whose per-trip chain is the SPINE's to
 * discharge rather than an emitter's — i.e. the only one that can witness a
 * MISSING SPINE DISCHARGE. That is the 19-vs-27 shape `iterationLocalRollable`'s
 * clause (c3) is built on.
 *
 * MEASURED: this file's golden is BYTE-IDENTICAL to its hand-unrolled twin's
 * (`e2e-loop-bank-derived-cond-twin-identical`), 36 lines each, and the per-trip
 * stream discharges everything it mints —
 *     and -> icmp -> x -> ry_controlled -> x -> icmp_unc -> and_unc -> free -> free
 * On the ORACLE (`cq-opt` 07d93784…) the ROLLED half DECLINED
 * `cq controlled lowering: control flow inside a loop body` while this twin
 * compiled, so the widening does not merely fail to break anything: it CLOSES a
 * leak the decline was hiding.
 *
 * ⚠ THE TAINTED-INDEX HALF IS UNTOUCHED and is a different program:
 * `$SES/probes/a1_taintedidx.c` still declines `cq QRAM access: tainted-index
 * memory access inside a loop` on both binaries. A rail parked in a bank is also
 * already FROZEN against adjoint and free by `railStoredToRailBank`, so marking
 * the block cannot make the spine touch it.
 */
#include "CQ.h"

int main(void) {
    int q = cq_theta(0, 0.7);
    bool k[3];
    for (int i = 0; i < 3; ++i) {
        if ((q >> i) & 1) k[i] = cq_theta(k[i], 0.5);
    }
    return cq_measure(k[0]) + cq_measure(k[1]) + cq_measure(k[2]) + cq_measure(q);
}
