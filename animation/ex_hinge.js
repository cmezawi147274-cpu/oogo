const { sw, mirror, halves } = require("./lib.js");
const L = [];
const add = d => (L.push(Object.assign({ cat: "hinge" }, d)), d);
const ST = { hx: 0, hy: -57.5, t: 180, lfx: -8, rfx: 2, lfy: 0, rfy: 0 };

// ======================= GRIND =======================
add({ id: "romanian-deadlift", name: "Romanian Deadlift", sub: "Grind", rep: 2.5,
  armMode: { l: "fkw", r: "fkw" }, bells: [{ hand: "l", z: 2.9 }, { hand: "r" }],
  defaults: { b0a: 0, b1a: 0, le: 0, re: 0 },
  keys: [
    [0.00, { ...ST, lua: 4, rua: 4 }],
    [0.08, {}],
    [0.48, { hx: -24, hy: -56, t: 129, lua: 0, rua: 0 }],
    [0.56, {}],
    [0.92, { ...ST, lua: 4, rua: 4 }],
  ],
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.5, 0.8]] });

add({ id: "kettlebell-deadlift", name: "Kettlebell Deadlift", sub: "Grind", rep: 2.5,
  armMode: { l: "ik", r: "ik" }, bells: [{ hand: "mid", z: 1.5 }],
  defaults: { b0a: 0, lfx: -12, rfx: 0 },
  keys: [
    [0.00, { hx: -5, hy: -57.5, t: 180, lhx: -2, lhy: -48, rhx: 0, rhy: -48 }],
    [0.10, {}],
    [0.48, { hx: -40, hy: -40, t: 138, lhx: -7, lhy: -27, rhx: -5, rhy: -27 }],
    [0.58, {}],
    [0.92, { hx: -5, hy: -57.5, t: 180, lhx: -2, lhy: -48, rhx: 0, rhy: -48 }],
  ],
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.56, 0.82]] });

add({ id: "single-leg-deadlift", name: "Single-Leg Deadlift", sub: "Grind", rep: 2.5,
  armMode: { l: "fkw", r: "fkw" }, legMode: { l: "fk", r: "ik" }, bells: [{ hand: "r" }],
  defaults: { b0a: 0, rfx: 2, lfa: 90 },
  keys: [
    [0.00, { hx: 0, hy: -57.5, t: 180, lth: 0, lk: 6, lua: -6, rua: 2, le: 10, re: 0, lfa: 70 }],
    [0.08, {}],
    [0.48, { hx: -10, hy: -58, t: 124, lth: 2, lk: 6, lua: -40, rua: 0, lfa: 20 }],
    [0.58, {}],
    [0.92, { hx: 0, hy: -57.5, t: 180, lth: 0, lk: 6, lua: -6, rua: 2, lfa: 70 }],
  ],
  effort: [0.74], sweat: sw(2.5, 0.78), strainAt: [[0.48, 0.8]] });

add({ id: "good-morning", name: "Good Morning", sub: "Grind", rep: 2.5,
  armMode: { l: "ikb", r: "ikb" }, bells: [{ hand: "mid" }],
  keys: [
    [0.00, { ...ST, lhx: 50, lhy: -40, rhx: 54, rhy: -40, b0a: 180 }],
    [0.08, {}],
    [0.48, { hx: -22, hy: -54, t: 106 }],
    [0.56, {}],
    [0.92, { ...ST }],
  ],
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.5, 0.8]] });

add({ id: "hip-thrust", name: "Hip Thrust", sub: "Grind", rep: 2.5,
  headComp: -1.05, headClamp: 180, armMode: { l: "ikb", r: "ikb" }, bells: [{ hand: "mid" }],
  hipOff: { l: { x: -40, y: 0 }, r: { x: -36, y: 0 } }, shOff: { l: { x: 10, y: -60 }, r: { x: 16, y: -60 } },
  props: [{ type: "bench", x: -148, y: -26, w: 70 }],
  defaults: { lfx: 14, rfx: 20, lfy: 0, rfy: 0, lhx: 42, lhy: -8, rhx: 46, rhy: -8, b0a: 0 },
  keys: [
    [0.00, { t: 247 }],
    [0.10, {}],
    [0.46, { t: 268 }],
    [0.58, {}],
    [0.92, { t: 247 }],
  ],
  post(c) { // pivot the upper back on the bench edge
    const phi = (180 - c.t) * Math.PI / 180, P = { x: -50, y: -66 }, B = { x: -92, y: -24 };
    c.hx = B.x - (P.x * Math.cos(phi) - P.y * Math.sin(phi));
    c.hy = B.y - (P.x * Math.sin(phi) + P.y * Math.cos(phi));
  },
  shadow: { x: -40, rx: 110 },
  effort: [0.32], sweat: sw(2.5, 0.4), strainAt: [[0.2, 0.6]] });

// ======================= BALLISTIC =======================
// side-view swing path (arm world angle)
const SW = {
  top: { hx: 0, hy: -57.5, t: 184 },
  fall: { hx: 0, hy: -57.5, t: 178 },
  hike: { hx: -2, hy: -56, t: 166 },
  bot: { hx: -13, hy: -48, t: 124 },
  snap: { hx: -4, hy: -55, t: 164 },
  up: { hx: 0, hy: -57.5, t: 180 },
};
const swingArm = (s, a) => ({ [s + "ua"]: a });
const swingKeys = (arms) => [
  [0.00, { ...SW.top, ...arms(86) }],
  [0.22, { ...SW.fall, ...arms(40) }],
  [0.34, { ...SW.hike, ...arms(5) }],
  [0.50, { ...SW.bot, ...arms(-34) }],
  [0.64, { ...SW.snap, ...arms(10) }],
  [0.76, { ...SW.up, ...arms(55) }],
  [0.90, { ...SW.top, ...arms(86) }],
];
const swingBase = { rep: 2, defaults: { lfx: -8, rfx: 2, le: 4, re: 4 }, armMode: { l: "fkw", r: "fkw" } };
add({ id: "two-hand-swing", name: "Two-Hand Swing", sub: "Ballistic · Beginner", ...swingBase,
  keys: swingKeys(a => ({ lua: a, rua: a })),
  bells: [{ hand: "mid" }], effort: [0.64], motion: [{ bell: 0, win: [0.62, 0.86] }], sweat: sw(2, 0.66), strainAt: [[0.56, 0.7]] });

add({ id: "one-hand-swing", name: "One-Hand Swing", sub: "Ballistic · Beginner", ...swingBase,
  keys: swingKeys(a => ({ rua: a, lua: a * 0.35 - 12, le: 14 })),
  bells: [{ hand: "r" }], effort: [0.64], motion: [{ bell: 0, win: [0.62, 0.86] }], sweat: sw(2, 0.66), strainAt: [[0.56, 0.7]] });

// hand-to-hand: switch at the float, two swings per cycle
const h2h = (() => {
  const A = swingKeys(a => ({ rua: a, lua: a > 60 ? a - 4 : -10, b0w: 1 }));
  A[0][1].lua = 82; A[6][1].lua = 82;           // free hand meets the bell at the top
  A[6][1].b0w = 0.5; A[0][1].b0w = 1;
  return A;
})();
add({ id: "hand-to-hand-swing", name: "Hand-to-Hand Swing", sub: "Ballistic · Intermediate", ...swingBase, rep: 4,
  keys: halves(h2h.map(([p, o], i) => [p, Object.assign({}, o, i === 0 ? { b0w: 0.5 } : {})]),
    h2h.map(([p, o], i) => {
      const n = {}; for (const k in o) { if (k === "lua") n.rua = o[k]; else if (k === "rua") n.lua = o[k]; else n[k] = o[k]; }
      n.b0w = i === 0 ? 0.5 : 0; return [p, n];
    })),
  bells: [{ hand: "swap" }], effort: [0.32, 0.82], motion: [{ bell: 0, win: [0.31, 0.43] }, { bell: 0, win: [0.81, 0.93] }],
  sweat: [6.6, 8.6], strainAt: [[0.28, 0.35], [0.78, 0.85]] });

// alternating: two bells in opposition
add({ id: "alternating-swing", name: "Alternating Swing", sub: "Ballistic · Intermediate", rep: 2.5,
  defaults: { lfx: -8, rfx: 2, le: 4, re: 4 }, armMode: { l: "fkw", r: "fkw" },
  bells: [{ hand: "l", z: 2.9 }, { hand: "r" }],
  keys: [
    [0.00, { hx: -9, hy: -49, t: 140, rua: 82, lua: -30 }],
    [0.14, { hx: -6, hy: -52, t: 150, rua: 50, lua: -10 }],
    [0.25, { hx: -2, hy: -56, t: 170, rua: 10, lua: 10 }],
    [0.36, { hx: -6, hy: -52, t: 150, rua: -10, lua: 50 }],
    [0.50, { hx: -9, hy: -49, t: 140, rua: -30, lua: 82 }],
    [0.64, { hx: -6, hy: -52, t: 150, rua: -10, lua: 50 }],
    [0.75, { hx: -2, hy: -56, t: 170, rua: 10, lua: 10 }],
    [0.86, { hx: -6, hy: -52, t: 150, rua: 50, lua: -10 }],
  ],
  effort: [0.25, 0.75], motion: [{ bell: 1, win: [0.8, 0.98] }, { bell: 0, win: [0.3, 0.48] }], sweat: [6.3, 8.8] });

// rack position in body frame (side view)
const RACK_R = { rhx: 42, rhy: -44 }, RACK_L = { lhx: 36, lhy: -44 };
const cleanKeys = (s, free) => {
  const R = s === "r" ? RACK_R : RACK_L, b = s === "r" ? "b0" : "b0";
  const o = (x) => Object.assign({}, x);
  return [
    [0.00, { ...SW.up, t: 182, [s + "m"]: 1, [s + "ua"]: 30, [b + "f"]: 150, ...R, ...free(-6) }],
    [0.16, {}],
    [0.30, { ...SW.fall, [s + "m"]: 0, [s + "ua"]: 30, [b + "f"]: 0, ...free(-4) }],
    [0.44, { ...SW.bot, [s + "ua"]: -34, ...free(-40) }],
    [0.57, { ...SW.snap, [s + "ua"]: 10, ...free(-10) }],
    [0.67, { ...SW.up, [s + "m"]: 0.55, [s + "ua"]: 40, [b + "f"]: 70 }],
    [0.77, { t: 182, [s + "m"]: 1, [b + "f"]: 150, ...free(-6) }],
  ];
};
add({ id: "clean", name: "Clean", sub: "Ballistic · Intermediate", rep: 2.5,
  armMode: { l: "fkw", r: "blend" }, defaults: { lfx: -8, rfx: 2, le: 10, re: 0 },
  keys: cleanKeys("r", a => ({ lua: a })),
  bells: [{ hand: "r" }], effort: [0.57], motion: [{ bell: 0, win: [0.55, 0.75] }], sweat: sw(2.5, 0.6), strainAt: [[0.5, 0.62]] });

add({ id: "ballistic-clean-variations", name: "Ballistic Clean Variations (Double Clean)", sub: "Ballistic · Advanced", rep: 2.5,
  armMode: { l: "blend", r: "blend" }, defaults: { lfx: -12, rfx: 4, le: 0, re: 0 },
  keys: cleanKeys("r", () => ({})).map(([p, o]) => {
    const n = Object.assign({}, o);
    if ("rm" in o) n.lm = o.rm; if ("rua" in o) n.lua = o.rua; if ("b0f" in o) n.b1f = o.b0f;
    if ("rhx" in o) { n.lhx = 34; n.lhy = -44; }
    if (p === 0.44) { n.hx = -15; n.hy = -43; n.t = 128; }
    return [p, n];
  }),
  bells: [{ hand: "l", z: 2.9 }, { hand: "r" }].reverse(), effort: [0.57], motion: [{ bell: 0, win: [0.55, 0.75] }], sweat: sw(2.5, 0.6), strainAt: [[0.5, 0.62]] });

add({ id: "dead-clean", name: "Dead Clean", sub: "Ballistic · Beginner", rep: 2.5,
  armMode: { l: "fkw", r: "blend" }, defaults: { lfx: -10, rfx: 2, le: 10, re: 0 },
  keys: [
    [0.00, { hx: -38, hy: -45, t: 140, rm: 0, rua: -2, b0f: 0, lua: -20 }],   // bell parked on the floor
    [0.10, {}],
    [0.26, { hx: -4, hy: -55, t: 166, rua: 12, lua: -8 }],
    [0.36, { hx: 0, hy: -57.5, t: 180, rm: 0.55, rua: 40, b0f: 70 }],
    [0.46, { t: 182, rm: 1, b0f: 150, lua: -6 }],
    [0.62, {}],
    [0.76, { t: 178, rm: 0, rua: 20, b0f: 0 }],
    [0.92, { hx: -38, hy: -45, t: 140, rua: -2, lua: -20 }],
  ],
  blendSpace: "body", bells: [{ hand: "r" }], effort: [0.26], motion: [{ bell: 0, win: [0.2, 0.44] }], sweat: sw(2.5, 0.3), strainAt: [[0.08, 0.3]] });

add({ id: "high-pull", name: "High Pull", sub: "Ballistic · Beginner", rep: 2, ...swingBase,
  armMode: { l: "fkw", r: "blend" }, elbowSign: { r: 1 },
  defaults: { lfx: -8, rfx: 2, le: 10, re: 0, rhx: 46, rhy: -60 },
  keys: [
    [0.00, { ...SW.up, t: 184, rm: 1, rua: 60, lua: -6 }],
    [0.12, {}],
    [0.26, { ...SW.fall, rm: 0, rua: 30 }],
    [0.36, { ...SW.hike, rua: 5 }],
    [0.50, { ...SW.bot, rua: -34, lua: -40 }],
    [0.64, { ...SW.snap, rua: 10, lua: -10 }],
    [0.76, { ...SW.up, rm: 0.6, rua: 50 }],
    [0.86, { t: 184, rm: 1, lua: -6 }],
  ],
  bells: [{ hand: "r" }], effort: [0.64], motion: [{ bell: 0, win: [0.62, 0.84] }], sweat: sw(2, 0.66), strainAt: [[0.56, 0.86]] });

// ---------------- front-view snatch family ----------------
// side "s" works; keys start in the backswing so hand switches can happen there.
const SNF = { lfx: -22, rfx: 22, lfa: -70, rfa: 70 };
function snatchKeys(opt = {}) {
  const both = opt.both, meet = opt.meet; // meet: free hand comes to the bell at the bottom
  const R = (x, y, f) => ({ rhx: x, rhy: y, b0f: f });
  const Lf = (x, y, f) => both ? { lhx: -x, lhy: y, b1f: -f } : {};
  const free = (k) => both ? {} : k;
  return [
    [0.00, { hx: 0, hy: -50, pt: 55, ...SNF, ...R(4, 46, 0), ...Lf(4, 46, 0), ...free(meet ? { lhx: -4, lhy: 46 } : { lhx: -24, lhy: 18 }) }],
    [0.06, { ...free({ lhx: -24, lhy: 18 }) }],
    [0.14, { hy: -57.5, pt: 6, ...R(12, -14, 0), ...Lf(12, -14, 0), ...free({ lhx: -30, lhy: 2 }) }],
    [0.24, { pt: 0, ...R(26, -72, -40), ...Lf(26, -72, -40) }],
    [0.33, { ...R(35, -125, -145), ...Lf(35, -118, -145) }],
    [0.40, { ...R(36, -131, -155), ...Lf(36, -131, -155) }],
    [0.60, {}],
    [0.70, { ...R(28, -76, -70), ...Lf(28, -76, -70) }],
    [0.80, { ...R(14, -26, 0), ...Lf(14, -26, 0) }],
    [0.94, { hy: -50, pt: 55, ...R(4, 46, 0), ...Lf(4, 46, 0), ...free(meet ? { lhx: -4, lhy: 46 } : { lhx: -24, lhy: 18 }) }],
  ];
}
const snatchBase = { view: "front", armMode: { l: "ikb", r: "ikb" }, effort: [0.14], strainAt: [[0.06, 0.24]] };
add({ id: "snatch", name: "Snatch", sub: "Ballistic · Intermediate", rep: 2.5, ...snatchBase,
  keys: snatchKeys(), bells: [{ hand: "r" }], motion: [{ bell: 0, win: [0.1, 0.36] }], sweat: sw(2.5, 0.45) });

add({ id: "double-snatch", name: "Double Snatch", sub: "Ballistic · Advanced", rep: 2.5, ...snatchBase,
  defaults: { lfx: -26, rfx: 26 },
  keys: snatchKeys({ both: true }).map(([p, o]) => [p, Object.assign({}, o, "rhx" in o ? { rhx: o.rhx + 6, lhx: o.lhx - 6 } : {})]),
  bells: [{ hand: "r" }, { hand: "l" }], motion: [{ bell: 0, win: [0.1, 0.36] }, { bell: 1, win: [0.1, 0.36] }], sweat: sw(2.5, 0.45) });

{
  const A = snatchKeys({ meet: true }).map(([p, o]) => [p, Object.assign({}, o, p === 0 ? { b0w: 1 } : {})]);
  const B = mirror(A);
  // switch the bell to the other hand while both hands are on it in the backswing
  A[A.length - 1][1].b0w = 1; B[0][1].b0w = 0;
  const keys = halves(A, B);
  keys.splice(keys.length / 2, 0); // keep order
  add({ id: "alternating-snatch", name: "Alternating Snatch", sub: "Ballistic · Advanced", rep: 5, ...snatchBase,
    effort: [0.07, 0.57], strainAt: [[0.03, 0.12], [0.53, 0.62]],
    keys, bells: [{ hand: "swap" }], motion: [{ bell: 0, win: [0.05, 0.18] }, { bell: 0, win: [0.55, 0.68] }], sweat: [7.4, 9.0] });
}

// ---------------- clean & jerk / long cycle (front view) ----------------
const FR = (x, y) => ({ rhx: x, rhy: y });
function cjKeys(both) {
  const K = (o) => {
    if (!both) return o;
    const n = Object.assign({}, o);
    if ("rhx" in o) { n.lhx = -o.rhx; n.lhy = o.rhy; }
    if ("b0f" in o) n.b1f = -o.b0f;
    return n;
  };
  const free = (x, y) => both ? {} : { lhx: x, lhy: y };
  return [
    [0.00, K({ hx: 0, hy: -50, pt: 55, ...SNF, ...FR(4, 46), b0f: 0, ...free(-24, 18) })],          // backswing
    [0.08, K({ hy: -57.5, pt: 6, ...FR(12, -14) })],                                                  // hip snap
    [0.15, K({ pt: 0, ...FR(38, -40), b0f: 140 })],                                                   // land in rack
    [0.24, {}],
    [0.31, K({ hy: -50, ...FR(38, -36) })],                                                           // dip
    [0.37, K({ hy: -59, ...FR(34, -100), b0f: 150 })],                                                // drive
    [0.42, K({ hy: -50, ...FR(36, -125), b0f: 155 })],                                                // re-dip under lockout
    [0.52, K({ hy: -57.5 })],                                                                         // stand
    [0.64, {}],
    [0.74, K({ hy: -54, ...FR(38, -40), b0f: 140 })],                                                 // back to rack
    [0.84, {}],
    [0.90, K({ ...FR(14, -26), b0f: 0, ...free(-24, 18) })],
  ];
}
add({ id: "clean-and-jerk", name: "Clean & Jerk", sub: "Ballistic · Advanced", view: "front", rep: 5,
  armMode: { l: "ikb", r: "ikb" }, keys: cjKeys(false), bells: [{ hand: "r" }],
  effort: [0.08, 0.37], strainAt: [[0.03, 0.12], [0.3, 0.45]], motion: [{ bell: 0, win: [0.04, 0.16] }], sweat: [6.9, 8.4] });
add({ id: "long-cycle", name: "Long Cycle (Double)", sub: "Ballistic · Advanced", view: "front", rep: 5,
  armMode: { l: "ikb", r: "ikb" }, defaults: { lfx: -26, rfx: 26 }, keys: cjKeys(true), bells: [{ hand: "r" }, { hand: "l" }],
  effort: [0.08, 0.37], strainAt: [[0.03, 0.12], [0.3, 0.45]], motion: [{ bell: 0, win: [0.04, 0.16] }, { bell: 1, win: [0.04, 0.16] }], sweat: [6.9, 8.4] });

module.exports = L;

