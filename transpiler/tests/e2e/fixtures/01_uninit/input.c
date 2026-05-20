#define quantum __attribute__((annotate("quantum")))

int main(void) {
    quantum int x;
    return 0;
}
