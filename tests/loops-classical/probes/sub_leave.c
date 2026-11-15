/* tests/loops-classical probe (cq-2xl5, CR rules 2, 5, 14): a loop's exit value measured on some classical paths only.
 * lowerMeasure measures a kept basis copy there, so the value's rail is no kept reader's: the reverse loop runs after
 * its readers and undoes it (a copy out would stay live, garbage). sl_goto: a sub-loop leaving its parent (goto out of
 * both loops); sl_nest: a nest whose result is measured on one path. Regenerate sub_leave.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec sub_leave.c -o sub_leave.O1.ll */
#include "CQ.h"
int sl_goto(int x0, double th, int n, int m) {
  int x = x0; cq_theta(&x, th);
  int s = 0;
  for (int i = 0; i < n; i++)
    for (int j = 0; j < m; j++) {
      if (i * 4 + j == 9) goto done;
      s += x ^ j;
    }
done:
  return cq_measure(s);
}
int sl_nest(int x0, double th, int n, int m, int c) {
  int x = x0; cq_theta(&x, th);
  int s = 0;
  for (int i = 0; i < n; i++)
    for (int j = 0; j < m; j++)
      s += x ^ j;
  if (c == 3) return 7;
  return cq_measure(s);
}
