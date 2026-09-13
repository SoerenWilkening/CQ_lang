/* verdict (a): the operand is an UNINITIALIZED local — undef/poison at -O1. */
#include "CQ.h"
int main(void) { bool b; return cq_measure(b); }
