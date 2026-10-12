// Oog animation engine: a 2D rig drawn in the oogo line-art style.
// Pure functions: makeClip(def) -> { svgAt(t), loop, ... }. Works in node and browser.
(function (root) {
  const INK = "#111111", RED = "#E53935", MIST = "#E8E8E5", WHITE = "#FFFFFF";
  const LEN = { thigh: 30, shin: 30, upper: 31, fore: 30, foot: 9 };
  const LOOP = 10;

  const rad = d => d * Math.PI / 180;
  const deg = r => r * 180 / Math.PI;
  const dir = a => ({ x: Math.sin(rad(a)), y: Math.cos(rad(a)) }); // 0 down, 90 forward(+x), 180 up
  const angOf = v => deg(Math.atan2(v.x, v.y));
  const add = (a, b) => ({ x: a.x + b.x, y: a.y + b.y });
  const sub = (a, b) => ({ x: a.x - b.x, y: a.y - b.y });
  const mul = (a, k) => ({ x: a.x * k, y: a.y * k });
  const lerp = (a, b, k) => ({ x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k });
  const len = v => Math.hypot(v.x, v.y);
  const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  const f1 = n => (Math.round(n * 100) / 100).toString();

  // ---------- keyframes: periodic monotone cubic per channel ----------
  function buildTrack(keys) {
    // keys: [[p, {ch: v}], ...] cumulative (missing channels inherit from previous key)
    const full = [];
    let cur = {};
    keys.forEach(([p, o]) => { cur = Object.assign({}, cur, o); full.push([p, cur]); });
    const chans = new Set();
    full.forEach(([, o]) => Object.keys(o).forEach(k => chans.add(k)));
    // channels missing in earliest keys: backfill from first key that has them
    chans.forEach(ch => {
      const first = full.find(([, o]) => ch in o);
      full.forEach(([, o]) => { if (!(ch in o)) o[ch] = first[1][ch]; });
    });
    const P = full.map(k => k[0]);
    const n = P.length;
    return function sample(p) {
      const out = {};
      if (n === 1) return Object.assign({}, full[0][1]);
      let i = n - 1;
      for (let k = 0; k < n; k++) { if (p >= P[k]) i = k; }
      if (p < P[0]) i = n - 1;
      const T = k => P[((k % n) + n) % n] + Math.floor(k / n);
      const V = (k, ch) => full[((k % n) + n) % n][1][ch];
      let base = i;
      let pp = p;
      if (p < P[0]) pp = p + 1; // wrap segment
      const t0 = T(base), t1 = T(base + 1), tm = T(base - 1), tp = T(base + 2);
      const h = t1 - t0, s = clamp((pp - t0) / h, 0, 1);
      const s2 = s * s, s3 = s2 * s;
      chans.forEach(ch => {
        const v0 = V(base, ch), v1 = V(base + 1, ch), vm = V(base - 1, ch), vp = V(base + 2, ch);
        const d0 = (v0 - vm) / (t0 - tm), d1 = (v1 - v0) / h, d2 = (vp - v1) / (tp - t1);
        const tan = (a, b) => (a * b <= 0 ? 0 : 2 / (1 / a + 1 / b));
        let m0 = tan(d0, d1), m1 = tan(d1, d2);
        // limit to keep monotone
        if (d1 !== 0) { m0 = clamp(m0 / d1, 0, 3) * d1; m1 = clamp(m1 / d1, 0, 3) * d1; } else { m0 = 0; m1 = 0; }
        out[ch] = (2 * s3 - 3 * s2 + 1) * v0 + (s3 - 2 * s2 + s) * h * m0 + (-2 * s3 + 3 * s2) * v1 + (s3 - s2) * h * m1;
      });
      return out;
    };
  }

  // ---------- IK ----------
  function ik(A, T, l1, l2, sign) {
    let v = sub(T, A), d = len(v);
    const dmax = l1 + l2 - 0.01, dmin = Math.abs(l1 - l2) + 0.5;
    const dc = clamp(d, dmin, dmax);
    const u = d > 1e-6 ? mul(v, 1 / d) : { x: 0, y: 1 };
    const a = Math.acos(clamp((l1 * l1 + dc * dc - l2 * l2) / (2 * l1 * dc), -1, 1));
    // rotate u by -sign*a (screen coords): sign=+1 bends to +x when limb points down
    const th = -sign * a;
    const r = { x: u.x * Math.cos(th) - u.y * Math.sin(th), y: u.x * Math.sin(th) + u.y * Math.cos(th) };
    const J = add(A, mul(r, l1));
    const E = add(A, mul(u, dc));
    return { J, E };
  }

  // ---------- shape helpers ----------
  function cloudPath(cx, cy, rx, ry, n, bulge) {
    let d = "";
    for (let i = 0; i <= n; i++) {
      const a = (i / n) * Math.PI * 2 + 0.3;
      const x = cx + Math.cos(a) * rx, y = cy + Math.sin(a) * ry;
      if (i === 0) { d += `M${f1(x)} ${f1(y)}`; continue; }
      const am = ((i - 0.5) / n) * Math.PI * 2 + 0.3;
      d += ` Q${f1(cx + Math.cos(am) * (rx + bulge))} ${f1(cy + Math.sin(am) * (ry + bulge))} ${f1(x)} ${f1(y)}`;
    }
    return d + " Z";
  }
  const CLOUD = cloudPath(0, -36, 42, 38, 12, 9);
  const BEARD_DOTS = (() => {
    let s = "";
    for (let i = 0; i <= 12; i++) {
      const a = Math.PI * (0.02 + 0.96 * i / 12);
      s += `<circle cx="${f1(Math.cos(a) * 26)}" cy="${f1(14 + Math.sin(a) * 30)}" r="6.2"/>`;
    }
    return s;
  })();

  function headSVG(leafRot, face) {
    // face: 'calm' | 'strain'
    const brows = face === "strain"
      ? `<path d="M-18 -14 C-14 -13 -8 -11 -4 -9 M4 -9 C8 -11 14 -13 18 -14" fill="none" stroke="${INK}" stroke-width="2.8" stroke-linecap="round"/>`
      : `<path d="M-18 -12 C-14 -15 -8 -15 -4 -12 M4 -12 C8 -15 14 -15 18 -12" fill="none" stroke="${INK}" stroke-width="2.8" stroke-linecap="round"/>`;
    const eyes = face === "strain"
      ? `<path d="M-17 -3 L-6 -3 M6 -3 L17 -3" fill="none" stroke="${INK}" stroke-width="2.2" stroke-linecap="round"/>`
      : `<path d="M-17 -4 C-14 0 -8 0 -5 -4 M5 -4 C8 0 14 0 17 -4" fill="none" stroke="${INK}" stroke-width="2" stroke-linecap="round"/>`;
    return `<g transform="rotate(${f1(leafRot)} 0 -33)">` +
      `<path d="M0 -33 C0 -40 1 -44 3 -48" fill="none" stroke="${INK}" stroke-width="2.2" stroke-linecap="round"/>` +
      `<path d="M3 -48 C6 -58 18 -60 22 -55 C18 -48 8 -45 3 -48 Z" fill="${WHITE}" stroke="${INK}" stroke-width="2" stroke-linejoin="round"/>` +
      `<path d="M5 -49 L19 -55 M10 -51 L11 -55 M14 -53 L15 -56.5" fill="none" stroke="${INK}" stroke-width="1.3" stroke-linecap="round"/></g>` +
      `<path d="M-29 -2 C-36 -4 -36 10 -28 10 M29 -2 C36 -4 36 10 28 10" fill="${WHITE}" stroke="${INK}" stroke-width="2.4"/>` +
      `<ellipse cx="0" cy="0" rx="28" ry="33" fill="${WHITE}" stroke="${INK}" stroke-width="2.6"/>` +
      `<g fill="${INK}"><circle cx="-10" cy="-30" r="3.6"/><circle cx="-4" cy="-32.5" r="3.6"/><circle cx="2" cy="-33" r="3.6"/><circle cx="8" cy="-31.5" r="3.6"/><circle cx="13" cy="-29" r="3.6"/></g>` +
      brows + eyes +
      `<path d="M1 -6 L-1 7 C0 9 3 9 4 8" fill="none" stroke="${INK}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>` +
      `<g fill="${INK}"><path d="M-27 4 C-26 30 -12 44 0 45 C12 44 26 30 27 4 C20 14 10 11 0 11 C-10 11 -20 14 -27 4 Z"/>${BEARD_DOTS}</g>` +
      (face === "strain"
        ? `<path d="M-7 17 C-3 15.5 3 15.5 7 17 C6 21 -6 21 -7 17 Z" fill="${WHITE}"/>`
        : `<path d="M-7 17 C-4 16 4 16 7 17 C6 23 -6 23 -7 17 Z" fill="${WHITE}"/>`);
  }

  function bellSVG(x, y, a, scale) {
    return `<g transform="translate(${f1(x)} ${f1(y)}) rotate(${f1(-a)}) scale(${scale})">` +
      `<path d="M-7 10 C-8 -3 8 -3 7 10" fill="none" stroke="${WHITE}" stroke-width="7" stroke-linecap="round"/>` +
      `<circle cx="0" cy="18" r="12.6" fill="${WHITE}"/><rect x="-9.6" y="25.4" width="19.2" height="6.7" rx="2.5" fill="${WHITE}"/>` +
      `<path d="M-7 10 C-8 -3 8 -3 7 10" fill="none" stroke="${INK}" stroke-width="4" stroke-linecap="round"/>` +
      `<circle cx="0" cy="18" r="11" fill="${INK}"/>` +
      `<rect x="-8" y="27" width="16" height="3.5" rx="1.5" fill="${INK}"/>` +
      `<path d="M-6 14 C-5 11 -3 10 -1 9.5" fill="none" stroke="${WHITE}" stroke-width="1.6" stroke-linecap="round" opacity=".8"/></g>`;
  }

  function haloPoly(pts, w) {
    return `<polyline points="${pts.map(p => f1(p.x) + "," + f1(p.y)).join(" ")}" fill="none" stroke="${WHITE}" stroke-width="${w + 2.6}" stroke-linecap="round" stroke-linejoin="round"/>`;
  }
  function lineSVG(a, b, w) {
    return `<line x1="${f1(a.x)}" y1="${f1(a.y)}" x2="${f1(b.x)}" y2="${f1(b.y)}" stroke="${INK}" stroke-width="${w}" stroke-linecap="round"/>`;
  }
  function polySVG(pts, w) {
    return `<polyline points="${pts.map(p => f1(p.x) + "," + f1(p.y)).join(" ")}" fill="none" stroke="${INK}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"/>`;
  }

  // ---------- props ----------
  // P (the pose) is only used by props that follow the body, like the jump rope.
  function propSVG(pr, t, P) {
    const w = 3;
    switch (pr.type) {
      case "box": { // x,y = top-left in world, w,h
        return `<rect x="${pr.x}" y="${pr.y}" width="${pr.w}" height="${pr.h}" rx="${pr.r ?? 4}" fill="${WHITE}" stroke="${INK}" stroke-width="2.6"/>`;
      }
      case "bench": { // top surface at y, from x to x+w, legs to ground
        return `<rect x="${pr.x}" y="${pr.y}" width="${pr.w}" height="${pr.th ?? 9}" rx="3" fill="${WHITE}" stroke="${INK}" stroke-width="2.6"/>` +
          lineSVG({ x: pr.x + 8, y: pr.y + (pr.th ?? 9) }, { x: pr.x + 8, y: 0 }, 2.8) +
          lineSVG({ x: pr.x + pr.w - 8, y: pr.y + (pr.th ?? 9) }, { x: pr.x + pr.w - 8, y: 0 }, 2.8);
      }
      case "barSide": { // bar seen end-on at (x,y) on a post
        return lineSVG({ x: pr.x + (pr.post ?? 30), y: pr.y }, { x: pr.x + (pr.post ?? 30), y: pr.ground ?? 0 }, 3) +
          lineSVG({ x: pr.x, y: pr.y }, { x: pr.x + (pr.post ?? 30), y: pr.y }, 3) +
          `<circle cx="${pr.x}" cy="${pr.y}" r="3.6" fill="${WHITE}" stroke="${INK}" stroke-width="2.6"/>`;
      }
      case "barFront": { // horizontal bar from x1 to x2 at y, with end caps like the icon
        return lineSVG({ x: pr.x1, y: pr.y }, { x: pr.x2, y: pr.y }, 3.6) +
          lineSVG({ x: pr.x1 + 4, y: pr.y - 5 }, { x: pr.x1 + 4, y: pr.y + 9 }, 3.6) +
          lineSVG({ x: pr.x2 - 4, y: pr.y - 5 }, { x: pr.x2 - 4, y: pr.y + 9 }, 3.6);
      }
      case "dip": { // bars seen from the side: top rail at y from x1..x2, posts to ground
        return lineSVG({ x: pr.x1, y: pr.y }, { x: pr.x2, y: pr.y }, 3.4) +
          lineSVG({ x: pr.x1 + 3, y: pr.y }, { x: pr.x1 + 3, y: 0 }, 3.4) +
          lineSVG({ x: pr.x2 - 3, y: pr.y }, { x: pr.x2 - 3, y: 0 }, 3.4);
      }
      case "ring": { // strap from top to ring center
        return lineSVG({ x: pr.ax, y: pr.ay }, { x: pr.x, y: pr.y - 7 }, 2.2) +
          `<circle cx="${pr.x}" cy="${pr.y}" r="6.5" fill="none" stroke="${INK}" stroke-width="2.8"/>`;
      }
      case "towel": { // wavy towel hanging from bar point (x,y) down len
        const L = pr.len ?? 34, sw = Math.sin(t * 2) * 1.5;
        return `<path d="M${pr.x - 3} ${pr.y} C${pr.x - 6 + sw} ${pr.y + L * .35} ${pr.x + sw} ${pr.y + L * .6} ${pr.x - 3} ${pr.y + L} L${pr.x + 4} ${pr.y + L} C${pr.x + 7 + sw} ${pr.y + L * .6} ${pr.x + 1 + sw} ${pr.y + L * .35} ${pr.x + 4} ${pr.y} Z" fill="${WHITE}" stroke="${INK}" stroke-width="2.2" stroke-linejoin="round"/>`;
      }
      case "block": { // small block, x center, sitting on ground
        return `<rect x="${pr.x - pr.w / 2}" y="${-pr.h}" width="${pr.w}" height="${pr.h}" rx="2.5" fill="${WHITE}" stroke="${INK}" stroke-width="2.6"/>`;
      }
      case "wedge": { // heel wedge: high side at x1
        return `<path d="M${pr.x1} 0 L${pr.x2} 0 L${pr.x1} ${-pr.h} Z" fill="${WHITE}" stroke="${INK}" stroke-width="2.4" stroke-linejoin="round"/>`;
      }
      case "handles": { // neutral grip handles hanging under a front bar
        return lineSVG({ x: pr.x1, y: pr.y }, { x: pr.x1, y: pr.y + 14 }, 3.2) + lineSVG({ x: pr.x2, y: pr.y }, { x: pr.x2, y: pr.y + 14 }, 3.2);
      }
      case "post": { // dip post seen end-on: vertical post with a grip cap
        return lineSVG({ x: pr.x, y: pr.y }, { x: pr.x, y: 0 }, 3.4) + lineSVG({ x: pr.x - 7, y: pr.y }, { x: pr.x + 7, y: pr.y }, 3.6);
      }
      case "mat": {
        return `<rect x="${pr.x1}" y="-2.5" width="${pr.x2 - pr.x1}" height="2.5" rx="1.25" fill="${MIST}"/>`;
      }
      case "rope": { // jump rope from hand to hand, front view; its middle orbits the body
        // turns: revolutions per rep, phase: offset in revolutions (0 = middle over the head,
        // 0.5 = under the feet), r: height of the top arc above the hands, floor: ground y,
        // side: +1 draws the half in front of the body (list it in propsFront) and the handles,
        // -1 the half behind (list it in props). trail: faint copies lagging trailStep rad.
        if (!P) return "";
        const side = pr.side ?? 1, rw = pr.w ?? 2.4, hl = pr.handle ?? 6;
        const tip = s => { const A = P.arms[s], v = sub(A.H, A.E), d = len(v) || 1; return add(A.H, mul(v, hl / d)); };
        const a = tip("l"), b = tip("r");
        const xm = (a.x + b.x) / 2, yh = (a.y + b.y) / 2, fw = (b.x - a.x) / 2 * (pr.flat ?? 0.6);
        const top = pr.r ?? 165, low = Math.max(0, (pr.floor ?? 0) - rw / 2 - yh);
        const turn = (pr.turns ?? 1) * P.p + (pr.phase ?? 0);
        let s = "";
        for (let i = pr.trail ?? 0; i >= 0; i--) {
          const phi = 2 * Math.PI * turn - i * (pr.trailStep ?? 0.4);
          if ((Math.sin(phi) > 0 ? 1 : -1) !== side) continue;
          const c = Math.cos(phi);
          const d = -((top * (1 + c) + low * (1 - c)) / 2) * c; // middle of the rope, relative to the hands
          const my = yh + d, bx = Math.abs(d) * (pr.bulge ?? 0.15);
          // two cubics, hand -> middle -> hand, level at the middle
          const path = `M${f1(a.x)} ${f1(a.y)} C${f1(a.x - bx)} ${f1(a.y + d / 2)} ${f1(xm - fw)} ${f1(my)} ${f1(xm)} ${f1(my)}` +
            ` C${f1(xm + fw)} ${f1(my)} ${f1(b.x + bx)} ${f1(b.y + d / 2)} ${f1(b.x)} ${f1(b.y)}`;
          s += `<path d="${path}" fill="none" stroke="${INK}" stroke-width="${f1(i ? rw * 0.8 : rw)}" stroke-linecap="round" stroke-linejoin="round"${i ? ` opacity="${f1(0.36 / i)}"` : ""}/>`;
        }
        if (side === 1) s += lineSVG(P.arms.l.H, a, 4.4) + lineSVG(P.arms.r.H, b, 4.4);
        return s;
      }
    }
    return "";
  }

  // ---------- clip ----------
  function makeClip(def) {
    const view = def.view || "side";
    const rep = def.rep || 2;
    const track = buildTrack(def.keys);
    const D = Object.assign({
      hx: 0, hy: -60, t: 180, hd: 0,
      lfx: -4, lfy: 0, rfx: 2, rfy: 0,
      lth: 0, lk: 0, rth: 0, rk: 0,
      lua: 0, le: 0, rua: 0, re: 0,
      lhx: 0, lhy: -60, rhx: 0, rhy: -60,
    }, view === "front" ? { lfx: -14, rfx: 14 } : {}, def.defaults || {});
    const front = view === "front";
    const hipOff = def.hipOff || (front ? { l: { x: -14, y: -2 }, r: { x: 14, y: -2 } } : { l: { x: -3, y: -2 }, r: { x: 2, y: -2 } });
    const shOff = def.shOff || (front ? { l: { x: -31, y: -66 }, r: { x: 31, y: -66 } } : { l: { x: -6, y: -64 }, r: { x: 6, y: -64 } });
    const AU = def.armLen ? def.armLen[0] : (front ? 34 : LEN.upper), AF = def.armLen ? def.armLen[1] : (front ? 33 : LEN.fore);
    const legMode = Object.assign({ l: "ik", r: "ik" }, def.legMode || {});
    const armMode = Object.assign({ l: "fk", r: "fk" }, def.armMode || {});
    const kneeSign = Object.assign(front ? { l: -1, r: 1 } : { l: 1, r: 1 }, def.kneeSign || {});
    const elbowSign = Object.assign(front ? { l: 1, r: -1 } : { l: -1, r: -1 }, def.elbowSign || {});
    const flex = Object.assign(front ? { l: -1, r: 1 } : { l: 1, r: 1 }, def.flex || {});
    const footDef = front ? { l: -90, r: 90 } : { l: 90, r: 90 };
    const z = Object.assign(front
      ? { legl: 1, legr: 1, body: 5, arml: 7, armr: 7 }
      : { legl: 1, legr: 2, body: 5, arml: 3, armr: 8 }, def.z || {});
    const bells = def.bells || [];
    const headX = def.headPos ? def.headPos.x : (front ? 0 : 4);
    const headY = def.headPos ? def.headPos.y : -98;
    const face = def.face || "calm";

    function pose(t) {
      const tt = ((t % LOOP) + LOOP) % LOOP;
      const p = (tt % rep) / rep;
      const c = Object.assign({}, D, track(p));
      if (def.post) def.post(c, p, tt);
      const hip = { x: c.hx, y: c.hy };
      const T = c.t, phi = rad(180 - T);
      const kp = Math.max(0.45, Math.cos(rad(c.pt || 0)));
      const W = (lx, ly0) => { const ly = ly0 * kp; return { x: hip.x + lx * Math.cos(phi) - ly * Math.sin(phi), y: hip.y + lx * Math.sin(phi) + ly * Math.cos(phi) }; };
      const legs = {}, arms = {};
      ["l", "r"].forEach(s => {
        const H = W(hipOff[s].x, hipOff[s].y);
        let K, A;
        const lt = LEN.thigh * (c[s + "tf"] ?? 1), ls = LEN.shin * (c[s + "sf"] ?? 1);
        if (legMode[s] === "ik") {
          const r = ik(H, { x: c[s + "fx"], y: c[s + "fy"] }, lt, ls, kneeSign[s]);
          K = r.J; A = r.E;
        } else {
          const td = (legMode[s] === "fkw" ? 0 : T - 180) + flex[s] * c[s + "th"];
          K = add(H, mul(dir(td), lt));
          A = add(K, mul(dir(td - flex[s] * c[s + "k"]), ls));
        }
        const fa = (s + "fa") in c ? c[s + "fa"] : footDef[s];
        const F = add(A, mul(dir(fa), LEN.foot * (c[s + "ff"] ?? 1)));
        legs[s] = { H, K, A, F };
        const S0 = W(shOff[s].x, shOff[s].y);
        let E, Hd;
        if (armMode[s] === "ik" || armMode[s] === "ikb") {
          const tgt = armMode[s] === "ikb" ? W(c[s + "hx"], c[s + "hy"]) : { x: c[s + "hx"], y: c[s + "hy"] };
          const r = ik(S0, tgt, AU, AF, elbowSign[s]);
          E = r.J; Hd = r.E;
        } else if (armMode[s] === "blend") {
          const ua = c[s + "ua"];
          const e0 = add(S0, mul(dir(ua), AU));
          const fkH = add(e0, mul(dir(ua + flex[s] * c[s + "e"]), AF));
          const ikT = (def.blendSpace || "body") === "body" ? W(c[s + "hx"], c[s + "hy"]) : { x: c[s + "hx"], y: c[s + "hy"] };
          const m = clamp(c[s + "m"] ?? 0, 0, 1);
          if (m < 0.001) { E = e0; Hd = fkH; }
          else {
            const r = ik(S0, lerp(fkH, ikT, m), AU, AF, elbowSign[s]);
            E = m < 1 ? lerp(e0, r.J, Math.min(1, m * 1.5)) : r.J; Hd = r.E;
            // keep forearm length honest after elbow blend
            const v = sub(Hd, E); const L0 = len(v) || 1; Hd = add(E, mul(v, AF / L0));
          }
        } else {
          const ua = armMode[s] === "fkw" ? c[s + "ua"] : T - 180 + flex[s] * c[s + "ua"];
          E = add(S0, mul(dir(ua), AU));
          Hd = add(E, mul(dir(ua + flex[s] * c[s + "e"]), AF));
        }
        arms[s] = { S: S0, E, H: Hd };
      });
      let lean = 180 - T; while (lean > 180) lean -= 360; while (lean < -180) lean += 360;
      const headRel = (def.headComp ?? -0.35) * clamp(lean, -(def.headClamp ?? 70), def.headClamp ?? 70) + c.hd;
      const bs = bells.map((b, i) => {
        const w = (("b" + i + "w") in c) ? c["b" + i + "w"] : (b.hand === "r" ? 1 : b.hand === "mid" ? 0.5 : 0);
        let at = lerp(arms.l.H, arms.r.H, clamp(w, 0, 1));
        if (b.offset) at = add(at, b.offset);
        let a;
        if (("b" + i + "a") in c) a = c["b" + i + "a"];
        else { const arm = w > 0.5 ? arms.r : arms.l; a = angOf(sub(arm.H, arm.E)) + (c["b" + i + "f"] || 0) * (b.mirror ? -1 : 1); }
        const zz = (("b" + i + "z") in c) ? c["b" + i + "z"] : (b.z ?? 9);
        const op = (("b" + i + "o") in c) ? clamp(c["b" + i + "o"], 0, 1) : 1;
        return { x: at.x, y: at.y, a, z: zz, op, center: add(at, mul(dir(a), 16 * 0.9)) };
      });
      return { c, p, t: tt, hip, T, W, legs, arms, headRel, bells: bs, lean, kp };
    }

    function leanAt(t) { return pose(t).lean; }

    function svgInner(t, fit) {
      const P = pose(t);
      const parts = [];
      const lw = 3.2, aw = 2.9;
      // leaf lag from recent motion (deterministic: derived from pose at earlier times)
      const pa = pose(t - 0.06), pb = pose(t - 0.16);
      let leaf = -(pa.lean - pb.lean) * 1.6 + (pa.hip.x - pb.hip.x) * -0.6 + (pa.hip.y - pb.hip.y) * 0.5;
      leaf = clamp(leaf, -24, 24) + 3;
      // heart pulse
      let beat = 0;
      (def.effort || []).forEach(e => {
        let d = P.p - e; d -= Math.round(d);
        beat = Math.max(beat, Math.exp(-Math.pow(d / 0.05, 2)));
      });
      const faceNow = def.strainAt
        ? (def.strainAt.some(([a, b]) => P.p >= a && P.p <= b) ? "strain" : "calm")
        : face;
      // body group
      const bodyG = `<g transform="translate(${f1(P.hip.x)} ${f1(P.hip.y)}) rotate(${f1(180 - P.T)}) scale(1 ${f1(P.kp)})">` +
        `<path d="${CLOUD}" fill="${WHITE}" stroke="${INK}" stroke-width="2.6" stroke-linejoin="round"/>` +
        `<g transform="translate(${front ? 14 : 18} -44) scale(${f1(1 + beat * 0.45)})"><path d="M0 3 C-6 -2 -6 -7 -3 -8 C-1.5 -8.6 -0.3 -7.6 0 -6.3 C0.3 -7.6 1.5 -8.6 3 -8 C6 -7 6 -2 0 3 Z" fill="${RED}"/></g>` +
        `</g>`;
      parts.push([z.body, bodyG]);
      const HC = P.W(headX, headY);
      parts.push([z.head ?? 6, `<g transform="translate(${f1(HC.x)} ${f1(HC.y)}) rotate(${f1(180 - P.T + P.headRel)})">${headSVG(leaf, faceNow)}</g>`]);
      ["l", "r"].forEach(s => {
        const L = P.legs[s];
        parts.push([("zg" + s) in P.c ? P.c["zg" + s] : z["leg" + s], haloPoly([L.H, L.K, L.A, L.F], lw) + polySVG([L.H, L.K, L.A], lw) + lineSVG(L.A, L.F, lw)]);
        const A = P.arms[s];
        parts.push([("z" + s) in P.c ? P.c["z" + s] : z["arm" + s], haloPoly([A.S, A.E, A.H], aw) + polySVG([A.S, A.E, A.H], aw) + `<circle cx="${f1(A.H.x)}" cy="${f1(A.H.y)}" r="2.5" fill="${INK}"/>`]);
      });
      P.bells.forEach((b, i) => {
        if (b.op <= 0.01) return;
        const s = bellSVG(b.x, b.y, b.a, 0.9);
        parts.push([b.z + i * 0.01, b.op < 1 ? `<g opacity="${f1(b.op)}">${s}</g>` : s]);
      });
      // motion lines behind a bell or limb
      (def.motion || []).forEach(m => {
        const [p0, p1] = m.win;
        let ph = P.p;
        if (ph < p0 || ph > p1) return;
        const show = Math.sin(Math.PI * (ph - p0) / (p1 - p0));
        const pt = tt => { const q = pose(tt); return m.bell != null ? q.bells[m.bell].center : (m.hand ? q.arms[m.hand].H : q.legs[m.foot].A); };
        const a = pt(t), b = pt(t - 0.1);
        const dx = a.x - b.x, dy = a.y - b.y, L = Math.hypot(dx, dy);
        if (L < 2) return;
        const nx = -dy / L, ny = dx / L;
        let s = "";
        [-1, 0, 1].forEach(k => {
          const off = k * 7, back = m.back ?? 14;
          const ux = dx / L, uy = dy / L;
          const x2 = a.x - ux * back + nx * off, y2 = a.y - uy * back + ny * off;
          const x1 = x2 - ux * (k === 0 ? 14 : 9), y1 = y2 - uy * (k === 0 ? 14 : 9);
          s += `<line x1="${f1(x1)}" y1="${f1(y1)}" x2="${f1(x2)}" y2="${f1(y2)}" stroke="${INK}" stroke-width="2.2" stroke-linecap="round" opacity="${f1(show * (k === 0 ? 1 : 0.7))}"/>`;
        });
        parts.push([m.z ?? 0.5, s]);
      });
      // sweat drop: flicks off the head at listed loop times
      const sweatTimes = def.sweat || [];
      sweatTimes.forEach(st => {
        const sp = (P.t - st) / 0.7;
        if (sp <= 0 || sp >= 1) return;
        const Q = pose(st);
        const hc = Q.W(headX, headY);
        const back = front ? (st % 2 < 1 ? -1 : 1) : -1;
        const x = hc.x + back * (32 + sp * 20), y = hc.y - 20 - Math.sin(sp * Math.PI) * 14 + sp * 12;
        const op = Math.min(1, sp * 5, (1 - sp) * 4);
        parts.push([20, `<g transform="translate(${f1(x)} ${f1(y)}) rotate(${f1(back * (40 - sp * 60))}) scale(1.4)" opacity="${f1(op)}"><path d="M0 -6 C3 -2 4 1 4 3 A4 4 0 0 1 -4 3 C-4 1 -3 -2 0 -6 Z" fill="${WHITE}" stroke="${INK}" stroke-width="1.8" stroke-linejoin="round"/></g>`]);
      });
      parts.sort((a, b) => a[0] - b[0]);

      // shadow
      let sx, srx;
      if (def.shadow) { const s = typeof def.shadow === "function" ? def.shadow(P) : def.shadow; sx = s.x; srx = s.rx; }
      else {
        const xs = [P.hip.x, P.legs.l.A.x, P.legs.r.A.x, P.W(0, -40).x];
        sx = xs.reduce((a, b) => a + b, 0) / xs.length;
        srx = clamp((Math.max(...xs) - Math.min(...xs)) / 2 + 42, 44, 110);
      }
      let ground = `<ellipse cx="${f1(sx)}" cy="1.5" rx="${f1(srx)}" ry="4.8" fill="${MIST}"/>`;
      if (def.scroll) {
        const sp = def.scroll, gap = 40;
        const off = ((P.t * sp) % gap + gap) % gap;
        let ticks = "";
        for (let x = -240; x <= 240; x += gap) {
          const xx = x - off;
          const fade = clamp(1 - Math.abs(xx) / 200, 0, 1);
          ticks += `<line x1="${f1(xx)}" y1="9" x2="${f1(xx + 12)}" y2="9" stroke="${INK}" stroke-width="2.2" stroke-linecap="round" opacity="${f1(fade * 0.35)}"/>`;
        }
        ground += ticks;
      }
      const props = (def.props || []).map(pr => propSVG(typeof pr === "function" ? pr(P) : pr, P.t, P)).join("");
      const propsFront = (def.propsFront || []).map(pr => propSVG(typeof pr === "function" ? pr(P) : pr, P.t, P)).join("");
      return ground + props + parts.map(p => p[1]).join("") + propsFront;
    }

    // bounding box in world units, sampled over the loop
    function bbox() {
      let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
      const pt = (x, y, r) => { x0 = Math.min(x0, x - r); x1 = Math.max(x1, x + r); y0 = Math.min(y0, y - r); y1 = Math.max(y1, y + r); };
      for (let i = 0; i < 120; i++) {
        const P = pose(i * LOOP / 120);
        for (let k = 0; k < 16; k++) { const a = k / 16 * Math.PI * 2; const q = P.W(Math.cos(a) * 50, -36 + Math.sin(a) * 46); pt(q.x, q.y, 0); }
        const hc = P.W(headX, headY);
        pt(hc.x, hc.y, 40);
        const lt = P.W(headX + 12, headY - 60); pt(lt.x, lt.y, 4);
        ["l", "r"].forEach(s => { [P.legs[s].K, P.legs[s].A, P.legs[s].F].forEach(q => pt(q.x, q.y, 3)); [P.arms[s].E, P.arms[s].H].forEach(q => pt(q.x, q.y, 3)); });
        P.bells.forEach(b => { if (b.op > 0.01) pt(b.center.x, b.center.y, 16); });
      }
      pt(0, 4, 0);
      (def.fitExtra || []).forEach(([x, y]) => pt(x, y, 0));
      return { x0, y0, x1, y1 };
    }

    let fitCache = null;
    function fit() {
      if (fitCache) return fitCache;
      const b = bbox();
      const w = b.x1 - b.x0, h = b.y1 - b.y0;
      const S = Math.min(def.maxScale || 1.45, 344 / w, 344 / h);
      const cx = (b.x0 + b.x1) / 2;
      // keep floor low in the frame when there is room
      let oy = 200 - ((b.y0 + b.y1) / 2) * S;
      const groundY = oy;
      if (groundY < 360) oy = Math.min(360, 400 - 28 - b.y1 * S);
      // ensure top fits
      if (b.y0 * S + oy < 26) oy = 26 - b.y0 * S;
      fitCache = { S, ox: 200 - cx * S, oy };
      return fitCache;
    }

    function svgAt(t, opts) {
      const F = fit();
      const size = (opts && opts.size) || null;
      return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400"${size ? ` width="${size}" height="${size}"` : ""}>` +
        `<rect width="400" height="400" fill="${WHITE}"/>` +
        `<g transform="translate(${f1(F.ox)} ${f1(F.oy)}) scale(${f1(F.S)})">${svgInner(t)}</g></svg>`;
    }
    function innerAt(t) {
      const F = fit();
      return `<rect width="400" height="400" fill="${WHITE}"/><g transform="translate(${f1(F.ox)} ${f1(F.oy)}) scale(${f1(F.S)})">${svgInner(t)}</g>`;
    }
    return { svgAt, innerAt, pose, fit, loop: LOOP, def };
  }

  const API = { makeClip, LOOP, LEN, dir, rad };
  if (typeof module !== "undefined" && module.exports) module.exports = API;
  else root.OogEngine = API;
})(typeof window !== "undefined" ? window : globalThis);
