/* cq-03rdt (pred, selectChainAt): GSL eigen gsl_eigen_nonsymmv_sort reduced. Early returns on quantum tests that run
   only when a classical pointer is set, then a K-loop with two exits: the exit merge selects among the early returns'
   values with arms on the evec != 0 side only, read where the evec == 0 path also passes, and a select condition was
   demanded there, where its atom is never computed. */
typedef struct { unsigned long size, stride; double *data; } vec;
typedef struct { unsigned long size1, size2; } mat;
double D[8];
vec V = {0, 1, D};
mat Mx = {2, 2};
void report1(void);
void report2(void);
void report3(void);
static int less(const double *a, const double *b) { return a[0] < b[0] || (a[0] == b[0] && a[1] < b[1]); }
__attribute__((noinline)) static void swap(vec *v, unsigned long i, unsigned long j) {
  double *a = v->data + 2 * v->stride * i, *b = v->data + 2 * v->stride * j;
  for (int k = 0; k < 2; k++) {
    double t = a[k];
    a[k] = b[k];
    b[k] = t;
  }
}
__attribute__((noinline)) static int sortish(vec *eval, mat *evec, int sort_type) {
  if (evec && (evec->size1 != evec->size2)) {
    report1();
    return 20;
  } else if (evec && (eval->size != evec->size1)) {
    report2();
    return 19;
  } else {
    const unsigned long N = eval->size;
    unsigned long i;
    for (i = 0; i < N - 1; i++) {
      unsigned long j;
      unsigned long k = i;
      const double *ek = eval->data + 2 * i * eval->stride;
      for (j = i + 1; j < N; j++) {
        int test;
        const double *ej = eval->data + 2 * j * eval->stride;
        if (ej[0] > 100.0)
          return 4;
        switch (sort_type) {
        case 2: test = less(ej, ek); break;
        case 3: test = less(ek, ej); break;
        default: test = 0;
        }
        if (test) {
          k = j;
          ek = ej;
        }
      }
      if (k != i)
        swap(eval, i, k);
    }
    return 0;
  }
}
int sel_union(unsigned long n, double a, int usem, int sort_type, double th) {
  unsigned long sz = n;
  cq_theta(&sz, th);
  V.size = 1 + (sz & 3);
  D[0] = a;
  D[2] = 1.0;
  D[4] = -a;
  return cq_measure(sortish(&V, usem & 1 ? &Mx : 0, sort_type));
}
