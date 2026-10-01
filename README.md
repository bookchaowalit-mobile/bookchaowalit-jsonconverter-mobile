# JSON Converter — Mobile

SwiftUI app for **JSON Converter** — format JSON and convert between JSON and CSV.

Part of [Chaowalit Greepoke](https://bookchaowalit.com)'s 101 Portfolio Projects.

## Status

This is a Swift package, not yet a shippable app:

- `Sources/JsonconverterCore` — Foundation-only domain logic, unit-tested in
  `Tests/JsonconverterCoreTests` (XCTest).
- `Sources/JsonconverterUI` — SwiftUI tab shell (Home / Explore / Profile). It does not
  use `JsonconverterCore` yet, and there is no Xcode app target (`@main`) yet.

The code has **not been compiled outside CI** (it was written without a Swift
toolchain); the macOS CI job is the first real build. See
[docs/UPGRADE-PLAN.md](docs/UPGRADE-PLAN.md).

## Core features (`JsonconverterCore`)

- `JSONValue` model that keeps booleans and numbers distinct (unlike `NSNumber`)
- Pretty-print / minify with sorted keys and unescaped slashes
- Flattening of nested objects/arrays into dot paths (`user.tags.0`)
- JSON array of objects → RFC 4180 CSV (sorted union of columns, proper quoting)
- CSV → JSON with an RFC 4180 parser (quoted fields, doubled quotes, embedded newlines, CRLF/LF), optional type inference that keeps codes like `007` as strings, and row-length validation

## Tech Stack

- **UI:** SwiftUI (iOS 17+ / macOS 14+)
- **Language:** Swift 5.10
- **Tests:** XCTest via SwiftPM

## Getting Started

```bash
swift build
swift test          # runs JsonconverterCoreTests
open Package.swift  # opens in Xcode 15+
```

CI (`.github/workflows/build.yml`, macOS 14) runs `swift build` and
`swift test`; failures fail the workflow.

## Related

- **Frontend:** [bookchaowalit-website/jsonconverter-frontend](https://github.com/bookchaowalit-website/bookchaowalit-jsonconverter-frontend)
- **Portfolio:** [bookchaowalit.com](https://bookchaowalit.com)

## License

MIT
