/* tests/chk-core (cq-743m, CR rule 27, §1.4 `_ctl`): a rule 27 declared clone under a quantum predicate. Lowered with
 * -cq-roots naming ext (standin_ctl.ll, frozen), the call is __cq_q_ext_1_t_ctl(pred, ...); the checker's stand-in
 * emits its phase under pred, so a mutant calling the clone uncontrolled, or with a constant-true predicate, differs
 * from the C program. Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../CQ_spec
 * standin_ctl.c -o standin_ctl.O1.ll; opt -load-pass-plugin=build/pass/libCQLower.so -passes=cq-lower
 * -cq-roots=<file: ext> -S standin_ctl.O1.ll -o standin_ctl.ll */
#include "CQ.h"
int ext(int);
int f(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    int r = 0;
    if (x > 3) r = ext(x);
    return cq_measure(r);
}
