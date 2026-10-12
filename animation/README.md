# Oog animation

This folder holds the Oog exercise animations: a small 2D rig drawn in the oogo line-art style, plus the clip definitions for every exercise. The JavaScript here is the source of truth for the animations. The iOS app does not run it. The app reads the data that `export.js` generates from it.

## What is in here

- `engine.js` is the animation engine. `makeClip(def)` turns a clip definition into poses and SVG.
- `lib.js` has the helpers used when authoring clips (`sw`, `mirror`, `halves`, `stepLegs`).
- `ex_legs.js`, `ex_hinge.js`, `ex_push.js`, `ex_pull.js` and `ex_core.js` hold the original clip definitions, one array per category. `ex_extra.js` is for clips authored later and uses the same format.
- `index.js` loads the engine and all definition files and exports `{ engine, defs }`.
- `movement-map.js` maps each clip to the app's movement id (the ids in `OogoModels.swift`). A clip with no app id maps to `null`.
- `export.js` writes the files the iOS app and its tests use.
- `build-preview.js` builds `preview.html`, a self-contained page for looking at every clip.

## Commands

Run these from anywhere. The paths resolve relative to this folder.

```
node animation/export.js
node animation/build-preview.js
```

`export.js` writes two files:

- `ios-oogo/Oogo/Resources/OogClips.json`, the clip data the app renders. Function-valued fields (`post`, a function `shadow`, function `props`) cannot be serialized, so they are also baked into sampled tables.
- `ios-oogo/OogoTests/Fixtures/OogGolden.json`, reference values from the real engine that the Swift unit tests compare against.

It also prints a summary, including how closely the baked `post` tables match the engine, and which clips or app movements have no counterpart.

`build-preview.js` writes `animation/preview.html`. Open it in a browser, or serve the folder (for example `python -m http.server --directory animation`). Click a clip for a single view with play/pause and a time scrubber. URL options:

- `?id=<clip id>` opens one clip, and `&cat=<category>` picks the right one if an id is shared.
- `?t=<seconds>` starts at a time, and `&paused=1` freezes it (useful for screenshots).

## After changing a clip

After you change any `ex_*.js` file (or the engine or `lib.js`), re-run `node animation/export.js`. Otherwise the iOS app's `OogClips.json` and the golden test fixtures stay out of date and the Swift tests will no longer match the animation. Re-run `node animation/build-preview.js` too if you want the preview page to show the change.

If you add a clip for a new app movement, make sure its id is in `movement-map.js`. The export summary lists clips without an app id and app movements without a clip.
