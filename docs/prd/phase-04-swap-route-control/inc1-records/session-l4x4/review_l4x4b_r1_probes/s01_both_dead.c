/* s01 — BOTH b and the rotated register are dead after the region; only an
   unrelated register is measured. Could the spine claim the whole DAG and free
   an entangled control? */
int slice(void) {
  _Bool b=0; int r=7; int u=1;
  b=cq_theta(b,0.5); r=cq_theta(r,0.25); u=cq_theta(u,0.15);
  if (b) { r = cq_theta(r, 0.9); }
  return cq_measure(u);
}
int main(void){(void)slice();return 0;}
