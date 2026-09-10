#include "CQ.h"
__attribute__((noinline)) bool mk(void){ return cq_theta((bool)0, 0.5); }
int main(void){ bool b = mk(); if (b) cq_phi(0.7); return cq_measure(b); }
