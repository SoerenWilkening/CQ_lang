/* A theta with an undef seed in a function NOTHING calls, beside a live one. */
#include "CQ.h"
int dead_one(void) { int s = 0; return cq_theta(s, 0.75); }
int main(void) { int t = 0; t = cq_theta(t, 0.5); return cq_measure(t); }
