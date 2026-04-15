# CineFlow

A movie discovery app built with UIKit that lets users explore now-playing films, search the catalogue, watch trailers, browse cast lists, and save favorites — all powered by [The Movie Database (TMDb) API](https://www.themoviedb.org/).

## Screenshots

| Home | Detail | Search | Favorites |
|:----:|:------:|:------:|:---------:|
| ![Home](CineFlow/tree/main/screenshots/home.png) | ![Detail](CineFlow/tree/main/screenshots/detail.png) | ![Search](CineFlow/tree/main/screenshots/search.png) | ![Favorites](CineFlow/tree/main/screenshots/favorites.png) |

## Features

- Now-playing banner with auto-scrolling slider
- Upcoming movies list with infinite pagination and pull-to-refresh
- Movie detail: backdrop, rating, runtime, IMDb link, trailer (YouTube), and cast list
- Full-text movie search with debounce and pagination
- Favorites — persist across sessions via UserDefaults
- TR / EN localization — follows device language automatically
- Empty states and error alerts on every screen

## Architecture

MVVM with closure-based bindings. Each screen owns a ViewModel that is fully decoupled from UIKit:

```
View (UIViewController)
  │  observes closures (didUpdate*, isLoading, didReceiveError)
  ▼
ViewModel
  │  depends on protocol, not concrete type
  ▼
NetworkManagerProtocol  ◄──  NetworkManager (Alamofire)
                         ◄──  MockNetworkManager (tests)
```

Key decisions:
- **No storyboards** — all layout is programmatic with SnapKit
- **Protocol-oriented networking** — `NetworkManagerProtocol` makes every ViewModel unit-testable with a `MockNetworkManager`
- **DispatchGroup** — detail, cast, and trailer requests run in parallel; loading ends only when all three complete
- **Kingfisher** behind an `ImageLoader` abstraction — swappable without touching call sites

## Tech Stack

| | |
|---|---|
| Language | Swift |
| UI | UIKit (programmatic, no Storyboard) |
| Architecture | MVVM |
| Networking | Alamofire |
| Image loading | Kingfisher |
| Layout | SnapKit |
| Persistence | UserDefaults |
| Testing | XCTest + MockNetworkManager |
| Dependency management | CocoaPods |

## Tests

Unit tests cover all three ViewModels using a `MockNetworkManager` that replays stubbed responses:

```
CineFlowTests/
├── Mocks/
│   ├── MockNetworkManager.swift
│   └── TestStubs.swift
├── HomeViewModelTests.swift      (5 tests)
├── SearchViewModelTests.swift    (6 tests)
└── DetailViewModelTests.swift    (5 tests)
```

Run tests with `Cmd+U` in Xcode.

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
