# Vacation Planning — Project Instructions

This project manages a collection of planned vacation trips and an interactive
trip viewer app. Work here follows a three-stage pipeline with dedicated skills
for each stage.

## The Three Stages

### Stage 1 — Plan the trip (`trip-planner` skill)

Research destinations, organize a day-by-day itinerary, estimate costs, and
produce a validated plan. The skill guides the RESEARCH and PLAN phases and
checks the result against the TripData schema before handing off.

**Trigger when:** the user mentions a destination, asks "what should we do in
[place]", wants to plan or research a trip, or hasn't yet produced a completed
plan for a destination.

### Stage 2 — Export the trip (`trip-exporter` skill)

Convert a completed plan into `trip-data.json`, then produce a `.trip.js` file
and regenerate `trips.js` so `trip-viewer.html` picks up the new trip
automatically. No viewer rebuild needed.

**Trigger when:** a plan is ready and the user says "export", "add to my trips",
"create the itinerary", or when `trip-planner` finishes and offers to hand off.

**Default output:** `.trip.js` + `trips.js` (dynamic loading). Standalone HTML
(`itinerary-SLUG.html`) is only produced when explicitly requested.

### Stage 3 — Rebuild the viewer (`viewer-builder` skill)

Rebuild `bundle-shell.html` from the `itinerary-app/` React source. This is
rare infrastructure work — only needed when the viewer UI, dependencies, or
data loading logic change.

**Trigger when:** the user says "rebuild the viewer", "update bundle-shell",
or mentions changing the React app source code. Never trigger just to add a trip.

## Shared Schema

All three skills reference `trip-data-schema.md` in the `shared/references/`
skill directory. This is the interface contract — it defines TripData types,
required fields, valid enum values, and example JSON. When the schema changes,
all three skills must stay in sync.

## How Trip Data Flows

```
trip-planner          trip-exporter              trip-viewer.html
 (plan)         →      (export)           →      (display)
                   trip-data.json
                   SLUG-YEAR.trip.js  ──→  trips.js loads .trip.js files
                   trips.js (regenerated)   window.__TRIPS__ populated
                                            React app reads & renders
```

Adding a trip never requires rebuilding trip-viewer.html. The viewer loads
trips dynamically via `<script src="trips.js">`.

## File Layout

```
Vacation Planning/
├── trip-viewer.html              ← app shell, loads trips.js dynamically
├── trips.js                      ← auto-generated loader (lists all .trip.js)
├── boston-plymouth-2027.trip.js   ← trip data files
├── bar-harbor-2026.trip.js
├── galena-2026.trip.js
└── CLAUDE.md                     ← this file
```

## User Preferences

Check auto-memory before planning. Key preferences:

- Direct descendant of Edward Doty Sr. (Mayflower, 1598–1655) — heritage sites
  are meaningful, especially Plymouth and related locations
- Wife loves scenic drives; not as keen on museums and battlefields — balance
  itineraries to include both interests
- Wife doesn't like lobster or clam chowder — avoid recommending these as dining
  highlights; suggest alternatives
- Lodging: verify Club Wyndham timeshare resort (points-eligible) vs.
  Wyndham-branded hotel — these are different things

## Quick Reference

| I want to...                        | Use                |
|-------------------------------------|--------------------|
| Plan a new trip                     | `trip-planner`     |
| Export a finished plan              | `trip-exporter`    |
| Make a standalone HTML to email     | `trip-exporter` (ask for standalone) |
| Fix a bug in the viewer app         | `viewer-builder`   |
| Add a feature to the viewer app     | `viewer-builder`   |
| Change data in an existing trip     | Edit the `.trip.js` file directly |
