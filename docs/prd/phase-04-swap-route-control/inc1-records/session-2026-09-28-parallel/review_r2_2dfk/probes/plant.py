import sys
p, old, new = sys.argv[1:]
t = open(p).read()
if t.count(old) != 1:
    print("NOT PLANTED (%d occurrences): %r" % (t.count(old), old)); sys.exit(3)
open(p, "w").write(t.replace(old, new, 1)); print("planted in", p.rsplit('/',1)[1])
