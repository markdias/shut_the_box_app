# Custom App Icon Setup

Follow these steps to replace the placeholder filenames in `Assets.xcassets/AppIcon.appiconset` with your own artwork.

## Required icon exports

Export your icon at the exact sizes listed below. PNG is the recommended format for iOS app icons.

| Idiom | Size (points) | Scale | Pixels | Filename |
| --- | --- | --- | --- | --- |
| iPhone | 20 × 20 | 2× | 40 × 40 | `AppIcon-20@2x.png` |
| iPhone | 20 × 20 | 3× | 60 × 60 | `AppIcon-20@3x.png` |
| iPhone | 29 × 29 | 2× | 58 × 58 | `AppIcon-29@2x.png` |
| iPhone | 29 × 29 | 3× | 87 × 87 | `AppIcon-29@3x.png` |
| iPhone | 40 × 40 | 2× | 80 × 80 | `AppIcon-40@2x.png` |
| iPhone | 40 × 40 | 3× | 120 × 120 | `AppIcon-40@3x.png` |
| iPhone | 60 × 60 | 2× | 120 × 120 | `AppIcon-60@2x.png` |
| iPhone | 60 × 60 | 3× | 180 × 180 | `AppIcon-60@3x.png` |
| iPad | 20 × 20 | 1× | 20 × 20 | `AppIcon-20~ipad.png` |
| iPad | 20 × 20 | 2× | 40 × 40 | `AppIcon-20@2x~ipad.png` |
| iPad | 29 × 29 | 1× | 29 × 29 | `AppIcon-29~ipad.png` |
| iPad | 29 × 29 | 2× | 58 × 58 | `AppIcon-29@2x~ipad.png` |
| iPad | 40 × 40 | 1× | 40 × 40 | `AppIcon-40~ipad.png` |
| iPad | 40 × 40 | 2× | 80 × 80 | `AppIcon-40@2x~ipad.png` |
| iPad | 76 × 76 | 1× | 76 × 76 | `AppIcon-76~ipad.png` |
| iPad | 76 × 76 | 2× | 152 × 152 | `AppIcon-76@2x~ipad.png` |
| iPad | 83.5 × 83.5 | 2× | 167 × 167 | `AppIcon-83.5@2x~ipad.png` |
| App Store | 1024 × 1024 | 1× | 1024 × 1024 | `AppIcon-1024.png` |

> **Tip:** If you use a design tool such as Figma, Sketch, or Photoshop, create a single square artboard and export each PNG at the pixel dimensions shown above.

## Replace the placeholders

1. Open `ShutTheBoxApp/Resources/Assets.xcassets/AppIcon.appiconset` in Finder or the Xcode asset catalog.
2. Drag each PNG into the matching slot, or copy them into the folder with the filenames listed in the table.
3. Commit the images to your own repository copy when you are ready. This template intentionally avoids storing binary assets.

After the files are in place, clean and rebuild the project in Xcode to verify that the new icon appears on the simulator or device.
