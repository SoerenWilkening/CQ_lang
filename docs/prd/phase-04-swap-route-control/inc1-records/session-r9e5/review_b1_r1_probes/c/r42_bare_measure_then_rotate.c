/* no control at all: is a post-measure rotation refused anywhere? */
#include "CQ.h"
int main(void){ bool b0=0; b0=cq_theta(b0,0.5); int m=cq_measure(b0); bool b=cq_theta(b0,0.3); return m+cq_measure(b); }
