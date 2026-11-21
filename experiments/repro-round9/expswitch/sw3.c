struct Op { int opcode, p1, p2; };
int interp(struct Op *ops, int n, int *reg) { int pc = 0, rc = 0;
  for (pc = 0; pc < n; pc++) { struct Op *o = &ops[pc]; switch (o->opcode) {
    case 0: if (reg[o->p1] > 0) reg[o->p2] += o->p1 * 3; else { rc ^= 0; if (reg[o->p2] == 0) goto done; } break;
    case 1: if (reg[o->p1] > 1) reg[o->p2] += o->p1 * 4; else { rc ^= 1; if (reg[o->p2] == 1) goto done; } break;
    case 2: if (reg[o->p1] > 2) reg[o->p2] += o->p1 * 5; else { rc ^= 2; if (reg[o->p2] == 2) goto done; } break;
    default: rc = -1; goto done; } }
done: return rc; }
