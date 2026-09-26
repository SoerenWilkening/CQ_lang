#!/usr/bin/env python3
"""F-EB-10: the scrub selftest rejects unknown CQ_OPT_DEBUG_ALLOC values loudly,
takes --require-reuse as an ARGUMENT, and REPORTS every aliasing branch (and its
check count) it skipped — never skips silently."""
p = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2/ir-pass/tools/scrub_selftest.cpp"
s = open(p).read()


def rep(a, b, n=1):
    global s
    assert s.count(a) == n, (a[:70], s.count(a))
    s = s.replace(a, b)


rep("""unsigned Checks = 0, Failures = 0, ReuseTried = 0, ReuseHit = 0;
bool StrictReuse = false;
""", """unsigned Checks = 0, Failures = 0, ReuseTried = 0, ReuseHit = 0;
unsigned SkippedBranches = 0, SkippedChecks = 0;
bool StrictReuse = false;
""")
rep("""void expect(bool Ok, const std::string &What) {""", """// The aliasing branch of one member did not run because the fresh object did not
// land on the dead address. Under `--require-reuse` that is a FAILURE (the branch
// would be vacuous); otherwise it is COUNTED and reported — never skipped
// silently (Rule-13 r1B F-EB-10).
void skipBranch(unsigned NChecks, const std::string &What);

void expect(bool Ok, const std::string &What) {""")
rep("""template <typename C> std::size_t iterCount(const C &Cont) {""", """void skipBranch(unsigned NChecks, const std::string &What) {
  ++SkippedBranches;
  SkippedChecks += NChecks;
  if (StrictReuse)
    expect(false, What + ": address reuse NOT reproduced under --require-reuse "
                         "(the aliasing branch would be vacuous)");
}

template <typename C> std::size_t iterCount(const C &Cont) {""")
# set branch: 3 checks
rep("""    expect(S.count(Y) == 1 && S.size() == 1 && iterCount(S) == 1,
           N + ": the revived address is a member exactly once");
  } else if (StrictReuse) {
    expect(false, N + ": LIFO reuse NOT reproduced (the aliasing branch would be vacuous)");
  }""", """    expect(S.count(Y) == 1 && S.size() == 1 && iterCount(S) == 1,
           N + ": the revived address is a member exactly once");
  } else {
    skipBranch(3, N);
  }""")
# map branch: 3 checks
rep("""    expect(Mp.count(Y) == 1 && Mp.size() == 1, N + ": the revived key is a member once");
  } else if (StrictReuse) {
    expect(false, N + ": LIFO reuse NOT reproduced (the aliasing branch would be vacuous)");
  }""", """    expect(Mp.count(Y) == 1 && Mp.size() == 1, N + ": the revived key is a member once");
  } else {
    skipBranch(3, N);
  }""")
# list branch: 2 checks
rep("""    expect(iterCount(L) == 1, N + ": the fresh call is listed exactly ONCE, not twice");
  } else if (StrictReuse) {
    expect(false, N + ": LIFO reuse NOT reproduced (the aliasing branch would be vacuous)");
  }""", """    expect(iterCount(L) == 1, N + ": the fresh call is listed exactly ONCE, not twice");
  } else {
    skipBranch(2, N);
  }""")
# handle-mapped probe: 1 check
rep("""               N + ": a FRESH key at the dead address has NO mapping (8e5r)");
      } else if (StrictReuse) {
        expect(false, N + ": LIFO reuse NOT reproduced (the aliasing branch would be vacuous)");
      }""", """               N + ": a FRESH key at the dead address has NO mapping (8e5r)");
      } else {
        skipBranch(1, N);
      }""")
# ControlledRotations: 1 check
rep("""             "ControlledRotations: a FRESH call at the dead address has NO flag (8e5r)");
    } else if (StrictReuse) {
      expect(false, "ControlledRotations: LIFO reuse NOT reproduced");
    }""", """             "ControlledRotations: a FRESH call at the dead address has NO flag (8e5r)");
    } else {
      skipBranch(1, "ControlledRotations");
    }""")
rep("""int main() {
  const char *Mode = std::getenv("CQ_OPT_DEBUG_ALLOC");
  StrictReuse = Mode && !std::strcmp(Mode, "lifo");
""", """int main(int argc, char **argv) {
  // Rule-13 r1B F-EB-10: the mode is VALIDATED, and "reuse required" is an
  // ARGUMENT, not a re-read of the env string — a typo (`LIFO`) or a lost ctest
  // ENVIRONMENT used to downgrade silently to "(not required)".
  const char *Mode = std::getenv("CQ_OPT_DEBUG_ALLOC");
  std::string M = Mode ? Mode : "";
  if (!M.empty() && M != "lifo" && M != "nofree") {
    errs() << "cq-scrub-selftest: unknown CQ_OPT_DEBUG_ALLOC='" << M
           << "' (expected unset, 'lifo' or 'nofree') — refusing to run\\n";
    return 2;
  }
  for (int I = 1; I < argc; ++I) {
    if (!std::strcmp(argv[I], "--require-reuse")) {
      StrictReuse = true;
    } else {
      errs() << "cq-scrub-selftest: unknown argument '" << argv[I] << "'\\n";
      return 2;
    }
  }
  if (StrictReuse && M != "lifo") {
    errs() << "cq-scrub-selftest: --require-reuse needs CQ_OPT_DEBUG_ALLOC=lifo (got '" << M
           << "') — refusing to run\\n";
    return 2;
  }
""")
rep("""  outs() << "scrub-on-delete selftest: " << Checks << " checks, " << Failures
         << " failures; LIFO address reuse reproduced " << ReuseHit << "/" << ReuseTried
         << (StrictReuse ? " (required: CQ_OPT_DEBUG_ALLOC=lifo)" : " (not required)")
         << "\\n";""", """  outs() << "scrub-on-delete selftest [CQ_OPT_DEBUG_ALLOC=" << (M.empty() ? "<unset>" : M)
         << "]: " << Checks << " checks, " << Failures << " failures; address reuse reproduced "
         << ReuseHit << "/" << ReuseTried
         << (StrictReuse ? " (REQUIRED)" : " (not required)") << "; aliasing branches SKIPPED "
         << SkippedBranches << "/" << ReuseTried << " (" << SkippedChecks << " checks)\\n";""")
open(p, "w").write(s)
print("ok")
