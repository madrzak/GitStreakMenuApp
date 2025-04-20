# GitStreak Menu App

A simple macOS menu bar app that displays your current GitHub commit streak.

## Features

- Shows your current GitHub commit streak directly in the macOS menu bar
- Displays a flame emoji 🔥 followed by the number of consecutive days with contributions
- Optional GitHub personal access token support for private repositories or to avoid API rate limits
- Easy to use settings interface

## Requirements

- macOS 12.0 or later
- Xcode 14.0 or later (for development)
- GitHub account

## Installation

1. Download the latest release from the Releases page
2. Extract the ZIP file
3. Drag GitStreakMenuApp to your Applications folder
4. Launch the app

## First Run

On first launch, you'll be prompted to enter your GitHub username. You can optionally provide a personal access token if you want to track private repositories or avoid API rate limits.

## GitHub Token

If you want to use a GitHub personal access token:

1. Visit https://github.com/settings/tokens
2. Click "Generate new token"
3. Give it a name like "GitStreak App"
4. Select only the `read:user` scope
5. Click "Generate token"
6. Copy the token and paste it into the app's settings

## Development

To build the app from source:

1. Clone this repository
2. Open `GitStreakMenuApp.xcodeproj` in Xcode
3. Build and run the app

## License

MIT 