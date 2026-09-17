import sys, collections
p = sys.argv[1]
rows = [l.rstrip("\n").split("\t") for l in open(p) if l.strip()]
movers = []
same = 0
for r in rows:
    if len(r) != 7:
        print("MALFORMED:", r); continue
    n, oe, ot, om, se, st, sm = r
    if (oe, ot, om) == (se, st, sm):
        same += 1
    else:
        movers.append(r)
print("rows=%d  unchanged=%d  movers=%d" % (len(rows), same, len(movers)))
kinds = collections.Counter()
for n, oe, ot, om, se, st, sm in movers:
    if oe != "0" and se == "0":
        k = "D->A"
    elif oe == "0" and se != "0":
        k = "A->D"
    elif oe != "0" and se != "0":
        k = "D->D (string changed)"
    else:
        k = "A->A (md5 changed)"
    kinds[k] += 1
for k, v in sorted(kinds.items()):
    print("  %-22s %d" % (k, v))
print()
for n, oe, ot, om, se, st, sm in movers:
    print("%-70s  O:%s %-55s  S:%s %s" % (n, oe, ot[:55], se, st[:55]))
