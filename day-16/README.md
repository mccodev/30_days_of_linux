# Day 16 - Shell Scripting — Functions, Arguments & Error Handling

## Objective

Move from one-liner commands to writing reusable, robust Bash scripts. Learn how to define functions, accept positional arguments (`$1`, `$2`, `$@`), handle errors with exit codes and `set -e`/`set -u`, and structure scripts that other scripts can source. Apply these skills by refactoring a previous day's pipeline into a proper, parameterised script.

---

## What I Learned

- How to define and call functions in Bash using the `function_name() { ... }` syntax.
- How positional parameters work: `$0` (script name), `$1`/`$2` (arguments), `$@` (all arguments), and `$#` (argument count).
- Using `set -euo pipefail` at the top of a script to make it fail fast on errors, unset variables, and broken pipes.
- Checking exit codes with `$?` and writing guard clauses with `if [[ $? -ne 0 ]]; then`.
- Using `local` to scope variables inside functions and avoid polluting the global namespace.
- Sourcing helper libraries with `source ./lib.sh` so functions can be reused across scripts.

---

## What I Built / Practiced

**Exercises:**

1. **Write a Greeting Function:** Define a `greet()` function that accepts a name as an argument and prints a formatted message. Call it with different names from the same script.
2. **Argument Validation Script:** Write a script that expects exactly two arguments (an input file and an output file), prints a usage message if they are missing, and exits with a non-zero code.
3. **Refactor a Pipeline:** Take the `curl` + `jq` pipeline from Day 13/15 and wrap it inside a parameterised script that accepts an API URL and output path as `$1` and `$2`.
4. **Error-Handling Wrapper:** Add `set -euo pipefail` and a `trap 'echo "Error on line $LINENO"' ERR` to a script, then intentionally trigger an error to see the trap fire.

(Record the commands you used in the Output section below)

---

## Challenges Faced

- Forgetting `local` inside functions caused variable collisions when two functions used the same variable name — a silent bug that was tricky to spot.
- `set -u` causing scripts to abort when referencing an optional argument (`$2`) that wasn't passed; fixed by using `${2:-default_value}` for safe defaults.
- Quoting pitfalls: passing a file path with spaces as a single argument required wrapping it in double quotes both at the call site and inside the function.

---

## Key Takeaways

- `set -euo pipefail` should be the first line of every production Bash script — it turns silent failures into loud, traceable ones.
- Functions make scripts testable and composable; a script full of functions is easier to debug than a long linear sequence of commands.
- Always validate `$#` at the top of a script and print a `Usage:` message — future you will thank present you.

---

## Resources

- `man bash` (search for "Special Parameters" and "Functions")
-