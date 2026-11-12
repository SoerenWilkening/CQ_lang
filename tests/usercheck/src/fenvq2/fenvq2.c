/* Rulings Q2 for CR rule 23's calls with an object operand (rows fegetenv, feholdexcept, fegetexceptflag@0/@01): the
   types are musl's x86_64 ones, the bodies musl's no-op shapes (fenvq2_musl.c, its own translation unit linked after
   -O1 as a musl row links libc), which rule 16 never lifts for the call (cq-rrc52): the
   call is the host's and writes the object's host bytes (rule 23). Where x is odd the objects hold a rail at the call
   and the host's write is not seen by the bus (CR 1.3): not compared. Where x is even both sides read the host's
   bytes: e's control word (0x7f, every exception masked) and g's flags (0). */
#include "CQ.h"
typedef unsigned short fexcept_t;
typedef struct {
    unsigned short __control_word, __unused1, __status_word, __unused2, __tags, __unused3;
    unsigned int __eip;
    unsigned short __cs_selector;
    unsigned int __opcode:11;
    unsigned int __unused4:5;
    unsigned int __data_offset;
    unsigned short __data_selector, __unused5;
    unsigned int __mxcsr;
} fenv_t;
void *memset(void *, int, unsigned long);
int fegetexceptflag(fexcept_t *, int);
int fegetenv(fenv_t *);
int f(int x) {
    fenv_t e;
    fexcept_t g = 0x10;
    memset(&e, 0, sizeof e);
    if (x & 1) {
        cq_theta((unsigned char *)&e, 0.3);
        cq_theta((unsigned char *)&g, 0.3);
    }
    fegetenv(&e);
    fegetexceptflag(&g, 0x3d);
    cq_measure(*(unsigned char *)&e);
    cq_measure(*(unsigned char *)&g);
    return 0;
}
