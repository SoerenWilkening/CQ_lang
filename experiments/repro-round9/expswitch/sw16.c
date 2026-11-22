struct Op { int opcode, p1, p2; };
int interp(struct Op *ops, int n, int *reg) { int pc = 0, rc = 0;
  for (pc = 0; pc < n; pc++) { struct Op *o = &ops[pc]; switch (o->opcode) {
    case 0: if (reg[o->p1] > 0) reg[o->p2] += o->p1 * 3; else { rc ^= 0; if (reg[o->p2] == 0) goto done; } break;
    case 1: if (reg[o->p1] > 1) reg[o->p2] += o->p1 * 4; else { rc ^= 1; if (reg[o->p2] == 1) goto done; } break;
    case 2: if (reg[o->p1] > 2) reg[o->p2] += o->p1 * 5; else { rc ^= 2; if (reg[o->p2] == 2) goto done; } break;
    case 3: if (reg[o->p1] > 3) reg[o->p2] += o->p1 * 6; else { rc ^= 3; if (reg[o->p2] == 3) goto done; } break;
    case 4: if (reg[o->p1] > 4) reg[o->p2] += o->p1 * 7; else { rc ^= 4; if (reg[o->p2] == 4) goto done; } break;
    case 5: if (reg[o->p1] > 5) reg[o->p2] += o->p1 * 8; else { rc ^= 5; if (reg[o->p2] == 5) goto done; } break;
    case 6: if (reg[o->p1] > 6) reg[o->p2] += o->p1 * 9; else { rc ^= 6; if (reg[o->p2] == 6) goto done; } break;
    case 7: if (reg[o->p1] > 7) reg[o->p2] += o->p1 * 10; else { rc ^= 7; if (reg[o->p2] == 7) goto done; } break;
    case 8: if (reg[o->p1] > 8) reg[o->p2] += o->p1 * 11; else { rc ^= 8; if (reg[o->p2] == 8) goto done; } break;
    case 9: if (reg[o->p1] > 9) reg[o->p2] += o->p1 * 12; else { rc ^= 9; if (reg[o->p2] == 9) goto done; } break;
    case 10: if (reg[o->p1] > 10) reg[o->p2] += o->p1 * 13; else { rc ^= 10; if (reg[o->p2] == 10) goto done; } break;
    case 11: if (reg[o->p1] > 11) reg[o->p2] += o->p1 * 14; else { rc ^= 11; if (reg[o->p2] == 11) goto done; } break;
    case 12: if (reg[o->p1] > 12) reg[o->p2] += o->p1 * 15; else { rc ^= 12; if (reg[o->p2] == 12) goto done; } break;
    case 13: if (reg[o->p1] > 13) reg[o->p2] += o->p1 * 16; else { rc ^= 13; if (reg[o->p2] == 13) goto done; } break;
    case 14: if (reg[o->p1] > 14) reg[o->p2] += o->p1 * 17; else { rc ^= 14; if (reg[o->p2] == 14) goto done; } break;
    case 15: if (reg[o->p1] > 15) reg[o->p2] += o->p1 * 18; else { rc ^= 15; if (reg[o->p2] == 15) goto done; } break;
    default: rc = -1; goto done; } }
done: return rc; }
