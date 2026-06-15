# Trip Planning System — Restructuring Plan

**Date:** March 31, 2026
**Status:** Draft — awaiting review before implementation

---

## Problem Statement

The current `itinerary-builder` skill conflates four distinct concerns into a single workflow: trip planning guidance, trip data generation (JSON), multi-trip file export (.trip.js), and viewer app building (bundle-shell.html). This creates confusion about what the skill does, makes the "optional" export path (which is actually the primary delivery model) feel secondary, and leaves the RESEARCH and PLAN phases as informal prose with no structured workflow.

---

## Current State — Conflicts and Overlaps

### 1. Two Incompatible Distribution Models in One Skill

The skill contains two scripts that solve the same problem differently:

- `inject-trip-data.sh` — embeds JSON directly into bundle-shell.html, producing a **standalone** HTML file. This is labeled as Step 2 (the primary path).
- `create-trip-file.sh` + `regenerate-loader.sh` — produces `.trip.js` files that `trip-viewer.html` loads dynamically via `trips.js`. This is labeled as Step 3 **(optional)**.

In practice, the dynamic loading path is how we actually use the system. The standalone path is a nice-to-have for sharing a single trip via email. The skill has these backwards.

### 2. SKILL.md Mixes Data Generation with App Building

The itinerary-builder SKILL.md covers:

- Generating `trip-data.json` from a completed plan (data transformation)
- Injecting JSON into bundle-shell.html (viewer assembly)
- Creating `.trip.js` and regenerating `trips.js` (file export)
- A "Build Reference" section documenting how to rebuild the React app from source (infrastructure)

These are four different operations at four different abstraction levels. A user asking "export my trip" shouldn't need to wade through React build instructions.

### 3. No Skill for Trip Planning

`vacation-planning-integration.md` describes three phases — RESEARCH, PLAN, GENERATE — but only GENERATE has a skill. The RESEARCH and PLAN phases are prose guidance buried in a reference doc. There's no structured workflow to move from "I want to visit Maine" to a validated plan with stops, coordinates, costs, and timing.

### 4. Shared Schema Without Shared Access

`trip-data-schema.md` lives inside `itinerary-builder/references/`. Both the planning phase (to know what fields to capture) and the export phase (to validate output) need this schema. Currently only the export skill references it.

### 5. "Optional" Step 3 Is the Primary Path

The three `.trip.js` files in the Vacation Planning folder and the dynamic `trip-viewer.html` prove that Step 3 is how we actually consume trip data. The standalone HTML files are one-off snapshots. The skill should reflect actual usage, not the other way around.

### 6. Build Reference Doesn't Belong in a Content Skill

The "Rebuild App — Rare" section documents `npm run build` → `html-inline` → copy to assets. This is infrastructure maintenance, not trip content generation. It belongs in its own skill that's triggered rarely and explicitly.

---

## Proposed Architecture — Three Skills

```
┌──────────────────────────────────────────────────────────┐
│                  STAGE 1: trip-planner                    │
│                                                          │
│  RESEARCH → PLAN → validate against schema               │
│                                                          │
│  Input:  destination, dates, preferences                 │
│  Output: completed plan (structured markdown)            │
│  Auto:   offers handoff to trip-exporter when done       │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼  (completed plan)
┌──────────────────────────────────────────────────────────┐
│                  STAGE 2: trip-exporter                   │
│                                                          │
│  Plan → trip-data.json → .trip.js + trips.js             │
│                                                          │
│  Input:  completed plan (from Stage 1 or uploaded)       │
│  Output: trip-data.json (always)                         │
│          SLUG-YEAR.trip.js + trips.js (default)          │
│          itinerary-SLUG.html (only on explicit request)  │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼  (files land in Vacation Planning/)
                   trip-viewer.html picks them up automatically

┌──────────────────────────────────────────────────────────┐
│              STAGE 3: viewer-builder (rare)               │
│                                                          │
│  React source → npm build → html-inline → bundle-shell   │
│                                                          │
│  Input:  modified itinerary-app/ source code             │
│  Output: updated assets/bundle-shell.html                │
│  When:   app UI changes, dependency updates, bug fixes   │
└──────────────────────────────────────────────────────────┘

SHARED (read-only interface contract):
  └── trip-data-schema.md
```

---

## Stage 1: trip-planner (NEW)

### Responsibility

Guide the user through RESEARCH and PLAN phases. Produce a validated, structured vacation plan that has all the fields `trip-data-schema.md` requires, ready for direct conversion by trip-exporter.

### Workflow

**RESEARCH phase:**

- Determine destination(s), travel dates, traveler count
- Check auto-memory for persistent preferences (scenic drives over museums, dietary restrictions, lodging constraints like Club Wyndham timeshare eligibility, family heritage context)
- Research attractions, restaurants, scenic routes, lodging options
- Check operating hours, seasonal availability, event calendars
- Identify timing constraints (closed days, reservation requirements)

**PLAN phase:**

- Organize stops into a day-by-day itinerary
- Route-optimize driving between stops
- Balance activity types per user preferences
- Assign day categories (travel, history, nature, driving, mixed, departure)
- Estimate costs across budget/mid/high tiers
- Identify reservation requirements and booking windows
- Generate alignment note (best arrival day and why)

**Validation checkpoint:**

Before handoff, confirm the plan has all schema-required data: every stop has a name, time estimate, emoji, description, approximate coords, and pricing; every day has a category and tip; cost estimates have all three tiers. Present the plan for user review.

**Auto-handoff:**

When the plan is validated and the user is satisfied, offer to run trip-exporter to generate the deliverable files.

### Triggers

- "plan a trip to [destination]"
- "I want to visit [destination]"
- "help me plan a vacation"
- "research [destination]"
- "organize a trip for [dates]"
- "what should we do in [destination]"

### Output

A structured plan document with enough detail for trip-exporter to generate `trip-data.json` without further research. Includes trip name, dates, airports, traveler count, day-by-day stops with all required fields, and cost estimates.

### Dependencies

- `trip-data-schema.md` (read-only, referenced by path for field validation)
- Auto-memory (user preferences, lodging constraints, heritage context)

---

## Stage 2: trip-exporter (RENAMED from itinerary-builder)

### Responsibility

Convert a completed vacation plan into machine-readable trip data and deliver it in the format(s) the user needs. Primary output is `.trip.js` + `trips.js` for dynamic loading into `trip-viewer.html`.

### Workflow

**Step 1: Generate trip-data.json**

- Parse the completed plan into structured JSON conforming to `trip-data-schema.md`
- Assign unique stop IDs in `d{day}-s{stop}` format
- Validate all required fields present
- Refine coordinates (approximate → precise)
- Verify cost math (tier totals match line items)

**Step 2: Create .trip.js (default output)**

- Run `create-trip-file.sh` to wrap JSON in `window.__TRIPS__.push(...)`
- Output: `SLUG-YEAR.trip.js`

**Step 3: Regenerate trips.js loader**

- Run `regenerate-loader.sh` with the new trip file as newest
- Output: `trips.js` with new trip listed first

**Step 4: Create standalone HTML (only on explicit request)**

- Run `inject-trip-data.sh` to embed JSON in bundle-shell.html
- Output: `itinerary-SLUG.html`
- Use case: sharing a single trip via email, offline viewing

**Step 5: Deliver to workspace**

- Copy outputs to Vacation Planning/ folder
- Confirm trip-viewer.html will pick up the new trip automatically

### Triggers

- "export the trip"
- "create the itinerary"
- "generate the trip data"
- "add this trip to my collection"
- "package the trip"
- "I'm done planning, now what?" (also caught by trip-planner handoff)
- "make a standalone file" (triggers Step 4)

### Validation Checklist

- JSON parses without errors
- Every stop has unique ID (`d{day}-s{stop}` format)
- Every stop has coords (lat/lng)
- Every stop has required fields: time, name, mapUrl, placeholderEmoji, description, pricing, status
- Cost estimate has all three tiers with correct totals
- Day categories use valid values (travel, history, nature, driving, mixed, departure)
- `.trip.js` file loads without errors
- `trips.js` references all existing `.trip.js` files plus the new one

### Scripts (unchanged)

| Script | Purpose |
|--------|---------|
| `create-trip-file.sh` | Wraps trip-data.json in `window.__TRIPS__.push()` → `.trip.js` |
| `regenerate-loader.sh` | Scans for all `.trip.js` files → regenerates `trips.js` |
| `inject-trip-data.sh` | Embeds JSON into bundle-shell.html → standalone HTML |

### Dependencies

- `trip-data-schema.md` (read-only, for validation)
- `assets/bundle-shell.html` (read-only, used by inject-trip-data.sh)
- Scripts in `scripts/` directory

---

## Stage 3: viewer-builder (NEW — rare)

### Responsibility

Rebuild `bundle-shell.html` from the itinerary-app React source code. This only runs when the app itself changes — not when trip data changes.

### When to Use

- React component changes (UI layout, new features, map improvements)
- Dependency updates (React, Leaflet, shadcn/ui, Tailwind)
- Print stylesheet modifications
- Bug fixes in the viewer app code
- `loadTripData()` logic changes

### When NOT to Use

- Adding a new trip → use trip-exporter
- Planning a trip → use trip-planner
- Changing trip data → edit the .trip.js file or re-export

### Workflow

```bash
cd itinerary-app
npm install                                    # only if package.json changed
npm run build                                  # Vite → dist/
npx html-inline -i dist/index.html -o bundle.html -b dist/
cp bundle.html <skill-dir>/assets/bundle-shell.html
```

After rebuilding, the new bundle-shell.html is used by trip-exporter for any future standalone HTML generation. Existing `.trip.js` files and `trip-viewer.html` are unaffected unless `trip-viewer.html` itself needs to be regenerated with the new shell (which would be a separate step using the updated bundle-shell + a `<script src="trips.js">` injection).

### Triggers

- "rebuild the viewer"
- "rebuild the app"
- "update bundle-shell.html"
- "I changed the React code"
- "the viewer needs updating"

### Dependencies

- `itinerary-app/` source directory
- Node.js, npm, Vite, html-inline

---

## Shared Schema: trip-data-schema.md

### Location

Single copy at a shared location (e.g., `COMMON/references/trip-data-schema.md` or a top-level references folder). Both `trip-planner` and `trip-exporter` SKILL.md files reference it by path.

### Role

This is the **interface contract** between all three stages. It defines the TripData type structure: days, stops, coordinates, pricing, cost estimates, day categories, and all required/optional fields.

### Change Protocol

When the schema changes:

1. Update the single source file
2. Verify trip-planner guidance still captures all required fields
3. Verify trip-exporter validation still checks all required fields
4. Determine if the viewer app needs updating (viewer-builder concern)
5. Existing trip data remains backward-compatible (new fields should be optional)

---

## File Organization — Target State

```
.claude/skills/
├── shared/
│   └── references/
│       └── trip-data-schema.md          ← single source of truth
│
├── trip-planner/                        ← NEW
│   └── SKILL.md
│       (references shared/references/trip-data-schema.md by path)
│
├── trip-exporter/                       ← RENAMED from itinerary-builder
│   ├── SKILL.md
│   ├── assets/
│   │   └── bundle-shell.html            (unchanged, ~594 KB)
│   ├── scripts/
│   │   ├── create-trip-file.sh          (unchanged)
│   │   ├── regenerate-loader.sh         (unchanged)
│   │   └── inject-trip-data.sh          (unchanged)
│   └── (references shared/references/trip-data-schema.md by path)
│
└── viewer-builder/                      ← NEW
    ├── SKILL.md
    └── scripts/
        └── build-bundle.sh              (wraps npm build + html-inline + copy)
```

### What Moves Where

| Current Location | Action | New Location |
|-----------------|--------|--------------|
| `itinerary-builder/SKILL.md` | Rewrite | `trip-exporter/SKILL.md` |
| `itinerary-builder/references/trip-data-schema.md` | Move | `shared/references/trip-data-schema.md` |
| `itinerary-builder/references/vacation-planning-integration.md` | Absorb into trip-planner SKILL.md, then remove | — |
| `itinerary-builder/scripts/*` | Move | `trip-exporter/scripts/*` |
| `itinerary-builder/assets/bundle-shell.html` | Move | `trip-exporter/assets/bundle-shell.html` |
| Build Reference section in SKILL.md | Extract | `viewer-builder/SKILL.md` |
| — | Create | `trip-planner/SKILL.md` |
| — | Create | `viewer-builder/scripts/build-bundle.sh` |

---

## Trigger Phrase Boundaries

To prevent overlap, each skill claims distinct intent:

| User Says | Matched Skill | Why |
|-----------|--------------|-----|
| "plan a trip to Maine" | trip-planner | No plan exists yet — needs research |
| "I want to visit Galena" | trip-planner | Starting from scratch |
| "export the trip" | trip-exporter | Plan exists, needs file output |
| "add to my trips" | trip-exporter | Plan exists, wants .trip.js |
| "make a standalone file" | trip-exporter | Explicitly wants embedded HTML |
| "rebuild the viewer" | viewer-builder | App code changed |
| "update bundle-shell" | viewer-builder | Infrastructure maintenance |

**Handoff case:** When trip-planner completes and validates a plan, it auto-offers: "Your plan is ready. Want me to export it to your trip collection?" This triggers trip-exporter.

---

## Design Principles

**Single Responsibility.** Each skill does exactly one thing. trip-planner doesn't know about .trip.js files. trip-exporter doesn't research attractions. viewer-builder doesn't touch trip data.

**Schema as Contract.** `trip-data-schema.md` is the interface between stages. Skills depend on the schema, not on each other.

**Default Path is Dynamic Loading.** `.trip.js` + `trips.js` is the primary output. Standalone HTML is opt-in. The user drops a file in a folder and it works.

**Backward Compatible.** Existing trip files (galena-2026, bar-harbor-2026, boston-plymouth-2027) continue working. No re-export required.

---

## Implementation Sequence

### Phase 1: Foundation

1. Create `shared/references/` directory
2. Move `trip-data-schema.md` to shared location
3. Rename `itinerary-builder/` → `trip-exporter/`
4. Rewrite `trip-exporter/SKILL.md` (remove Build Reference, flip primary/optional paths)
5. Update script paths if needed

### Phase 2: New Skills

6. Write `trip-planner/SKILL.md` (absorb vacation-planning-integration.md content, add structured workflow, schema awareness, auto-memory integration)
7. Write `viewer-builder/SKILL.md` (extract Build Reference, add build-bundle.sh wrapper)

### Phase 3: Validation

8. Test trip-planner triggers don't collide with trip-exporter triggers
9. Verify trip-exporter produces correct .trip.js + trips.js output
10. Verify standalone HTML still works when explicitly requested
11. Confirm trip-viewer.html loads new trips without rebuild
12. Package all three as .skill files for Cowork installation

---

## Open Questions

None currently — all decision points resolved:

- **Handoff:** Auto-offer from trip-planner → trip-exporter ✓
- **Schema sharing:** Single location, referenced by path ✓
- **Default output:** .trip.js only; standalone on explicit request ✓
