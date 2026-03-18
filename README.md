# Vibe Demo

A Flutter web boilerplate optimized for rapid prototyping and vibe coding.

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run on web (Chrome)
flutter run -d chrome
```

## Pre-installed Packages

- `supabase_flutter` - Backend (database, auth, storage)
- `http` - HTTP requests
- `provider` - Simple state management
- `google_fonts` - Custom fonts

## Supabase Setup

Credentials are in `lib/supabase_config.dart`. When forking for a new demo:

1. Create a new project at [supabase.com](https://supabase.com)
2. Update `supabaseUrl` and `supabaseAnonKey` in `lib/supabase_config.dart`

**Quick usage example:**

```dart
import 'supabase_config.dart';

// Fetch data
final data = await supabase.from('todos').select();

// Insert data
await supabase.from('todos').insert({'title': 'New todo'});
```

## Tips for Vibe Coding

1. **Start simple** - Build the UI first, add logic later
2. **Iterate fast** - Hot reload is your friend
3. **Don't over-engineer** - Working code beats perfect code
4. **Use AI** - Let Cursor help you build features quickly

## VS Code Launch

Use the "Flutter Web" launch configuration (F5) to run in Chrome.
