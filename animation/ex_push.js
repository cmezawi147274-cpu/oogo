const { sw, mirror, halves } = require("./lib.js");
const L = [];
const add = d => (L.push(Object.assign({ cat: "push" }, d)), d);

const FST = { hx: 0, hy: -57.5, t: 180, lfx: -16, rfx: 16, lfy: 0, rfy: 0, lfa: -75, rfa: 75 };
const RACK = { rhx: 38, rhy: -40, b0f: 140 };
const LOCK = { rhx: 36, rhy: -131, b0f: 155 };
const FREE = { lhx: -36, lhy: 2 };
const press = { view: "front", armMode: { l: "ikb", r: "ikb" }, bells: [{ hand: "r" }] };

add({ id: "strict-press", name: "Strict Press", sub: "Vertical", rep: 2.5, ...press,
  keys: [
    [0.00, { ...FST, ...RACK, ...FREE }],
    [0.12, {}],
    [0.48, { ...LOCK }],
    [0.60, {}],
    [0.94, { ...RACK }],
  ],
  effort: [0.3], sweat: sw(2.5, 0.35), strainAt: [[0.15, 0.45]] });

add({ id: "push-press", name: "Push Press", sub: "Vertical", rep: 2.5, ...press,
  keys: [
    [0.00, { ...FST, ...RACK, ...FREE }],
    [0.14, {}],
    [0.26, { hy: -49 }],                                   // dip
    [0.34, { hy: -59, rhx: 37, rhy: -96, b0f: 150 }],      // drive
    [0.42, { hy: -57.5, ...LOCK }],
    [0.60, {}],
    [0.90, { ...RACK }],
  ],
  effort: [0.33], motion: [{ bell: 0, win: [0.28, 0.42] }], sweat: sw(2.5, 0.36), strainAt: [[0.24, 0.42]] });

add({ id: "push-jerk", name: "Push Jerk", sub: "Power", rep: 2.5, ...press,
  keys: [
    [0.00, { ...FST, ...RACK, ...FREE }],
    [0.14, {}],
    [0.25, { hy: -49 }],                                   // dip
    [0.31, { hy: -60, rhx: 37, rhy: -92, b0f: 150 }],      // drive
    [0.38, { hy: -48, ...LOCK }],                          // drop under, arm locked
    [0.50, { hy: -57.5 }],                                 // stand up
    [0.64, {}],
    [0.90, { ...RACK }],
  ],
  effort: [0.31], motion: [{ bell: 0, win: [0.26, 0.38] }], sweat: sw(2.5, 0.33), strainAt: [[0.22, 0.48]] });

add({ id: "thruster", name: "Thruster", sub: "Power", rep: 2.5, ...press,
  keys: [
    [0.00, { ...FST, lfx: -24, rfx: 24, lfa: -65, rfa: 65, ...RACK, ...FREE, pt: 0 }],
    [0.08, {}],
    [0.38, { hy: -30, pt: 22, lhx: -40, lhy: -6 }],
    [0.44, {}],
    [0.62, { hy: -57.5, pt: 0, rhx: 37, rhy: -96, b0f: 150, ...FREE }],
    [0.70, { ...LOCK }],
    [0.78, {}],
    [0.96, { ...RACK }],
  ],
  effort: [0.56], motion: [{ bell: 0, win: [0.5, 0.7] }], sweat: sw(2.5, 0.6), strainAt: [[0.4, 0.7]] });

// half-kneeling: legs drawn in profile (left knee down, right foot forward) so the stance reads clearly
add({ id: "half-kneeling-press", name: "Half-Kneeling Press", sub: "Vertical", rep: 2.5, ...press,
  legMode: { l: "fkw", r: "fkw" },
  defaults: { lth: 0, lk: -90, lfa: -150, lff: 0.7, rth: 90, rk: 90, rfa: 90 },
  keys: [
    [0.00, { hx: 0, hy: -30, t: 180, lhx: -38, lhy: -16, rhx: -38, rhy: -40, b0f: -140 }],
    [0.12, {}],
    [0.48, { lhx: -36, lhy: -131, b0f: -155 }],
    [0.60, {}],
    [0.94, { lhx: -38, lhy: -40, b0f: -140 }],
  ].map(([p, o]) => { const n = Object.assign({}, o); if (p === 0) { n.lhx = -38; n.lhy = -40; n.rhx = 44; n.rhy = -12; } return [p, n]; }),
  bells: [{ hand: "l" }], effort: [0.3], sweat: sw(2.5, 0.35), strainAt: [[0.15, 0.45]],
  shadow: { x: 0, rx: 64 } });

add({ id: "z-press", name: "Z Press", sub: "Vertical", rep: 2.5, ...press,
  defaults: { lfx: -74, rfx: 74, lfy: -4, rfy: -4, lfa: -165, rfa: 165 },
  keys: [
    [0.00, { hx: 0, hy: -13, t: 180, ...RACK, lhx: -46, lhy: 4 }],
    [0.12, {}],
    [0.48, { ...LOCK }],
    [0.60, {}],
    [0.94, { ...RACK }],
  ],
  effort: [0.3], sweat: sw(2.5, 0.35), strainAt: [[0.15, 0.48]], shadow: { x: 0, rx: 90 } });

add({ id: "bottoms-up-press", name: "Bottoms-Up Press", sub: "Vertical", rep: 2.5, ...press,
  keys: [
    [0.00, { ...FST, rhx: 44, rhy: -42, b0a: 180, ...FREE }],
    [0.12, {}],
    [0.50, { rhx: 38, rhy: -131 }],
    [0.62, {}],
    [0.94, { rhx: 44, rhy: -42 }],
  ],
  effort: [0.32], sweat: sw(2.5, 0.35), strainAt: [[0.0, 1.0]] });

// clean & press (front view)
add({ id: "clean-and-press", name: "Clean & Press", sub: "Power", rep: 5, ...press,
  keys: [
    [0.00, { hx: 0, hy: -50, pt: 55, lfx: -22, rfx: 22, lfy: 0, rfy: 0, lfa: -70, rfa: 70, rhx: 4, rhy: 46, b0f: 0, lhx: -24, lhy: 18 }],
    [0.08, { hy: -57.5, pt: 6, rhx: 12, rhy: -14, lhx: -36, lhy: 2 }],
    [0.15, { pt: 0, ...RACK }],
    [0.24, {}],
    [0.44, { ...LOCK }],
    [0.54, {}],
    [0.70, { ...RACK }],
    [0.80, {}],
    [0.88, { rhx: 14, rhy: -26, b0f: 0, lhx: -24, lhy: 18 }],
  ],
  effort: [0.08, 0.32], strainAt: [[0.03, 0.12], [0.26, 0.46]], motion: [{ bell: 0, win: [0.04, 0.16] }], sweat: [7.2, 8.9] });

// ---------------- bodyweight / horizontal (side view) ----------------
const prone = {
  headComp: -1.05, headClamp: 90, headPos: { x: -20, y: -90 }, armMode: { l: "ik", r: "ik" },
  shOff: { l: { x: 26, y: -58 }, r: { x: 32, y: -58 } }, hipOff: { l: { x: 20, y: -4 }, r: { x: 26, y: -4 } },
  kneeSign: { l: -1, r: -1 },
};
const pushKeys = (top, bot) => [
  [0.00, top], [0.12, {}], [0.50, bot], [0.58, {}], [0.90, top],
];
add({ id: "push-up", name: "Push-up", sub: "Horizontal", rep: 2.5, ...prone,
  defaults: { lfx: -66, rfx: -62, lfy: -7, rfy: -7, lfa: 15, rfa: 15, lhx: 62, rhx: 66, lhy: 0, rhy: 0 },
  keys: pushKeys({ hx: 0, hy: -74, t: 98 }, { hx: 2, hy: -56, t: 91 }),
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.45, 0.8]] });

add({ id: "deficit-push-up", name: "Deficit Push-up", sub: "Horizontal", rep: 2.5, ...prone,
  props: [{ type: "block", x: 66, w: 26, h: 13 }],
  defaults: { lfx: -66, rfx: -62, lfy: -7, rfy: -7, lfa: 15, rfa: 15, lhx: 62, rhx: 66, lhy: -13, rhy: -13 },
  keys: pushKeys({ hx: 0, hy: -82, t: 103 }, { hx: 3, hy: -56, t: 93 }),
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.45, 0.8]] });

add({ id: "close-grip-push-up", name: "Close-Grip Push-up", sub: "Horizontal", rep: 2.5, ...prone,
  shOff: { l: { x: 26, y: -50 }, r: { x: 32, y: -50 } },
  defaults: { lfx: -66, rfx: -62, lfy: -7, rfy: -7, lfa: 15, rfa: 15, lhx: 44, rhx: 48, lhy: 0, rhy: 0 },
  keys: pushKeys({ hx: 0, hy: -74, t: 98 }, { hx: 2, hy: -56, t: 91 }),
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.45, 0.8]] });

add({ id: "ring-push-up", name: "Ring Push-up", sub: "Horizontal", rep: 2.5, ...prone,
  props: [P => ({ type: "ring", x: P.arms.l.H.x, y: P.arms.l.H.y, ax: 60, ay: -300 }), P => ({ type: "ring", x: P.arms.r.H.x, y: P.arms.r.H.y, ax: 66, ay: -300 })],
  defaults: { lfx: -66, rfx: -62, lfy: -7, rfy: -7, lfa: 15, rfa: 15 },
  keys: [
    [0.00, { hx: 0, hy: -84, t: 102, lhx: 62, rhx: 66, lhy: -16, rhy: -16 }],
    [0.12, {}],
    [0.50, { hx: 2, hy: -62, t: 94, lhx: 60, rhx: 64, lhy: -15, rhy: -15 }],
    [0.58, {}],
    [0.90, { hx: 0, hy: -84, t: 102, lhx: 62, rhx: 66, lhy: -16, rhy: -16 }],
  ],
  fitExtra: [[60, -170]],
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.45, 0.8]] });

add({ id: "dips", name: "Dips", sub: "Vertical", view: "front", rep: 2.5,
  armMode: { l: "ik", r: "ik" }, legMode: { l: "fkw", r: "fkw" }, elbowSign: { l: -1, r: 1 },
  props: [{ type: "post", x: -50, y: -112 }, { type: "post", x: 50, y: -112 }],
  defaults: { lhx: -50, lhy: -114, rhx: 50, rhy: -114, lth: 6, rth: 6, lk: 0, rk: 0, lsf: 0.45, rsf: 0.45, lfa: -20, rfa: 20, lff: 0.8, rff: 0.8 },
  keys: [
    [0.00, { hx: 0, hy: -110, t: 180 }],
    [0.10, {}],
    [0.48, { hy: -76, pt: 18 }],
    [0.56, {}],
    [0.92, { hy: -110, pt: 0 }],
  ],
  shadow: { x: 0, rx: 60 }, effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.48, 0.8]] });

// floor press: supine, head on the left
add({ id: "floor-press", name: "Floor Press", sub: "Horizontal", rep: 2.5,
  headComp: -1.05, headClamp: 180, armMode: { l: "ik", r: "ik" }, elbowSign: { l: 1, r: 1 },
  hipOff: { l: { x: -30, y: 0 }, r: { x: -26, y: 0 } }, shOff: { l: { x: -26, y: -46 }, r: { x: -20, y: -46 } },
  bells: [{ hand: "r" }],
  defaults: { hx: 30, hy: -52, t: 270, lfx: 70, rfx: 76, lfy: 0, rfy: 0, b0a: -25 },
  keys: [
    [0.00, { lhx: -10, lhy: -4, rhx: -16, rhy: -82 }],
    [0.12, {}],
    [0.50, { rhx: -4, rhy: -44 }],
    [0.58, {}],
    [0.92, { rhx: -16, rhy: -82 }],
  ],
  shadow: { x: 10, rx: 110 }, effort: [0.7], sweat: sw(2.5, 0.74), strainAt: [[0.55, 0.85]] });

module.exports = L;

