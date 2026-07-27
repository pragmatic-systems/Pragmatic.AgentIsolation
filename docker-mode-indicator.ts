/**
 * Docker Mode Indicator Extension
 *
 * Detects when Pi is running with Docker support (via PI_DOCKER_MODE env var
 * set by the host scripts) and shows a persistent status indicator in the footer.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {

    // Set Docker Status
    var message = "🐳 Secure Sandbox";

    const inDocker = process.env.PI_DOCKER_MODE === "true";
    if (inDocker) {
      message += " (❗) docker in docker (❗)";
    }
    else {
      message += " (✅) locked down (✅)";
    }

    ctx.ui.setStatus(
      "sandbox-mode",
      ctx.ui.theme.fg("warning", message),
    );
  });
}