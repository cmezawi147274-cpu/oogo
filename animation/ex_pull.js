const { sw, mirror, halves } = require("./lib.js");
const L = [];
const add = d => (L.push(Object.assign({ cat: "pull" }, d)), d);

// ---------------- bodyweight (front view) ----------------
const hang = (grip, barY, extra = {}) => ({
  view: "front", rep: 2.5, armMode: { l: "ik", r: "ik" }, legMode: { l: "fkw", r: "fkw" },
  defaults: Object.assign({ lhx: -grip, rhx: grip, lhy: barY, rhy: barY, lth: 4, rth: 4, lk: 0, rk: 0, lfa: -30, rfa: 30 }, extra.defaults || {}),
  shadow: { x: 0, rx: 46 }, effort: [0.3], sweat: sw(2.5, 0.35), strainAt: [[0.12, 0.5]],
});
function hangKeys(barY, grip) {
  const reach = Math.sqrt(67 * 67 - Math.pow(Math.max(0, grip - 31), 2));
  const low = barY + reach + 66 - 1, high = barY + 76;
  return [
    [0.00, { hx: 0, hy: low, lsf: 1, rsf: 1 }],
    [0.10, {}],
    [0.42, { hy: high, lsf: 0.8, rsf: 0.8 }],
    [0.56, {}],
    [0.92, { hy: low, lsf: 1, rsf: 1 }],
  ];
}
add({ id: "pull-up", name: "Pull-up", sub: "Bodyweight", ...hang(48, -200),
  props: [{ type: "barFront", x1: -92, x2: 92, y: -200 }], keys: hangKeys(-200, 48) });
add({ id: "chin-up", name: "Chin-up", sub: "Bodyweight", ...hang(26, -200),
  props: [{ type: "barFront", x1: -92, x2: 92, y: -200 }], keys: hangKeys(-200, 26) });
add({ id: "neutral-grip-pull-up", name: "Neutral-Grip Pull-up", sub: "Bodyweight", ...hang(22, -186),
  props: [{ type: "barFront", x1: -92, x2: 92, y: -200 }, { type: "handles", x1: -22, x2: 22, y: -200 }], keys: hangKeys(-186, 22) });
add({ id: "towel-pull-up", name: "Towel Pull-up", sub: "Bodyweight", ...hang(34, -172),
  props: [{ type: "barFront", x1: -92, x2: 92, y: -204 }, { type: "towel", x: -34, y: -204, len: 40 }, { type: "towel", x: 34, y: -204, len: 40 }],
  keys: hangKeys(-172, 34) });

// inverted row: side view, supine under a bar (head on the left)
add({ id: "inverted-row", name: "Inverted Row", sub: "Bodyweight", rep: 2.5,
  headComp: -1.05, headClamp: 180, armMode: { l: "ik", r: "ik" }, elbowSign: { l: 1, r: 1 },
  hipOff: { l: { x: -30, y: 0 }, r: { x: -26, y: 0 } }, shOff: { l: { x: 20, y: -56 }, r: { x: 26, y: -56 } },
  props: [{ type: "barSide", x: -14, y: -138, post: -40 }],
  defaults: { lfx: 92, rfx: 96, lfy: -3, rfy: -3, lfa: 165, rfa: 165, lhx: -14, rhx: -12, lhy: -138, rhy: -138 },
  keys: [
    [0.00, { hx: 40, hy: -48, t: 256 }],
    [0.10, {}],
    [0.44, { hx: 36, hy: -74, t: 262 }],
    [0.56, {}],
    [0.92, { hx: 40, hy: -48, t: 256 }],
  ],
  shadow: { x: 30, rx: 100 }, effort: [0.3], sweat: sw(2.5, 0.35), strainAt: [[0.15, 0.55]] });

// ---------------- kettlebell rows (side view) ----------------
const ROWT = { hx: -30, hy: -56, t: 118, lfx: -16, rfx: 8, lfy: 0, rfy: 0 };
add({ id: "gorilla-row", name: "Gorilla Row", sub: "Kettlebell", rep: 5,
  armMode: { l: "ik", r: "ik" }, elbowSign: { l: 1, r: 1 },
  bells: [{ hand: "l", z: 2.9 }, { hand: "r" }], defaults: { b0a: 0, b1a: 0 },
  keys: [
    [0.00, { ...ROWT, lhx: 20, lhy: -27.5, rhx: 28, rhy: -27.5 }],
    [0.08, {}],
    [0.22, { rhx: 6, rhy: -66, t: 120 }],
    [0.30, {}],
    [0.44, { rhx: 28, rhy: -27.5, t: 118 }],
    [0.58, {}],
    [0.72, { lhx: 0, lhy: -66, t: 120 }],
    [0.80, {}],
    [0.94, { lhx: 20, lhy: -27.5, t: 118 }],
  ],
  effort: [0.2, 0.7], sweat: [6.9, 8.8], strainAt: [[0.14, 0.34], [0.64, 0.84]] });

add({ id: "single-arm-row", name: "Single-Arm Row", sub: "Kettlebell", rep: 2.5,
  armMode: { l: "ik", r: "ik" }, elbowSign: { l: -1, r: 1 },
  bells: [{ hand: "r" }], defaults: { b0a: 0 },
  keys: [
    [0.00, { hx: -26, hy: -54, t: 120, lfx: -30, rfx: 14, lfy: 0, rfy: 0, lhx: 26, lhy: -40, rhx: 26, rhy: -30 }],
    [0.10, {}],
    [0.42, { rhx: 4, rhy: -66 }],
    [0.54, {}],
    [0.90, { rhx: 26, rhy: -30 }],
  ],
  effort: [0.3], sweat: sw(2.5, 0.35), strainAt: [[0.2, 0.55]] });

add({ id: "three-point-row", name: "Three-Point Row", sub: "Kettlebell", rep: 2.5,
  armMode: { l: "ik", r: "ik" }, elbowSign: { l: -1, r: 1 },
  props: [{ type: "bench", x: 46, y: -42, w: 62 }],
  bells: [{ hand: "r" }], defaults: { b0a: 0 },
  keys: [
    [0.00, { hx: -24, hy: -56, t: 112, lfx: -22, rfx: 4, lfy: 0, rfy: 0, lhx: 60, lhy: -43, rhx: 30, rhy: -30 }],
    [0.10, {}],
    [0.42, { rhx: 6, rhy: -68 }],
    [0.54, {}],
    [0.90, { rhx: 30, rhy: -30 }],
  ],
  effort: [0.3], sweat: sw(2.5, 0.35), strainAt: [[0.2, 0.55]] });

add({ id: "renegade-row", name: "Renegade Row", sub: "Kettlebell", rep: 5,
  headComp: -1.05, headClamp: 90, headPos: { x: -20, y: -90 }, armMode: { l: "ik", r: "ik" }, elbowSign: { l: -1, r: 1 },
  shOff: { l: { x: 26, y: -58 }, r: { x: 32, y: -58 } }, hipOff: { l: { x: 20, y: -4 }, r: { x: 26, y: -4 } }, kneeSign: { l: -1, r: -1 },
  bells: [{ hand: "l", z: 2.9 }, { hand: "r" }],
  defaults: { lfx: -74, rfx: -62, lfy: -7, rfy: -7, lfa: 15, rfa: 15, b0a: 0, b1a: 0 },
  keys: [
    [0.00, { hx: 0, hy: -96, t: 104, lhx: 60, lhy: -27.5, rhx: 64, rhy: -27.5 }],
    [0.10, {}],
    [0.24, { rhx: 38, rhy: -66, t: 102 }],
    [0.32, {}],
    [0.46, { rhx: 64, rhy: -27.5, t: 104 }],
    [0.60, {}],
    [0.74, { lhx: 34, lhy: -66, t: 106 }],
    [0.82, {}],
    [0.96, { lhx: 60, lhy: -27.5, t: 104 }],
  ],
  effort: [0.22, 0.72], sweat: [6.9, 8.8], strainAt: [[0.0, 1.0]] });

add({ id: "ballistic-row", name: "Ballistic Row", sub: "Kettlebell", rep: 2,
  armMode: { l: "fkw", r: "ik" }, elbowSign: { r: 1 },
  bells: [{ hand: "r" }],
  keys: [
    [0.00, { hx: -24, hy: -54, t: 122, lfx: -14, rfx: 6, lfy: 0, rfy: 0, rhx: 6, rhy: -70, lua: -10, le: 30 }],
    [0.12, {}],
    [0.30, { rhx: 26, rhy: -28 }],
    [0.46, { rhx: -6, rhy: -26 }],                 // bell swings back through the legs
    [0.62, { rhx: 22, rhy: -30 }],
    [0.74, { rhx: 6, rhy: -70 }],                  // explosive row
  ],
  effort: [0.68], motion: [{ bell: 0, win: [0.62, 0.8] }], sweat: sw(2, 0.7), strainAt: [[0.62, 0.95]] });

add({ id: "dead-clean-pull", name: "Dead Clean Pull", sub: "Kettlebell", rep: 2.5,
  armMode: { l: "fkw", r: "blend" }, elbowSign: { r: 1 },
  defaults: { lfx: -10, rfx: 2, le: 10, re: 0, rhx: 46, rhy: -60 },
  keys: [
    [0.00, { hx: -38, hy: -45, t: 140, rm: 0, rua: -2, lua: -20 }],
    [0.10, {}],
    [0.26, { hx: -4, hy: -55, t: 166, rua: 12, lua: -8 }],
    [0.38, { hx: 0, hy: -57.5, t: 182, rm: 1, rua: 50, lua: -6 }],
    [0.50, {}],
    [0.64, { t: 178, rm: 0, rua: 20 }],
    [0.92, { hx: -38, hy: -45, t: 140, rua: -2, lua: -20 }],
  ],
  bells: [{ hand: "r" }], effort: [0.26], motion: [{ bell: 0, win: [0.2, 0.42] }], sweat: sw(2.5, 0.3), strainAt: [[0.08, 0.36]] });

module.exports = L;

