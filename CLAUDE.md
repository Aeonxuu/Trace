# Trace

iOS barcode scanner. The user saves ingredients they avoid. They scan a
product barcode. The app returns one of three verdicts.

## Rules

- SwiftUI only. No third-party UI packages.
- iOS 16 minimum. Swift concurrency (async/await), never completion handlers.
- Every field decoded from Open Food Facts is Optional. No exceptions.
- Never let missing data produce a "clear" verdict. Missing data is its
  own verdict: unknown.
- Persistence goes behind a protocol so the implementation can be swapped
  later. Do not scatter storage calls through views.
- No Firebase yet. It comes after this phase.

## API

GET https://world.openfoodfacts.org/api/v2/product/{barcode}.json

- Success is determined by the `status` field in the response body, not
  by the HTTP status code. A missing product returns HTTP 200 with
  "status": 0.
- Send a User-Agent header: "Trace/1.0 (iOS; student project)"
- On a miss, retry once with a leading zero stripped from the barcode.
  iOS reports UPC-A as 13 digits with a leading zero.
- Read energy from `energy-kcal_100g`. The plain `energy` field is
  kilojoules.
- Ingredient text: try `ingredients_text_en`, then `ingredients_text`,
  then treat as missing.

## Verdict logic

Check in order, stop at first match against the user's saved tag IDs:

1. allergens_tags
2. traces_tags and traces_from_ingredients (only when severity is severe
   or the trace toggle is on)
3. ingredients_tags
4. ingredients_analysis_tags
5. additives_tags

Return `unknown` when allergens_tags, ingredients_tags, and the
ingredient text are all empty or missing.

## Design tokens

ink #101A2E, paper #F7F8FA, surface #FFFFFF, muted #6B7689
contains #C81E3A, clear #0E7C5A, unknown #E5952B

Verdict colors appear only on verdicts. Never on buttons or other UI.

Radius 14 on cards and buttons, 24 on sheets. Side margins 20.

## Build command

xcodebuild -scheme Trace -destination 'platform=iOS Simulator,name=iPhone 17' build
