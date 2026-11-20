/* GLPK mpl fn_str2time's time-zone field (reduced, its gotos kept): a format loop over a quantum string whose trip
   holds two digit loops (a classical bound with a quantum exit) and error arms reached by goto from both (an
   irreducible loop after fix-irreducible; the exit arms with a call meet at hubs, cq-os2bx). */
char str[8];
int nerr;
__attribute__((noinline)) void err(int k) { nerr += k; }
int str2time(unsigned x0, unsigned y0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  for (int k = 0; k < 8; k++)
    str[k] = (x >> (3 * k)) & 1 ? '0' + ((y0 >> (2 * k)) & 7) : ((y0 >> k) & 1 ? ':' : '+');
  const char *s = str;
  int zone = 0, n = 0;
  for (int f = 0; f < 2; f++) {
    int z, hh, mm, j;
    if (*s == '+')
      z = 1, s++;
    else
      z = -1;
    hh = 0;
    for (j = 1; j <= 2; j++) {
      if (!('0' <= *s && *s <= '9'))
      err1:
        err(1);
      hh = 10 * hh + ((*s++) - '0');
    }
    if (hh > 23)
    err2:
      err(2);
    if (*s == ':') {
      s++;
      if (!('0' <= *s && *s <= '9'))
        goto err1;
    }
    mm = 0;
    if (!('0' <= *s && *s <= '9'))
      goto skip;
    for (j = 1; j <= 2; j++) {
      if (!('0' <= *s && *s <= '9'))
        goto err1;
      mm = 10 * mm + ((*s++) - '0');
    }
    if (mm > 59)
      goto err2;
  skip:
    zone += z * (60 * hh + mm);
    n++;
    if (s >= str + 6)
      break;
  }
  return zone * 16 + n + nerr * 4096;
}
