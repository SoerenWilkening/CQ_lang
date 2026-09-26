typedef int v4 __attribute__((vector_size(16))); int h(int a, int k) { volatile v4 z = (v4){a, k, 0, 0}; return k + 1; }
