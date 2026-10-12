#!/usr/bin/env node
// Exports the Oog clip defs for the iOS app.
//
//   node animation/export.js
//
// Writes (paths relative to the repo root):
//   ios-oogo/Oogo/Resources/OogClips.json          data for the Swift renderer
//   ios-oogo/OogoTests/Fixtures/OogGolden.json     reference values from the real JS engine
//
// The Swift side is data driven. Function-valued def fields cannot be serialized, so
// they are flagged AND baked into sampled tables (see postTable, shadowTable and the
// "fn" prop entries below). Re-run this whenever any ex_*.js changes.

const fs = require("fs");
const path = require("path");
const { engine, defs } = require("./index.js");
const mapMovement = require("./movement-map.js");

const REPO_ROOT = path.resolve(__dirname, "..");
const CLIPS_OUT = path.join(REPO_ROOT, "ios-oogo", "Oogo", "Resources", "OogClips.json");
const GOLDEN_OUT = path.join(REPO_ROOT, "ios-oogo", "OogoTests", "Fixtures", "OogGolden.json");
const SWIFT_MODELS = path.join(REPO_ROOT, "ios-oogo", "Oogo", "Models", "OogoModels.swift");

const LOOP = engine.LOOP; // 10 seconds
const TABLE_N = 240;      // samples per baked table
const SANITY_SAMPLES = 50;
const GOLDEN_TIMES = [0, 0.37, 1.13, 2.5, 4.05, 5.55, 6.6, 7.77, 9.3, 9.95];
const GOLDEN_SVG_T = 2.5;

// ---------- helpers ----------
const roundTo = (v, nd) => { const k = Math.pow(10, nd); const r = Math.round(v * k) / k; return r === 0 ? 0 : r; };
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const isPlainObject = v => v !== null && typeof v === "object" && !Array.isArray(v);

function mulberry32(seed) {
  return function () {
    seed |= 0; seed = (seed + 0x6D2B79F5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Deep-copies plain data, rounding numbers to nd decimals. Functions are an error here:
// callers must handle them explicitly before calling.
function clean(v, nd, where) {
  if (typeof v === "number") {
    if (!Number.isFinite(v)) throw new Error("non-finite number at " + where);
    return roundTo(v, nd);
  }
  if (typeof v === "function") throw new Error("unexpected function at " + where);
  if (Array.isArray(v)) return v.map((x, i) => clean(x, nd, where + "[" + i + "]"));
  if (isPlainObject(v)) {
    const o = {};
    for (const k of Object.keys(v)) {
      if (v[k] === undefined) continue;
      o[k] = clean(v[k], nd, where + "." + k);
    }
    return o;
  }
  return v; // string, boolean, null
}

function pretty(n) { return n >= 1024 * 1024 ? (n / 1024 / 1024).toFixed(2) + " MB" : (n / 1024).toFixed(1) + " KB"; }

// ---------- baked tables ----------

// def.post(c, p, tt) mutates the channel object after the keyframe track is sampled.
// Bake the channels it changes into a per-phase table (one rep, periodic).
function buildPostTable(def, clip, noPostClip) {
  const rep = def.rep || 2;
  const n = TABLE_N;
  const withPost = [], without = [];
  for (let i = 0; i < n; i++) {
    const t = (i / n) * rep;
    withPost.push(clip.pose(t).c);
    without.push(noPostClip.pose(t).c);
  }
  const names = new Set();
  withPost.forEach((a, i) => {
    const b = without[i];
    for (const k of Object.keys(a)) {
      if (typeof a[k] !== "number" || !Number.isFinite(a[k])) throw new Error(def.id + ": post produced non-numeric channel " + k);
      if (!(k in b) || Math.abs(a[k] - b[k]) > 1e-9) names.add(k);
    }
  });
  const channels = [...names].sort();
  const values = channels.map(ch => withPost.map(c => roundTo(c[ch], 4)));
  // Channels that jump (z-order switches and the like) are flat with a few abrupt steps.
  // Linear interpolation is wrong across a jump, so flag them: hold the previous sample instead.
  const stepChannels = channels.filter((ch, ci) => {
    const v = values[ci];
    let nonZero = 0, biggest = 0;
    for (let i = 0; i < n; i++) {
      const d = Math.abs(v[(i + 1) % n] - v[i]);
      if (d > 0) nonZero++;
      biggest = Math.max(biggest, d);
    }
    return nonZero <= 4 && biggest > 0.5;
  });
  const table = { n, channels, values };
  if (stepChannels.length) table.stepChannels = stepChannels;
  return table;
}

// def.shadow(P) -> {x, rx}, sampled over the whole 10 s loop.
function buildShadowTable(def, clip) {
  const n = TABLE_N, x = [], rx = [];
  for (let i = 0; i < n; i++) {
    const s = def.shadow(clip.pose((i * LOOP) / n));
    if (!Number.isFinite(s.x) || !Number.isFinite(s.rx)) throw new Error(def.id + ": shadow() returned non-finite");
    x.push(roundTo(s.x, 4)); rx.push(roundTo(s.rx, 4));
  }
  return { n, x, rx };
}

// props / propsFront entry that is a function of the pose -> sampled over the loop.
function buildPropTable(def, clip, fn, label) {
  const n = TABLE_N;
  const base = {}, fields = {};
  const baseSeen = {};
  for (let i = 0; i < n; i++) {
    const o = fn(clip.pose((i * LOOP) / n));
    for (const k of Object.keys(o)) {
      const v = o[k];
      if (typeof v === "number") {
        if (!Number.isFinite(v)) throw new Error(def.id + " " + label + ": non-finite field " + k);
        (fields[k] = fields[k] || []).push(roundTo(v, 4));
      } else {
        const s = JSON.stringify(v);
        if (!(k in baseSeen)) { baseSeen[k] = s; base[k] = v; }
        else if (baseSeen[k] !== s) throw new Error(def.id + " " + label + ": non-numeric field " + k + " changes over time");
      }
    }
  }
  for (const k of Object.keys(fields)) {
    if (fields[k].length !== n) throw new Error(def.id + " " + label + ": numeric field " + k + " is not present in every sample");
  }
  return { n, base, fields };
}

// ---------- clip serialization ----------
const summary = { post: [], shadowFn: [], fnProps: [], maxPostErr: {} };

function serializeDef(def) {
  const clip = engine.makeClip(def);
  const out = {};
  out.id = def.id;
  out.movementId = mapMovement(def);
  const aliases = mapMovement.aliasesFor(def).filter(a => !defs.some(d => mapMovement(d) === a));
  if (aliases.length) out.movementAliases = aliases;
  out.cat = def.cat;
  out.name = def.name;

  let noPostClip = null;
  for (const k of Object.keys(def)) {
    if (k === "id" || k === "cat" || k === "name") continue;
    const v = def[k];
    if (v === undefined) continue;
    if (k === "post") {
      if (typeof v === "function") {
        out.post = true;
        noPostClip = engine.makeClip(Object.assign({}, def, { post: undefined }));
        out.postTable = buildPostTable(def, clip, noPostClip);
        summary.post.push(def.id);
      } else if (v) {
        throw new Error(def.id + ": post is not a function");
      }
    } else if (k === "shadow") {
      if (typeof v === "function") {
        out.shadowFn = true;
        out.shadowTable = buildShadowTable(def, clip);
        summary.shadowFn.push(def.id);
      } else {
        out.shadow = clean(v, 4, def.id + ".shadow");
      }
    } else if (k === "props" || k === "propsFront") {
      if (!Array.isArray(v)) throw new Error(def.id + "." + k + " is not an array");
      out[k] = v.map((e, i) => {
        if (typeof e === "function") {
          summary.fnProps.push(def.id + "." + k + "[" + i + "]");
          return { type: "fn", index: i, table: buildPropTable(def, clip, e, k + "[" + i + "]") };
        }
        return clean(e, 4, def.id + "." + k + "[" + i + "]");
      });
    } else if (k === "rep") {
      // Never round rep: 10/3 rounded to 3.3333 drifts the phase across the 10 s loop.
      if (typeof v !== "number" || !Number.isFinite(v)) throw new Error(def.id + ".rep is not a number");
      out.rep = v;
    } else {
      out[k] = clean(v, 6, def.id + "." + k); // throws on any other function field
    }
  }
  return { out, clip, noPostClip };
}

// ---------- postTable sanity check ----------
function interp(arr, p) {
  const n = arr.length;
  const x = p * n, fl = Math.floor(x);
  const i0 = ((fl % n) + n) % n, i1 = (i0 + 1) % n, f = x - fl;
  return arr[i0] * (1 - f) + arr[i1] * f;
}

function checkPostTable(def, entry, clip, noPostClip) {
  const rand = mulberry32(0x0A66 + def.id.length);
  const rep = def.rep || 2;
  const cycles = Math.max(1, Math.floor(LOOP / rep + 1e-9));
  const tb = entry.postTable;
  const stepSet = new Set(tb.stepChannels || []);

  // Rebuild the channels from the table (what the Swift side does) and compare with the engine.
  function errAt(ph, cyc, tableOnly) {
    const t = (cyc + ph) * rep;
    const real = clip.pose(t);
    const rebuilt = tableOnly ? {} : Object.assign({}, noPostClip.pose(t).c);
    tb.channels.forEach((ch, ci) => { rebuilt[ch] = interp(tb.values[ci], real.p); });
    let worst = 0, worstCh = "", smooth = 0;
    const keys = tableOnly ? tb.channels : new Set([...Object.keys(real.c), ...Object.keys(rebuilt)]);
    for (const key of keys) {
      const rv = real.c[key], bv = rebuilt[key];
      const err = (rv === undefined || bv === undefined) ? Infinity : Math.abs(rv - bv);
      if (err > worst) { worst = err; worstCh = key; }
      if (!stepSet.has(key)) smooth = Math.max(smooth, err);
    }
    return { worst, worstCh, smooth };
  }

  // 1) the requested check: SANITY_SAMPLES random phases, every channel
  let worst = 0, worstCh = "";
  for (let k = 0; k < SANITY_SAMPLES; k++) {
    // a few phases are pinned next to the wrap point to prove the table is periodic
    const ph = k < 3 ? [0.99999, 0.9999, 0.995][k] : rand();
    const r = errAt(ph, Math.floor(rand() * cycles) % cycles, false);
    if (r.worst > worst) { worst = r.worst; worstCh = r.worstCh; }
  }
  // 2) extra diagnostics: dense sweep of the table channels
  const DENSE = 1000;
  let over = 0, smoothMax = 0;
  for (let k = 0; k < DENSE; k++) {
    const r = errAt((k + 0.5) / DENSE, 0, true);
    if (r.worst > 0.05) over++;
    smoothMax = Math.max(smoothMax, r.smooth);
  }
  summary.maxPostErr[def.id] = {
    err: worst, channel: worstCh, channels: tb.channels.length,
    steps: tb.stepChannels || [], denseOverPct: (100 * over) / DENSE, denseSmoothMax: smoothMax,
  };
}

// ---------- golden fixture ----------
function pt(p) { return { x: p.x, y: p.y }; }

function goldenFor(def, clip) {
  const F = clip.fit();
  const samples = GOLDEN_TIMES.map(t => {
    const P = clip.pose(t);
    // leaf lag, exactly as svgInner computes it
    const pa = clip.pose(t - 0.06), pb = clip.pose(t - 0.16);
    let leaf = -(pa.lean - pb.lean) * 1.6 + (pa.hip.x - pb.hip.x) * -0.6 + (pa.hip.y - pb.hip.y) * 0.5;
    leaf = clamp(leaf, -24, 24) + 3;
    // heart pulse
    let beat = 0;
    (def.effort || []).forEach(e => {
      let d = P.p - e; d -= Math.round(d);
      beat = Math.max(beat, Math.exp(-Math.pow(d / 0.05, 2)));
    });
    // face
    const face = def.strainAt
      ? (def.strainAt.some(([a, b]) => P.p >= a && P.p <= b) ? "strain" : "calm")
      : (def.face || "calm");
    // shadow
    let sx, srx;
    if (def.shadow) {
      const s = typeof def.shadow === "function" ? def.shadow(P) : def.shadow;
      sx = s.x; srx = s.rx;
    } else {
      const xs = [P.hip.x, P.legs.l.A.x, P.legs.r.A.x, P.W(0, -40).x];
      sx = xs.reduce((a, b) => a + b, 0) / xs.length;
      srx = clamp((Math.max(...xs) - Math.min(...xs)) / 2 + 42, 44, 110);
    }
    const c = {};
    for (const k of Object.keys(P.c)) {
      if (typeof P.c[k] === "number" && Number.isFinite(P.c[k])) c[k] = P.c[k];
      else throw new Error(def.id + ": non-numeric channel " + k + " at t=" + t);
    }
    const leg = s => ({ H: pt(P.legs[s].H), K: pt(P.legs[s].K), A: pt(P.legs[s].A), F: pt(P.legs[s].F) });
    const arm = s => ({ S: pt(P.arms[s].S), E: pt(P.arms[s].E), H: pt(P.arms[s].H) });
    return {
      t, p: P.p, T: P.T, kp: P.kp, lean: P.lean, headRel: P.headRel,
      hip: pt(P.hip),
      legs: { l: leg("l"), r: leg("r") },
      arms: { l: arm("l"), r: arm("r") },
      bells: P.bells.map(b => ({ x: b.x, y: b.y, a: b.a, z: b.z, op: b.op })),
      c,
      leaf, beat, face,
      shadow: { x: sx, rx: srx },
    };
  });
  const golden = {
    id: def.id, cat: def.cat,
    fit: { S: F.S, ox: F.ox, oy: F.oy },
    samples,
    svg: clip.innerAt(GOLDEN_SVG_T),
  };
  return clean(golden, 6, def.id + ".golden");
}

// ---------- main ----------
const clips = [];
const golden = [];
const ids = new Set();
for (const def of defs) {
  const key = def.cat + ":" + def.id;
  if (ids.has(key)) throw new Error("duplicate def " + key);
  ids.add(key);
  const { out, clip, noPostClip } = serializeDef(def);
  clips.push(out);
  if (out.postTable) checkPostTable(def, out, clip, noPostClip);
  golden.push(goldenFor(def, clip));
}

fs.mkdirSync(path.dirname(CLIPS_OUT), { recursive: true });
fs.mkdirSync(path.dirname(GOLDEN_OUT), { recursive: true });

// Clips: version, loop length, then one entry per def.
const clipsJSON = JSON.stringify({ version: 1, loop: LOOP, clips });
fs.writeFileSync(CLIPS_OUT, clipsJSON);
const goldenJSON = JSON.stringify(golden);
fs.writeFileSync(GOLDEN_OUT, goldenJSON);

// ---------- report ----------
const byCat = {};
clips.forEach(c => { (byCat[c.cat] = byCat[c.cat] || []).push(c); });
console.log("OogClips.json : " + clips.length + " clips, " + pretty(Buffer.byteLength(clipsJSON)) + "  -> " + path.relative(REPO_ROOT, CLIPS_OUT));
console.log("OogGolden.json: " + golden.length + " clips x " + GOLDEN_TIMES.length + " samples, " + pretty(Buffer.byteLength(goldenJSON)) + "  -> " + path.relative(REPO_ROOT, GOLDEN_OUT));
console.log("\nclips per category: " + Object.keys(byCat).map(k => k + "=" + byCat[k].length).join(", "));
console.log("\nids with post functions (" + summary.post.length + "): " + summary.post.join(", "));
console.log("ids with shadow functions (" + summary.shadowFn.length + "): " + (summary.shadowFn.join(", ") || "none"));
console.log("function props (" + summary.fnProps.length + "): " + (summary.fnProps.join(", ") || "none"));

console.log("\npostTable sanity check (max abs error over " + SANITY_SAMPLES + " phases, table linear interpolation vs real pose().c):");
let worstAll = 0;
for (const id of summary.post) {
  const m = summary.maxPostErr[id];
  worstAll = Math.max(worstAll, m.err);
  console.log("  " + id.padEnd(22) + m.err.toExponential(2) + "  (worst channel " + m.channel + ", table channels " + m.channels + ")" +
    (m.err > 0.05 ? "  <-- ABOVE 0.05" : "") +
    (m.err > 0.05 || m.denseOverPct > 0 ? "\n" + " ".repeat(24) + "dense sweep: " + m.denseOverPct.toFixed(2) + "% of phases > 0.05, max error excluding step channels " + m.denseSmoothMax.toExponential(2) + (m.steps.length ? ", step channels " + m.steps.join(",") : "") : ""));
}
if (summary.post.length) console.log("  worst overall: " + worstAll.toExponential(2) + (worstAll > 0.05 ? "  <-- ABOVE 0.05" : "  (ok, < 0.05)"));

const unmapped = clips.filter(c => c.movementId === null).map(c => c.cat + ":" + c.id);
const claimed = new Set();
clips.forEach(c => { if (c.movementId) claimed.add(c.movementId); (c.movementAliases || []).forEach(a => claimed.add(a)); });
const noDef = mapMovement.APP_IDS.filter(i => !claimed.has(i));
console.log("\ndefs with no app movement id (" + unmapped.length + "): " + (unmapped.join(", ") || "none"));
console.log("app movement ids with no def (" + noDef.length + "): " + (noDef.join(", ") || "none"));
const aliased = clips.filter(c => c.movementAliases).map(c => c.id + " also serves " + c.movementAliases.join(", "));
if (aliased.length) console.log("aliases: " + aliased.join("; "));

// Drift check against the Swift movement library (read-only).
try {
  const swift = fs.readFileSync(SWIFT_MODELS, "utf8");
  const swiftIds = [...swift.matchAll(/Movement\(\s*id:\s*"([^"]+)"/g)].map(m => m[1]);
  const known = new Set(mapMovement.APP_IDS);
  const missingInMap = swiftIds.filter(i => !known.has(i));
  const missingInSwift = mapMovement.APP_IDS.filter(i => !swiftIds.includes(i));
  if (missingInMap.length || missingInSwift.length) {
    console.log("\nWARNING: movement-map.js APP_IDS is out of date vs OogoModels.swift");
    if (missingInMap.length) console.log("  in Swift, not in APP_IDS: " + missingInMap.join(", "));
    if (missingInSwift.length) console.log("  in APP_IDS, not in Swift: " + missingInSwift.join(", "));
  } else {
    console.log("\nmovement-map.js APP_IDS matches OogoModels.swift (" + swiftIds.length + " ids)");
  }
} catch (e) {
  console.log("\n(skipped Swift id drift check: " + e.message + ")");
}
