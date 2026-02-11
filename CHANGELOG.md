# Changelog

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
