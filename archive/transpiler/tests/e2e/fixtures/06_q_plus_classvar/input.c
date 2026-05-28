#define quantum __attribute__((annotate("quantum")))

int main(void) {
    int classic = 7;
    quantum int a = 3;
    quantum int e = a + classic;
    return 0;
}
