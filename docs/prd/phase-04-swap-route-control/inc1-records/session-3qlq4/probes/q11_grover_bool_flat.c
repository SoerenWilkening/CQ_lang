#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(3.14159); b = cq_theta(b, -0.5); if (!b) cq_phi(3.14159); b = cq_theta(b, 0.5); if (b) cq_phi(3.14159); b = cq_theta(b, -0.5); if (!b) cq_phi(3.14159); b = cq_theta(b, 0.5); return cq_measure(b); }
