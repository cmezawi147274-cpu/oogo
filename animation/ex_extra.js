// New Oog clips authored after the original export. Same format as the other ex_*.js files.
const { sw, mirror, halves, stepLegs } = require("./lib.js");
const L = [];
const adder = cat => d => (L.push(Object.assign({ cat }, d)), d);
const addPush = adder("push"), addPull = adder("pull"), addLegs = adder("legs-squat"), addHinge = adder("hinge");

// ======================= PUSH =======================
// double press: front view, a bell racked on each side (strict-press timing)
const FST = { hx: 0, hy: -57.5, t: 180, lfx: -18, rfx: 18, lfy: 0, rfy: 0, lfa: -75, rfa: 75 };
const RACK2 = { rhx: 38, rhy: -40, b0f: 140, lhx: -38, lhy: -40, b1f: -140 };
const LOCK2 = { rhx: 36, rhy: -131, b0f: 155, lhx: -36, lhy: -131, b1f: -155 };
addPush({ id: "double-press", name: "Double Press", sub: "Vertical", view: "front", rep: 2.5,
  armMode: { l: "ikb", r: "ikb" }, bells: [{ hand: "r" }, { hand: "l" }],
  keys: [
    [0.00, { ...FST, ...RACK2 }],
    [0.12, {}],
    [0.48, { ...LOCK2 }],
    [0.60, {}],
    [0.94, { ...RACK2 }],
  ],
  effort: [0.3], sweat: sw(2.5, 0.35), strainAt: [[0.15, 0.45]] });

// double floor press: supine, head on the left (floor-press rig), both arms press together
addPush({ id: "double-floor-press", name: "Double Floor Press", sub: "Horizontal", rep: 2.5,
  headComp: -1.05, headClamp: 180, armMode: { l: "ik", r: "ik" }, elbowSign: { l: 1, r: 1 },
  hipOff: { l: { x: -30, y: 0 }, r: { x: -26, y: 0 } }, shOff: { l: { x: -26, y: -46 }, r: { x: -20, y: -46 } },
  z: { arml: 5.4 }, bells: [{ hand: "l", z: 5.5 }, { hand: "r" }],  // far arm: over the torso, behind the head
  defaults: { hx: 30, hy: -52, t: 270, lfx: 70, rfx: 76, lfy: 0, rfy: 0, b0a: -25, b1a: -25 },
  keys: [
    [0.00, { lhx: -25, lhy: -76, rhx: -16, rhy: -82 }],
    [0.12, {}],
    [0.50, { lhx: -13, lhy: -38, rhx: -4, rhy: -44 }],
    [0.58, {}],
    [0.92, { lhx: -25, lhy: -76, rhx: -16, rhy: -82 }],
  ],
  shadow: { x: 10, rx: 110 }, effort: [0.7], sweat: sw(2.5, 0.74), strainAt: [[0.55, 0.85]] });

// archer push-up: seen head-on so the side shift and the straight "bow" arm read. Hands planted
// very wide; the torso is foreshortened (pt) into a puff behind the head with the shoulders at its
// sides; the legs run away from the camera, out of sight. Alternates sides each rep.
const archR = [
  [0.00, { hx: 0, hy: -25.5, t: 180 }],
  [0.10, {}],
  [0.46, { hx: 19, hy: -10, t: 177 }],       // chest to the right hand, left arm long and straight
  [0.58, {}],
  [0.92, { hx: 0, hy: -25.5, t: 180 }],
];
addPush({ id: "archer-push-up", name: "Archer Push-up", sub: "Horizontal", view: "front", rep: 5,
  armMode: { l: "ik", r: "ik" }, legMode: { l: "fkw", r: "fkw" }, elbowSign: { l: -1, r: 1 },
  headPos: { x: 0, y: -80 }, shOff: { l: { x: -46, y: -40 }, r: { x: 46, y: -40 } },
  defaults: { pt: 52, lhx: -80, rhx: 80, lhy: 0, rhy: 0, lth: 180, rth: 180, lk: 0, rk: 0, ltf: 0.3, rtf: 0.3, lsf: 0.01, rsf: 0.01, lff: 0.01, rff: 0.01 },
  keys: halves(archR, mirror(archR)),
  shadow: { x: 0, rx: 96 }, effort: [0.23, 0.73], sweat: [7.4, 9.0], strainAt: [[0.2, 0.4], [0.7, 0.9]] });

// bench dip: hands on the bench edge behind, feet forward, elbows bend straight back
addPush({ id: "bench-dip", name: "Bench Dip", sub: "Vertical", rep: 2.5,
  armMode: { l: "ik", r: "ik" },
  props: [{ type: "bench", x: -118, y: -46, w: 74 }],
  defaults: { lhx: -52, rhx: -48, lhy: -46, rhy: -46, lfx: 6, rfx: 12, lfy: 0, rfy: 0 },
  keys: [
    [0.00, { hx: -30, hy: -37, t: 180 }],
    [0.10, {}],
    [0.48, { hx: -32, hy: -14, t: 176 }],
    [0.56, {}],
    [0.92, { hx: -30, hy: -37, t: 180 }],
  ],
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.48, 0.8]] });

// ======================= PULL =======================
const DROW = { hx: -26, hy: -54, t: 122, lfx: -12, rfx: 2, lfy: 0, rfy: 0 };
addPull({ id: "double-row", name: "Double Row", sub: "Kettlebell", rep: 2.5,
  armMode: { l: "ik", r: "ik" }, elbowSign: { l: 1, r: 1 },
  bells: [{ hand: "l", z: 2.9 }, { hand: "r" }], defaults: { b0a: 0, b1a: 0 },
  keys: [
    [0.00, { ...DROW, lhx: 23, lhy: -36, rhx: 30, rhy: -32 }],
    [0.10, {}],
    [0.42, { lhx: -2, lhy: -70, rhx: 4, rhy: -66, t: 124 }],
    [0.54, {}],
    [0.90, { lhx: 23, lhy: -36, rhx: 30, rhy: -32, t: 122 }],
  ],
  effort: [0.3], sweat: sw(2.5, 0.35), strainAt: [[0.2, 0.55]] });

// ======================= LEGS =======================
// double front squat: side view so the upright torso and depth read (the front view is front-rack-squat)
const ST = { hx: 0, hy: -57.5, t: 180, lfx: -8, rfx: 2, lfy: 0, rfy: 0 };
addLegs({ id: "double-front-squat", name: "Double Front Squat", sub: "Squat", rep: 2.5,
  armMode: { l: "ikb", r: "ikb" }, bells: [{ hand: "l", z: 5.5 }, { hand: "r" }],   // far bell peeks out behind the near one
  defaults: { lhx: 34, lhy: -46, rhx: 42, rhy: -44, b0f: 150, b1f: 150 },
  keys: [
    [0.00, { ...ST }],
    [0.06, {}],
    [0.48, { hx: -13, hy: -27, t: 162 }],
    [0.56, {}],
    [0.92, { ...ST }],
  ],
  effort: [0.72], sweat: sw(2.5, 0.75), strainAt: [[0.5, 0.8]] });

// jump rope: front view. The rope prop is listed twice: the half behind Oog in props, the half
// in front (and the handles) in propsFront. Elbows stay by the ribs, hands out at hip height;
// the hands rise a touch while the rope is overhead and dip as it comes down (wrist turn).
const ropeBase = (o, top) => ({
  view: "front", armMode: { l: "ikb", r: "ikb" },
  props: [Object.assign({ type: "rope", side: -1 }, o)], propsFront: [Object.assign({ type: "rope", side: 1 }, o)],
  shadow: { x: 0, rx: 50 }, fitExtra: [[-92, top], [92, 4]],
});
const ropeHands = (x, y) => ({ lhx: -x, lhy: y, rhx: x, rhy: y });

addLegs({ id: "rope-skip", name: "Rope Skip", sub: "Conditioning", rep: 0.5, ...ropeBase({ turns: 1, phase: 0, r: 168 }, -244),
  keys: [
    [0.00, { hx: 0, hy: -58.5, t: 180, lfx: -13, rfx: 13, lfy: -2, rfy: -2, lfa: -66, rfa: 66, ...ropeHands(58, -14) }], // rope overhead, heels light
    [0.25, { hy: -61, lfy: -3.5, rfy: -3.5, lfa: -58, rfa: 58 }],                          // pop off the balls of the feet
    [0.50, { hy: -68.5, lfy: -11.5, rfy: -11.5, lfa: -46, rfa: 46, ...ropeHands(58, -10) }], // airborne: rope passes under
    [0.75, { hy: -61, lfy: -3.5, rfy: -3.5, lfa: -58, rfa: 58 }],                          // land softly
  ],
  effort: [0.25], sweat: [6.65, 8.9] });

addLegs({ id: "rope-double-under", name: "Double Under", sub: "Conditioning", rep: 0.625, ...ropeBase({ turns: 2, phase: 0, r: 168, trail: 2 }, -258),
  keys: [
    [0.00, { hx: 0, hy: -58, t: 180, lfx: -13, rfx: 13, lfy: -2, rfy: -2, lfa: -66, rfa: 66, ...ropeHands(60, -9) }], // loaded landing
    [0.13, { hy: -61, lfy: -3.5, rfy: -3.5, lfa: -58, rfa: 58 }],                          // drive up
    [0.25, { hy: -71, lfy: -14, rfy: -14, lfa: -44, rfa: 44 }],                            // first pass under
    [0.50, { hy: -77, lfy: -21, rfy: -21, lfa: -40, rfa: 40 }],                            // top of the jump, rope overhead
    [0.75, { hy: -71, lfy: -14, rfy: -14, lfa: -44, rfa: 44 }],                            // second pass under
    [0.87, { hy: -61, lfy: -3.5, rfy: -3.5, lfa: -58, rfa: 58 }],
  ],
  effort: [0.13], sweat: [6.6, 8.8], strainAt: [[0.1, 0.9]] });

addLegs({ id: "rope-high-knee", name: "Rope High Knee", sub: "Conditioning", rep: 10 / 12, ...ropeBase({ turns: 2, phase: 0.5, r: 168 }, -246),
  legMode: { l: "fkw", r: "fkw" }, flex: { l: 1, r: 1 },
  keys: [[0, { hx: 0, hy: -57.5, t: 180, ...ropeHands(58, -12) }]],
  post(c, p) {
    stepLegs(c, p, { high: true });
    const q = (2 * p) % 1, dq = Math.min(q, 1 - q);       // 0 at each foot switch
    c.hy -= 7 * Math.exp(-Math.pow(dq / 0.13, 2));         // quick hop at the switch: the rope passes under here
    c.lhy = c.rhy = -12 + 2 * Math.cos(4 * Math.PI * p);   // wrist turn, one per step
  },
  effort: [0.25, 0.75], sweat: [6.6, 8.9] });

// ======================= HINGE =======================
const SW = {
  top: { hx: 0, hy: -57.5, t: 184 },
  fall: { hx: 0, hy: -57.5, t: 178 },
  hike: { hx: -2, hy: -56, t: 166 },
  bot: { hx: -13, hy: -48, t: 124 },
  snap: { hx: -4, hy: -55, t: 164 },
  up: { hx: 0, hy: -57.5, t: 180 },
};
const swingKeys = (arms) => [
  [0.00, { ...SW.top, ...arms(86) }],
  [0.22, { ...SW.fall, ...arms(40) }],
  [0.34, { ...SW.hike, ...arms(5) }],
  [0.50, { ...SW.bot, ...arms(-40) }],          // bells ride a little higher behind: the near one clears the floor
  [0.64, { ...SW.snap, ...arms(10) }],
  [0.76, { ...SW.up, ...arms(55) }],
  [0.90, { ...SW.top, ...arms(86) }],
];
addHinge({ id: "double-swing", name: "Double Swing", sub: "Ballistic · Intermediate", rep: 2,
  defaults: { lfx: -8, rfx: 2, le: 4, re: 4 }, armMode: { l: "fkw", r: "fkw" },
  keys: swingKeys(a => ({ lua: a, rua: a })),
  bells: [{ hand: "l", z: 2.9 }, { hand: "r" }], effort: [0.64], motion: [{ bell: 1, win: [0.62, 0.86] }], sweat: sw(2, 0.66), strainAt: [[0.56, 0.7]] });

module.exports = L;
