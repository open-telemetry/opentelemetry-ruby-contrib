// This script is necessary as we can't pass environment variables to
// npm scripts in a cross platform manner.
import { spawnSync } from "node:child_process";

const cfg = process.env.lsconfig || "";

const result = spawnSync("linkspector", ["check", ...cfg.split(" ")], {
  stdio: "inherit",
  shell: true
});

process.exit(result.status ?? 1);
