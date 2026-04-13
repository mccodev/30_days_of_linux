# Day 13 - jq — JSON processing (Parsing API responses / event logs)

## Objective

Master the basics of `jq` for parsing, filtering, and transforming JSON data from the command line. You will practice extracting specific fields from API responses and filtering arrays in event logs.

---

## What I Learned

- How to parse JSON files in the command line using `jq`.
- Using filters like `.` and `.field` to navigate JSON payloads and extract specific objects.
- Iterating over arrays with `[]` and filtering data based on conditions using the `select()` function.
- Shaping the output into new JSON objects or raw text to feed into other pipeline tools.

---

## What I Built / Practiced

**Exercises:**
Using the sample files provided (`users.json` and `events.json`), practice using `jq` to solve the following:

1. **Basic Extraction:** From `users.json`, extract just the `users` array.
2. **Filtering Arrays:** From `users.json`, get the names of all users who are currently `active`.
3. **Selecting by Attribute:** From `events.json`, find all events with a "level" of `"ERROR"`.
4. **Formatting Output:** From `events.json`, print a clean list of just the `timestamp` and `message` for each event.

(Record the commands you used in the Output section below)

---

## Challenges Faced

- Distinguishing between array mapping (`.[]`) and object keys when navigating deeply nested JSON structures.
- Enclosing `jq` filters in single quotes to prevent the shell from interpreting special characters like `|` or `$` prematurely.

---

## Key Takeaways

- `jq` functions similarly to `awk` or `sed`, but specifically engineered for structured JSON.
- Combining `select()` with pipe `|` within the `jq` expression itself allows for powerfully chaining transformations on the fly.

---

## Resources

- [jq Manual](https://jqlang.github.io/jq/manual/)
- 

---

## Output

**1. Extract the `users` array:**
```bash
jq '.users' users.json
```

**2. Get the names of all active users:**
```bash
jq '.users[] | select(.active == true) | .name' users.json
```

**3. Find all events with a "level" of "ERROR":**
```bash
jq '.[] | select(.level == "ERROR")' events.json
```

**4. Print a clean list of just the timestamp and message:**
```bash
jq '.[] | {time: .timestamp, info: .message}' events.json
```
