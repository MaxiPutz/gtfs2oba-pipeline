## GTFS2OBA Pipeline

A Docker‑based workflow to **validate**, **clean**, and **transform** GTFS feeds for use with OpenTripPlanner (OTP). This README walks you through three stages:


1. **Validation & Checking** with `runCheck.sh`
2. **Generating Transformations** via `docker-compose up pipFile`
3. **Cleanup & Tidy** with `runTidy.sh`

### Project Layout

```
gtfs2oba-pipeline/
├── docker-compose.yml
├── runCheck.sh      # Validates & checks GTFS
├── runTidy.sh       # Applies transformations and cleans feed
├── config.json      # Transformation config for gtfs2oba-pipeline
└── share/           # Mounted folder for input & outputs
    └── (files appear here)
```

---

## 0. Build the image: `sudo docker-compose up build --build`

## 1. Validation & Checking: `runCheck.sh`

Use this script to validate your raw GTFS and generate a `report.json` of issues.

```bash
bash runCheck.sh path/to/your-feed.zip
```

- **Copies** your ZIP to `share/in.gtfs.zip`
- **Runs** the GTFS Validator CLI (service `valid`) 
- **Runs** the OneBusAway checks (service `check`)
- **Outputs** `share/report.json`

**Example output snippet:**

```plain
▶ Running GTFS validation...
Attaching to valid-1
... validator table ...
▶ Running GTFS checks...
+----------+---------+----------------------------------------------------------------+
| SEVERITY | ENTRIES | CODE                                                           |
+----------+---------+----------------------------------------------------------------+
| ERROR    |    374  | missing_trip_edge                                              |
| WARNING  |     26  | fast_travel_between_consecutive_stops                          |
... more rows ...
+----------+---------+----------------------------------------------------------------+
```
Here, `missing_trip_edge` (374 occurrences) flags a data gap that will break OTP’s routing graph.

---

## 2. Generating Transformations: `docker-compose up pipFile`

After identifying the target issue (e.g. `missing_trip_edge`), edit **`config.json`** to specify what to remove. A minimal example:

```json
{
  "code": "missing_trip_edge",
  "SNProp": "tripId",
  "SNValFilter": "",
  "template": {
    "op": "remove",
    "match": {"file": "trips.txt", "trip_id": "%s"}
  },
  "inFile": "./share/report.json",
  "outFile": "./share/modifications.txt"
}
```

- **`code`**: the error code from `report.json`
- **`SNProp`**: property name in each error entry (e.g. `tripId`)
- **`SNValFilter`**: optional substring filter
- **`template`**: JSON template for operations
- **`inFile`**, **`outFile`**: fixed paths inside the container

Run:

```bash
docker-compose up pipFile
```

This generates `share/modifications.txt`, for example:

```json
{"op":"remove","match":{"file":"trips.txt","trip_id":"7.T3.22-5-j25-3.3.H"}}
... more operations ...
```

---

## 3. Cleanup & Tidy: `runTidy.sh`

With `in.gtfs.zip`, `report.json`, **and** `modifications.txt` in `share/`, run:

```bash
bash runTidy.sh
```

The script will:

1. **Verify** `share/in.gtfs.zip`, `share/report.json`, and `share/modifications.txt` exist
2. **Start** the `pipFile` service to apply removals
3. **Start** the `tidy` service to produce a cleaned GTFS
4. **Output** `share/tidy.gtfs.zip`

**Final message example:**

```plain
✅ Pipeline completed successfully.
Tidy GTFS file is available at: /path/to/project/share/tidy.gtfs.zip
```

---

## Customization & Contribution

- To target a different issue, adjust **`code`**, **`SNProp`**, and **`SNValFilter`** in `config.json`.
- If your transform logic changes the structure of output objects, update code under `/obj/` accordingly.
- Contributions are welcome! Please fork, implement enhancements, and open a Pull Request.

---

*Enjoy cleaner GTFS feeds in your OTP deployments!*
