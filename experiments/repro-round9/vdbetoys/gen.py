# Toy bytecode interpreters for cq-ct59d, one VdbeExec shape per family: python3 gen.py FAMILY N > toy.c
import sys

fam, n = sys.argv[1], int(sys.argv[2])
o = []
P = o.append
P("struct Op { int opcode, p1, p2, p3; };")
P("int interp(struct Op *ops, int n, int *reg) { int rc = 0;")
P("  struct Op *op = ops;")
if fam == "live":   # many variables live across the trip, each written by one case
    P("  " + " ".join(f"int v{i} = {i};" for i in range(n)))
P("  for (int t = 0; t < n; t++, op++) { switch (op->opcode) {")
for i in range(n):
    body = f"if (reg[op->p1] > {i}) reg[op->p2] += op->p1 * {i+3}; else {{ rc ^= {i}; if (reg[op->p2] == {i}) goto done; }}"
    if fam == "jump":     # shared label inside the loop, jump_to_p2 style
        body = f"if (reg[op->p1] > {i}) {{ reg[op->p2] += {i+3}; goto jump_to_p2; }} rc ^= {i};"
    elif fam == "abort":  # shared error exit
        body = f"if (reg[op->p1] == {i}) goto abort_due_to_error; reg[op->p2] += {i+3};"
    elif fam == "fall":   # fall-through into the next case
        P(f"    case {i}: reg[op->p2] += {i+3}; if (reg[op->p1] > {i}) break;")
        continue
    elif fam == "live":
        body = f"if (reg[op->p1] > {i}) v{i} += op->p2; else rc ^= v{i};"
    elif fam == "mem":    # conditions on loaded values only
        body = f"if (reg[reg[op->p1] & 7] > {i}) reg[op->p2] = reg[op->p3] + {i}; else rc += reg[op->p3];"
    P(f"    case {i}: {body} break;")
P("    default: rc = -1; goto done; }")
if fam == "jump":
    P("    continue;")
    P("  jump_to_p2: op = &ops[op->p2] - 1;")
P("  }")
if fam == "abort":
    P("  goto done;")
    P("abort_due_to_error: rc = 99;")
P("done:")
if fam == "live":
    P("  return rc" + "".join(f" + v{i}" for i in range(n)) + ";")
else:
    P("  return rc;")
P("}")
print("\n".join(o))
