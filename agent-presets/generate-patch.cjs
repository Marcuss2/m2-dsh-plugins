// @no-unit — kept as provenance: generates cordis.patch.yml from the legacy
// ~/.dsh/.agent-presets directories (DSH 0.1.7-rc.2 stopped reading them).
// Rerun after editing the legacy files to refreeze the bundle.
const fs = require("fs");
const path = require("path");

const HOME = process.env.HOME;
const legacyRoot = path.join(HOME, ".dsh", ".agent-presets");
const here = __dirname;

// One substitution for the removed package (dropped in 0.1.7-rc.2):
// @deepseek-ai/dsh-workflow-worker-thread -> @deepseek-ai/dsh-workflow-ptc,
// keeping config.provider: spawn. dsh-workflow-ptc is the workflowEngine
// PROVIDER the delegation group's isolate realm requires — the same row the
// shipped presets mount. (tool-workflow / tool-ralph only CONSUME it.)
const SUBST = {
  from: [
    "- id: workflow-worker-thread",
    "name: '@deepseek-ai/dsh-workflow-worker-thread'",
  ],
  to: [
    "- id: workflow-ptc",
    "name: '@deepseek-ai/dsh-workflow-ptc'",
  ],
};

function field(text, key) {
  const m = text.match(new RegExp("^" + key + ":\\s*(.*)$", "m"));
  if (!m) return "";
  let v = m[1].trim();
  if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) v = v.slice(1, -1);
  return v;
}

function presetDecl(card, entryText) {
  const indented = substitute(card.id, entryText)
    .replace(/^#.*$/gm, "") // strip the legacy file's leading commentary
    .replace(/\s+$/g, "")
    .split("\n")
    .map(l => (l.length ? " ".repeat(10) + l : ""))
    .join("\n");
  return [
    "- insert:",
    "    - id: preset-" + card.id,
    "      name: '@deepseek-ai/dsh-agent-preset'",
    "      config:",
    "        id: " + card.id,
    "        name: " + card.name,
    "        description: " + card.description,
    "        order: " + card.order,
    "        plugins:",
    indented,
  ].join("\n");
}

function substitute(card, indented) {
  let out = indented;
  for (let i = 0; i < SUBST.from.length; i++) {
    if (!out.includes(SUBST.from[i])) throw new Error(`card '${card}': expected the removed row line, not found: ${SUBST.from[i]}`);
    out = out.replace(SUBST.from[i], SUBST.to[i]);
  }
  return out;
}

const cards = [];
for (const [dir, override] of [["custom", { name: "Productivity Mode" }], ["coding", {}]]) {
  const card = {
    id: dir,
    order: 0,
    ...Object.fromEntries(["name", "description"].map(k => [k, field(fs.readFileSync(path.join(legacyRoot, dir, "preset.yml"), "utf8"), k)])),
    ...override,
  };
  for (const k of ["name", "description"]) card[k] = JSON.stringify(card[k]);
  cards.push(card);
}

const decls = cards.map((card, i) =>
  presetDecl(card, fs.readFileSync(path.join(legacyRoot, card.id, "agent.cordis.yml"), "utf8"))
);

const patch = [
  "# @local/dsh-custom-presets — legacy user presets, migrated.",
  "#",
  "# DSH 0.1.7-rc.2 no longer reads the legacy ~/.dsh/.agent-presets/<id>/",
  "# directories (preset.yml + agent.cordis.yml). Per the dsh-agent-preset",
  "# migration doc (skill editing-cordis-compositions), presets are now declared",
  "# as @deepseek-ai/dsh-agent-preset rows in a bundle patch. This file carries",
  "# both presets with the plugin entry lists taken verbatim from the legacy",
  "# agent.cordis.yml files, with one substitution:",
  "#",
  "#   @deepseek-ai/dsh-workflow-worker-thread (removed in 0.1.7-rc.2) ->",
  "#   @deepseek-ai/dsh-workflow-ptc (config.provider: spawn kept), the",
  "#   workflowEngine provider row the shipped presets mount.",
  "#",
  "# The 'custom' preset was renamed from \"Custom mode\" to \"Productivity Mode\"",
  "# at the user's request; its id stays `custom` so the registry default and",
  "# prior references keep working. To edit from the Web editor, restate the",
  "# whole plugins entry list: Web edits override config.plugins by id from the",
  "# profile patch, while this file is loader-edited by decl id.",
  "#",
  ...decls.flatMap(d => [d, ""]),
].join("\n");

fs.writeFileSync(path.join(here, "cordis.patch.yml"), patch);
console.log("cordis.patch.yml written,", patch.split("\n").length, "lines");
