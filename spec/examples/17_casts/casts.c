short trunc_i32_i16(int x0, double th)        { int x = x0; cq_theta(&x, th); short y = (short)x; return cq_measure(y); }
int zext_u16_i32(unsigned short x0, double th) { unsigned short x = x0; cq_theta(&x, th); int y = x; return cq_measure(y); }
int sext_i8_i32(signed char x0, double th)    { signed char x = x0; cq_theta(&x, th); int y = x; return cq_measure(y); }
double sitofp_q(int x0, double th)            { int x = x0; cq_theta(&x, th); return cq_measure((double)x); }
int fptosi_q(double x0, double th)            { double x = x0; cq_theta(&x, th); return cq_measure((int)x); }
double fpext_q(float x0, double th)           { float x = x0; cq_theta(&x, th); return cq_measure((double)x); }
float fptrunc_q(double x0, double th)         { double x = x0; cq_theta(&x, th); return cq_measure((float)x); }
