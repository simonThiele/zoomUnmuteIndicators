# Zoom Unmute Indicators

## But why?

Everybody using zoom frequently knows the issue: You say something and forget to mute yourself, sometimes leaking funny information to your collegues.
You just need a bigger indication, that you are not muted!

## How does it work?

This is a simple MacOS app build in swift that runs in the background. To check if zoom is on mute or not, a JXA script is fired, checking, if the zoom window is muted or not. There are two different ways to indicate the mute status:

1. **Menu bar icon**: The menu bar icon changes color depending on the mute status. It is a simple red dot, that turns red when unmuted.
2. **Window border**: The window border of the zoom window changes color depending on the mute status. It is a simple red gradient when unmuted.

## Installation

### Build the swift app

```bash
mkdir -p ./build
```

```bash
swiftc -framework Cocoa -o ./build/App main.swift App.swift BorderController.swift MenuBarMutable.swift WindowBorderMutable.swift PreferencesWindowController.swift
```

### Run the swift app manually

```bash
./build/App
```

### Preferences

The app includes a preferences dialog where you can configure:

- **Enable Border Indicator**: Show the window border indicator (default: enabled)
- **Unmute Button Text**: Set the text of the unmute button in Zoom (default: "Mute audio")

The menu bar indicator is always enabled to provide a consistent way to access the preferences.

You can access the preferences in two ways:
1. Click on the menu bar icon and select "Preferences..." from the menu
2. Use the keyboard shortcut ⌘, (Command + Comma) when the app is active

All preferences are automatically saved between app launches.

Feel free to automate the startup

## Troubleshooting

### Known issues

- You need to have at least MacOS Yosemite since the JXA script is not supported in older versions.
- The executing app needs accessibility permissions to get access the zoom app menu bar entries. Note: When you start the app via shell, it's the shell which needs permissions as well.
