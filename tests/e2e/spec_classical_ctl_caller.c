/* spec_classical_ctl_caller.c — CQ TU for the bd p3kd.7.2 golden: classical control
   inside lifted helpers (spec_classical_ctl_lib.c), the owner ruling of 2026-10-06
   (speculate both arms, choose the rail classically).

   `lim` and `mode` are RUNTIME classical values (argc, so 1 when the harness runs
   the binary without arguments), never literals. Both helpers lift to clones with
   mask 01 (first argument quantum). In each clone the classical branch or switch is
   if-converted: every arm's gates run, a quantum-condition merge becomes the
   controlled-copy mux, and a classical-condition merge becomes a `select` between
   rail handles whose chosen rail the copy-out reads. The Bennett reverse then undoes
   every arm on its own operands. With argc = 1:
     clampsub(b, 1): lim >= 0, so out = [b > 1]·(b − 1); the copy-out reads the mux
                     rail, not the materialized |−lim> rail.
     pick(b, 1):     out = 2b; the copy-out reads the `mul` rail.
   LINK PROVES both clones and every emitted template resolve across llvm-link. */
int clampsub(int x, int lim);
int pick(int x, int mode);

int slice(int k) {
    int b = 6;
    cq_theta(&b, 0.5);
    int r = clampsub(b, k) + pick(b, k);
    return cq_measure(r);
}
int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc);
    return 0;
}
