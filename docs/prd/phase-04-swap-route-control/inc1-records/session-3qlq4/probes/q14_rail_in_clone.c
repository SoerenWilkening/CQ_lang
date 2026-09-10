#include "CQ.h"
static void f(bool c) { if (c) cq_phi(0.9); } int main(void){ bool b = cq_theta((bool)0, 0.5); f(b); return cq_measure(b); }
