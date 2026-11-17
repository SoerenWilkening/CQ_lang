int local_array_quantum_index(unsigned x0, double th, int a, int b) {
    unsigned x = x0;
    cq_theta(&x, th);
    int arr[4];
    arr[0] = a; arr[1] = b; arr[2] = a + b; arr[3] = a * b;
    int v = arr[x & 3];
    return cq_measure(v);
}
int local_array_quantum_write(unsigned x0, double th, int a) {
    unsigned x = x0;
    cq_theta(&x, th);
    int arr[4] = {0, 0, 0, 0};
    arr[x & 3] = a;
    return cq_measure(arr[0] + arr[2]);
}
