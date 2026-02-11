# GarminConnect

A Ruby client for the Garmin Connect API. Provides access to health, fitness, activity, and device data from your Garmin account.

Inspired by [python-garminconnect](https://github.com/cyberjunky/python-garminconnect), rebuilt idiomatically for Ruby.

## Installation

Add to your Gemfile:

```ruby
gem "garmin_connect"
```

Or install directly:

```
gem install garmin_connect
```

## Quick Start

```ruby
require "garmin_connect"

# Login with credentials (tokens are saved to ~/.garminconnect automatically)
client = GarminConnect::Client.new(email: "you@example.com", password: "your-password")
client.login

# Subsequent sessions resume from saved tokens (no re-login for ~1 year)
client = GarminConnect::Client.new
client.login

# Get today's stats
puts client.daily_summary
puts client.heart_rates
puts client.sleep_data
puts client.stress
```

## Authentication

The gem uses the same OAuth flow as the Garmin Connect mobile app:

1. SSO login with your email/password
2. Exchange for an OAuth1 token (~1 year lifetime)
3. Exchange OAuth1 for an OAuth2 Bearer token (~20 hours)
4. Auto-refresh when the OAuth2 token expires

### MFA Support

If your account has MFA enabled, the gem prompts via `$stdin` by default. You can provide a custom handler:

```ruby
client = GarminConnect::Client.new(
  email: "you@example.com",
  password: "your-password",
  mfa_handler: -> { print "MFA code: "; gets.chomp }
)
client.login
```

### Token Storage

Tokens are saved to `~/.garminconnect` by default. You can customize this:

```ruby
# Custom directory
client = GarminConnect::Client.new(token_dir: "/path/to/tokens")

# Base64-encoded string (useful for environment variables)
encoded = client.dump_tokens
client = GarminConnect::Client.new(token_string: encoded, token_dir: nil)

# Disable persistence entirely
client = GarminConnect::Client.new(token_dir: nil)
```

### Token Interoperability

Token files are compatible with [garth](https://github.com/matin/garth) (the Python auth library). If you have existing tokens from the Python library, point `token_dir` at the same directory.

## API Reference

### User & Profile

```ruby
client.user_settings           # Measurement system, sleep settings, etc.
client.user_profile            # Profile configuration
client.personal_information    # Age, gender, email, biometric profile
client.display_name            # "YourDisplayName"
client.full_name               # "Your Full Name"
client.unit_system             # "statute_us" or "metric"
```

### Daily Health

```ruby
client.daily_summary(date)      # Steps, calories, distance, active minutes
client.heart_rates(date)        # Heart rate data with resting HR
client.resting_heart_rate(start_date, end_date)
client.hrv(date)                # Heart rate variability
client.sleep_data(date)         # Sleep stages, duration, scores
client.stress(date)             # All-day stress levels
client.body_battery(start, end) # Body battery reports
client.body_battery_events(date)
client.steps_data(date)         # Steps chart data
client.floors(date)             # Floors climbed
client.respiration(date)        # Respiration rate
client.spo2(date)               # Blood oxygen
client.intensity_minutes(date)  # Intensity minutes
client.daily_events(date)       # Auto-detected activities
client.request_reload(date)     # Request data reload from device
```

### Activities

```ruby
# Listing
client.activities(start: 0, limit: 20)
client.activities_by_date("2026-01-01", "2026-01-31")
client.activity_count
client.last_activity

# Details
client.activity(activity_id)
client.activity_details(activity_id)
client.activity_splits(activity_id)
client.activity_typed_splits(activity_id)
client.activity_split_summaries(activity_id)
client.activity_weather(activity_id)
client.activity_hr_zones(activity_id)
client.activity_power_zones(activity_id)
client.activity_exercise_sets(activity_id)
client.activity_types

# CRUD
client.create_activity(payload_hash)
client.rename_activity(activity_id, "Morning Run")
client.update_activity_type(activity_id, type_dto)
client.delete_activity(activity_id)

# Download & Upload
client.download_activity(activity_id, format: :original) # :tcx, :gpx, :kml, :csv
client.upload_activity("/path/to/file.fit")

# Progress
client.progress_summary("2026-01-01", "2026-12-31", metric: "distance")
```

### Body Composition & Weight

```ruby
client.body_composition(start_date, end_date)
client.weigh_ins(start_date, end_date)
client.daily_weigh_ins(date)
client.add_weigh_in(84.5, date: "2026-02-11", unit_key: "kg")
client.delete_weigh_in(date, weight_pk)
```

### Hydration

```ruby
client.hydration(date)
client.log_hydration(250, date: "2026-02-11")   # 250 ml
client.log_hydration(-250, date: "2026-02-11")  # Subtract
```

### Blood Pressure

```ruby
client.blood_pressure(start_date, end_date)
client.log_blood_pressure(systolic: 120, diastolic: 80, pulse: 65)
client.delete_blood_pressure(date, version)
```

### Advanced Metrics

```ruby
client.max_metrics(date)                # VO2 Max
client.training_readiness(date)         # Training readiness score
client.training_status(date)            # Aggregated training status
client.endurance_score(date)            # Single day
client.endurance_score(start_date: s, end_date: e) # Date range
client.hill_score(date)
client.race_predictions                 # 5k, 10k, half, full marathon
client.fitness_age(date)
client.lactate_threshold                # Latest
client.lactate_threshold_history(start_date, end_date)
client.cycling_ftp                      # Functional Threshold Power
```

### Historical Data

```ruby
client.daily_steps(start_date, end_date)       # Auto-chunked at 28 days
client.weekly_steps(end_date, weeks: 52)
client.weekly_stress(end_date, weeks: 52)
client.weekly_intensity_minutes(start_date, end_date)
```

### Devices & Gear

```ruby
# Devices
client.devices
client.device_settings(device_id)
client.last_used_device
client.primary_training_device
client.device_solar_data(device_id, start_date, end_date)
client.device_alarms                     # Alarms across all devices

# Gear
client.gear
client.activity_gear(activity_id)
client.gear_stats(gear_uuid)
client.gear_defaults
client.set_gear_default(gear_uuid, activity_type)
client.link_gear(gear_uuid, activity_id)
client.unlink_gear(gear_uuid, activity_id)
client.gear_activities(gear_uuid)
```

### Badges, Challenges & Goals

```ruby
client.earned_badges
client.available_badges
client.in_progress_badges
client.adhoc_challenges
client.badge_challenges
client.available_badge_challenges
client.non_completed_badge_challenges
client.virtual_challenges
client.personal_records
client.goals(status: "active")
```

### Workouts & Training Plans

```ruby
client.workouts(start: 0, limit: 20)
client.workout(workout_id)
client.download_workout(workout_id)
client.create_workout(payload_hash)
client.scheduled_workout(id)
client.training_plans
client.training_plan(plan_id)
client.adaptive_training_plan(plan_id)
```

### Wellness & Misc

```ruby
client.menstrual_data(date)
client.menstrual_calendar(start_date, end_date)
client.pregnancy_summary
client.lifestyle_logging(date)
client.graphql(query_string, variables: {})
```

## Error Handling

```ruby
begin
  client.daily_summary
rescue GarminConnect::UnauthorizedError
  # Token expired or invalid
rescue GarminConnect::TooManyRequestsError
  # Rate limited, back off
rescue GarminConnect::NotFoundError
  # Resource doesn't exist
rescue GarminConnect::ServerError
  # Garmin's servers are having issues
rescue GarminConnect::HTTPError => e
  # Any other HTTP error
  puts e.status
  puts e.body
rescue GarminConnect::AuthenticationError
  # Login/token issues
rescue GarminConnect::Error
  # Catch-all for gem errors
end
```

## Development

```
git clone https://github.com/drbragg/garmin_connect.git
cd garmin_connect
bundle install
bundle exec rspec
```

## License

MIT License. See [LICENSE](LICENSE).
