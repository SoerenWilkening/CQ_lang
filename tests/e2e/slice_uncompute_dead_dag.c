/* slice_uncompute_dead_dag.c — Phase 5 (WI-6, test_C_libtooling-p2s2.6): the
   FIRST end-to-end proof of the whole-DAG uncompute spine — the only layer that
   LINKS, so the only proof every void in-place `_unc` symbol the emitter mints
   (WI-3/WI-4) resolves AND signature-matches against the generated runtime ABI
   (WI-2) (Rule 2, Rule 16). A green `opt -verify` and a passing FileCheck on the
   .ll fixtures are NOT this proof: the ir-pass fixtures assert IR text and never
   link, so a name/signature disagreement between the generator and the emitter is
   invisible to them. This slice caught exactly that — the QQ `_unc` form was
   generated as `cq_template_mul_i32_qq_unc` while the emitter (and every fixture)
   emits the BARE `cq_template_mul_i32_unc` (matching the bare forward QQ form);
   the two never met until this link. See docs/prd/phase-05-uncomputation.

   TWO dead, unmeasured, unreturned source-derived tainted handles in a
   `__attribute__((noinline))` helper. `noinline` is LOAD-BEARING: Phase 5
   uncompute is gated OFF in `main` (FreePoint.cpp — `main`'s handles are
   reclaimed at process exit, so they are a recognized escape). At `-O1` clang
   would inline `slice` into `main` and the inlined copy would carry NO uncompute,
   while the real (uncompute-bearing) `slice` would be dead and never run — the
   trace would show only the forward chain. `noinline` forces the function
   boundary so the uncompute actually executes. This is also a faithful program:
   a subroutine that prepares quantum scratch and drops it without measuring.

   `cq_phi` (Rz, a side-effecting extern that READS its operand) is the keep-alive
   that prevents `-O1` from DCE-ing the dead arithmetic while its own result is
   dropped — so a real `cq_template_*` terminal survives to be uncomputed. The
   pass recovers the whole DAG and reverses it ONCE in reverse program order
   (LIFO): each gate adjointed exactly once via the void in-place `_unc` form
   (DD-3 slots: `out` first, then the forward operands in order), each rail freed
   right after its last reverse-use, the Rz keep-alives undone with a negated
   angle. NO fresh-minting `_inv`, NO added measurement (Rules 5/6), NO
   `cqrt_cswap`.

   Chain 2 (later in program) reverses first. Exactly FIVE frees (h4,h3 then
   h2,h1,h0) — one per allocated rail, none double-freed.

   IT WAS SIX BEFORE M-C INCREMENT 2c (bd test_C_libtooling-6uqc), and the
   arithmetic of that change is the point rather than a caveat: `b = b ^ 9` used
   to MINT a rail (`cq_template_xor_i32_hl`) and therefore needed its own free;
   it now mutates the `shl` rail in place (`cqrt_xorc_i32`), so there is one
   fewer alloc AND one fewer free. A free that disappears together with its
   alloc is the mechanism working; a free that disappears alone would be the
   Rule-6 defect this slice exists to catch.

   TWO distinct `_unc` symbols are now exercised at the link layer — the BARE QQ
   `cq_template_mul_i32_unc` (the WI-6-caught fix) and
   `cq_template_shl_i32_hl_unc` — plus the in-place `cqrt_xorc_i32`, whose
   adjoint is the IDENTICAL call (self-inverse), emitted before the `shl` `_unc`
   that reads the rail it restored. `cq_template_xor_i32_hl_unc` left this slice
   with 2c and is NOT uncovered: it still links in slice_control_value_diamond,
   slice_loop_iter_local and spec_twoarm_caller (6 occurrences, measured).

   cq_theta/cq_phi resolve from CQ.h, force-included by run_slice.sh
   (-include CQ.h -I include). */
__attribute__((noinline))
void slice(int x, int y) {
    /* (1) linear Q+C (_hl) chain, dropped without measure. */
    int a = cq_theta(x, 0.25);   /* taint x -> handle (alloc + ry)            */
    int b = a << 2;              /* shl_hl                                    */
    b = b ^ 9;                   /* xor_hl                                    */
    (void) cq_phi(b, 0.5);       /* Rz keep-alive; result dropped (dead)      */

    /* (2) Q+Q (_qq) product, dropped without measure — the bare-QQ `_unc`. */
    int p = cq_theta(x, 0.10);   /* alloc + ry                                */
    int q = cq_theta(y, 0.20);   /* alloc + ry                                */
    int prod = p * q;            /* mul_qq (operands ordered by BirthOrder)   */
    (void) cq_phi(prod, 0.30);   /* Rz keep-alive; result dropped (dead)      */
}
int main(void) { slice(2, 5); return 0; }
