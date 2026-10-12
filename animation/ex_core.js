const { sw, mirror, halves, stepLegs } = require("./lib.js");
const L = [];
const add = d => (L.push(Object.assign({ cat: "core" }, d)), d);
const S = Math.sin, C = Math.cos, PI = Math.PI;

// ================= CARRIES & MARCHES (front view, stepping in place) =================
const walker = (high) => ({
  view: "front", rep: high ? 2.5 : 1.25, legMode: { l: "fkw", r: "fkw" }, armMode: { l: "ikb", r: "ikb" },
  flex: { l: 1, r: 1 }, shadow: { x: 0, rx: 52 }, scroll: high ? 0 : 80,
});
const RACK = { rhx: 38, rhy: -40, b0f: 140 }, RACKL = { lhx: -38, lhy: -40, b1f: -140 };
const LOCK = { rhx: 36, rhy: -131, b0f: 155 };
const freeSwing = (c, p, amt) => { c.lhx = -42 + amt * S(2 * PI * p); c.lhy = -6 - Math.abs(amt * 0.4 * S(2 * PI * p)); };

add({ id: "suitcase-carry", name: "Suitcase Carry", sub: "Carries", ...walker(false),
  bells: [{ hand: "r" }], keys: [[0, { hy: -57.5, t: 180, rhx: 48, rhy: -2, b0a: 0 }]],
  post(c, p) { stepLegs(c, p); freeSwing(c, p, 6); c.t = 180 + 0.6 * S(2 * PI * p); },
  effort: [0.25, 0.75], sweat: [6.4, 8.9] });
add({ id: "front-rack-carry", name: "Front Rack Carry", sub: "Carries", ...walker(false),
  bells: [{ hand: "r" }], keys: [[0, { hy: -57.5, t: 180, ...RACK }]],
  post(c, p) { stepLegs(c, p); freeSwing(c, p, 6); },
  effort: [0.25, 0.75], sweat: [6.4, 8.9] });
add({ id: "waiters-carry", name: "Waiter's Carry", sub: "Carries", ...walker(false),
  bells: [{ hand: "r" }], keys: [[0, { hy: -57.5, t: 180, rhx: 36, rhy: -131, b0a: 180 }]],
  post(c, p) { stepLegs(c, p); freeSwing(c, p, 6); },
  effort: [0.25, 0.75], sweat: [6.4, 8.9], strainAt: [[0, 1]] });
add({ id: "overhead-carry", name: "Overhead Carry", sub: "Carries", ...walker(false),
  bells: [{ hand: "r" }], keys: [[0, { hy: -57.5, t: 180, ...LOCK }]],
  post(c, p) { stepLegs(c, p); freeSwing(c, p, 6); },
  effort: [0.25, 0.75], sweat: [6.4, 8.9] });

add({ id: "offset-march", name: "Offset March", sub: "Marches", ...walker(true),
  bells: [{ hand: "r" }], keys: [[0, { hy: -57.5, t: 180, ...RACK }]],
  post(c, p) { stepLegs(c, p, { high: true }); freeSwing(c, p, 4); },
  effort: [0.25, 0.75], sweat: [6.6, 8.9] });
add({ id: "front-rack-march", name: "Front Rack March", sub: "Marches", ...walker(true),
  bells: [{ hand: "r" }, { hand: "l" }], keys: [[0, { hy: -57.5, t: 180, ...RACK, ...RACKL }]],
  post(c, p) { stepLegs(c, p, { high: true }); },
  effort: [0.25, 0.75], sweat: [6.6, 8.9] });
add({ id: "overhead-march", name: "Overhead March", sub: "Marches", ...walker(true),
  bells: [{ hand: "r" }], keys: [[0, { hy: -57.5, t: 180, ...LOCK }]],
  post(c, p) { stepLegs(c, p, { high: true }); freeSwing(c, p, 4); },
  effort: [0.25, 0.75], sweat: [6.6, 8.9], strainAt: [[0, 1]] });

// ================= STATIC =================
add({ id: "plank", name: "Plank", sub: "Static", rep: 5,
  headComp: -1.05, headClamp: 90, headPos: { x: -20, y: -90 }, armMode: { l: "ik", r: "ik" }, elbowSign: { l: 1, r: 1 },
  shOff: { l: { x: 30, y: -58 }, r: { x: 36, y: -58 } }, hipOff: { l: { x: 20, y: -4 }, r: { x: 26, y: -4 } }, kneeSign: { l: -1, r: -1 },
  defaults: { lfx: -66, rfx: -62, lfy: -7, rfy: -7, lfa: 15, rfa: 15, lhx: 86, rhx: 90, lhy: -3, rhy: -3 },
  keys: [[0.00, { hx: 0, hy: -66, t: 91 }], [0.50, { hx: 0, hy: -67.5, t: 92 }]],
  effort: [0.5], sweat: [4.2, 8.2], strainAt: [[0, 1]] });

add({ id: "side-plank", name: "Side Plank", sub: "Static", view: "front", rep: 5,
  headComp: -0.9, headClamp: 90, armMode: { l: "ik", r: "fkw" }, elbowSign: { l: 1 },
  bells: [],
  defaults: { lfx: 70, rfx: 74, lfy: -3, rfy: -3, lfa: 160, rfa: 160, rua: 180, re: 0 },
  keys: [[0.00, { hx: 4, hy: -46, t: 238, lhx: -40, lhy: -2 }], [0.50, { hx: 4, hy: -48, t: 239, lhx: -40, lhy: -2 }]],
  post(c) { // keep the support elbow under the shoulder: forearm flat on floor
  },
  effort: [0.5], sweat: [4.2, 8.2], strainAt: [[0, 1]], shadow: { x: 10, rx: 100 } });

const supine = {
  headComp: -1.05, headClamp: 180,
  hipOff: { l: { x: -26, y: 10 }, r: { x: -22, y: 10 } }, shOff: { l: { x: -22, y: -48 }, r: { x: -16, y: -48 } },
};
add({ id: "hollow-hold", name: "Hollow Hold", sub: "Static", rep: 5, ...supine,
  legMode: { l: "fk", r: "fk" }, armMode: { l: "fk", r: "fk" },
  defaults: { lua: 46, rua: 46, le: 0, re: 0, lk: 0, rk: 0, lfa: 70, rfa: 70 },
  keys: [[0.00, { hx: 26, hy: -54, t: 262, lth: 28, rth: 28 }], [0.50, { hx: 26, hy: -55, t: 263, lth: 26, rth: 26 }]],
  effort: [0.5], sweat: [4.2, 8.2], strainAt: [[0, 1]], shadow: { x: 0, rx: 110 } });

// ================= DYNAMIC =================
// hanging raises: torso faces you, legs drawn in profile so the lift reads clearly
const hangRaise = (keys) => ({
  view: "front", rep: 2.5, armMode: { l: "ik", r: "ik" }, legMode: { l: "fkw", r: "fkw" }, flex: { l: 1, r: 1 },
  props: [{ type: "barFront", x1: -92, x2: 92, y: -200 }],
  defaults: { lhx: -46, rhx: 46, lhy: -200, rhy: -200, hy: -80, lfa: 90, rfa: 90 },
  keys, shadow: { x: 0, rx: 46 }, effort: [0.42], sweat: sw(2.5, 0.45), strainAt: [[0.3, 0.6]],
});
add({ id: "hanging-knee-raise", name: "Hanging Knee Raise", sub: "Dynamic", ...hangRaise([
  [0.00, { lth: 2, rth: 2, lk: 4, rk: 4 }],
  [0.10, {}],
  [0.42, { lth: 104, rth: 104, lk: 112, rk: 112, hy: -84 }],
  [0.56, {}],
  [0.92, { lth: 2, rth: 2, lk: 4, rk: 4, hy: -80 }],
]) });
add({ id: "hanging-leg-raise", name: "Hanging Leg Raise", sub: "Dynamic", ...hangRaise([
  [0.00, { lth: 2, rth: 2, lk: 2, rk: 2 }],
  [0.10, {}],
  [0.44, { lth: 92, rth: 92, lk: 4, rk: 4, hy: -84 }],
  [0.56, {}],
  [0.92, { lth: 2, rth: 2, lk: 2, rk: 2, hy: -80 }],
]) });

const bugA = [
  [0.00, { lua: 90, rua: 90, lth: 84, rth: 84, lk: 88, rk: 88 }],
  [0.10, {}],
  [0.40, { rua: 166, lth: 16, lk: 4 }],
  [0.56, {}],
  [0.86, { rua: 90, lth: 84, lk: 88 }],
];
add({ id: "dead-bug", name: "Dead Bug", sub: "Dynamic", rep: 5, ...supine,
  legMode: { l: "fk", r: "fk" }, armMode: { l: "fk", r: "fk" }, z: { legl: 1, legr: 7, arml: 3, armr: 8, body: 5 },
  defaults: { hx: 26, hy: -52, t: 270, le: 0, re: 0, lfa: 90, rfa: 90 },
  keys: halves(bugA, bugA.map(([p, o]) => {
    const n = {}; for (const k in o) n[k.replace(/^l/, "#").replace(/^r/, "l").replace(/^#/, "r")] = o[k]; return [p, n];
  })),
  effort: [0.2, 0.7], sweat: [6.8, 9.0], strainAt: [[0.15, 0.32], [0.65, 0.82]], shadow: { x: 0, rx: 110 } });

const dogA = [
  [0.00, { rth: 90, rk: 90, lth: 90, lk: 90, lhx: 58, lhy: -1, rhx: 62, rhy: -1 }],
  [0.10, {}],
  [0.40, { rth: 4, rk: 2, lhx: 118, lhy: -66 }],
  [0.56, {}],
  [0.86, { rth: 90, rk: 90, lhx: 58, lhy: -1 }],
];
add({ id: "bird-dog", name: "Bird Dog", sub: "Dynamic", rep: 5,
  headComp: -1.05, headClamp: 90, headPos: { x: -18, y: -92 }, armMode: { l: "ik", r: "ik" }, legMode: { l: "fk", r: "fk" },
  elbowSign: { l: 1, r: 1 }, z: { arml: 7.5, armr: 8, legl: 1, legr: 2, body: 5, head: 6 },
  shOff: { l: { x: 2, y: -58 }, r: { x: 8, y: -58 } }, hipOff: { l: { x: 30, y: -4 }, r: { x: 34, y: -4 } },
  defaults: { hx: 0, hy: -62, t: 90, lfa: -100, rfa: -100 },
  keys: halves(dogA, dogA.map(([p, o]) => {
    const n = {}; for (const k in o) n[k.replace(/^l/, "#").replace(/^r/, "l").replace(/^#/, "r")] = o[k]; return [p, n];
  })),
  effort: [0.2, 0.7], sweat: [6.8, 9.0], strainAt: [[0.15, 0.32], [0.65, 0.82]] });

// ================= ROTATIONAL / ANTI-ROTATION (front view) =================
const FST = { hx: 0, hy: -57.5, t: 180, lfx: -18, rfx: 18, lfy: 0, rfy: 0, lfa: -75, rfa: 75 };
const front2 = { view: "front", armMode: { l: "ikb", r: "ikb" } };

add({ id: "halo", name: "Halo", sub: "Rotational", rep: 2.5, ...front2, bells: [{ hand: "mid" }],
  elbowSign: { l: 1, r: -1 },
  keys: [[0, { ...FST }]],
  post(c, p) {
    const th = 2 * PI * p; // 0 = in front of chin, goes around to the right
    const x = 44 * S(th), y = -66 - 30 * (1 - C(th)) / 2 - 8 * Math.abs(S(th));
    c.lhx = x - 4; c.rhx = x + 4; c.lhy = y; c.rhy = y; c.b0a = 180;
    const front = C(th) > -0.25;
    c.b0z = front ? 9 : 3.5; c.zl = front ? 8 : 3.4; c.zr = front ? 8 : 3.4;
  },
  effort: [0.5], sweat: sw(2.5, 0.55) });

add({ id: "around-the-world", name: "Around the World", sub: "Rotational", rep: 2.5, ...front2, bells: [{ hand: "swap" }],
  keys: [[0, { ...FST }]],
  post(c, p) {
    const th = 2 * PI * p; // 0 front, PI/2 right, PI behind, 3PI/2 left
    const bx = 58 * S(th), by = -26 - 6 * C(th);
    // right hand carries front->right->back, left hand carries back->left->front
    const rIn = p < 0.5, k = rIn ? 1 : 0;
    const mir = { x: -bx, y: by };
    c.rhx = rIn ? bx + 3 : mir.x + 3; c.rhy = rIn ? by : mir.y;
    c.lhx = rIn ? -bx - 3 : bx - 3; c.lhy = by;
    if (!rIn) { c.lhx = bx - 3; c.lhy = by; c.rhx = -bx + 3; c.rhy = by; }
    // hand-off blend near front (p~0/1) and back (p~0.5)
    const d0 = Math.min(p, 1 - p), d1 = Math.abs(p - 0.5);
    c.b0w = d1 < 0.04 ? 0.5 + (0.5 - p) * 12 : d0 < 0.04 ? (p < 0.5 ? 0.5 + p * 12 : 0.5 - (1 - p) * 12) : k;
    c.b0w = Math.max(0, Math.min(1, c.b0w));
    c.b0a = 0;
    const front = C(th) > -0.2;
    c.b0z = front ? 9 : 0.5; c.zl = front ? 8 : 0.6; c.zr = front ? 8 : 0.6;
  },
  effort: [0.5], sweat: sw(2.5, 0.55) });

// half-kneeling chop: profile legs (left knee down), bell by the horns
add({ id: "half-kneeling-chop", name: "Half-Kneeling Chop", sub: "Rotational", rep: 2.5, ...front2, legMode: { l: "fkw", r: "fkw" },
  bells: [{ hand: "mid" }],
  defaults: { lth: 0, lk: -90, lfa: -150, lff: 0.7, rth: 90, rk: 90, rfa: 90, b0a: 180 },
  keys: [
    [0.00, { hx: 0, hy: -30, t: 182, lhx: 40, lhy: -112, rhx: 48, rhy: -112 }],
    [0.12, {}],
    [0.46, { t: 172, lhx: -52, lhy: 8, rhx: -44, rhy: 8 }],
    [0.58, {}],
    [0.92, { t: 182, lhx: 40, lhy: -112, rhx: 48, rhy: -112 }],
  ],
  motion: [{ bell: 0, win: [0.16, 0.46] }], effort: [0.3], sweat: sw(2.5, 0.35), strainAt: [[0.2, 0.5]], shadow: { x: 0, rx: 64 } });

add({ id: "uppercut", name: "Uppercut", sub: "Rotational", rep: 2, ...front2, bells: [{ hand: "r" }],
  elbowSign: { r: 1 },
  keys: [
    [0.00, { ...FST, t: 176, rhx: -22, rhy: -2, lhx: -40, lhy: -50, b0a: 180, rfa: 40 }],
    [0.14, {}],
    [0.40, { t: 186, rhx: 40, rhy: -84, rfa: 75 }],
    [0.52, {}],
    [0.88, { t: 176, rhx: -22, rhy: -2, rfa: 40 }],
  ],
  motion: [{ bell: 0, win: [0.16, 0.42] }], effort: [0.3], sweat: sw(2, 0.35), strainAt: [[0.16, 0.45]] });

add({ id: "figure-8-to-hold", name: "Figure-8 to Hold", sub: "Rotational", rep: 5, ...front2, bells: [{ hand: "swap" }],
  defaults: { lfx: -24, rfx: 24, lfy: 0, rfy: 0, lfa: -70, rfa: 70 },
  keys: [
    [0.00, { hx: 0, hy: -57.5, t: 180, pt: 0, lhx: -4, lhy: -30, rhx: 4, rhy: -30, b0a: 180, b0w: 0.5, b0z: 9, zl: 7, zr: 7 }],
    [0.10, {}],
    [0.18, { hy: -52, pt: 45, rhx: 44, rhy: 30, lhx: -30, lhy: 10, b0a: 0, b0w: 1 }],                 // outside right leg
    [0.28, { rhx: 2, rhy: 44, lhx: -2, lhy: 44, b0w: 0.5, b0z: 0.5, zl: 0.6, zr: 0.6 }],              // between legs, hand-off
    [0.38, { lhx: -44, lhy: 30, rhx: 30, rhy: 10, b0w: 0, b0z: 9, zl: 7, zr: 7 }],                    // around left leg
    [0.48, { lhx: -2, lhy: 44, rhx: 2, rhy: 44, b0w: 0.5, b0z: 0.5, zl: 0.6, zr: 0.6 }],              // back through
    [0.58, { rhx: 44, rhy: 30, lhx: -30, lhy: 10, b0w: 1, b0z: 9, zl: 7, zr: 7 }],
    [0.68, { hy: -57.5, pt: 0, lhx: -4, lhy: -30, rhx: 4, rhy: -30, b0a: 180, b0w: 0.5 }],          // pop up to the hold
  ],
  effort: [0.66], motion: [{ bell: 0, win: [0.6, 0.7] }], sweat: [7.6, 8.9] });

const rotCleanR = [
  [0.00, { ...FST, lfx: -22, rfx: 22, t: 180, pt: 0, rhx: 38, rhy: -40, b0f: 140, lhx: -40, lhy: -6 }],
  [0.14, {}],
  [0.36, { hy: -50, pt: 45, t: 194, rhx: -30, rhy: 40, b0f: 0, lhx: -42, lhy: 0 }],      // bell back outside the left knee
  [0.52, { hy: -57.5, pt: 6, t: 182, rhx: 10, rhy: -20 }],                                // rotate and snap
  [0.62, { pt: 0, t: 180, rhx: 38, rhy: -40, b0f: 140, lhx: -40, lhy: -6 }],
];
add({ id: "rotational-clean", name: "Rotational Clean", sub: "Rotational", rep: 2.5, ...front2, bells: [{ hand: "r" }],
  keys: rotCleanR, effort: [0.5], motion: [{ bell: 0, win: [0.44, 0.62] }], sweat: sw(2.5, 0.55), strainAt: [[0.4, 0.6]] });

const rotDL = [
  [0.00, { ...FST, lfx: -24, rfx: 24, t: 180, pt: 0, lhx: -4, lhy: -4, rhx: 4, rhy: -4, b0a: 0 }],
  [0.10, {}],
  [0.42, { hy: -46, pt: 42, t: 164, hx: 8, lhx: 32, lhy: 58, rhx: 40, rhy: 58 }],      // reach to the bell outside the right foot
  [0.54, {}],
  [0.86, { hy: -57.5, pt: 0, t: 180, hx: 0, lhx: -4, lhy: -4, rhx: 4, rhy: -4 }],
];
add({ id: "rotational-deadlift", name: "Rotational Deadlift", sub: "Rotational", rep: 5, ...front2, bells: [{ hand: "mid" }],
  keys: halves(rotDL, mirror(rotDL)), effort: [0.35, 0.85], sweat: [7.2, 9.0], strainAt: [[0.27, 0.42], [0.77, 0.92]] });

add({ id: "windmill", name: "Windmill", sub: "Rotational", view: "front", rep: 10 / 3,
  armMode: { l: "ik", r: "fkw" }, bells: [{ hand: "r" }], headComp: -0.6,
  defaults: { lfx: -26, rfx: 20, lfy: 0, rfy: 0, lfa: -80, rfa: -40, rua: 172, re: 0, b0f: 155 },
  keys: [
    [0.00, { hx: 0, hy: -57.5, t: 180, lhx: -36, lhy: -60 }],
    [0.10, {}],
    [0.48, { hx: 16, hy: -54, t: 246, pt: 10, lhx: -32, lhy: -4 }],
    [0.58, {}],
    [0.92, { hx: 0, hy: -57.5, t: 180, pt: 0, lhx: -36, lhy: -60 }],
  ],
  effort: [0.72], sweat: sw(10 / 3, 0.75), strainAt: [[0.4, 0.8]] });

add({ id: "bent-press", name: "Bent Press", sub: "Rotational · Advanced", view: "front", rep: 5,
  armMode: { l: "ik", r: "ik" }, bells: [{ hand: "r" }], headComp: -0.6, elbowSign: { r: -1, l: 1 },
  defaults: { lfx: -26, rfx: 20, lfy: 0, rfy: 0, lfa: -80, rfa: -40 },
  keys: [
    [0.00, { hx: 0, hy: -57.5, t: 180, pt: 0, rhx: 40, rhy: -98, b0f: 140, lhx: -36, lhy: -60 }],
    [0.10, {}],
    [0.30, { hx: 10, hy: -56, t: 214, rhx: 14, rhy: -128, b0f: 150, lhx: -38, lhy: -36 }],
    [0.46, { hx: 16, hy: -52, t: 238, pt: 8, rhx: -14, rhy: -178, b0f: 155, lhx: -32, lhy: -10 }],   // under the bell, arm locked
    [0.56, {}],
    [0.74, { hx: 0, hy: -57.5, t: 180, pt: 0, rhx: 34, rhy: -188, lhx: -36, lhy: -60 }],              // stand up with lockout
    [0.82, {}],
    [0.96, { rhx: 40, rhy: -98, b0f: 140 }],
  ],
  effort: [0.4], sweat: [6.9, 8.9], strainAt: [[0.25, 0.75]] });

// arm bar: supine, bell locked out; the near knee crosses over to roll toward the far side
add({ id: "arm-bar", name: "Arm Bar", sub: "Rotational", rep: 5, ...supine,
  legMode: { l: "fk", r: "fk" }, armMode: { l: "fk", r: "fkw" }, bells: [{ hand: "r" }],
  defaults: { hx: 26, hy: -52, lua: 172, le: 0, rua: 180, re: 0, b0f: 155, lfa: 90, rfa: 90 },
  keys: [
    [0.00, { t: 270, lth: 0, lk: 0, rth: 0, rk: 0, zgr: 2 }],
    [0.10, {}],
    [0.26, { rth: 70, rk: 100, zgr: 7 }],                  // near knee up
    [0.42, { t: 280, hy: -56, rth: 90, rk: 80, zgr: 0.4 }],// knee drops across, roll
    [0.66, {}],
    [0.80, { t: 270, hy: -52, rth: 70, rk: 100, zgr: 7 }],
    [0.94, { rth: 0, rk: 0, zgr: 2 }],
  ],
  effort: [0.42], sweat: [7.4, 9.0], strainAt: [[0.4, 0.7]], shadow: { x: 0, rx: 110 } });

module.exports = L;

