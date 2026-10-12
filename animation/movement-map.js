// Maps an Oog clip def to the iOS app's movement id (Movement(id: "...") in
// ios-oogo/Oogo/Models/OogoModels.swift).
//
// Most clip ids equal the app id. The exceptions live in OVERRIDES below.
// A def with no matching app id maps to null (the preview flags these).
//
// If the app gains a movement, add its id to APP_IDS (export.js warns when this
// list drifts from the Swift file).

// Every app movement id, grouped as in MovementLibrary.
const APP_IDS = [
  // push
  "strict-press", "push-press", "half-kneeling-press", "z-press", "bottoms-up-press",
  "floor-press", "push-jerk", "thruster", "clean-and-press", "push-up", "deficit-push-up",
  "close-grip-push-up", "archer-push-up", "double-press", "double-floor-press", "dips",
  "bench-dip",
  // pull
  "gorilla-row", "single-arm-row", "three-point-row", "renegade-row", "ballistic-row",
  "pull-high-pull", "dead-clean-pull", "pull-up", "chin-up", "neutral-grip-pull-up",
  "inverted-row", "double-row", "towel-pull-up",
  // legs
  "goblet-squat", "front-rack-squat", "tempo-goblet-squat", "pause-squat", "cyclist-squat",
  "reverse-lunge", "walking-lunge", "forward-lunge", "bulgarian-split-squat", "step-up",
  "double-front-squat", "rope-skip", "rope-double-under", "rope-high-knee", "cossack-squat",
  "lateral-lunge", "skater-squat", "squat",
  // hinge
  "two-hand-swing", "one-hand-swing", "hand-to-hand-swing", "alternating-swing", "dead-clean",
  "hinge-high-pull", "clean", "snatch", "alternating-snatch", "clean-and-jerk", "long-cycle",
  "double-snatch", "romanian-deadlift", "kettlebell-deadlift", "single-leg-deadlift",
  "good-morning", "hip-thrust", "double-swing",
  // core
  "suitcase-carry", "front-rack-carry", "waiters-carry", "overhead-carry", "halo",
  "around-the-world", "half-kneeling-chop", "uppercut", "figure-8-to-hold", "rotational-clean",
  "rotational-deadlift", "windmill", "bent-press", "arm-bar", "offset-march",
  "front-rack-march", "overhead-march", "plank", "side-plank", "hollow-hold",
  "hanging-knee-raise", "hanging-leg-raise", "dead-bug", "bird-dog",
];

// Def id differs from the app id. Keyed "<cat>:<def id>".
const OVERRIDES = {
  "hinge:high-pull": "hinge-high-pull",
  "pull:high-pull": "pull-high-pull",
  "legs-squat:single-leg-reverse-lunge": "reverse-lunge",
  "legs:single-leg-reverse-lunge": "reverse-lunge",
};

// The original export has ONE high-pull def (category "hinge"; the pull folder's
// 11-high-pull.html just re-plays it). The app has two movements for it, so the
// hinge def also serves pull-high-pull. Keyed "<cat>:<def id>" -> extra app ids.
// export.js writes these as `movementAliases` and ignores an alias once a
// dedicated def maps to the same app id.
const ALIASES = {
  "hinge:high-pull": ["pull-high-pull"],
};

const APP_ID_SET = new Set(APP_IDS);

function mapMovement(def) {
  const key = def.cat + ":" + def.id;
  if (Object.prototype.hasOwnProperty.call(OVERRIDES, key)) return OVERRIDES[key];
  return APP_ID_SET.has(def.id) ? def.id : null;
}

function aliasesFor(def) {
  return ALIASES[def.cat + ":" + def.id] || [];
}

module.exports = mapMovement;
module.exports.mapMovement = mapMovement;
module.exports.aliasesFor = aliasesFor;
module.exports.APP_IDS = APP_IDS;
module.exports.OVERRIDES = OVERRIDES;
module.exports.ALIASES = ALIASES;
