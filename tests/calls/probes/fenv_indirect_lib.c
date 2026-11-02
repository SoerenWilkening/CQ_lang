/* tests/calls probe (cq-4e6m): fhalf compiled under FENV_ACCESS ON (strict ops), fplain without. */
#include <fenv.h>
double fplain(double x) { return x + 2.0; }
#pragma STDC FENV_ACCESS ON
double fhalf(double x) { return x * 0.5 - 1.0; }
