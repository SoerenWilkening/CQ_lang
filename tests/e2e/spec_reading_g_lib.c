/* spec_reading_g_lib.c — bd test_C_libtooling-cepm, library TU 2 of 4. `f2` is an
   external in THIS TU, so `clang -O1` infers no memory(none)/willreturn for `g`, and a
   call to `g` is a liveness ROOT of the pass (DeadValueLiveness.h): its body holds a
   call, so the body rule does not clear it either. `g` is VOID, so its clone is
   self-contained (Bennett forward + reverse, no result rail) and the hand-inlined
   twin's top-level `g(q)` emits exactly the gates `h`'s clone emits. */
int f2(int a);
void g(int a) { f2(a); }
