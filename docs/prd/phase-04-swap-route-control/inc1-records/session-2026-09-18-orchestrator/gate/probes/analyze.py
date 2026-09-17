#!/usr/bin/env python3
"""Analyze the ORACLE-vs-SUBJECT corpus sweep.

Row: rel|O:<rc>:<A|D>:<md5|errline>:<esha>|S:<rc>:<A|D>:<md5|errline>:<esha>

Reports, in the four directions that matter:
  A->D  (new DECLINE; the over-decline direction)
  D->A  (new ACCEPT;  the over-accept direction -- every one needs attribution)
  A->A  md5 changed (same verdict, different circuit)
  D->D  STRING or full-stderr changed  <-- invisible to the shared corpus.sh tag
                                           regex (PROTOCOL S3); closed here by a
                                           full-stderr sha compare.
"""
import sys, collections

def parse(line):
    line = line.rstrip('\n')
    parts = line.split('|')
    if len(parts) != 3:
        return None
    rel, o, s = parts
    if o in ('CLANGERR', 'EMPTYMOD'):
        return (rel, o, None, None, None, None, None)
    def half(x):
        # O:<rc>:<A|D>:<payload...>:<esha>   payload may contain ':'
        f = x.split(':')
        rc, kind = f[1], f[2]
        esha = f[-1]
        payload = ':'.join(f[3:-1])
        return rc, kind, payload, esha
    orc, okind, opay, oesha = half(o)
    src, skind, spay, sesha = half(s)
    return (rel, None, (orc, okind, opay, oesha), (src, skind, spay, sesha), None, None, None)

def main():
    rows = 0
    skipped = collections.Counter()
    buckets = collections.defaultdict(list)
    with open(sys.argv[1]) as f:
        for line in f:
            p = parse(line)
            if p is None:
                skipped['unparsed'] += 1
                continue
            rel, special, O, S, *_ = p
            if special:
                skipped[special] += 1
                continue
            rows += 1
            (orc, ok, opay, oe) = O
            (src, sk, spay, se) = S
            if ok == 'A' and sk == 'D':
                buckets['A->D'].append((rel, spay))
            elif ok == 'D' and sk == 'A':
                buckets['D->A'].append((rel, opay))
            elif ok == 'A' and sk == 'A':
                if opay != spay:
                    buckets['A->A md5'].append((rel, ''))
                if oe != se:
                    buckets['A->A stderr'].append((rel, ''))
            else:  # D->D
                if opay != spay:
                    buckets['D->D string'].append((rel, f'{opay}   ==>   {spay}'))
                elif oe != se:
                    buckets['D->D stderr-only'].append((rel, f'{oe} -> {se}'))
    print(f"rows scored: {rows}")
    for k, v in sorted(skipped.items()):
        print(f"skipped {k}: {v}")
    total = 0
    for k in ('A->D', 'D->A', 'A->A md5', 'A->A stderr', 'D->D string', 'D->D stderr-only'):
        n = len(buckets[k])
        total += n
        print(f"\n=== {k}: {n} ===")
        for rel, extra in sorted(buckets[k]):
            print(f"  {rel}" + (f"\n        {extra}" if extra else ""))
    print(f"\nTOTAL MOVERS: {total}")

if __name__ == '__main__':
    main()
