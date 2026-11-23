// an inverted region and a phase
#include "cq.hpp"
ENTRY int f(int x, int y) { unsigned char a = (unsigned char)x; cq_theta(&a, 1.57); if ((a * a + 3 * a) % 16 == 4) cq_phi(3.14159); cq_invert_begin(); cq_theta(&a, 1.57); cq_invert_end(); if (a == 0) cq_phi(3.14159); return cq_measure(a); }
