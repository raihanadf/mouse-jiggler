# Mouse Mover

A tiny Mac menu bar app that moves your cursor when you're AFK. Keeps your computer awake during long downloads, presentations, or when you just don't want it to sleep.

## What it does

- Sits in your menu bar (top right)
- Waits for you to be idle (default: 30 seconds)
- Moves your mouse to random spots every 10 seconds
- Stops immediately when you move the mouse

## Download

```bash
git clone https://github.com/yourusername/mouse-jiggler.git
cd mouse-jiggler
./build.sh
cp -r MouseJiggler.app /Applications/
```

Or just grab the latest release.

## Usage

1. Open the app
2. Grant Accessibility permissions (System Settings → Privacy & Security → Accessibility)
3. Click the icon in your menu bar
4. Toggle it on
5. Go grab coffee ☕

## Customize

Click the menu bar icon to change:

- **Idle time** - how long to wait before moving (6 sec to 60 min)
- **Move interval** - how often to move the cursor (1 to 60 sec)
- **Icon** - pick from mouse, cat, dog, ghost, robot, gamepad, fire, or bolt
- **Notifications** - get alerted when it starts/stops
- **Keyboard shortcut** - ⌃⌥J to toggle anywhere

## Requirements

- macOS 13+
- Accessibility permissions (for cursor control)

## Why?

Because screensavers and sleep timers are annoying when you're:
- Screen sharing and don't want to appear "away"
- Downloading large files
- Running long tests
- Just want your computer to stay awake

## License

MIT - do whatever you want

---

Built with Swift because Objective-C scares me.
