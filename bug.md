# bug.md

Open items found on 2026-10-20 while comparing c90 with cpp11. Measured against c90 1.4 (5b8d33a) and cpp11 1.21
(`Ghulamrs/Compiler-Cpp-Optimize` 61d34cb), both built on Linux with their own `make`. Nothing in the source has
been changed for these yet.

| # | Item | Size | Status |
|---|---|---|---|
| B1 | c90 keeps its own copies of files cpp11 also has | about a day | open |

---

## B1 - c90 keeps its own copies of files cpp11 also has

86% of the lines of c90's preprocessor, lexer, driver, walker and back ends appear word for word in cpp11.
Each fix has to be made twice, and the copies have started to drift: c90's `genX87Binary` calls `std::exit(1)`
where cpp11's calls `compileFailed()`.

**Minimum action** - only the files that are already identical:

| File | Lines that differ, c90 vs cpp11 | Lines removed from c90 |
|---|---|---|
| `src/backend/Dwarf.cpp` + `Dwarf.h` | 9 + 10 | about 540 |
| `src/backend/Backend.cpp` | 5 | about 115 |

1. Reconcile those 24 lines once.
2. Delete c90's copies and build them from `../C++Optimize/src/backend/` - the sibling layout GRIDE's
   `Toolchain/Compilers` already guarantees: `Makefile`, `ide/generate.py` (then `ide/cc1.vcxproj`), and
   `tools/seal.json`.
3. Add a check to `make test` that fails when a file c90 still copies changes in cpp11 without its copy
   following. Both repositories already carry the same `tools/backend-overlap`, which can be extended for this.

**Check.** c90: `make test` (440 pass, plus x86_64-windows 21/21, driver modes 12/12, gdb 62/62 and 58/58,
fingerprint 2586 files identical). cpp11: `make test` (baseline on Linux 834 passed, 4 failed only because the
container's shell prints `Aborted` after `abort()`).

**Cost to accept.** c90 no longer builds without cpp11 checked out beside it, and a change to a shared file has
to be tested in both compilers.

The other duplicated files (about 11,000 lines: `Preprocessor`, `Lexer`, `Type`, `Walker`, `Spelling` and the
four back ends) need a C / C++ language setting before c90 can use cpp11's copy; they can move over the same
way, one at a time, when each is next touched.
