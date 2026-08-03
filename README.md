# FloodFax AI

**Property flood and environmental risk reports, built from public geospatial data.**

A buyer can see a listing's photographs, price and location. They cannot see that the plot sits
three metres below the road, that the tank behind it overtops most Novembers, or that heavy-rain
days there have been climbing for twenty years. FloodFax reads the ground and writes it down.

---

## What it does

Give it an address, a coordinate pair, a Google Maps link or a click on the map. It returns a
sourced report:

- **Flood risk** — a weighted composite of terrain position, slope, water proximity, rainfall
  extremes, sealed-surface share and (where configured) observed satellite water.
- **Twelve further factors** — water logging, drainage quality, elevation standing, slope,
  nearby water bodies, rainfall exposure, climate trend, infrastructure, wet-weather road access,
  environmental quality, insurance risk and an overall investment standing.
- **Reasoning for every score**, the evidence behind it, its confidence, and the dataset it came
  from.
- **A PDF** laid out like a credit report, with the terrain cross-section, rainfall history,
  satellite timeline, recommendations and a QR link back to the live report.

### Two rules the codebase holds to

1. **A score is only produced from data actually held.** If a provider fails or is not configured,
   the affected signal is reported as `unavailable`, dropped from the weighted average, and named
   in the report. It is never replaced with a neutral 50, because a neutral 50 is indistinguishable
   from a measurement to the person reading it.
2. **The model explains; it does not score.** Scoring is a deterministic pure function over the
   measured inputs — the same property returns the same numbers every time. The language model
   receives those numbers plus the evidence and writes the prose. Without an API key a rule-based
   composer writes the same sections from the same evidence.

---

## Quick start

Requires Python 3.11+ and Node 20+. No API keys are needed to run it — every required data source
is public and unauthenticated.

**One command, one port.** This builds the web app to static files and serves the whole product —
UI, API, and PDF reports — from a single FastAPI process:

```bash
./run.sh
# everything on http://localhost:8000   (API docs at /docs)
```

`./run.sh --rebuild` forces a fresh frontend build; `PORT=9000 ./run.sh` serves elsewhere.

### How it fits together

The frontend is a Next.js **static export** (`output: "export"` → `frontend/out`). The backend
serves that export from the same origin, so the browser talks to `/api/...` with no CORS and no
second server. The React app fetches every report client-side, so `/property/<id>/` resolves against
one exported HTML shell that reads the id from the URL.

### Docker — single image

```bash
cp backend/.env.example backend/.env
docker compose up --build         # http://localhost:8000, Postgres included
```

The `Dockerfile` is multi-stage: Node builds the export, then a slim Python image serves it. One
container, one port.

### Running the two halves separately (optional)

For frontend hot-reload during UI work you can still run them apart: `uvicorn app.main:app --reload`
for the API, and `npm run dev` in `frontend/` with `NEXT_PUBLIC_API_URL=http://localhost:8000` set so
the dev server points at the API. The single-port setup above is the default and the one to ship.

---

## Architecture

```
┌──────────────┐   query    ┌────────────────────────────────────────┐
│ Next.js 15   │───────────▶│ FastAPI                                │
│ App Router   │            │                                        │
│ React Query  │◀───────────│  geocoding ─┐                          │
│ MapLibre GL  │   report   │             ▼                          │
│ Recharts     │            │  ┌── terrain (Copernicus DEM)          │
└──────────────┘            │  ├── hydrology (OSM Overpass)          │
                            │  ├── built env (OSM Overpass)  ─┐      │
                            │  ├── rainfall (ERA5/Open-Meteo)  │ async│
                            │  └── satellite (Sentinel-2/GEE) ─┘      │
                            │             ▼                          │
                            │       scoring engine (pure)            │
                            │             ▼                          │
                            │   narrative (OpenAI │ deterministic)   │
                            │             ▼                          │
                            │   store (Postgres │ JSON files)        │
                            │             ▼                          │
                            │   PDF renderer (ReportLab)             │
                            └────────────────────────────────────────┘
```

The five feature extractors run concurrently and fail independently: a dead Overpass mirror
degrades one signal, not the report.

### Layout

```
backend/
  app/
    core/         config, schemas, errors, geodesy, logging
    clients/      shared HTTP with retries and a TTL cache
    services/     geocoding, terrain, osm, rainfall, satellite,
                  scoring, recommendations, narrative, report_pdf, pipeline
    store/        file and Postgres repositories behind one protocol
    api/          routers
  tests/          scoring fixtures and input parsing
frontend/
  app/            landing, features, analyze, property/[id], pricing, api, about, settings
  components/     ui primitives, map canvas, waterline, report views
  lib/            typed API client, shared types, formatters
infra/            PostGIS schema
```

---

## Data sources

| Signal | Dataset | Provider | Licence |
| --- | --- | --- | --- |
| Elevation, slope, drainage direction | Copernicus DEM GLO-30 | OpenTopoData | Free, attribution required |
| Rivers, tanks, wetlands, drains, buildings, roads | OpenStreetMap | Overpass API | ODbL 1.0 |
| Daily rainfall, 30 years | ERA5 reanalysis | Open-Meteo Archive | CC BY 4.0 |
| Surface water history *(optional)* | Sentinel-2 L2A, MNDWI | Google Earth Engine | Copernicus, attribution required |
| Place resolution | Nominatim | OpenStreetMap | ODbL 1.0 |

The public mirrors for OpenTopoData, Overpass and Nominatim are shared community infrastructure.
The client paces elevation batches to one request per second and caches identical requests for
twelve hours. For anything beyond development traffic, point `OPENTOPODATA_URL`, `OVERPASS_URL`
and `NOMINATIM_URL` at your own instances.

---

## Configuration

Everything optional degrades honestly rather than breaking.

| Variable | Default | Effect if unset |
| --- | --- | --- |
| `DATABASE_URL` | — | Reports persist as JSON files under `DATA_DIR` |
| `OPENAI_API_KEY` | — | The deterministic composer writes the narrative |
| `OPENAI_MODEL` | `gpt-5.1` | Set to a reasoning model your account can call |
| `GEE_SERVICE_ACCOUNT`, `GEE_PRIVATE_KEY_JSON` | — | No satellite timeline; the report says so and confidence drops |
| `NEXT_PUBLIC_MAPBOX_TOKEN` | — | Satellite basemap control is hidden; OSM raster basemap is used |
| `DEM_GRID_SIZE`, `DEM_RADIUS_METERS` | `11`, `750` | Elevation sampling density and window |
| `RAINFALL_YEARS` | `30` | Length of the rainfall record analysed |

`/api/health` reports which integrations are live, and the Settings page renders it.

---

## Testing

```bash
cd backend && python -m pytest tests -q
```

The suite scores two fixtures — a low-lying, heavily sealed, high-rainfall sink and a well-drained
hillside — and asserts that the engine separates them, that every metric carries reasoning and a
direction, that missing sources reduce confidence, and that recommendations are triggered by
measurements rather than emitted unconditionally. It also covers coordinate and Google Maps URL
parsing.

---

## Design notes

The interface is a document, not a dashboard skin. One institutional superfamily in three roles
(serif for report headings, sans for the interface, mono for every measured value), a cartographic
palette that would print legibly on a survey sheet, and one memorable element: the **waterline** —
the parcel's real elevation cross-section, cut along the direction water runs, with the waterline
raised to the assessed risk. A dial gives you the number; the cross-section shows the shape of the
ground the number came from.

---

## Limits

This is desk diligence, not a survey. Elevation resolves to roughly 30 m, so it can tell you a
neighbourhood is a basin but not that your plot was raised half a metre by fill. It does not check
title, structure, approvals or plot-level grading, it has no municipal flood records or resident
reports wired in, and it is not an insurance quotation. Every report states these limits on the
same page as its findings.
