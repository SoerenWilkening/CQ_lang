enum mode { RED, GREEN, BLUE, ALPHA };
int enum_switch_fallthrough(enum mode m0, double th, int y0, double p) {
    enum mode m = m0;
    cq_theta(&m, th);                       /* enum mode * is compatible with unsigned int *: a quantum enum */
    int y = y0;
    switch (m) {                            /* no default: an out-of-range m runs no case */
    case RED:   cq_phi(p);                  /* phase, then fall through */
                /* fallthrough */
    case GREEN: y += 1;                     /* value effect shared by RED and GREEN */
                /* fallthrough */
    case BLUE:  y *= 3; break;              /* shared by RED, GREEN and BLUE */
    case ALPHA: cq_phi(-p); break;          /* phase only */
    }
    return cq_measure(y) + (int)cq_measure(m);
}
