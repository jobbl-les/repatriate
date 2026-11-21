# SIM labels

Development utility (not part of the app, not compiled into it).

`sim-labels.pdf` is a full A4 page of nano-SIM labels. **Print at 100% /
"Actual size" (turn off "Fit to page")** and each label matches a physical
nano-SIM: 12.3 x 8.8 mm, diagonal cut-off at lower right, 4 mm gaps for
cutting by hand. The sheet carries 12 x 22 = 264 labels numbered 100 to 363,
white digits in Arial Rounded MT Bold on the app's brand red (#db052c).

## Regenerating

```bash
cd tools/sim-labels
swift make_sim_labels.swift sim-labels.pdf 100   # output file, first number
```

Needs macOS (uses CoreGraphics / CoreText and the Arial Rounded MT Bold font
that ships with it). Sizes, gaps, margins and the cut-off corner are constants
at the top of `make_sim_labels.swift`.
