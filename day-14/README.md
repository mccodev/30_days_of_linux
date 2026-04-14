# Day 14 - curl — Fetching Data from APIs

## Objective

Learn how to use `curl` to make HTTP requests from the command line, fetch data from public APIs, and combine it with `jq` to build lightweight data extraction pipelines.

---

## What I Learned

- How to use `curl` to make GET requests to public REST APIs and retrieve JSON responses.
- Key `curl` flags: `-s` (silent), `-o` (output to file), `-L` (follow redirects), `-H` (set headers), and `-w` (write out metadata like HTTP status codes).
- Piping `curl` output directly into `jq` to parse and filter API responses on the fly.
- The difference between `-X GET` (default) and `-X POST` for different HTTP methods.

---

## What I Built / Practiced

**Exercises:**
Using `curl` with public APIs, practice fetching and processing live data:

1. **Basic GET Request:** Fetch a list of posts from the JSONPlaceholder API and display the raw JSON.
2. **Piping to jq:** Fetch users from the API and extract only their `name` and `email` fields using `jq`.
3. **Saving to File:** Download a JSON response and save it to a local file for offline processing.
4. **Checking Response Headers:** Use `curl -I` to inspect HTTP response headers from an API endpoint.

(Record the commands you used in the Output section below)

---

## Challenges Faced

- Remembering to use `-s` (silent mode) when piping `curl` output to `jq`, otherwise the progress bar mixes into the JSON and breaks parsing.
- Understanding when to use `-L` to follow redirects, since some API endpoints redirect to a different URL and `curl` does not follow by default.

---

## Key Takeaways

- `curl` + `jq` together form a powerful lightweight alternative to writing full scripts for quick API data extraction.
- Always check the HTTP status code (`curl -w '%{http_code}'`) to confirm a successful response before processing the data.

---

## Resources

- [curl Manual](https://curl.se/docs/manpage.html)
- [JSONPlaceholder — Free Fake API](https://jsonplaceholder.typicode.com/)

---


## Data Engineering Project

See the [project/](./project/) folder for a hands-on exercise: **API-to-CSV Extraction Pipeline** — fetching exchange rate data with `curl`, transforming with `jq`, and landing as CSV.
