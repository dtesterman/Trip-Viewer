# TripData Schema Reference

Complete TypeScript type definitions for the itinerary viewer data format.
When generating trip-data.json, every field marked **required** must be present.

---

## Top-Level: TripData

| Field           | Type           | Required | Description |
|-----------------|----------------|----------|-------------|
| `name`          | `string`       | Yes      | Display name for the trip (e.g., "Northwest Illinois Road Trip") |
| `dates.start`   | `string`       | Yes      | ISO date string, start date (e.g., "2026-10-15") |
| `dates.end`     | `string`       | Yes      | ISO date string, end date |
| `travelers`     | `number`       | Yes      | Number of people on the trip |
| `airports.flyIn`| `string`       | Yes      | IATA code for arrival airport (e.g., "ORD") |
| `airports.flyOut`| `string`      | Yes      | IATA code for departure airport |
| `days`          | `Day[]`        | Yes      | Array of day objects, one per day |
| `costEstimate`  | `CostEstimate` | Yes      | Full cost breakdown with three tiers |
| `alignmentNote` | `string`       | No       | Timing advisory (e.g., "Best travel dates: Arrive Thursday so museums are open on weekdays") |

```typescript
interface TripData {
  name: string;
  dates: { start: string; end: string };
  travelers: number;
  airports: { flyIn: string; flyOut: string };
  days: Day[];
  costEstimate: CostEstimate;
  alignmentNote?: string;
}
```

---

## Day

| Field         | Type          | Required | Description |
|---------------|---------------|----------|-------------|
| `dayNumber`   | `number`      | Yes      | 0-indexed day number (Day 0 = arrival day) |
| `title`       | `string`      | Yes      | Short title (e.g., "Arrival & Galena First Look") |
| `subtitle`    | `string`      | Yes      | Date display (e.g., "Thursday, Oct 15") |
| `category`    | `DayCategory` | Yes      | One of: `travel`, `history`, `nature`, `driving`, `mixed`, `departure` |
| `stops`       | `Stop[]`      | Yes      | Ordered array of stops for this day |
| `tip`         | `string`      | Yes      | Day-specific travel tip shown at bottom of day card |
| `drivingTime` | `string`      | No       | Total driving time (e.g., "2h 45m") |
| `drivingMiles`| `string`      | No       | Total driving distance (e.g., "165 mi") |

```typescript
type DayCategory = "travel" | "history" | "nature" | "driving" | "mixed" | "departure";

interface Day {
  dayNumber: number;
  title: string;
  subtitle: string;
  category: DayCategory;
  stops: Stop[];
  tip: string;
  drivingTime?: string;
  drivingMiles?: string;
}
```

**Category guidance:**
- `travel` — arrival/departure day with significant transit
- `history` — primarily historical sites, museums, battlefields
- `nature` — parks, gardens, scenic areas, outdoor activities
- `driving` — scenic route day where driving IS the activity
- `mixed` — combination of multiple categories
- `departure` — final day heading home

---

## Stop

| Field             | Type           | Required | Description |
|-------------------|----------------|----------|-------------|
| `id`              | `string`       | Yes      | Unique ID in format `d{dayNum}-s{stopIdx}` (e.g., `d0-s1`) |
| `time`            | `string`       | Yes      | Planned time (e.g., "11:30 AM", "~2:00 PM") |
| `name`            | `string`       | Yes      | Place name |
| `mapUrl`          | `string`       | Yes      | Google Maps URL for the location |
| `placeholderEmoji`| `string`       | Yes      | Emoji shown as thumbnail placeholder |
| `description`     | `string`       | Yes      | 1-3 sentences describing the stop, what to expect |
| `pricing`         | `StopPricing`  | Yes      | Cost info for this stop |
| `status`          | `StopStatus`   | Yes      | One of: `planned`, `visited`, `skipped` |
| `coords`          | `Coords`       | **Strongly recommended** | Lat/lng for map and route links |
| `photoUrl`        | `string`       | No       | URL to a photo (rarely used — emoji is the default) |
| `hours`           | `string`       | No       | Operating hours (e.g., "9 AM – 5 PM, closed Mon") |
| `accessibility`   | `string`       | No       | Accessibility info |
| `reservation`     | `string`       | No       | Reservation status (e.g., "Recommended", "Required", "Booked") |
| `lodging`         | `StopLodging`  | No       | Present only for lodging stops |

```typescript
interface Stop {
  id: string;
  time: string;
  name: string;
  mapUrl: string;
  photoUrl?: string;
  placeholderEmoji: string;
  description: string;
  hours?: string;
  accessibility?: string;
  reservation?: string;
  pricing: StopPricing;
  lodging?: StopLodging;
  coords?: Coords;
  status: StopStatus;
}

interface Coords {
  lat: number;
  lng: number;
}

type StopStatus = "planned" | "visited" | "skipped";
```

### StopPricing

| Field    | Type        | Required | Description |
|----------|-------------|----------|-------------|
| `amount` | `string`    | Yes      | Display price (e.g., "$45–$65/pp", "$0", "$0 (timeshare)") |
| `type`   | `PriceType` | Yes      | One of: `confirmed`, `estimated`, `free`, `optional` |

```typescript
interface StopPricing {
  amount: string;
  type: PriceType;
}
type PriceType = "confirmed" | "estimated" | "free" | "optional";
```

### StopLodging

| Field  | Type         | Required | Description |
|--------|--------------|----------|-------------|
| `type` | `LodgingType`| Yes      | `primary` = base camp, `away` = overnight elsewhere |
| `name` | `string`     | Yes      | Property name |

```typescript
interface StopLodging {
  type: LodgingType;
  name: string;
}
type LodgingType = "primary" | "away";
```

---

## CostEstimate

| Field        | Type             | Required | Description |
|--------------|------------------|----------|-------------|
| `categories` | `CostCategory[]` | Yes      | Grouped line items (Flights, Lodging, Food, etc.) |
| `totals`     | `{budget, mid, high}` | Yes | Sum of all items across all three tiers |
| `tips`       | `string[]`       | Yes      | Cost-saving tips |

```typescript
interface CostEstimate {
  categories: CostCategory[];
  totals: { budget: number; mid: number; high: number };
  tips: string[];
}
```

### CostCategory

| Field   | Type             | Required | Description |
|---------|------------------|----------|-------------|
| `emoji` | `string`         | Yes      | Category icon (✈️, 🏨, 🍽️, 🚗, 🎟️, etc.) |
| `name`  | `string`         | Yes      | Category name (e.g., "Flights", "Dining") |
| `items` | `CostLineItem[]` | Yes      | Line items in this category |

### CostLineItem

| Field       | Type                       | Required | Description |
|-------------|----------------------------|----------|-------------|
| `item`      | `string`                   | Yes      | What the cost is for |
| `detail`    | `string`                   | Yes      | Provider or specifics |
| `cost`      | `{budget, mid, high}`      | Yes      | Dollar amounts (numbers, not strings) |
| `priceType` | `"confirmed" \| "estimated"` | Yes    | Whether price is locked or estimated |
| `note`      | `string`                   | No       | Additional context |

```typescript
interface CostLineItem {
  item: string;
  detail: string;
  cost: { budget: number; mid: number; high: number };
  priceType: "confirmed" | "estimated";
  note?: string;
}
```

---

## Common Emoji Reference

| Context       | Emoji |
|---------------|-------|
| Airport       | ✈️    |
| Rental car    | 🚗    |
| Driving       | 🚗    |
| Hotel/lodging | 🏨    |
| Restaurant    | 🍽️    |
| Museum        | 🏛️    |
| Historic site | 🏛️    |
| Park/nature   | 🌳    |
| Beach/water   | 🌊    |
| Shopping      | 🛍️    |
| Walking tour  | 🗺️    |
| Church        | ⛪    |
| Scenic view   | 🏔️    |
| Garden        | 🌺    |
| Train/rail    | 🚂    |
| Coffee/café   | ☕    |
| Bar/brewery   | 🍺    |
| Entertainment | 🎭    |
| Departure     | 🏠    |

---

## Example: Minimal Valid Stop

```json
{
  "id": "d0-s1",
  "time": "11:30 AM",
  "name": "Arrive at O'Hare (ORD)",
  "mapUrl": "https://maps.google.com/maps/search/Chicago+O'Hare+International+Airport",
  "placeholderEmoji": "✈️",
  "description": "Arrive at Terminal 1 or 2 depending on carrier. Rental car counters are in the Multi-Modal Facility.",
  "pricing": { "amount": "$0", "type": "free" },
  "coords": { "lat": 41.9742, "lng": -87.9073 },
  "status": "planned"
}
```

## Example: Lodging Stop

```json
{
  "id": "d0-s4",
  "time": "3:15 PM",
  "name": "Check in at Club Wyndham Galena",
  "mapUrl": "https://maps.google.com/maps/search/Club+Wyndham+Galena+IL",
  "placeholderEmoji": "🏨",
  "description": "Resort is east of town. Check-in at 4 PM. Timeshare points property — no nightly cost.",
  "pricing": { "amount": "$0 (timeshare)", "type": "confirmed" },
  "lodging": { "type": "primary", "name": "Club Wyndham Galena" },
  "coords": { "lat": 42.3692, "lng": -90.3701 },
  "status": "planned"
}
```

## Example: CostEstimate

```json
{
  "categories": [
    {
      "emoji": "✈️",
      "name": "Flights",
      "items": [
        {
          "item": "Round-trip DFW ↔ ORD (2 people)",
          "detail": "American, United, or Southwest",
          "cost": { "budget": 350, "mid": 500, "high": 650 },
          "priceType": "estimated"
        }
      ]
    },
    {
      "emoji": "🍽️",
      "name": "Dining",
      "items": [
        {
          "item": "Dinners (5 nights × 2 people)",
          "detail": "Mix of casual and fine dining",
          "cost": { "budget": 250, "mid": 400, "high": 600 },
          "priceType": "estimated"
        }
      ]
    }
  ],
  "totals": { "budget": 600, "mid": 900, "high": 1250 },
  "tips": [
    "Book flights 6–8 weeks out for best fares.",
    "Timeshare saves $600–$800 vs hotel stays."
  ]
}
```
