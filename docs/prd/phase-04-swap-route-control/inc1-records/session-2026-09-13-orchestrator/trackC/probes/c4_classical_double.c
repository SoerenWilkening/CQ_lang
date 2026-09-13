/* (accept target) a measure of a CLASSICAL double — the f64 width, where
 * "allocate a rail for a classical f64" is the angle/f64 miscompile family. */
#include "CQ.h"
double g(double x) { double y = x * 2.0; return cq_measure(y); }
int main(void) { return (int)g(1.5); }
