// This script is necessary as we can't pass environment variables to
// npm scripts in a cross platform manner.
import { execSync } from "node:child_process";

const cfg = process.env.lsconfig || "";

execSync(`linkspector check ${cfg}`, { stdio: "inherit" });
