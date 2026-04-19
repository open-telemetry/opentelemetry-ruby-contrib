// This script is necessary as we can't pass environment variables to
// npm scripts in a cross platform manner.
const { spawnSync } = require("node:child_process");

const cfg = process.env.lsconfig || "";

const result = spawnSync("linkspector", ["check", ...cfg.split(" ")], {
  stdio: "inherit",
  shell: true,
});

// Workaround for https://github.com/nodejs/node/issues/56645
setTimeout(() => {
  process.exit(result.status ?? 1);
}, 50);
