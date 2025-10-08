# Podcasts App
## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Setup Instructions](#setup-instructions)
- [Architecture](#architecture)
- [Testing](#testing)

## Overview

The Podcasts App is a two-screen iOS application that allows users to discover and explore podcasts from the Listen Notes API. The app features a clean, modern interface with infinite scroll pagination, persistent favorites, and detailed podcast information.

## Features

### 🎧 Podcast Discovery
- **Infinite Scroll**: Load 20 podcasts per page with seamless pagination
- **Rich Content**: High-quality images and detailed descriptions

### ❤️ Favorites Management
- **Persistent Storage**: Favorites saved locally using UserDefaults
- **Instant Toggle**: Quick add/remove from both list and detail views
- **Visual Indicators**: Clear favorite status in UI

### 📱 User Experience
- **Portrait Only**: Optimized for single orientation
- **Pull-to-Refresh**: Easy content refresh
- **Loading States**: Clear feedback during data operations
- **Error Handling**: Graceful error recovery with retry options

## Setup Instructions
### Prerequisites
- Xcode 15.0 or later
- iOS 16.0+ deployment target

### Installation
1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mobile-challenge
   ```

2. **Open in Xcode**
   ```bash
   open PodcastsApp/PodcastsApp.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run
   - The app will launch with sample data

## Architecture

The app follows a clean MVVM architecture with a Repository pattern for data management:

```
┌──────────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   SwiftUI Views      │    │  ViewModels      │    │   Repository    │
│                      │    │                  │    │                 │
│ • PodcastListView    │◄──►│ • PodcastsListVM │◄──►│ • PodcastsRepo  │
│ • PodcastDetailView  │    │ • PodcastDetailVM│    │                 │
│ • PodcastRowView     │    │                  │    │                 │
└──────────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │         │
                                                         ▼         ▼
                                         ┌──────────────────┐    ┌─────────────────┐
                                         │  Favorites       │    │   Network       │
                                         │  Manager         │    │   Layer         │
                                         │                  │    │                 │
                                         │ • UserDefaults   │    │ • URLSession    │
                                         │                  │    │ • API Client    │
                                         └──────────────────┘    └─────────────────┘
```

### Architecture Choices
- **MVVM + Repository**: Clean separation of concerns with testable components
    - **Views**: SwiftUI-based UI components with reactive data binding
    - **ViewModels**: `@ObservableObject` classes that manage UI state and business logic
    - **Repository**: Data coordination layer that manages pagination and favorites
    - **Network Layer**: Async/await based API client with error handling
    - **Persistence**: UserDefaults-based favorites storage
- **Protocol-Based**: Dependency injection for better testability
- **Single Responsibility**: Each class has one clear purpose

### Technical Decisions
- **Async/Await**: Modern concurrency over completion handlers
- **UserDefaults**: Simple persistence for favorites (no Core Data overhead)
- **SwiftUI**: Declarative UI for rapid development and maintenance
- **Test-Driven Development**: Comprehensive unit and UI test coverage
- **XCTest/XCUITest**: Unit and UI testing frameworks

## Testing
### Test Coverage
- **Unit Tests**: 90%+ coverage across all layers
- **UI Tests**: Complete user journey validation

### Test Structure
```
PodcastsAppTests/
├── Core/
│   ├── Network/
│   │   └── PodcastAPIClientTests.swift
│   ├── Persistence/
│   │   └── FavoritesManagerTests.swift
│   └── Repository/
│       └── PodcastsRepositoryTests.swift
└── Features/
    ├── PodcastList/
    │   └── PodcastsListViewModelTests.swift
    └── PodcastDetail/
        └── PodcastDetailViewModelTests.swift

PodcastsAppUITests/
├── PodcastListViewUITests.swift
└── PodcastDetailViewUITests.swift
```
