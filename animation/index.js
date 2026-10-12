// Loads the Oog engine and every exercise definition file.
// Exports { engine, defs, exFiles }: defs is the concatenated list of all clip defs
// (each def keeps its `cat`), exFiles is the list of ex_*.js files that were loaded
// (build-preview.js bundles the same files).
const path = require("path");
const fs = require("fs");

const engine = require("./engine.js");

const FILES = ["ex_legs.js", "ex_hinge.js", "ex_push.js", "ex_pull.js", "ex_core.js", "ex_extra.js"];

const defs = [];
const exFiles = [];
for (const f of FILES) {
  if (!fs.existsSync(path.join(__dirname, f))) continue;
  exFiles.push(f);
  const list = require("./" + f);
  if (!Array.isArray(list)) throw new Error(f + " must export an array of defs");
  defs.push(...list);
}

module.exports = { engine, defs, exFiles };
