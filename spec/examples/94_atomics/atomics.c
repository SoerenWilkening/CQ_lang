int atomics(int x0, double th, int c, int e) {
    int x = x0;
    cq_theta(&x, th);
    int cell = c;
    __atomic_store_n(&cell, x, __ATOMIC_SEQ_CST);
    int old = __atomic_fetch_add(&cell, c, __ATOMIC_SEQ_CST);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    int expected = e;
    int ok = __atomic_compare_exchange_n(&cell, &expected, old, 0, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
    int now = __atomic_load_n(&cell, __ATOMIC_SEQ_CST);
    return cq_measure(now) + cq_measure(ok) + cq_measure(expected);
}
