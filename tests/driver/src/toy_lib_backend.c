/* A toy classical backend for the lowered-library executable test: rails are slots holding a basis value; Ry is
 * dropped. Just the symbols qlib.c and qlib_user.c lower to (BACKEND_ABI: copy(a, b) is b ^= a). */
static int rail[256]; static int next = 1;
static int stack[64]; static int sp;
static int fresh(int v) { rail[next] = v; return next++; }
int cqrt_qram_alloc_i8(int n) { return fresh(n); }   /* the bus handle cq_host.c asks for; never accessed here */
int cqrt_alloc_i1(_Bool v) { return fresh(v); }
int cqrt_alloc_i32(int v) { return fresh(v); }
void cqrt_copy_i1(int a, int b) { rail[b] ^= rail[a]; }
void cqrt_copy_i32(int a, int b) { rail[b] ^= rail[a]; }
void cqrt_copy_i32_controlled(int c, int a, int b) { if (rail[c]) rail[b] ^= rail[a]; }
void cqrt_free(int r) { (void)r; }
int cqrt_measure_i32(int r) { return rail[r]; }
void cqrt_push(int v) { stack[sp++] = v; }
int cqrt_pop(void) { return stack[--sp]; }
void cqrt_ry_i32(int r, double a) { (void)r; (void)a; }
void cqrt_ry_i32_controlled(int c, int r, double a) { (void)c; (void)r; (void)a; }
void cqrt_ry_i32_qangle(int r, int a) { (void)r; (void)a; }
void cqrt_ry_i32_qangle_controlled(int c, int r, int a) { (void)c; (void)r; (void)a; }
int cq_template_add_i32_hl(int a, int c) { return fresh(rail[a] + c); }
void cq_template_add_i32_hl_unc(int r, int a, int c) { rail[r] ^= rail[a] + c; }
int cq_template_mul_i32_hl(int a, int c) { return fresh(rail[a] * c); }
void cq_template_mul_i32_hl_unc(int r, int a, int c) { rail[r] ^= rail[a] * c; }
