#!/usr/bin/env node
// Builds animation/preview.html: one self-contained page with the engine and every
// exercise def inlined, a grid of looping clips and a single-clip view.
//
//   node animation/build-preview.js
//
// URL options on preview.html:
//   ?id=<def id>[&cat=<cat>]   open one clip directly
//   ?t=<seconds>[&paused=1]    start at a time; paused=1 freezes it (for screenshots)

const fs = require("fs");
const path = require("path");
const { defs, exFiles } = require("./index.js");
const mapMovement = require("./movement-map.js");

const OUT = path.join(__dirname, "preview.html");

// ---------- inline sources (with a tiny CommonJS shim, like the original export) ----------
// Keep the text from closing the surrounding <script> tag.
const safeScript = s => s.replace(/<\/(script)/gi, "<\\/$1").replace(/<!--/g, "<\\!--");
const read = f => fs.readFileSync(path.join(__dirname, f), "utf8");

const engineSrc = safeScript(read("engine.js"));
const moduleFiles = ["lib.js", ...exFiles];
const modules = moduleFiles
  .map(f => JSON.stringify("./" + f) + ": function (module, exports, require) {\n" + read(f).replace(/\s+$/, "") + "\n}")
  .join(",\n");
const bundleSrc = safeScript(
  "(function(){var __S={" + modules + "};var __M={};" +
  "function __r(n){if(__M[n])return __M[n].exports;var m={exports:{}};__M[n]=m;__S[n](m,m.exports,__r);return m.exports;}" +
  "window.OogExercises=[].concat(" + exFiles.map(f => "__r(" + JSON.stringify("./" + f) + ")").join(",") + ");})();"
);

// ---------- metadata the page needs but the defs do not carry ----------
const CAT_LABELS = {
  "legs-squat": "Legs: squat pattern",
  hinge: "Legs: hinge and ballistics",
  push: "Push",
  pull: "Pull",
  core: "Core",
};
const meta = defs.map(d => ({
  cat: d.cat,
  id: d.id,
  movementId: mapMovement(d),
  aliases: mapMovement.aliasesFor(d).filter(a => !defs.some(o => mapMovement(o) === a)),
}));
// JSON for embedding inside a <script>: escape characters that could end or confuse the tag.
const BS = String.fromCharCode(92);
const jsonForScript = v => JSON.stringify(v)
  .replace(/</g, BS + "u003c")
  .replace(new RegExp(String.fromCharCode(0x2028), "g"), BS + "u2028")
  .replace(new RegExp(String.fromCharCode(0x2029), "g"), BS + "u2029");

// ---------- page ----------
const CSS = String.raw`
:root { --ink:#111111; --white:#FFFFFF; --cloud:#F7F7F5; --mist:#E8E8E5; --sub:#6A6A66; --red:#E53935; }
*, *::before, *::after { box-sizing: border-box; }
html, body { margin: 0; }
body { background: #FFFFFF; color: var(--ink); font: 15px/1.4 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; -webkit-tap-highlight-color: transparent; }
button { font: inherit; color: inherit; }
header.top { display: flex; align-items: center; gap: 14px; flex-wrap: wrap; padding: 16px 20px; position: sticky; top: 0; background: #FFFFFF; z-index: 5; border-bottom: 1px solid var(--mist); }
header.top h1 { font-size: 18px; margin: 0; letter-spacing: -0.01em; }
header.top .count { color: var(--sub); font-size: 13px; }
header.top nav { display: flex; gap: 6px; flex-wrap: wrap; margin-left: auto; }
.pill { border: 1px solid var(--mist); background: var(--white); border-radius: 999px; padding: 5px 12px; font-size: 13px; cursor: pointer; text-decoration: none; color: var(--ink); }
.pill:hover { background: var(--cloud); }
.pill:focus-visible, .tile:focus-visible, .ctl button:focus-visible, #back:focus-visible { outline: 3px solid var(--ink); outline-offset: 2px; }
main { padding: 4px 20px 48px; max-width: 1400px; margin: 0 auto; }
section.cat { scroll-margin-top: 72px; }
section.cat h2 { font-size: 15px; font-weight: 600; margin: 28px 0 12px; display: flex; align-items: baseline; gap: 8px; }
section.cat h2 small { color: var(--sub); font-weight: 400; font-size: 13px; }
.tiles { display: grid; grid-template-columns: repeat(auto-fill, minmax(190px, 1fr)); gap: 12px; }
.tile { position: relative; display: block; width: 100%; text-align: left; background: var(--white); border: 1px solid var(--mist); border-radius: 12px; padding: 8px 8px 10px; cursor: pointer; }
.tile:hover { border-color: #BDBDB8; }
.tile .stage { aspect-ratio: 1 / 1; background: #FFFFFF; border-radius: 8px; overflow: hidden; }
.stage svg { display: block; width: 100%; height: 100%; }
.tile .name { font-weight: 600; margin: 6px 4px 0; font-size: 14px; }
.tile .slug { color: var(--sub); font-size: 12px; margin: 0 4px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.noid { background: var(--red); color: #FFFFFF; font-size: 10px; font-weight: 600; line-height: 1; padding: 3px 7px; border-radius: 999px; letter-spacing: 0.02em; }
.tile .noid { position: absolute; top: 14px; left: 14px; }
#single { position: fixed; inset: 0; background: #FFFFFF; z-index: 10; overflow: auto; padding: 16px 20px 32px; }
#single[hidden] { display: none; }
#single .wrap { max-width: 760px; margin: 0 auto; }
#single .bar { display: flex; align-items: center; gap: 12px; }
#single h2 { font-size: 20px; margin: 0; letter-spacing: -0.01em; }
#single .meta { color: var(--sub); font-size: 13px; margin: 6px 0 12px; display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
#single .meta code { background: var(--cloud); padding: 1px 6px; border-radius: 6px; color: var(--ink); font-size: 12px; }
#sStage { width: min(100%, calc(100vh - 220px)); aspect-ratio: 1 / 1; margin: 0 auto; }
.ctl { display: flex; align-items: center; gap: 12px; margin-top: 12px; }
.ctl button { min-width: 74px; }
.ctl input[type=range] { flex: 1; accent-color: var(--ink); }
.ctl .time { font-variant-numeric: tabular-nums; color: var(--sub); min-width: 56px; text-align: right; font-size: 13px; }
`;

const CLIENT = String.raw`
(function () {
  var LOOP = OogEngine.LOOP;
  var META = __META__;
  var CAT_LABELS = __CAT_LABELS__;
  var defs = window.OogExercises;
  var qs = new URLSearchParams(location.search);
  var reduce = false;
  try { reduce = !!(window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches); } catch (e) {}

  var startT = parseFloat(qs.get("t"));
  var state = {
    t: isFinite(startT) ? Math.max(0, Math.min(LOOP, startT)) : 0,
    playing: !(qs.get("paused") === "1" || qs.get("paused") === "true") && !reduce,
  };

  var tiles = [];          // { key, def, clip, btn, stage, visible, lastT }
  var byKey = {};
  var metaByKey = {};
  META.forEach(function (m) { metaByKey[m.cat + ":" + m.id] = m; });

  function h(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }
  function badge() { return h("span", "noid", "no app id"); }

  // ---------- grid ----------
  var main = document.getElementById("grid");
  var nav = document.getElementById("catnav");
  var catOrder = [];
  defs.forEach(function (d) { if (catOrder.indexOf(d.cat) < 0) catOrder.push(d.cat); });

  catOrder.forEach(function (cat) {
    var list = defs.filter(function (d) { return d.cat === cat; });
    var sec = h("section", "cat");
    sec.id = "cat-" + cat;
    var h2 = h("h2", null, CAT_LABELS[cat] || cat);
    h2.appendChild(h("small", null, list.length + " clips"));
    sec.appendChild(h2);
    var grid = h("div", "tiles");
    list.forEach(function (def) {
      var key = def.cat + ":" + def.id;
      var m = metaByKey[key] || {};
      var btn = h("button", "tile");
      btn.type = "button";
      btn.setAttribute("aria-label", "Open " + def.name);
      var stage = h("div", "stage");
      btn.appendChild(stage);
      btn.appendChild(h("div", "name", def.name));
      btn.appendChild(h("div", "slug", def.id));
      if (!m.movementId) btn.appendChild(badge());
      var t = { key: key, def: def, clip: OogEngine.makeClip(def), btn: btn, stage: stage, visible: true, lastT: null };
      btn.addEventListener("click", function () { openSingle(key); });
      tiles.push(t); byKey[key] = t;
      grid.appendChild(btn);
    });
    sec.appendChild(grid);
    main.appendChild(sec);
    var a = h("a", "pill", CAT_LABELS[cat] || cat);
    a.href = "#cat-" + cat;
    nav.appendChild(a);
  });
  document.getElementById("count").textContent = defs.length + " clips";

  if ("IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        var t = byKey[en.target.getAttribute("data-key")];
        if (t) { t.visible = en.isIntersecting; if (en.isIntersecting) t.lastT = null; }
      });
    }, { rootMargin: "120px" });
    tiles.forEach(function (t) { t.btn.setAttribute("data-key", t.key); t.visible = false; io.observe(t.btn); });
  }

  // ---------- single view ----------
  var single = document.getElementById("single");
  var sName = document.getElementById("sName");
  var sMeta = document.getElementById("sMeta");
  var sStage = document.getElementById("sStage");
  var sPlay = document.getElementById("sPlay");
  var sScrub = document.getElementById("sScrub");
  var sTime = document.getElementById("sTime");
  var current = null;      // tile shown in the single view
  var singleLastT = null;
  var scrubbing = false;

  function updateUrl(key) {
    try {
      var p = new URLSearchParams(location.search);
      if (key) { var parts = key.split(":"); p.set("cat", parts[0]); p.set("id", parts.slice(1).join(":")); }
      else { p.delete("cat"); p.delete("id"); }
      var s = p.toString();
      history.replaceState(null, "", location.pathname + (s ? "?" + s : ""));
    } catch (e) { /* file:// and sandboxed frames may refuse */ }
  }

  function openSingle(key) {
    var t = byKey[key];
    if (!t) return false;
    var m = metaByKey[key] || {};
    current = t;
    sName.textContent = t.def.name;
    sMeta.textContent = "";
    var code = function (txt) { var c = h("code", null, txt); return c; };
    sMeta.appendChild(document.createTextNode("def id "));
    sMeta.appendChild(code(t.def.id));
    sMeta.appendChild(document.createTextNode(" in " + (CAT_LABELS[t.def.cat] || t.def.cat) + " / movementId "));
    if (m.movementId) sMeta.appendChild(code(m.movementId));
    else { sMeta.appendChild(code("null")); sMeta.appendChild(badge()); }
    if (m.aliases && m.aliases.length) {
      sMeta.appendChild(document.createTextNode(" / also serves "));
      m.aliases.forEach(function (a) { sMeta.appendChild(code(a)); });
    }
    if (t.def.sub) sMeta.appendChild(document.createTextNode(" / " + t.def.sub));
    document.title = "oog clip: " + t.def.id;
    single.hidden = false;
    singleLastT = null;
    updateUrl(key);
    syncControls();
    return true;
  }
  function closeSingle() {
    current = null;
    single.hidden = true;
    document.title = "Oog clips";
    updateUrl(null);
    tiles.forEach(function (t) { t.lastT = null; });
  }
  function syncControls() {
    sPlay.textContent = state.playing ? "Pause" : "Play";
    document.getElementById("allPlay").textContent = state.playing ? "Pause all" : "Play all";
  }
  function setPlaying(v) { state.playing = v; syncControls(); }

  document.getElementById("back").addEventListener("click", closeSingle);
  sPlay.addEventListener("click", function () { setPlaying(!state.playing); });
  document.getElementById("allPlay").addEventListener("click", function () { setPlaying(!state.playing); });
  sScrub.addEventListener("input", function () {
    scrubbing = true;
    state.t = parseFloat(sScrub.value) || 0;
    setPlaying(false);
  });
  sScrub.addEventListener("change", function () { scrubbing = false; });
  window.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && current) closeSingle();
    else if (e.key === " " && current && document.activeElement && document.activeElement.tagName !== "BUTTON") { e.preventDefault(); setPlaying(!state.playing); }
  });

  // ---------- render loop ----------
  var last = null;
  function frame(now) {
    if (last === null) last = now;
    var dt = Math.min(0.05, (now - last) / 1000); last = now;
    if (state.playing) state.t = (state.t + dt) % LOOP;
    if (current) {
      if (singleLastT !== state.t) {
        sStage.innerHTML = current.clip.svgAt(state.t);
        singleLastT = state.t;
        if (!scrubbing) sScrub.value = state.t.toFixed(2);
        sTime.textContent = state.t.toFixed(2) + " s";
      }
    } else {
      for (var i = 0; i < tiles.length; i++) {
        var t = tiles[i];
        if (t.visible && t.lastT !== state.t) { t.stage.innerHTML = t.clip.svgAt(state.t); t.lastT = state.t; }
      }
    }
    requestAnimationFrame(frame);
  }

  syncControls();
  var wantId = qs.get("id"), wantCat = qs.get("cat");
  if (wantId) {
    var key = null;
    if (wantCat && byKey[wantCat + ":" + wantId]) key = wantCat + ":" + wantId;
    else if (!wantCat) { for (var i = 0; i < tiles.length; i++) if (tiles[i].def.id === wantId) { key = tiles[i].key; break; } }
    if (!key || !openSingle(key)) {
      var note = h("p", null, "No clip with id " + wantId + (wantCat ? " in cat " + wantCat : "") + ".");
      note.style.color = "#E53935";
      main.insertBefore(note, main.firstChild);
    }
  }
  window.OogPreview = { state: state, tiles: tiles, openSingle: openSingle, closeSingle: closeSingle };
  requestAnimationFrame(frame);
})();
`;

const clientSrc = CLIENT
  .split("__META__").join(jsonForScript(meta))
  .split("__CAT_LABELS__").join(jsonForScript(CAT_LABELS));

const html = [
  "<!doctype html>",
  '<html lang="en"><head><meta charset="utf-8">',
  '<meta name="viewport" content="width=device-width, initial-scale=1">',
  "<title>Oog clips</title>",
  "<style>" + CSS + "</style></head>",
  "<body>",
  '<header class="top"><h1>Oog clips</h1><span class="count" id="count"></span>',
  '<button class="pill" id="allPlay" type="button">Pause all</button>',
  '<nav id="catnav" aria-label="Categories"></nav></header>',
  '<main id="grid"></main>',
  '<div id="single" hidden><div class="wrap">',
  '<div class="bar"><button class="pill" id="back" type="button">Back to all</button><h2 id="sName"></h2></div>',
  '<div class="meta" id="sMeta"></div>',
  '<div class="stage" id="sStage" role="img" aria-label="Exercise animation"></div>',
  '<div class="ctl"><button class="pill" id="sPlay" type="button">Pause</button>',
  '<input id="sScrub" type="range" min="0" max="10" step="0.01" value="0" aria-label="Time in seconds">',
  '<span class="time" id="sTime">0.00 s</span></div>',
  "</div></div>",
  "<script>" + engineSrc + "</script>",
  "<script>" + bundleSrc + "</script>",
  "<script>" + safeScript(clientSrc) + "</script>",
  "</body></html>",
  "",
].join("\n");

fs.writeFileSync(OUT, html);
const bytes = Buffer.byteLength(html);
console.log("wrote " + path.relative(path.resolve(__dirname, ".."), OUT) + " (" + (bytes / 1024).toFixed(1) + " KB, " + defs.length + " clips, " + meta.filter(m => !m.movementId).length + " without an app id)");
