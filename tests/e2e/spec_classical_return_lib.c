/* spec_classical_return_lib.c — the plain-C library TU of e2e-spec-classical-return
   (bd test_C_libtooling-9bhg). No CQ.h. `h2` READS `a`, in a branch over a volatile
   load, so `clang -O1` keeps the parameter live and bd vsfp's dead-argument drop
   does not remove it. `K` is a never-written static volatile, so vsfp's
   `foldVolatileConstGlobalLoads` (owner ruling 2026-09-26: a volatile access to an
   object unreachable from outside the program is unobservable) folds the load. The
   specialized clone's own pipeline then drops the branch and returns the CLASSICAL
   `k + 1`. See the caller's header for why this spelling (and `musttail`) is the
   one that still reaches bd 9bhg's path. */
static volatile int K = 7;
int h2(int a, int k) { if (a > 3) (void)K; return k + 1; }
