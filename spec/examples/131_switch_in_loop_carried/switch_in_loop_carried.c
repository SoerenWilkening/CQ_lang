int switch_in_loop_carried(int x0, double th, int n) {
    int x = x0;
    cq_theta(&x, th);
    int acc = 1;
    for (int i = 0; i < n; i++) {           /* classical bound: a classical loop */
        switch ((x >> i) & 3) {             /* quantum scrutinee, different bits each trip */
        case 0:  acc += i;   break;
        case 1:  acc ^= 5;   break;
        case 2:  acc *= 3;   break;
        default:             break;         /* acc carried unchanged */
        }
    }
    return cq_measure(acc);
}
