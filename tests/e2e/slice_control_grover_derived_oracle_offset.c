/* slice_control_grover_derived_oracle_offset.c — THE DERIVED ORACLE *AND* THE
   OFFSET TRICK, IN ONE PROGRAM. The customer M-C Increment 7a was built for
   (bd test_C_libtooling-x67f).

   SOURCE INTENT — a full Grover iteration in which state preparation is a
   rotation FOLLOWED BY a classical shift of the register, and the oracle is a
   COMPUTATION rather than a compare against a constant:

       S    q = cq_theta(q, 0.5);  q += off;               prepare, then shift
       O    if (((q * 5) >> 2) == 5) q = cq_phi(q, PI);    the DERIVED oracle
       S-   q -= off;  q = cq_theta(q, -0.5);              un-shift, un-prepare
       R0   if (q == 0) q = cq_phi(q, PI);                 reflect about |0>
       S    q = cq_theta(q, 0.5);  q += off;               re-prepare
       M    measure q

   IT IS THE UNION OF TWO SLICES THAT ALREADY SHIP, and until this increment the
   union did not compile even though both halves did:

     * slice_control_seq_grover.c has the `+= off` / `-= off` trick, but a
       DIRECT oracle (`if (q == 5)`). Both offset steps convert in `lowerOps`
       Phase 1, because the only prior reader of the register is the region
       COMPARE, whose flag strip the Phase-4 emitter has already inlined by then
       (arm (b) of the M-C prior-use fence; SPIKE §9.8).

     * slice_control_grover_derived_oracle.c has the computed oracle, but no
       offset — the S / S-dagger pair is a bare rotation.

   WHY THE UNION FAILED, AND IT WAS NEVER PHYSICS. With a DERIVED oracle the
   prior readers of the register are the chain's own templates (`ashr`, then a QQ
   `add`), and their `_unc` + `cqrt_free` are emitted by the M-B interior
   partition, which runs LAST. `lowerOps` runs BEFORE it, so at Phase 1 those
   readers are not even `CallInst`s yet — they are plain `ashr`/`add` opcodes,
   which arm (e) refuses on sight. `q -= off` therefore stayed OUT of place,
   minted a fresh rail, and the ORIGINAL register stood as a dead ancestor
   record at the S-dagger `cq_theta`, where the M-A live-record guard declined
   the whole program with a message naming the wrong cause. bd memory
   [mc-cannot-see-mb-discharge-2026-08-29] recorded exactly this and told slice
   authors to keep the offset trick OUT of a derived-oracle Grover. Increment 7a
   moves the decision to a LATE round that runs after every emitter except
   `uncompute` and reads the M-B discharge PLAN, so the advice is retired and
   this file is the receipt.

   WHAT THE TRACE WITNESSES, in order, for the oracle half of each iteration:
   cqrt_addc_i32(h0, 3) — the `+= off`, in place, no rail; then ashr_i32_hl,
   add_i32 (QQ), the flag mint, route, Rz, route back, work-rail free, the flag
   STRIP; then add_i32_unc + free, ashr_i32_hl_unc + free, the flag free; and
   only then cqrt_addc_i32(h0, -3) — the `-= off`, ALSO in place, with the
   immediate negated at compile time — followed by the S-dagger cqrt_ry_i32.

   RAIL LIVENESS AT EVERY NON-DIAGONAL GATE (the reading the golden cannot do
   for itself, and the only physics claim this file makes): cqrt_alloc_i32
   appears THREE times — the register h0 and one work rail per region — and each
   work rail is freed inside its own region. At each of the three cqrt_ry_i32
   gates the ONLY allocated rail is h0. Neither offset step mints a rail at all,
   which is the whole increment.

   THE IMMEDIATE IS NEGATED, NOT SUBTRACTED. There is no `cqrt_subc_` and there
   must not be one: `x - c` and `x + (-c)` are the same permutation under the
   runtime's `h := (h + imm) mod 2^W` contract, so `sub` emits `cqrt_addc_<W>`
   with the immediate negated (Rule 15 — the Phase-11 freeze surface is
   untouched). `off` is a `volatile` global, so the negation is an ordinary
   classical `sub i32 0, %off` rather than a folded constant; `free_pairing_
   check.py` cannot pair two SSA-named immediates by `is_negation`, which costs
   nothing here because h0 is MEASURED and therefore never freed. STRICT stage
   2b (no --allow-unproven).

   WHY `off` IS `volatile` (Rule 9): written as a plain literal, `clang -O1`
   constant-folds `q + 3` into the oracle's own arithmetic and the offset steps
   vanish from the IR before the pass ever sees them. The `volatile` load is what
   keeps the two `addc` sites in the program.

   R0 IS DELIBERATELY DIRECT — the reflection about |0> really is `q == 0`, and
   keeping it direct puts BOTH condition shapes in one trace, exactly as
   slice_control_grover_derived_oracle.c does.

   THE ORACLE PREDICATE IS SATISFIABLE. `(q*5)>>2 == 5` holds exactly when
   20 <= 5q <= 23, i.e. for q == 4 and no other integer, so the oracle really
   does phase-mark one basis state a C program may legally reach (bd 160a
   Rule-13 finding F2 — a demo whose predicate marks nothing is not a demo).
   Note the offset shifts WHICH state: the compare reads `q + off`, so the
   marked register value is q == 4 - off.

   IT IS NOT, BY ITSELF, CORRECTNESS EVIDENCE (bd nepx): read it with the
   liveness reading above, the strict free-pairing, and the adversarial round. */

#define CQ_PI 3.14159265358979323846

volatile int off = 3;

int slice(void) {
    int q = 0;

    q = cq_theta(q, 0.5);                       /* S  */
    q += off;
    if (((q * 5) >> 2) == 5) {                  /* O — the derived oracle */
        q = cq_phi(q, CQ_PI);
    }
    q -= off;                                   /* S- */
    q = cq_theta(q, -0.5);
    if (q == 0) {                               /* R0 */
        q = cq_phi(q, CQ_PI);
    }
    q = cq_theta(q, 0.5);                       /* S  */
    q += off;
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
