---
name: itinerary-builder
description: >
  Generates an interactive single-file HTML itinerary viewer from a structured
  vacation plan. Converts a planned trip (days, stops, costs, logistics) into a
  trip-data.json file conforming to the TripData schema, then packages it into a
  self-contained HTML file with an embedded React app featuring day-by-day cards,
  interactive map, cost tracking, Google Maps route links, and print support.

  Use this skill whenever the conversation involves vacation itineraries, trip
  planning output, or turning a travel plan into something viewable or shareable.
  Trigger on: "generate itinerary", "build itinerary", "create itinerary viewer",
  "package the trip", "create the HTML", "build the trip app", "make the
  itinerary", or any reference to the GENERATE phase of vacation planning. Also
  trigger when the user has finished planning a trip and asks what's next, says
  "here's the plan, make it interactive", wants to share or print a trip plan,
  or asks to update an existing itinerary viewer with new trip data.
---

# Itinerary Builder Skill

## Purpose

Converts a structured vacation plan into two deliverables:

1. **trip-data.json** — machine-readable trip data conforming to the TripData schema
2. **Single-file HTML** — a self-contained interactive itinerary viewer with the
   trip data embedded (opens in any browser, no server needed)

The HTML viewer is a pre-built React application bundled into `bundle-shell.html`.
This skill does NOT rebuild the app — it generates the JSON data and injects it
into the existing shell using the build scripts.

---

## Prerequisites

Before running this skill, you need:

1. **A completed vacation plan** — either in the conversation context or as an
   uploaded document. The plan must include: trip name, dates, traveler count,
   airports, day-by-day itinerary with stops, and cost estimates.

2. **This skill's bundled assets and scripts** — located relative to this
   SKILL.md file:
   - `assets/bundle-shell.html` — the pre-built app shell (~590 KB)
   - `scripts/inject-trip-data.sh` — the injection script
   - `scripts/create-trip-file.sh` — multi-trip file creator
   - `scripts/regenerate-loader.sh` — trip loader generator

   These ship with the skill. If `bundle-shell.html` is missing or the app
   code has been modified, it must be rebuilt (see Build Reference below).

---

## Workflow

### Step 1 — Generate trip-data.json

Convert the vacation plan into JSON conforming to the **TripData schema**
(see `references/trip-data-schema.md` for the complete type definitions and
field-by-field guidance).

Key rules:

- **Every stop needs an `id`** in the format `d{dayNumber}-s{stopIndex}` (e.g., `d0-s1`, `d2-s3`)
- **Every stop needs `coords`** (lat/lng) for the map and Google Maps route links.
  Look up coordinates for each location. This is critical — stops without coords
  won't appear on the map or in route URLs.
- **`placeholderEmoji`** is required for every stop — pick a contextually relevant
  emoji (✈️ airport, 🏨 hotel, 🍽️ restaurant, 🏛️ museum, 🌊 beach, etc.)
- **`mapUrl`** should be a Google Maps search URL for the location
- **Cost estimates** need all three tiers: `budget`, `mid`, `high`
- **`alignmentNote`** is optional but valuable for explaining timing constraints
  (e.g., "museums closed Mondays", "festival only runs Oct 15–18")
- **Day categories** must be one of: `travel`, `history`, `nature`, `driving`,
  `mixed`, `departure`
- **Stop status** should be `planned` for new trips

Validate the JSON:
```bash
node -e "const d = JSON.parse(require('fs').readFileSync('trip-data.json','utf8')); console.log('Valid:', d.name, '-', d.days.length, 'days,', d.days.reduce((s,d)=>s+d.stops.length,0), 'stops')"
```

### Step 2 — Build single-file HTML

Use the injection script bundled with this skill to embed the trip data into
the app shell. The `SKILL_DIR` variable should point to this skill's directory:

```bash
SKILL_DIR="<path-to-this-skill>"
bash "$SKILL_DIR/scripts/inject-trip-data.sh" trip-data.json itinerary-SLUG.html
```

Where `SLUG` is a short identifier for the trip (e.g., `galena`, `san-antonio`).
The script automatically finds `assets/bundle-shell.html` relative to itself.

### Step 3 — Create multi-trip file (optional)

If adding to an existing multi-trip viewer, also create a `.trip.js` file:

```bash
bash "$SKILL_DIR/scripts/create-trip-file.sh" trip-data.json SLUG-YEAR OUTPUT_DIR
bash "$SKILL_DIR/scripts/regenerate-loader.sh" OUTPUT_DIR SLUG-YEAR.trip.js
```

### Step 4 — Deliver to user

Copy the final HTML file(s) and trip-data.json to the output directory:

```
Vacation Planning/itinerary-SLUG.html    — standalone single-file viewer
Vacation Planning/trip-data.json         — raw data (for future edits)
Vacation Planning/SLUG-YEAR.trip.js      — multi-trip file (if applicable)
Vacation Planning/trips.js               — updated loader (if applicable)
```

---

## Output Checklist

Before delivering, verify:

- [ ] JSON parses without errors
- [ ] Every stop has `coords` (lat/lng)
- [ ] Every stop has a unique `id`
- [ ] Cost estimate has all three tiers with a `totals` object
- [ ] HTML file opens in a browser and renders correctly
- [ ] Day count matches the plan
- [ ] Stop count matches the plan
- [ ] Cost totals are mathematically correct (sum of category items = totals)

---

## Schema Reference

See `references/trip-data-schema.md` for the complete TypeScript type definitions,
field descriptions, and example data for each type.

---

## Build Reference (Rebuild App — Rare)

If the bundle-shell.html is missing or the app code has been modified:

```bash
cd itinerary-app
npm install
npm run build          # Vite build → dist/
npx html-inline -i dist/index.html -o bundle.html -b dist/
cp bundle.html bundle-shell.html
```

The app uses: React 19, TypeScript, Vite 8, Tailwind CSS 3.4, shadcn/ui,
Radix UI, Leaflet (maps), and includes a print fix that disables Tailwind
during print and substitutes a standalone print stylesheet.
