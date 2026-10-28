/* A toy classical backend for the executable test: rails are slots holding a basis value; Ry is
 * logged, not applied. Just the symbols kfun.c lowers to. */
#include <stdio.h>
static int rail[64]; static int next = 1;
int cqrt_alloc_i32(int v) { rail[next] = v; return next++; }
void cqrt_ry_i32(int r, double a) { (void)r; (void)a; }
int cq_template_add_i32_hl(int r, int c) { rail[next] = rail[r] + c; return next++; }
int cq_template_sub_i32_hl(int r, int c) { rail[next] = rail[r] - c; return next++; }
void cq_template_sub_i32_hl_unc(int r, int a, int c) { rail[r] ^= rail[a] - c; }
void cq_template_add_i32_hl_unc(int r, int a, int c) { rail[r] ^= rail[a] + c; }
void cqrt_copy_i32(int dst, int src) { rail[dst] ^= rail[src]; }
void cqrt_free(int r) { (void)r; }
int cqrt_measure_i32(int r) { return rail[r]; }
