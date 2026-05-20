#define quantum __attribute__((annotate("quantum")))

int main(void) {
    int classic = 7;
    qint_t a = init_qint(3, 16);
    qint_t e = add(a, init_qint(classic, 16));
    return 0;
}
