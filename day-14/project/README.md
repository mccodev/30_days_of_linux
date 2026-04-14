# Data Engineering Example — API-to-CSV Extraction Pipeline

**Scenario:** Your team needs daily exchange rates loaded into a data warehouse. The source is a public API that returns JSON. Your job is to extract, transform to CSV, and land the file for downstream loading.

**Step 1 — Fetch the raw JSON from the API:**
```bash
curl -s https://open.er-api.com/v6/latest/USD -o raw_rates.json
```

**Step 2 — Inspect the structure to understand the schema:**
```bash
jq 'keys' raw_rates.json
jq '.rates | keys[0:5]' raw_rates.json
```

**Step 3 — Extract specific currency rates and reshape into rows:**
```bash
jq -r '.base_code as $base | .time_last_update_utc as $ts |
  .rates | to_entries[] |
  select(.key == "KES" or .key == "EUR" or .key == "GBP" or .key == "NGN") |
  [$ts, $base, .key, .value] | @csv' raw_rates.json
```

**Step 4 — Add a CSV header and save the final output:**
```bash
echo "timestamp,base_currency,target_currency,rate" > exchange_rates.csv

curl -s https://open.er-api.com/v6/latest/USD | \
  jq -r '.base_code as $base | .time_last_update_utc as $ts |
    .rates | to_entries[] |
    select(.key == "KES" or .key == "EUR" or .key == "GBP" or .key == "NGN") |
    [$ts, $base, .key, .value] | @csv' >> exchange_rates.csv
```

**Step 5 — Verify the result:**
```bash
cat exchange_rates.csv
wc -l exchange_rates.csv
```

**Why this matters for data engineering:**
- This is a real **Extract → Transform → Load** pattern done entirely from the command line.
- `curl` handles the **Extract** (fetching from the API).
- `jq` handles the **Transform** (filtering currencies, reshaping JSON → CSV).
- The redirect `>>` handles the **Load** (landing the file for a warehouse loader like `COPY` or a cron-scheduled ingestion).
