# Desktop clients for DSH — research note (2026-08-28)

**Status: recommendation only — nothing installed.** The kit's delivery model
remains the Web GUI on `127.0.0.1:3080` (`dsh --profile web`); this note exists
so the search does not have to be repeated.

## The ask

The browser GUI works but is "a bit clunky" — find an existing way to run DSH
as a desktop application (Electron or Tauri expected). Per ground rule 1,
searched before proposing anything new.

## Machine context (drives compatibility)

- Arch Linux, native (no WSL), **Wayland under Hyprland**
- upstream `dsh` **0.1.1-rc.2** installed globally (`/usr/bin/dsh`), `DSH_HOME=~/.dsh`
- web profile with all kit bundles; GUI served on `127.0.0.1:3080`

→ Anything Windows/macOS-only is dead on arrival; anything Electron or
Tauri must ship a Linux artifact and tolerate Wayland.

## Recommendation: dsh-tauri-desk/deepseek-harness-desktop

"DeepSeek Harness 桌面版" — https://github.com/dsh-tauri-desk/deepseek-harness-desktop
(listed in the awesome-dsh-plugin intro as `hairyf/deepseek-harness-desktop`;
that repo 301s to this org). MIT. **★1,333 — pushed and released v0.9.2 the day
of this research (2026-08-28).**

Why it fits this setup:

- **Tauri 2** shell (Rust + WebKitGTK, explicitly "非 Electron"): small
  install, low memory, native window — the user's stated preference.
- **Wraps, does not replace.** It serves the *same* harness surface
  (`dsh --profile <档案> --host 127.0.0.1 --port 3080`, `DSH_HOME=~/.dsh`)
  inside the window. On first run it downloads a Node runtime + Harness core
  **only when no global `dsh` exists — the CLI-installed core is preferred**,
  so this kit's core, web profile, settings (`qwencloud` provider +
  reasoning-effort declarations) and all nine bundles carry over unchanged.
- Adds what the browser lacks: native window/menus, tray, plugin panel with
  per-plugin upgrade/uninstall + error surface, preset onboarding (includes
  DSH Market), built-in first-party plugins (`dsh-tauri` host bridge,
  `dsh-tauri-worktree` per-session Git worktrees, panel/skills management),
  app self-update, `dsh` CLI shim (PATH-registered, no rc edits).
- Releases include **`Deepseek.Harness.Desktop_<ver>_amd64.AppImage` and
  `_amd64.deb`** (plus macOS dmg/Homebrew tap, Windows msi/exe). No AUR
  package exists (checked) — on Arch: run the AppImage, `dpkg-deb -x` the
  .deb, or convert with `debtap`.

Known caveat for this machine (documented by the project itself): the
AppImage can black-screen/crash under Wayland (WebKitGTK; reports from
PikaOS/GNOME Wayland/Ubuntu 22.04+). The app auto-handles common cases; the
manual fallbacks are the **.deb** (verified on Wayland) or launching with
`WEBKIT_DISABLE_COMPOSITING_MODE=1 WEBKIT_DISABLE_DMABUF_RENDERER=1
GDK_BACKEND=x11` (forces XWayland — fine under Hyprland). If the icon is
missing after install, copy the bundled `hicolor` icons into
`~/.local/share/icons` and run `update-desktop-database`.

Docs are Chinese-first (`README.zh.md` default, English README available);
the project labels itself a development preview that tracks fast upstream
changes. Upstream's own awesome-list endorses it ("ships dsh-market built
in"), and its core-download channel is `deepseek-harness-pkg` (their
repackaging of upstream releases) — used only when no local core is present.

## Adoption steps when the user decides to go desktop

1. Download the latest `amd64.deb` (preferred on Wayland) or AppImage from
   GitHub Releases; install/extract per Arch above.
2. Point it at the existing `web` profile (or accept its default) — it reuses
   `~/.dsh`, so **no bundle reinstallation is needed**.
3. Stop the plain `dsh --profile web` server first if it holds port 3080, or
   let the app pick its port; one `dsh` server at a time per profile.
4. If the window is black on Hyprland: .deb, or the env-var launch above.
5. Record a kit entry (`plugins/deepseek-harness-desktop/` or a `clients/`
   section) with the version adopted and these steps verified; add to
   `RESTORE.md` as a client choice, not a bundle (profile composition does
   not change).

## Alternatives considered (all rejected; 2026-08-28 evidence)

| Candidate | What it is | Why not |
|---|---|---|
| **s3yf1337/dsh-desktop** (★2, v0.2.3a 2026-08-16, Linux .deb+tar.gz, MIT) | The honest plugin answer: a `desktop` *profile* = `dsh-base` + `dsh-web-app` + `dsh-desktop-shell`; the bundle spawns a native Tauri window on the served URL. Tray agent monitor, real file-manager panel, in-chat search, close-to-tray, `dsh-desktop` Settings tab. | Very young/low adoption; its separate `desktop` profile means re-running the batched `dsh plugin add` for all nine bundles there; spawn model = "open a window for a whole extra harness profile" rather than managing the existing one. First choice *if* the plugin-native route is ever mandated. |
| **hust-open-atom-club/oh-dsh** (★288, very active) | Community **distribution**: one `ohdsh` command for Desktop + Web + TUI, own plugin market, skins, install.sh on Linux. | Ships **pinned copies of DSH + Node** per release — adopts a fork-of-stack, not a client of ours; the kit's whole point is a stock upstream install. Migration would re-platform `~/.dsh` onto their cadence. |
| dataelement/dsh-desktop (Electron, dshdesktop.com) | Polished standalone: signed/notarized, Safe Mode, phone pairing via Cloudflare tunnel, portable presets. | Platform table: **Linux "Not currently supported."** Excluded. |
| anywhere-labs/deepseek-harness-desktop | Electron "everything is a plugin incl. the desktop", Windows+macOS, pins an upstream version. | No Linux artifact. Excluded. |
| FuqiangCraft/dsh-desktop (★5, v0.2.5 2026-08-28) | Tauri shell + companion plugins (screen capture tool, agent tiling grid, native notifications). | Latest release ships **Windows Setup/Portable only**. Excluded. |
| Icather/dsh-clean-desktop-shell | Plugin shell: native window over your existing web profile, tray-managed backend, offline reconnect. | Windows + macOS only. Would have been a strong fit on those OSes. |
| MDR-EX1000/dsh-desktop-kit | Tauri/WKWebView macOS shell + plugin. | macOS only. |
| ZichengGurrr/dsh-window, ReachGa0/dsh-desktop, RAFOLIE/dsh-desktop-windowos, pingg02/dsh-desktop-entry, ayingQAQ/dsh-web-launcher, HUITianYi/dsh-whale-desktop-launcher, ingleav626-art/dsh-native-launcher, Isilsolme/dsh-splash-launcher, liyu34/dsh-wsl-tray, YV3507/dsh-webui-launcher, Yvesgao/dsh-desktop-launcher, acebang0303/dsh-quick-launch, hanwuji1/dsh-web-launcher, jinsiyu/dsh-auto-open-web (WebView2) | Windows (or WSL) launchers / Chrome-app-mode / tray wrappers. | Not Linux-native; most are "browser in costume" — no real native surface. |
| wodongx123/dsh-desktop-tray; luumod/dsh-desktop-lifecycle; Ch0uHuaZ1/DeepSeek-Harness-Desktop | Companion plugins *for* DSH Desktop (the dataelement client) — tray hide-on-close, close/restart controls, launcher card. | Depend on a client with no Linux build. |
| happpsee/dsh-desktop-app (skill) | Playbook for packaging DSH into your own Tauri 2 app (macOS + Windows). | macOS + Windows recipes only; DIY, not a client. |
| Browser "desktop-feel" UI plugins (hunter118/dsh-s7r System-7 workstation, SamizuHM/dsh-client-ui-theme-xp, AlexYin-Tongji/dsh-ui-enhancer, lsz-asd/dsh-chameleon self-editing workbench) | Make the web tab *look* desktop-ish. | The complaint is the delivery model (tab chrome, no tray/notifications/native pickers), not the styling. |

## Sources

- `.research/awesome-dsh-plugin.md` — intro §"On desktop clients" + UI Enhancements /
  Development & Runtime sections (local snapshot, 619 KB).
- GitHub API: repo metadata + release assets for s3yf1337/dsh-desktop,
  dsh-tauri-desk/deepseek-harness-desktop, FuqiangCraft/dsh-desktop,
  hust-open-atom-club/oh-dsh, dataelement, anywhere-labs.
- READMEs fetched for all four serious candidates (Tauri/Electron details,
  Wayland notes, architecture diagrams, install commands).
- AUR RPC search (`deepseek-harness`, `dsh-desktop`): no packages.
- Live machine: `uname`/`/proc/version` (Arch kernel 7.1.9), `XDG_SESSION_TYPE=wayland`,
  `DESKTOP_SESSION=hyprland-uwsm`, `/usr/bin/dsh` → 0.1.1-rc.2.
