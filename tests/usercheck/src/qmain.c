/* The entry is main (renamed for the checker's drivers); the register starts as a constant. */
int main(void) {
    int x = 5;
    cq_theta(&x, 0.5);
    return cq_measure(x * 3 + 1);
}
