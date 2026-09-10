#include "CQ.h"
int main(void){ int r = cq_theta(0, 0.2); bool b = cq_theta((bool)0, 0.5); if (b) r = cq_theta(r, 0.9); else r = cq_theta(r, 0.3); return cq_measure(r) + cq_measure(b); }
