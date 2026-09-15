#include "CQ.h"
/* E3 ESCAPE: a post-measure read STORED to memory. Today `declineTaintEscapes` refuses
   a tainted store. Under (b) the stored value is the classical outcome. */
int g;
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q); g=q; return m+g; }
