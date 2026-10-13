#!/bin/sh
# tests/tms6747-debug.sh - c90 -g's .dwpsn stopped on by a debugger, both ways: vm6747 --debug on the assembly,
# and sim6747 --run --debug on the image asm6x and lnk6x make of it against rts6x.lib (its line table ASM6x
# builds and LNK6x carries). Each is a session in gdb's words over tests/tms6747-debug/step.c - RIDE's own
# commands: break FILE:LINE, run, step, backtrace, finish, next, print - and the transcript is checked word
# for word. The tools are the sibling checkouts' unless named (CC1, VM, ASM6X, LNK6X, SIM6747, TIRTS).
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
find_tool() { for t in "$@"; do [ -n "$t" ] && [ -x "$t" ] && { echo "$t"; return; }; done; }
CC1=${CC1:-$ROOT/c90.exe}; T=$ROOT/../../TI
VM=$(find_tool "${VM:-}" "$T/VM6747/vm6747.exe" "$(command -v vm6747 2>/dev/null)")
ASM6X=$(find_tool "${ASM6X:-}" "$T/ASM6x/build/asm6x.exe" "$(command -v asm6x 2>/dev/null)")
LNK6X=$(find_tool "${LNK6X:-}" "$T/LNK6x/build/lnk6x.exe" "$(command -v lnk6x 2>/dev/null)")
SIM6747=$(find_tool "${SIM6747:-}" "$T/SIM6747/sim6747.exe" "$(command -v sim6747 2>/dev/null)")
TIRTS=${TIRTS:-$T/RTS6x/build}
D=$ROOT/tests/tms6747-debug; OUT=$ROOT/tests/out-tms6747-debug; mkdir -p "$OUT"
[ -n "$VM" ] || { echo "tms6747-debug: no vm6747 - build VM6747 or name it with VM"; exit 2; }
cd "$D" || exit 2
"$CC1" -S -arch tms6747 -g step.c -o "$OUT/step.s" > "$OUT/step.log" 2>&1 || { echo "tms6747-debug: c90 -g refused step.c"; cat "$OUT/step.log"; exit 1; }
cp step.c "$OUT/step.c"          # the session echoes the source line from beside what it runs
fail=0
( cd "$OUT" && "$VM" --debug step.s < "$D/step.commands" > "$OUT/vm.got" 2>&1; echo "exit $?" >> "$OUT/vm.got" )
if diff "$D/vm.expected" "$OUT/vm.got" > "$OUT/vm.diff"; then echo "tms6747-debug vm6747: ok"; else echo "tms6747-debug vm6747: FAILED - $OUT/vm.diff"; head -12 "$OUT/vm.diff"; fail=1; fi
if [ -n "$ASM6X" ] && [ -n "$LNK6X" ] && [ -n "$SIM6747" ] && [ -f "$TIRTS/rts6x.lib" ]; then
    if "$ASM6X" "$OUT/step.s" -o "$OUT/step.obj" > "$OUT/link.log" 2>&1 &&
       "$LNK6X" -mv6740 --abi=eabi -i "$TIRTS" link.cmd "$OUT/step.obj" -l rts6x.lib -o "$OUT/step.out" >> "$OUT/link.log" 2>&1; then
        ( cd "$OUT" && "$SIM6747" --run --debug step.out < "$D/step.commands" > "$OUT/sim.got" 2>&1; echo "exit $?" >> "$OUT/sim.got" )
        if diff "$D/sim.expected" "$OUT/sim.got" > "$OUT/sim.diff"; then echo "tms6747-debug sim6747: ok"; else echo "tms6747-debug sim6747: FAILED - $OUT/sim.diff"; head -12 "$OUT/sim.diff"; fail=1; fi
    else echo "tms6747-debug sim6747: FAILED - asm6x or lnk6x refused it"; cat "$OUT/link.log"; fail=1; fi
else echo "tms6747-debug sim6747: skipped - asm6x, lnk6x, sim6747 and rts6x.lib are not all here (ASM6X, LNK6X, SIM6747, TIRTS name them)"; fi
exit $fail
