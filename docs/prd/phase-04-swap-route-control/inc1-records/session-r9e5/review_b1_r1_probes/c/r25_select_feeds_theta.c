/* the select result feeds a later theta arg-0 — gate 5 should refuse the ARMS */
#include "CQ.h"
int main(void){ bool b=0,c=0,d=0; b=cq_theta(b,0.5); c=cq_theta(c,0.7); d=cq_theta(d,0.9); bool o=b?c:d; o=cq_theta(o,0.3); return cq_measure(o)+cq_measure(b); }
