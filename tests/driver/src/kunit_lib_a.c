/* CQ_K / CQ_K2 lines for libf, which no unit defines externally: they stay constants */
CQ_K(libf, 3)
CQ_K2(libf, 100)
int libf(int);
int ua(int x0, double th) { int x = x0; cq_theta(&x, th); return cq_measure(libf(x)); }
