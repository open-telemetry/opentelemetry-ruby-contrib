// This script is necessary as we can't pass environment variables to
// npm scripts in a cross platform manner.

const os = require("node:os");

// Detect Windows and exit immediately
// Workaround for https://github.com/nodejs/node/issues/56645
if (os.platform() === "win32") {
  console.log("Skipping linkspector on Windows to avoid runner teardown bug");
  process.exit(0);
}

const { spawnSync } = require("node:child_process");

const cfg = process.env.lsconfig || "";

const result = spawnSync("linkspector", ["check", ...cfg.split(" ")], {
  stdio: "inherit",
  shell: true,
});

// Workaround for https://github.com/nodejs/node/issues/56645

  process.exit(result.status ?? 1);
