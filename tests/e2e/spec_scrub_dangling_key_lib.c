/* spec_scrub_dangling_key_lib.c — the classical callee of
   spec_scrub_dangling_key_caller.c (bd test_C_libtooling-8e5r). Plain C, no
   CQ.h: compiled as its own TU so the specializer sees an UN-INLINED body. */
int k1(int a, int b) { return (a * 7) + b; }
