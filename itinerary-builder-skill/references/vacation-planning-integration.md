# Vacation Planning Integration

## How This Skill Fits the Workflow

The vacation planning process has three phases:

### RESEARCH Phase
- Identify destination, dates, traveler preferences
- Research lodging options
- Survey attractions, restaurants, scenic routes
- Check operating hours, seasonal availability, event calendars

### PLAN Phase
- Organize stops into a day-by-day itinerary
- Route-optimize driving between stops
- Balance activity types (history, nature, driving, dining)
- Estimate costs across budget/mid/high tiers
- Incorporate traveler preferences
- Identify timing constraints (closed days, reservation requirements)

### GENERATE Phase ← This Skill
- Convert the completed plan into `trip-data.json` (TripData schema)
- Inject into the pre-built HTML shell → single-file interactive viewer
- Optionally create `.trip.js` for multi-trip viewer
- Deliver to user's output folder

## Important Context

Before generating, check the user's auto-memory for any persistent travel
preferences (lodging constraints, dietary restrictions, activity preferences,
family history relevant to destinations). These should inform the content of
stop descriptions and cost estimates but are not hardcoded here — they live
in memory so they stay current.

## Output Directory

All deliverables go to the user's workspace folder:
- `itinerary-SLUG.html` — standalone viewer
- `trip-data.json` — raw data
- `SLUG-YEAR.trip.js` — multi-trip file
- `trips.js` — updated loader
- `itinerary-viewer.html` — generic multi-trip shell (if already present)
