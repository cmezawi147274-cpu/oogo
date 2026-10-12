const { sw, mirror, halves } = require("./lib.js");
const L = [];
const add = d => (L.push(Object.assign({ cat: "legs-squat" }, d)), d);

const ST = { hx: 0, hy: -57.5, t: 180, lfx: -8, rfx: 2, lfy: 0, rfy: 0 };
const GOB = { lhx: 50, lhy: -40, rhx: 54, rhy: -40, b0a: 180 };
const goblet = { armMode: { l: "ikb", r: "ikb" }, bells: [{ hand: "mid" }] };

// ---------------- squat family ----------------
add({
  id: "squat", name: "Squat", sub: "Squat", rep: 2.5, armMode: { l: "fkw", r: "fkw" },
  keys: [
    [0.00, { ...ST, lua: 8, rua: 8, le: 10, re: 10 }],
    [0.10, {}],
    [0.48, { hx: -17, hy: -27, t: 148, lua: 88, rua: 88, le: 0, re: 0 }],
    [0.56, {}],
    [0.92, { ...ST, lua: 8, rua: 8, le: 10, re: 10 }],
  ],
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.5, 0.78]],
});

const gobletSquat = (rep, down, holdEnd, up) => [
  [0.00, { ...ST, ...GOB }],
  [0.06, {}],
  [down, { hx: -15, hy: -27, t: 156 }],
  [holdEnd, {}],
  [up, { ...ST }],
];
add({ id: "goblet-squat", name: "Goblet Squat", sub: "Squat", rep: 2.5, ...goblet,
  keys: gobletSquat(2.5, 0.48, 0.56, 0.92), effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.5, 0.8]] });

add({ id: "tempo-goblet-squat", name: "Tempo Goblet Squat", sub: "Squat", rep: 5, ...goblet,
  keys: [
    [0.00, { ...ST, ...GOB }],
    [0.08, {}],
    [0.62, { hx: -15, hy: -27, t: 156 }],   // slow 3-count lower
    [0.70, {}],
    [0.86, { ...ST }],                       // stand up with intent
  ],
  effort: [0.78], sweat: [7.9], strainAt: [[0.45, 0.88]] });

add({ id: "pause-squat", name: "Pause Squat", sub: "Squat", rep: 10 / 3, ...goblet,
  keys: [
    [0.00, { ...ST, ...GOB }],
    [0.06, {}],
    [0.32, { hx: -15, hy: -27, t: 156 }],
    [0.66, { hx: -15, hy: -27.5, t: 156 }],  // hold the bottom
    [0.90, { ...ST }],
  ],
  effort: [0.76], sweat: sw(10 / 3, 0.8), strainAt: [[0.32, 0.86]] });

add({ id: "front-rack-squat", name: "Front Rack Squat", sub: "Squat", view: "front", rep: 2.5,
  armMode: { l: "ikb", r: "ikb" },
  bells: [{ hand: "l" }, { hand: "r" }],
  keys: [
    [0.00, { hx: 0, hy: -57, lfx: -24, rfx: 24, lfa: -65, rfa: 65, lhx: -40, lhy: -42, rhx: 40, rhy: -42, b0f: 140, b1f: -140, pt: 0 }],
    [0.08, {}],
    [0.48, { hy: -30, pt: 22 }],
    [0.56, {}],
    [0.92, { hy: -57, pt: 0 }],
  ],
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.5, 0.8]] });

add({ id: "cyclist-squat", name: "Cyclist Squat", sub: "Squat", rep: 2.5, ...goblet,
  defaults: { lfa: 62, rfa: 62 },
  props: [{ type: "wedge", x1: -14, x2: 18, h: 10 }],
  keys: [
    [0.00, { ...ST, hx: -4, hy: -64, lfx: -8, rfx: -6, lfy: -8, rfy: -8, ...GOB }],
    [0.08, {}],
    [0.48, { hx: -6, hy: -30, t: 170 }],
    [0.56, {}],
    [0.92, { hx: -4, hy: -64, t: 180 }],
  ],
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.5, 0.8]] });

// ---------------- lunges ----------------
const LST = { hx: 2, hy: -57.5, t: 180, lfx: -2, rfx: 6, lfy: 0, rfy: 0, lfa: 90 };
add({ id: "single-leg-reverse-lunge", name: "Single-Leg Reverse Lunge", sub: "Lunge", rep: 2.5, ...goblet,
  keys: [
    [0.00, { ...LST, ...GOB }],
    [0.08, {}],
    [0.24, { hx: -2, hy: -52, lfx: -32, lfy: -10, lfa: 40 }],
    [0.46, { hx: -10, hy: -32, t: 176, lfx: -52, lfy: -6, lfa: 20 }],
    [0.56, {}],
    [0.76, { hx: -2, hy: -52, t: 180, lfx: -30, lfy: -10, lfa: 40 }],
    [0.92, { ...LST }],
  ],
  effort: [0.68], sweat: sw(2.5, 0.72), strainAt: [[0.46, 0.76]] });

add({ id: "forward-lunge", name: "Forward Lunge", sub: "Lunge", rep: 2.5, ...goblet,
  keys: [
    [0.00, { ...ST, ...GOB }],
    [0.08, {}],
    [0.24, { hx: 6, hy: -55, rfx: 30, rfy: -12 }],
    [0.42, { hx: 14, hy: -32, t: 178, rfx: 46, rfy: 0, lfx: -10, lfy: -5, lfa: 25 }],
    [0.54, {}],
    [0.72, { hx: 6, hy: -55, t: 180, rfx: 30, rfy: -12, lfx: -8, lfy: 0, lfa: 90 }],
    [0.88, { ...ST }],
  ],
  effort: [0.62], sweat: sw(2.5, 0.68), strainAt: [[0.42, 0.7]] });

add({ id: "walking-lunge", name: "Walking Lunge", sub: "Lunge", rep: 2.5, ...goblet, scroll: 40,
  keys: [[0, { ...ST, ...GOB }]],
  post(c, p) {
    const half = p < 0.5 ? 0 : 1, h = (p * 2) % 1;
    const front = half === 0 ? "r" : "l", back = half === 0 ? "l" : "r";
    c[front + "fx"] = 25 - 50 * h; c[front + "fy"] = 0; c[front + "fa"] = 90;
    if (h < 0.55) {
      c[back + "fx"] = -25 - 50 * h; c[back + "fy"] = -Math.min(1, h / 0.15) * 5;
      c[back + "fa"] = 90 - 70 * Math.sin(Math.min(1, h / 0.5) * Math.PI / 2);
    } else {
      const s = (h - 0.55) / 0.45, e = s * s * (3 - 2 * s);
      c[back + "fx"] = -52.5 + 77.5 * e; c[back + "fy"] = -5 - 14 * Math.sin(Math.PI * s) + 5 * e;
      c[back + "fa"] = 20 + 70 * e;
    }
    const depth = h < 0.35 ? h / 0.35 : h < 0.75 ? 1 - (h - 0.35) / 0.4 : 0;
    const d = depth * depth * (3 - 2 * depth);
    c.hy = (h < 0.75 ? -51 : -51 - 5 * Math.sin(Math.PI * (h - 0.75) / 0.25)) + 21 * d;
    c.hx = -6 * d;
    c.t = 180 - 3 * d;
  },
  effort: [0.2, 0.7], sweat: [6.6, 8.9], strainAt: [[0.12, 0.3], [0.62, 0.8]] });

add({ id: "bulgarian-split-squat", name: "Bulgarian Split Squat", sub: "Lunge", rep: 2.5, ...goblet,
  props: [{ type: "bench", x: -104, y: -30, w: 52 }],
  defaults: { lfa: -80 },
  keys: [
    [0.00, { hx: -10, hy: -52, t: 178, rfx: 14, rfy: 0, lfx: -66, lfy: -36, ...GOB }],
    [0.08, {}],
    [0.48, { hx: -18, hy: -30, t: 172 }],
    [0.56, {}],
    [0.92, { hx: -10, hy: -52, t: 178 }],
  ],
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.48, 0.8]] });

add({ id: "step-up", name: "Step-Up", sub: "Lunge", rep: 10 / 3, armMode: { l: "fkw", r: "fkw" },
  bells: [{ hand: "l", z: 2.5 }, { hand: "r" }],
  props: [{ type: "box", x: 12, y: -28, w: 64, h: 28 }],
  defaults: { lua: 2, rua: 2, le: 4, re: 4, b0a: 0, b1a: 0 },
  keys: [
    [0.00, { hx: -16, hy: -57.5, t: 180, lfx: -24, lfy: 0, rfx: -12, rfy: 0 }],
    [0.06, {}],
    [0.16, { rfx: 14, rfy: -44 }],
    [0.24, { rfx: 34, rfy: -28 }],
    [0.48, { hx: 30, hy: -85.5, t: 178, lfx: 6, lfy: -30 }],
    [0.54, { lfx: 24, lfy: -28, t: 180 }],
    [0.62, {}],
    [0.72, { lfx: -4, lfy: -18 }],
    [0.82, { hx: -16, hy: -57.5, lfx: -24, lfy: 0 }],
    [0.90, { rfx: 12, rfy: -40 }],
    [0.97, { rfx: -12, rfy: 0 }],
  ],
  effort: [0.38], sweat: sw(10 / 3, 0.4), strainAt: [[0.24, 0.5]] });

add({ id: "skater-squat", name: "Skater Squat Progression", sub: "Lunge", rep: 2.5,
  armMode: { l: "fkw", r: "fkw" }, legMode: { l: "fk", r: "ik" },
  keys: [
    [0.00, { hx: 2, hy: -57.5, t: 180, rfx: 6, lth: -10, lk: 85, lfa: 10, lua: 30, rua: 30, le: 10, re: 10 }],
    [0.08, {}],
    [0.48, { hx: -10, hy: -32, t: 140, lth: 30, lk: 100, lua: 88, rua: 88, le: 0, re: 0 }],
    [0.56, {}],
    [0.92, { hx: 2, hy: -57.5, t: 180, lth: -10, lk: 85, lua: 30, rua: 30, le: 10, re: 10 }],
  ],
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.48, 0.8]] });

// ---------------- mobility (front view) ----------------
const FG = { lhx: -4, lhy: -28, rhx: 4, rhy: -28, b0a: 180 };
const cossackR = [
  [0.00, { hx: 0, hy: -50, t: 180, lfx: -54, rfx: 54, lfy: 0, rfy: 0, lfa: -90, rfa: 90, pt: 0, ...FG }],
  [0.08, {}],
  [0.44, { hx: 40, hy: -24, t: 176, lfa: 180, pt: 18 }],
  [0.60, {}],
  [0.94, { hx: 0, hy: -50, t: 180, lfa: -90, pt: 0 }],
];
add({ id: "cossack-squat", name: "Cossack Squat", sub: "Mobility", view: "front", rep: 5, ...goblet,
  keys: halves(cossackR, mirror(cossackR)), effort: [0.3, 0.8], sweat: [8.3], strainAt: [[0.2, 0.36], [0.7, 0.86]] });

const latR = [
  [0.00, { hx: 0, hy: -57.5, t: 180, lfx: -12, rfx: 12, lfy: 0, rfy: 0, lfa: -90, rfa: 90, pt: 0, ...FG }],
  [0.08, {}],
  [0.22, { hx: 6, hy: -56, rfx: 36, rfy: -10 }],
  [0.36, { hx: 26, hy: -36, rfx: 52, rfy: 0, pt: 26, t: 178 }],
  [0.58, {}],
  [0.74, { hx: 6, hy: -56, rfx: 36, rfy: -10, pt: 0, t: 180 }],
  [0.90, { hx: 0, hy: -57.5, rfx: 12, rfy: 0 }],
];
add({ id: "lateral-lunge", name: "Lateral Lunge", sub: "Mobility", view: "front", rep: 5, ...goblet,
  keys: halves(latR, mirror(latR)), effort: [0.33, 0.83], sweat: [8.4], strainAt: [[0.18, 0.32], [0.68, 0.82]] });

module.exports = L;

