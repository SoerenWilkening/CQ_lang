struct Op { int opcode, p1, p2, p3; };
int interp(struct Op *ops, int n, int *reg) { int rc = 0;
  struct Op *op = ops;
  for (int t = 0; t < n; t++, op++) { switch (op->opcode) {
    case 0: reg[op->p2] += 3; if (reg[op->p1] > 0) break;
    case 1: reg[op->p2] += 4; if (reg[op->p1] > 1) break;
    default: rc = -1; goto done; }
  }
done:
  return rc;
}
