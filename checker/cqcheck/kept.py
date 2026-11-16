"""The kept list of a run (RunResult.kept): the exit event's live rails, never one entry per rail (cq-pckdl).

An entry is one of
  - a row: {"h", "w", "v", "role", "known"} for one rail, or with "n" and "step" for the n rails h, h + step, ...,
    h + (n - 1) * step, all of one width, value, role and known flag;
  - a pattern: {"pat": [rows], "at": [uses]} or {"pat": [rows], "at": [uses], "skip": [[b, [rel, ...]], ...]}: a use
    is a base b or a run [b, n, step] of the bases b, b + step, ..., b + (n - 1) * step (ascending by b); for each
    base the pattern's rows with every handle moved by it, less the rails at the relative handles that "skip" lists
    for the use that starts at b (each base of a run alike). rt/core.c at_exit_handler writes a stretch of rails that
    recurs once in full and then by reference, and a replayed call as a use of its record's rows (a replayed
    snprintf left 145M live rails at exit, cq-kcn5i); a skipped rail is one the caller touched, written as a row of
    its own or not at all.
Every "h" is a rail's NAME, never its handle (rt/core.c, rail names; owner 2026-11-09: a replayed call reserves no
handles): a rail made inside occurrence o (a top-level call of a replayable clone, however it ran) is (o + 1) << 32 |
row, row its place among the occurrence's rails; any other rail its rank among the rails made outside occurrences.
Names do not depend on which calls were replayed, so two samples on one path name their rails alike, as handles did
before. A replayed call's use has its base at (o + 1) << 32 | rows before it, so its def's row r is that name + r.
No handle is in two places. A reader goes through leaves(): (row, uses) pairs, uses None for a row of its own and
a Uses for a pattern's row; the pair stands for count(row, uses) rails that share the row's width, value, role and
known flag (a pattern row none of whose rails is left is not a leaf). A reader that
needs one rail at a time asks KeptIndex for it, or expands only the pairs it selects first (rails); nothing but
the reference's kept multiset (compare._kept_rows, CQ_spec examples) expands every entry of a run.

run.py builds the list from the exit event's entries (build): rows, {"def": id, "rows": [...]} (a pattern's rows,
handles relative to its first rail) and {"use": id, "h": b} or {"use": id, "h": b, "n": n, "step": s} (the pattern
at b, b + s, ...), either with "skip": [rel, ...] (those rails of the pattern left out at each of its bases).
"""
from __future__ import annotations

import bisect
from typing import Any, Dict, Iterable, Iterator, List, Optional, Sequence, Tuple

Row = Dict[str, Any]


# Interning (cq-v0u99): a run's patterns repeat a few thousand distinct rows half a million times (swscanf: 514902 rows
# of 23764 patterns, 4317 distinct rows, 511 distinct row lists), and the samples of one path repeat them again. Every
# row and every pattern's row list is one shared object per distinct content in the process, never copied: no reader
# changes a row or a row list in place (each change makes a new one: rail, split, mark_results). A Pat carries what
# the readers derive from its rows (offsets, widths, digest terms), computed once.
_ROWS: Dict[Tuple, Row] = {}
_PATS: Dict[Tuple, "Pat"] = {}
_INTERN_MAX = 1 << 21     # entries of either table; past it both start afresh (sharing is lost, never a value)


def _row_key(e: Row) -> Optional[Tuple]:
    try:
        k = (tuple(e.items()), tuple(map(type, e.values())))    # the types tell True from 1
        hash(k)
        return k
    except TypeError:
        return None


def intern_row(e: Row) -> Row:
    """The one row of the process equal to e (same fields in the same order, same values and value types)."""
    k = _row_key(e)
    if k is None:
        return e
    r = _ROWS.get(k)
    if r is None:
        if len(_ROWS) >= _INTERN_MAX:
            _ROWS.clear()
            _PATS.clear()
        r = _ROWS[k] = e
    return r


class Pat(list):
    """A pattern's rows (a list, as JSON reads it), interned; its derived tables made on first use."""

    __slots__ = ("_offs", "_first", "_digest", "_width", "_ids")

    def ids(self) -> frozenset:
        """The ids of its rows."""
        try:
            return self._ids
        except AttributeError:
            self._ids = frozenset(id(r) for r in self)
            return self._ids

    def offs(self) -> Dict[int, List[Row]]:
        """Relative handle -> the rows that hold it, in row order."""
        try:
            return self._offs
        except AttributeError:
            d: Dict[int, List[Row]] = {}
            for r in self:
                for o in _offsets(r):
                    d.setdefault(o, []).append(r)
            self._offs = d
            return d

    def first(self) -> Tuple[Dict[int, Row], int]:
        """(relative handle -> the first row that holds it, the largest relative handle or 0)."""
        try:
            return self._first
        except AttributeError:
            f = {o: rs[0] for o, rs in self.offs().items()}
            self._first = (f, max(f, default=0))
            return self._first

    def width(self) -> Dict[int, Any]:
        """Relative handle -> the width of the first row that holds it."""
        try:
            return self._width
        except AttributeError:
            self._width = {o: r.get("w") for o, r in self.first()[0].items()}
            return self._width

    def digest(self) -> List[Tuple[Any, int, Tuple[int, ...]]]:
        """Per width, in order of first appearance: (width, rails of one use, the sum of _geo(r, h, n, step) over the
        rows of that width mod _P, for each r of _BASES)."""
        try:
            return self._digest
        except AttributeError:
            acc: Dict[Any, List[int]] = {}
            for row in self:
                a = acc.setdefault(row.get("w"), [0] + [0] * len(_BASES))
                a[0] += row.get("n", 1)
                for j, r in enumerate(_BASES):
                    a[1 + j] = (a[1 + j] + _geo(r, row["h"], row.get("n", 1), row.get("step", 0))) % _P
            self._digest = [(w, a[0], tuple(a[1:])) for w, a in acc.items()]
            return self._digest


def intern_pat(rows: Sequence[Row], interned: bool = False) -> Pat:
    """The one Pat of the process with these rows (interned: the rows are intern_row's already)."""
    if not interned:
        rows = [intern_row(r) for r in rows]
    k = tuple(id(r) for r in rows)
    p = _PATS.get(k)
    if p is None or len(p) != len(rows) or any(a is not b for a, b in zip(p, rows)):
        if len(_PATS) >= _INTERN_MAX:
            _PATS.clear()
        p = _PATS[k] = Pat(rows)
    return p


class PatEntry(dict):
    """A pattern entry ({"pat", "at"[, "skip"]}, a dict as JSON reads it) that keeps its Uses once made (uses_of).
    Its "at" and "skip" are never changed after the Builder made it."""

    __slots__ = ("_uses",)


class Builder:
    """The kept list of one exit event, from its entries one at a time."""

    def __init__(self) -> None:
        self.rows: List[Row] = []
        self.pats: Dict[Any, Row] = {}
        self.order: List[Row] = []
        self.strs: Dict[str, str] = {}

    def _own(self, e: Row) -> Row:
        """e with its width, value and role strings shared with every other entry's (a run keeps 10^5 rows)."""
        for f in ("w", "v", "role"):
            x = e.get(f)
            if isinstance(x, str):
                e[f] = self.strs.setdefault(x, x)
        return e

    def _pat(self, rows: Sequence[Row]) -> "Pat":
        """A pattern's rows, shared with every equal row list (intern_pat): its rows' handles are relative, so they
        recur; a row of its own (a distinct handle each) is not interned."""
        return intern_pat([intern_row(self._own(r)) for r in rows], interned=True)

    def add(self, e: Row) -> None:
        if "pat" in e:                       # a pattern entry of a list built before (a cached run)
            p = PatEntry(pat=self._pat(e["pat"]), at=list(e["at"]))
            if e.get("skip"):
                p["skip"] = list(e["skip"])
            self.order.append(p)
        elif "def" in e:
            p = PatEntry(pat=self._pat(e["rows"]), at=[])
            self.pats[e["def"]] = p
            self.order.append(p)
        elif "use" in e:
            p = self.pats[e["use"]]
            n = e.get("n", 1)
            p["at"].append([e["h"], n, e["step"]] if n > 1 else e["h"])   # a run stays a run, never its bases
            if e.get("skip"):
                p.setdefault("skip", []).append([e["h"], sorted(e["skip"])])
        else:
            self.rows.append(self._own(e))

    def kept(self) -> List[Row]:
        for p in self.order:
            p["at"].sort(key=_start)
            if "skip" in p:
                p["skip"].sort(key=lambda t: t[0])
        return sorted(self.rows, key=lambda e: e["h"]) + [p for p in self.order if p["at"]]


def intern_kept(kept: List[Row]) -> List[Row]:
    """A kept list as JSON read it back (a cached run) with its patterns' rows and row lists shared (intern_pat) and its
    pattern entries PatEntry, entry and key order kept."""
    out: List[Row] = []
    for e in kept:
        if isinstance(e, dict) and isinstance(e.get("pat"), list):
            out.append(PatEntry((k, intern_pat(v) if k == "pat" else v) for k, v in e.items()))
        else:
            out.append(e)
    return out


def build(entries: Iterable[Row]) -> List[Row]:
    b = Builder()
    for e in entries:
        b.add(e)
    return b.kept()


def _start(u: Any) -> int:
    return u if isinstance(u, int) else u[0]


def _run(u: Any) -> Tuple[int, int, int]:
    """A use as (first base, number of bases, step)."""
    return (u, 1, 1) if isinstance(u, int) else (u[0], u[1], u[2])


class Uses:
    """The bases of one pattern (its "at" and "skip"), as leaves() hands them to count, handles and rails."""

    __slots__ = ("at", "skip", "n", "skipped", "pat", "rowskip")

    def __init__(self, at: Sequence[Any], skip: Optional[Sequence[Any]] = None):
        self.at = at
        self.skip: Dict[int, frozenset] = {b: frozenset(rels) for b, rels in (skip or [])}
        self.n = sum(_run(u)[1] for u in at)
        self.skipped: Dict[int, int] = {}     # relative handle -> how many bases leave it out
        for u in at:
            rels = self.skip.get(_start(u))
            if rels:
                for o in rels:
                    self.skipped[o] = self.skipped.get(o, 0) + _run(u)[1]
        self.pat: Optional[Pat] = None
        self.rowskip: Optional[Dict[int, int]] = None   # id(row of pat) -> the rails of it the bases leave out

    def _rowskip(self, row: Row) -> Optional[int]:
        """What count subtracts for `row`, from the pattern's offset table (None: row is not one of the pattern's). Only
        the rows a base leaves rails of are held (a run keeps a Uses per pattern entry)."""
        if self.pat is None or id(row) not in self.pat.ids():
            return None
        if self.rowskip is None:
            offs = self.pat.offs()
            rs: Dict[int, int] = {}
            for o, m in self.skipped.items():
                for i in {id(r) for r in offs.get(o, ())}:    # each row once, as count reads each row once
                    rs[i] = rs.get(i, 0) + m
            self.rowskip = rs
        return self.rowskip.get(id(row), 0)

    def __len__(self) -> int:
        return self.n

    def __iter__(self) -> Iterator[int]:
        for u in self.at:
            b, n, st = _run(u)
            yield from range(b, b + n * st, st)

    def runs(self) -> Iterator[Tuple[int, int, int, frozenset]]:
        """Each use as (first base, number of bases, step, the relative handles it leaves out)."""
        for u in self.at:
            b, n, st = _run(u)
            yield b, n, st, self.skip.get(b, frozenset())


def uses_of(e: Row) -> Uses:
    if isinstance(e, PatEntry):
        try:
            return e._uses
        except AttributeError:
            pass
    u = Uses(e["at"], e.get("skip"))
    if isinstance(e.get("pat"), Pat):
        u.pat = e["pat"]
    if isinstance(e, PatEntry):
        e._uses = u
    return u


def _uses(at: Any) -> Uses:
    return at if isinstance(at, Uses) else Uses(at)


def leaves(kept: Optional[Sequence[Row]]) -> Iterator[Tuple[Row, Optional[Uses]]]:
    for e in kept or []:
        if not isinstance(e, dict):
            continue
        if "pat" in e:
            u = uses_of(e)
            for r in e["pat"]:
                if not u.skipped or count(r, u):
                    yield r, u
        else:
            yield e, None


def count(row: Row, at: Optional[Any] = None) -> int:
    if at is None:
        return row.get("n", 1)
    u = _uses(at)
    n = row.get("n", 1) * len(u)
    if u.skipped:
        m = u._rowskip(row)
        if m is None:
            offs = _offsets(row)
            m = sum(m for o, m in u.skipped.items() if o in offs)
        n -= m
    return n


def _offsets(row: Row) -> range:
    n = row.get("n", 1)
    st = row.get("step", 0) if n > 1 else 1
    return range(row["h"], row["h"] + n * st, st)


def handles(row: Row, at: Optional[Any] = None) -> Iterator[int]:
    if at is None:
        yield from _offsets(row)
        return
    offs = _offsets(row)
    for b0, n, st, sk in _uses(at).runs():
        for b in range(b0, b0 + n * st, st):
            for o in offs:
                if o not in sk:
                    yield b + o


def rail(row: Row, h: int) -> Row:
    """The entry of rail h of `row`, as a row of one rail."""
    if "n" not in row and row["h"] == h:
        return row
    one = {k: v for k, v in row.items() if k not in ("n", "step")}
    one["h"] = h
    return one


def rails(row: Row, at: Optional[Any] = None) -> Iterator[Row]:
    """The rails of one leaf, one entry each."""
    if at is None and "n" not in row:
        yield row
        return
    for h in handles(row, at):
        yield rail(row, h)


def holds(row: Row, h: int) -> bool:
    n = row.get("n", 1)
    if n <= 1:
        return row["h"] == h
    d = h - row["h"]
    st = row["step"]
    return d >= 0 and d % st == 0 and d // st < n


def split(row: Row, picks: Dict[int, Row]) -> List[Row]:
    """A row (no pattern) with each rail h of `picks` (handle -> its own entry) cut out as that entry: the rows before,
    between and after keep their run form."""
    hs = sorted(h for h in picks if holds(row, h))   # a pick of None: the rail is left out
    if not hs:
        return [row]
    st = row.get("step", 0)
    base = {k: v for k, v in row.items() if k not in ("h", "n", "step")}
    out: List[Row] = []
    lo = row["h"]
    end = row["h"] + row.get("n", 1) * st if row.get("n", 1) > 1 else row["h"] + 1

    def piece(a: int, b: int) -> None:      # rails a, a + st, ... below b
        m = (b - a) // st if st else (1 if a < b else 0)
        if m == 1:
            out.append(dict(base, h=a))
        elif m > 1:
            out.append(dict(base, h=a, n=m, step=st))

    for h in hs:
        piece(lo, h)
        if picks[h] is not None:
            out.append(picks[h])
        lo = h + (st or 1)
    piece(lo, end)
    return out


_SMALL_RUN = 16   # a row of at most this many rails is looked up by its handles (KeptIndex.small)


class KeptIndex:
    """Handle -> the entry of that rail in one run's kept list, without expanding its patterns or long rows. No handle is
    in two places (module docstring), so a lookup has one answer whichever table holds it."""

    def __init__(self, kept: Optional[Sequence[Row]]):
        self.one: Dict[int, Row] = {}
        runs: Dict[Tuple[int, int], List[Tuple[int, int, Row]]] = {}
        small: List[Tuple[int, int, Row]] = []
        self.pats: List[Tuple[Dict[int, Row], Uses, int]] = []
        for e in kept or []:
            if not isinstance(e, dict):
                continue
            if "pat" in e:
                pat = e["pat"]
                offs, span = (pat if isinstance(pat, Pat) else Pat(pat)).first()   # shared by every use of an interned one
                self.pats.append((offs, uses_of(e), span))
            elif e.get("n", 1) <= 1:
                self.one.setdefault(e["h"], e)     # first match wins, as a scan of the list
            elif e["n"] <= _SMALL_RUN:
                small.append((e["step"], len(small), e))
            else:
                st = e["step"]
                runs.setdefault((st, e["h"] % st), []).append((e["h"], e["h"] + (e["n"] - 1) * st, e))
        # cq-v0u99: a short row's rails by handle (a scan of every step's runs per lookup cost 300 dict reads for 302
        # steps); by ascending step, as the scan went
        self.small: Dict[int, Tuple[int, Row]] = {}
        for st, _, e in sorted(small, key=lambda t: (t[0], t[1])):
            for h in range(e["h"], e["h"] + e["n"] * st, st):
                self.small.setdefault(h, (st, e))
        self.runs: Dict[Tuple[int, int], Tuple[List[int], List[Tuple[int, int, Row]]]] = {}
        for k, lst in runs.items():
            lst.sort(key=lambda t: t[0])
            self.runs[k] = ([t[0] for t in lst], lst)
        self.steps = sorted({k[0] for k in self.runs})
        self._starts: Optional[Tuple] = None

    def _uses(self):
        """Every use of every pattern: the single bases ascending (with their pattern index and skip), and every base of
        every run ascending, with the pattern index, the run's skip, how far above it a handle may lie for this base to
        be its run's nearest base at or below it, and the furthest handle the hulls of the bases up to it reach. Runs
        are cut into their bases (cq-v0u99): a run's hull spans its whole step range (a replayed call's run steps over
        occurrences, 2^33 handles), so a walk over run hulls read every run below a handle."""
        if self._starts is None:
            from array import array
            one, many = [], []
            skips: List[frozenset] = [frozenset()]
            sk_ix: Dict[int, int] = {}
            for i, (_, u, span) in enumerate(self.pats):
                for b, n, st, sk in u.runs():
                    if n == 1:
                        one.append((b, i, 0, sk))
                    else:
                        j = 0
                        if sk:
                            j = sk_ix.get(id(sk))
                            if j is None:
                                j = sk_ix[id(sk)] = len(skips)
                                skips.append(sk)
                        for k in range(n):
                            many.append((b + k * st, i, j, st if k < n - 1 else -1, span))
            one.sort(key=lambda t: t[0])
            many.sort(key=lambda t: t[0])
            base, pix, six, lim, reach = array("q"), array("q"), array("q"), array("q"), array("q")
            m = -1
            for b, i, j, st, span in many:
                base.append(b)
                pix.append(i)
                six.append(j)
                lim.append(st)
                m = max(m, b + span)
                reach.append(m)
            del many
            self._starts = ([t[0] for t in one], one, base, pix, six, lim, reach, skips)
        return self._starts

    def get(self, h: Any) -> Optional[Row]:
        if not isinstance(h, int):
            return None
        e = self.one.get(h)
        if e is not None:
            return e
        sm = self.small.get(h)
        if sm is not None:
            return rail(sm[1], h)
        for st in self.steps:
            r = self.runs.get((st, h % st))
            if r is None:
                continue
            i = bisect.bisect_right(r[0], h) - 1
            if i >= 0 and r[1][i][1] >= h:
                return rail(r[1][i][2], h)
        if self.pats:
            bases, one, base, pix, six, lim, reach, skips = self._uses()
            i = bisect.bisect_right(bases, h) - 1
            # single uses do not overlap (each covers one stretch of consecutive live rails, and none spans a
            # replayed call's), so only the last base at or below h can hold it; rows of their own lie between uses
            if i >= 0:
                b, p, _, sk = one[i]
                if h - b not in sk:
                    r = self.pats[p][0].get(h - b)
                    if r is not None:
                        return rail(r, h)
            j = bisect.bisect_right(base, h) - 1
            while j >= 0 and reach[j] >= h:   # every base whose hull may hold h: of each run, its nearest base at or below h
                b = base[j]
                o = h - b
                if lim[j] < 0 or o < lim[j]:
                    p = pix[j]
                    if o <= self.pats[p][2] and o not in skips[six[j]]:
                        r = self.pats[p][0].get(o)
                        if r is not None:
                            return rail(r, h)
                j -= 1
        return None


def expand(kept: Optional[Sequence[Row]]) -> Iterator[Row]:
    """Every rail of the list, one entry each (only for a reader that needs every rail by its handle)."""
    for row, at in leaves(kept):
        yield from rails(row, at)


def mark_results(kept: Optional[Sequence[Row]], results: Iterable[int]) -> List[Row]:
    """The list with each rail of `results` its own entry with "result": true (run.resolve_handle_rets): a pattern's
    use that holds one becomes rows of its own."""
    res = set(results)
    out: List[Row] = []
    for e in kept or []:
        if not isinstance(e, dict):
            out.append(e)
            continue
        if "pat" in e:
            offs = {o for r in e["pat"] for o in _offsets(r)}
            u = uses_of(e)
            hit: Dict[int, frozenset] = {}                 # base -> the rails it leaves out
            rest: List[Any] = []
            skip: List[Any] = []
            for b0, n, st, sk in u.runs():
                hs = set()
                for h in res:                              # the one base of the run at or below h a step away
                    if h >= b0:
                        b = b0 + min((h - b0) // st, n - 1) * st
                        if h - b in offs and h - b not in sk:
                            hs.add(b)
                lo = b0
                for b in sorted(hs) + [b0 + n * st]:       # the run's bases between two hits stay a run
                    m = (b - lo) // st
                    if m:
                        rest.append(lo if m == 1 else [lo, m, st])
                        if sk:
                            skip.append([lo, sorted(sk)])
                    if b in hs:
                        hit[b] = sk
                    lo = b + st
            if not hit:
                out.append(e)
                continue
            if rest:
                out.append(PatEntry({"pat": e["pat"], "at": rest}, **({"skip": skip} if skip else {})))
            for b in sorted(hit):
                for r in e["pat"]:
                    moved = dict(r, h=r["h"] + b)
                    picks: Dict[int, Optional[Row]] = {b + o: None for o in hit[b] if holds(moved, b + o)}
                    picks.update({h: dict(rail(moved, h), result=True) for h in res if holds(moved, h) and h not in picks})
                    out.extend(split(moved, picks))
            continue
        picks = {h: dict(rail(e, h), result=True) for h in res if holds(e, h)}
        out.extend(split(e, picks) if picks else [e])
    return out


_P = (1 << 61) - 1
_BASES = (0x5DEECE66D, 0x2545F4914F6CDD1D % _P)


_QINV: Dict[Tuple[int, int], Tuple[int, Optional[int]]] = {}   # (r, step) -> (r^step, (r^step - 1)^-1) mod _P


def _geo(r: int, h: int, n: int, st: int) -> int:
    """sum of r^(h + i st) for i < n, mod _P."""
    first = pow(r, h, _P)
    if n == 1:
        return first
    t = _QINV.get((r, st))
    if t is None:
        q = pow(r, st, _P)
        if len(_QINV) >= _INTERN_MAX:
            _QINV.clear()
        t = _QINV[(r, st)] = (q, None if q == 1 else pow(q - 1, _P - 2, _P))
    q, inv = t
    if q == 1:
        return first * n % _P
    return first * (pow(q, n, _P) - 1) % _P * inv % _P


def handle_digest(kept: Optional[Sequence[Row]]) -> Tuple:
    """The set of (handle, width) of the kept rails as a value that does not depend on how the rails are cut into
    rows and patterns (compare._shape_of hashed the sorted rails before): per width the count and two polynomial
    hashes, the sum of r^h mod the prime 2^61 - 1 at two fixed points r, each row and pattern in closed form. Equal
    sets give equal digests; two different sets collide only where both difference polynomials vanish at those
    points."""
    acc: Dict[Any, List[int]] = {}
    for e in kept or []:
        if not isinstance(e, dict):
            continue
        if "pat" in e:
            u = uses_of(e)
            sums = [sum(_geo(r, b, n, st) for b, n, st, _ in u.runs()) % _P for r in _BASES]
            pat = e["pat"] if isinstance(e["pat"], Pat) else Pat(e["pat"])
            # each row adds sums * _geo(row) at its width: per width, sums * (the rows' sum), made once per pattern
            for w, cnt, gs in pat.digest():
                a = acc.setdefault(w, [0, 0, 0])
                a[0] += cnt * len(u)
                for j in range(len(_BASES)):
                    a[1 + j] = (a[1 + j] + sums[j] * gs[j]) % _P
            if u.skip:                               # less the (handle, width) of each rail a use leaves out
                width = pat.width()
                for b, n, st, sk in u.runs():
                    for o in sk:
                        a = acc.setdefault(width.get(o), [0, 0, 0])
                        a[0] -= n
                        for j, r in enumerate(_BASES):
                            a[1 + j] = (a[1 + j] - _geo(r, b + o, n, st)) % _P
            continue
        a = acc.setdefault(e.get("w"), [0, 0, 0])
        a[0] += e.get("n", 1)
        for j, r in enumerate(_BASES):
            a[1 + j] = (a[1 + j] + _geo(r, e["h"], e.get("n", 1), e.get("step", 0))) % _P
    return tuple(sorted(((w, *a) for w, a in acc.items() if a[0]), key=lambda t: (str(t[0]), t[1:])))
