// helpers for authoring exercises
const LR = ["fx", "fy", "fa", "th", "k", "ua", "e", "hx", "hy", "m", "tf", "sf", "ff"];
const NEG_X = new Set(["hx", "lfx", "rfx", "lhx", "rhx"]);

// sweat flick times on later reps at a given phase
function sw(rep, n) {
  const out = [];
  for (let r = 0; r < 10 / rep; r++) { const t = r * rep + n * rep; if (t > 5.0 && t < 9.25) out.push(+t.toFixed(2)); }
  return out.slice(-2);
}

// mirror a set of front-view keys left<->right
function mirror(keys, opt = {}) {
  const fkwArms = opt.fkwArms || false;
  return keys.map(([p, o]) => {
    const n = {};
    for (const k in o) {
      let v = o[k], key = k;
      const m = /^([lr])(.+)$/.exec(k);
      if (m && LR.includes(m[2])) key = (m[1] === "l" ? "r" : "l") + m[2];
      else if (k === "zl") key = "zr"; else if (k === "zr") key = "zl";
      else if (k === "zgl") key = "zgr"; else if (k === "zgr") key = "zgl";
      if (NEG_X.has(k)) v = -v;
      if (/^[lr]fa$/.test(k)) v = -v;
      if (fkwArms && /^[lr]ua$/.test(k)) v = -v;
      if (k === "t") v = 360 - v;
      if (k === "hd") v = -v;
      if (/^b\d[fa]$/.test(k)) v = -v;
      if (/^b\dw$/.test(k)) v = 1 - v;
      n[key] = v;
    }
    return [p, n];
  });
}

// squeeze two key lists into first and second half of one cycle
function halves(a, b) {
  return [...a.map(([p, o]) => [p / 2, o]), ...b.map(([p, o]) => [0.5 + p / 2, o])];
}

// stepping legs drawn in profile (torso faces you): walking or high-knee marching
function stepLegs(c, p, opt) {
  const { high = false } = opt || {};
  let maxExt = 0;
  ["l", "r"].forEach(s => {
    const off = s === "r" ? 0.5 : 0;
    let th, k, fa = 90;
    if (high) {
      const q = (p + off) % 1;
      const lift = q < 0.5 ? Math.pow(Math.sin(Math.PI * q / 0.5), 0.75) : 0;
      th = 82 * lift; k = 96 * lift; fa = 90 - 28 * lift;
    } else {
      const ph = 2 * Math.PI * (p + off);
      th = 24 * Math.sin(ph);
      k = 46 * Math.pow(Math.max(0, Math.cos(ph)), 2);
      fa = 90 - 20 * Math.max(0, Math.cos(ph));
    }
    c[s + "th"] = th; c[s + "k"] = k; c[s + "fa"] = fa; c[s + "tf"] = 1; c[s + "sf"] = 1;
    const r = Math.PI / 180;
    const ext = 30 * Math.cos(th * r) + 30 * Math.cos((th - k) * r);
    maxExt = Math.max(maxExt, ext);
  });
  c.hy = 2 - maxExt + 0.5;
  c.t = (c.t ?? 180) + (high ? 1.5 : 1) * Math.sin(4 * Math.PI * p);
}

module.exports = { sw, mirror, halves, stepLegs };

