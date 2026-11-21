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
    case 16: if (reg[o->p1] > 16) reg[o->p2] += o->p1 * 19; else { rc ^= 16; if (reg[o->p2] == 16) goto done; } break;
    case 17: if (reg[o->p1] > 17) reg[o->p2] += o->p1 * 20; else { rc ^= 17; if (reg[o->p2] == 17) goto done; } break;
    case 18: if (reg[o->p1] > 18) reg[o->p2] += o->p1 * 21; else { rc ^= 18; if (reg[o->p2] == 18) goto done; } break;
    case 19: if (reg[o->p1] > 19) reg[o->p2] += o->p1 * 22; else { rc ^= 19; if (reg[o->p2] == 19) goto done; } break;
    case 20: if (reg[o->p1] > 20) reg[o->p2] += o->p1 * 23; else { rc ^= 20; if (reg[o->p2] == 20) goto done; } break;
    case 21: if (reg[o->p1] > 21) reg[o->p2] += o->p1 * 24; else { rc ^= 21; if (reg[o->p2] == 21) goto done; } break;
    case 22: if (reg[o->p1] > 22) reg[o->p2] += o->p1 * 25; else { rc ^= 22; if (reg[o->p2] == 22) goto done; } break;
    case 23: if (reg[o->p1] > 23) reg[o->p2] += o->p1 * 26; else { rc ^= 23; if (reg[o->p2] == 23) goto done; } break;
    case 24: if (reg[o->p1] > 24) reg[o->p2] += o->p1 * 27; else { rc ^= 24; if (reg[o->p2] == 24) goto done; } break;
    case 25: if (reg[o->p1] > 25) reg[o->p2] += o->p1 * 28; else { rc ^= 25; if (reg[o->p2] == 25) goto done; } break;
    case 26: if (reg[o->p1] > 26) reg[o->p2] += o->p1 * 29; else { rc ^= 26; if (reg[o->p2] == 26) goto done; } break;
    case 27: if (reg[o->p1] > 27) reg[o->p2] += o->p1 * 30; else { rc ^= 27; if (reg[o->p2] == 27) goto done; } break;
    case 28: if (reg[o->p1] > 28) reg[o->p2] += o->p1 * 31; else { rc ^= 28; if (reg[o->p2] == 28) goto done; } break;
    case 29: if (reg[o->p1] > 29) reg[o->p2] += o->p1 * 32; else { rc ^= 29; if (reg[o->p2] == 29) goto done; } break;
    case 30: if (reg[o->p1] > 30) reg[o->p2] += o->p1 * 33; else { rc ^= 30; if (reg[o->p2] == 30) goto done; } break;
    case 31: if (reg[o->p1] > 31) reg[o->p2] += o->p1 * 34; else { rc ^= 31; if (reg[o->p2] == 31) goto done; } break;
    default: rc = -1; goto done; } }
done: return rc; }
