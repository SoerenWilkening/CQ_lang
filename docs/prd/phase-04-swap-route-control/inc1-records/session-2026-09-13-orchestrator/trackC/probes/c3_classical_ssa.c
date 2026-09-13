/* (accept target) a measure of a CLASSICAL SSA i32 (`n + 3` of a runtime arg). */
#include "CQ.h"
int f(int n) { int a = n + 3; return cq_measure(a); }
int main(void) { return f(4); }
