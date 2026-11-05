/* One bus: an address-rail load of a constant global and of a mutable global are the same bus load of HOST cells. */
static const int ROM[4] = {3, 1, 4, 1};
int tab[4] = {2, 7, 1, 8};
void tab_set(unsigned i, int v) { tab[i & 3] = v; }      /* all-classical: its store writes the host bytes */
int bus_mutable_table(unsigned k0, double tk) {
    unsigned k = k0;
    cq_theta(&k, tk);
    return cq_measure(ROM[k & 3] + tab[k & 3]);          /* two loads at address rails, one index */
}
