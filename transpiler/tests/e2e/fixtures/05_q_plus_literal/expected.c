#define quantum __attribute__((annotate("quantum")))

int main(void) {
    qint_t a = init_qint(3, 16);
    qint_t d = add(a, init_qint(5, 16));
    return 0;
}
