#include "CQ.h"
/* §14 ITEM 3: does cqrt_alloc_<W> take a RUNTIME value operand? */
int main(int argc, char **argv){ (void)argv; int q=cq_theta(argc,0.3); return cq_measure(q); }
