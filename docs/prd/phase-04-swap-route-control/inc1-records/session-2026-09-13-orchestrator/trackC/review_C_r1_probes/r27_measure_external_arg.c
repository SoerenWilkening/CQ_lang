/* r27 — an EXTERNALLY-LINKED function measuring its own argument: no taint anywhere. */
#include "CQ.h"
int api_measure(int x) { return cq_measure(x); }
int main(void) { return api_measure(3); }
