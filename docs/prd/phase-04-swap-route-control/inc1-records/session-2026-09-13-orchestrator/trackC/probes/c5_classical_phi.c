/* (accept target) verdict (b): a measure of a CLASSICAL phi/select. */
#include "CQ.h"
int f(int n) { int a = 1; if (n > 2) a = 9; return cq_measure(a); }
int main(void) { return f(5); }
