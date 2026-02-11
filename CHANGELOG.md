# Changelog

## 0.2.1 (2026-02-11)

### Fixed

- `training_readiness` raising `TypeError: no implicit conversion of String into Integer` when Garmin returns a response with a UTF-8 BOM or unparseable JSON body
- `display_name` and `full_name` returning `nil` on login when the profile endpoint nests data under `socialProfile` or uses `userName` instead of `displayName`

### Added

- `ParseError` exception class — raised when a response claims `application/json` content-type but the body can't be parsed (instead of silently returning a raw string)
- UTF-8 BOM stripping in response parsing
- Fallback profile extraction: tries `displayName` → `socialProfile.displayName` → `userName`

### Improved

- Test coverage increased to 205 examples (up from 199)

## 0.2.0 (2026-02-11)

### Added

- `add_body_composition` - upload body scale data (body fat %, muscle mass, etc.) as a FIT file
- `add_weigh_in_with_timestamps` - add a weigh-in with explicit local and GMT timestamps
- `delete_weigh_ins` - batch delete all weigh-ins for a given date
- Typed workout creation helpers:
  - `create_running_workout`
  - `create_cycling_workout`
  - `create_swimming_workout`
  - `create_walking_workout`
  - `create_hiking_workout`

### Improved

- Comprehensive test coverage for all 9 API modules (199 examples, up from 48)
  - User, Health, Activities, Body Composition, Metrics, Devices, Badges, Workouts, Wellness

## 0.1.0 (2026-02-11)

- Initial release
- Full Garmin Connect OAuth authentication (SSO + OAuth1 + OAuth2)
- MFA support
- Token persistence (file and string-based, garth-compatible)
- Automatic token refresh
- 108 API methods across 9 categories:
  - User & Profile
  - Daily Health (steps, HR, HRV, sleep, stress, body battery, SpO2, respiration)
  - Activities (list, details, CRUD, download in 5 formats, upload)
  - Body Composition & Weight (weigh-ins, hydration, blood pressure)
  - Advanced Metrics (VO2 max, training readiness, endurance/hill score, race predictions, lactate threshold)
  - Devices & Gear (device settings, gear management, gear-activity linking)
  - Badges, Challenges & Goals (earned/available badges, challenges, personal records, goals)
  - Workouts & Training Plans
  - Wellness (menstrual cycle, pregnancy, lifestyle logging, GraphQL)
- Retry with exponential backoff on server errors
- Typed error hierarchy
