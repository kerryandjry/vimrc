import { execFile } from "node:child_process";

const FOCUS_IN = "\x1b[I";
const FOCUS_OUT = "\x1b[O";
const ENABLE_FOCUS_REPORTING = "\x1b[?1004h";
const DISABLE_FOCUS_REPORTING = "\x1b[?1004l";

function announceMode(mode) {
  // OSC 2 reaches Kitty directly, or becomes tmux's pane_title. The local
  // Hammerspoon config watches it so a remote process can request English.
  process.stdout.write(`\x1b]2;terminal:pi-${mode}\x07`);
}

function enterMode(mode) {
  const simplified = mode === "insert" ? "insert" : "normal";
  announceMode(simplified);
  if (simplified === "normal" && process.platform === "darwin") {
    execFile("/opt/homebrew/bin/hs", ["-c", "setEnglishInputSource()"], () => {});
  }
}

export default function (pi) {
  pi.events.on("pi-vim:mode-change", (data) => {
    if (data?.mode) enterMode(data.mode);
  });

  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    const previous = ctx.ui.getEditorComponent();
    if (!previous) return;

    process.stdout.write(ENABLE_FOCUS_REPORTING);
    announceMode("insert");
    ctx.ui.setEditorComponent((tui, theme, keybindings) => {
      const editor = previous(tui, theme, keybindings);
      const originalHandleInput = editor.handleInput.bind(editor);

      editor.handleInput = (data) => {
        if (data === FOCUS_IN) {
          const mode = editor.getMode?.();
          if (mode) enterMode(mode);
          return;
        }
        if (data === FOCUS_OUT) return;
        originalHandleInput(data);
      };

      return editor;
    });
  });

  pi.on("session_shutdown", (_event, ctx) => {
    if (ctx.mode === "tui") process.stdout.write(DISABLE_FOCUS_REPORTING);
  });
}
