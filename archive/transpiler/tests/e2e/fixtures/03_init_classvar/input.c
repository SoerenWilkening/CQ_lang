#define quantum __attribute__((annotate("quantum")))

int main(void) {
    int classic = 7;
    quantum int z = classic;
    return 0;
}
