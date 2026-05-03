# CineFlow

A movie discovery app that lets users explore now-playing films, search the catalogue, watch trailers, browse cast lists, and save favorites — powered by [The Movie Database (TMDb) API](https://www.themoviedb.org/).

Built with **UIKit + SwiftUI interop**, **async/await**, **SwiftData**, and **MVVM**.

> Requires iOS 17+ and Xcode 15+.

## Screenshots

| Home | Detail | Search | Favorites |
|:----:|:------:|:------:|:---------:|
| ![Home](screenshots/home.png) | ![Detail](screenshots/detail.png) | ![Search](screenshots/search.png) | ![Favorites](screenshots/favorites.png) |

## Features

- Now-playing banner with auto-scrolling slider
- Upcoming movies list with infinite pagination and pull-to-refresh
- Movie detail (SwiftUI): backdrop, rating, runtime, IMDb link, trailer (YouTube), and cast list
- Full-text movie search with debounce and pagination
- Favorites — persisted with SwiftData (auto-migrates the legacy UserDefaults store)
- **Home screen widget** (WidgetKit + App Intents) — Now Playing or Upcoming movies, configurable per widget instance, with deep links into the app
- TR / EN localization — follows device language automatically
- Empty states and error alerts on every screen

## Architecture

MVVM. The Home, Search, and Favorites screens are programmatic UIKit; the Detail screen is SwiftUI embedded via `UIHostingController`. Networking uses native `URLSession` with `async/await` and `async let` for parallel requests.

```
UIKit screens (Home / Search / Favorites)
  │  closure bindings → ViewModel
  ▼
ViewModel ──────────────►  @Published / closures
  │  depends on protocol
  ▼
NetworkManagerProtocol  ◄──  NetworkManager (URLSession + async/await)
                         ◄──  MockNetworkManager (tests)

SwiftUI Detail screen ──►  @StateObject DetailViewModel (ObservableObject)
```

Key decisions:
- **No storyboards** — UIKit layout is programmatic with SnapKit
- **UIKit + SwiftUI interop** — `DetailScreen.make(...)` returns a `UIHostingController` so existing UIKit `pushViewController` call sites work unchanged
- **Native networking, no Alamofire** — `URLSession.data(for:)` + `async let` for parallel detail / credits / trailer requests
- **Protocol-oriented networking** — `NetworkManagerProtocol` makes every ViewModel unit-testable with a `MockNetworkManager`
- **SwiftData for persistence** — separate `FavoriteMovie @Model` keeps the API DTO (`Movie` struct) decoupled from storage. One-time migration ports any existing UserDefaults favorites on first launch. Tests inject an in-memory `ModelContainer`.
- **Widget extension** — `AppIntentTimelineProvider` re-uses the main app's `NetworkManager` (shared via Target Membership, no code duplication). `WidgetConfigurationIntent` lets the user pick Now Playing / Upcoming per widget instance. Tap any item → `cineflow://movie/<id>` deep link → app opens the Detail screen.
- **Kingfisher** for image loading — `ImageLoader` abstraction in UIKit, `KFImage` in SwiftUI

## Tech Stack

| | |
|---|---|
| Language | Swift |
| UI | UIKit (programmatic) + SwiftUI (Detail screen) |
| Architecture | MVVM |
| Concurrency | async/await, `async let` |
| Networking | URLSession |
| Image loading | Kingfisher |
| Layout (UIKit) | SnapKit |
| Persistence | SwiftData |
| Testing | XCTest + MockNetworkManager |
| Dependency management | CocoaPods |

## Tests

Unit tests cover all three ViewModels using a `MockNetworkManager` that replays stubbed responses:

```
CineFlowTests/
├── Mocks/
│   ├── MockNetworkManager.swift
│   └── TestStubs.swift
├── HomeViewModelTests.swift
├── SearchViewModelTests.swift
└── DetailViewModelTests.swift
```

Run tests with `Cmd+U` in Xcode.

## Dependencies

- [SnapKit](https://github.com/SnapKit/SnapKit) — UIKit Auto Layout DSL
- [Kingfisher](https://github.com/onevcat/Kingfisher) — image downloading & caching (`KFImage` in SwiftUI, `ImageLoader` abstraction in UIKit)

## Installation

```bash
git clone https://github.com/yourusername/CineFlow.git
cd CineFlow
pod install
open CineFlow.xcworkspace
```

Add your TMDb API key in `CineFlow/Common/Constants/AppConstants.swift`:

```swift
static let apiKey = "YOUR_API_KEY_HERE"
```

Get a free key at [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api).
