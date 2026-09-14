/* Ruling clause 4: cq_measure of a NEVER-QUANTUM undef must KEEP DECLINING. */
#include "CQ.h"
int main(void) { int u; return cq_measure(u); }
