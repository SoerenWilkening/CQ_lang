// kfun.c's add_q in C++: a template, a lambda and the overloaded cq_theta.
template <class T, class F> static T apply(T v, F f) { return f(v); }
extern "C" int add_q(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(apply(x, [c](int v) { return v + c; }));
}
extern "C" int add_t(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    return apply(x, [c](int v) { return v * 3 + c; });
}
