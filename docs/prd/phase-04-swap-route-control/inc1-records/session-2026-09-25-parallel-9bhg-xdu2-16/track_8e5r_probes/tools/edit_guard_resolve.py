#!/usr/bin/env python3
"""Teach the semantic guard to RESOLVE an unqualified type name the way the
compiler's lookup does (innermost enclosing scope outward), instead of failing on
it. The JSON dump desugars only the TOP LEVEL of a type, so `R2CleanRec *` (a
pointer to a type written unqualified) reaches the walker unqualified."""
p = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2/tools/taintset_scrub_guard.py"
s = open(p).read()


def rep(a, b, n=1):
    global s
    assert s.count(a) == n, (a[:80], s.count(a))
    s = s.replace(a, b)


rep("""        self.walked = set()   # qualified names of records already walked
        self.tparams = set()  # template type-parameter names of the pattern being walked
""", """        self.walked = set()   # qualified names of records already walked
        self.tparams = set()  # template type-parameter names of the pattern being walked
        self.scope = "cq"     # qualified name of the record whose fields are being walked
        self.unresolved = []  # (path, scope, kind, node, via): names written UNQUALIFIED
""")
# pointer to an unqualified named / template
rep("""                if nm in BUILTINS or self._is_tparam(nm):
                    return
                if nm in IR_OWNED_DENY:""", """                if nm in BUILTINS or self._is_tparam(nm):
                    return
                if "::" not in nm:
                    self.unresolved.append((path, self.scope, "ptr", inner, None))
                    return
                if nm in IR_OWNED_DENY:""")
rep("""            if inner[0] == "tmpl":
                if inner[1].startswith(PROJECT_NS)""", """            if inner[0] == "tmpl":
                if "::" not in inner[1]:
                    self.unresolved.append((path, self.scope, "ptr", inner, None))
                    return
                if inner[1].startswith(PROJECT_NS)""")
# a template held by value, written unqualified
rep("""        if k == "tmpl":
            nm = node[1]
            if nm in SCRUB_KEYS_ONLY:""", """        if k == "tmpl":
            nm = node[1]
            if "::" not in nm:
                self.unresolved.append((path, self.scope, "tmpl", node, None))
                return
            if nm in SCRUB_KEYS_ONLY:""")
rep("""    def _named(self, path, nm, via=None):
        if nm in BUILTINS or self._is_tparam(nm):
            return
        if nm in HANDLES or nm in LEAVES:
            return
""", """    def _named(self, path, nm, via=None):
        if nm in BUILTINS or self._is_tparam(nm):
            return
        if nm in HANDLES or nm in LEAVES:
            return
        if "::" not in nm:
            self.unresolved.append((path, self.scope, "named", ("named", nm), via))
            return
""")
# scope tracking in the record walk
rep('''def _walk_record(W, rec, path, top_level):
    """Walk a CXXRecordDecl JSON node: bases, fields, static members, nested records."""
    W.walked.add(path)
''', '''def _walk_record(W, rec, path, top_level):
    """Walk a CXXRecordDecl JSON node: bases, fields, static members, nested records."""
    W.walked.add(path)
    saved_scope = W.scope
    W.scope = path
    try:
        _walk_record_body(W, rec, path, top_level)
    finally:
        W.scope = saved_scope


def _walk_record_body(W, rec, path, top_level):
''')
# the resolver + the loop
rep('''def _traits(tu_dir, names):''', '''def _requalify(node, qname):
    return ("named", qname) if node[0] == "named" else ("tmpl", qname, node[2])


def _resolve(tu_dir, items):
    """Qualify each UNQUALIFIED type name the way C++ lookup from its field's scope
    would: innermost enclosing record/namespace first, then outward, then the global
    namespace. One TU; each candidate is one line, and a candidate EXISTS iff its
    line compiles. -> {(name, scope): qualified-name or None}."""
    keys = sorted({(it[3][1], it[1]) for it in items})
    lines = ['#include "TaintPropagation.h"']
    where = {}  # line number -> (key, candidate)
    for i, (nm, scope) in enumerate(keys):
        parts = scope.split("::")
        cands = ["::".join(parts[:k]) + "::" + nm for k in range(len(parts), 0, -1)] + [nm]
        for j, c in enumerate(cands):
            lines.append(f"template <class... Ts> using cq_guard_r{i}_{j} = ::{c}<Ts...>;"
                         if any(it[3][0] == "tmpl" and it[3][1] == nm for it in items)
                         else f"using cq_guard_r{i}_{j} = ::{c};")
            where[len(lines)] = ((nm, scope), c, j)
    path = os.path.join(tu_dir, "cq_guard_resolve.cpp")
    open(path, "w").write("\\n".join(lines) + "\\n")
    r = _compile(tu_dir, path, [])
    bad = set()
    for line in r.stderr.splitlines():
        m = re.search(r"cq_guard_resolve\\.cpp:(\\d+):\\d+: error", line)
        if m:
            bad.add(int(m.group(1)))
    out = {}
    for ln in sorted(where):
        key, cand, j = where[ln]
        if ln not in bad and key not in out:
            out[key] = cand
    return {k: out.get(k) for k in keys}


def _traits(tu_dir, names):''')
rep('''        while True:
            todo = [n for n in W.foreign if n not in W.walked]
            if not todo:
                break
''', '''        while True:
            if W.unresolved:
                items, W.unresolved = W.unresolved, []
                res = _resolve(tmp, items)
                for path, scope, kind, node, via in items:
                    q = res.get((node[1], scope))
                    if q is None:
                        W.errs.append(f"{path}: unqualified type `{node[1]}` does not resolve from "
                                      f"scope `{scope}` — closed world: refused")
                        continue
                    saved = W.scope
                    W.scope = scope
                    try:
                        qn = _requalify(node, q)
                        if kind == "ptr":
                            W._t(path, ("ptr", qn))
                        elif kind == "tmpl":
                            W._t(path, qn)
                        else:
                            W._named(path, q, via=via)
                    finally:
                        W.scope = saved
            todo = [n for n in W.foreign if n not in W.walked]
            if not todo and not W.unresolved:
                break
''')
open(p, "w").write(s)
print("ok")
