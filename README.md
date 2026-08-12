# gwt

A simple CLI tool that lets you work on multiple Git branches at the same time — no stashing, no switching. Just open another branch in a new editor window.

<!-- Replace with an actual GIF/screenshot of the script in action -->
![Demo](demo.gif)

## The Problem

You're deep in work on `feature-A`, and someone asks you to review `feature-B`. Normally you'd have to stash your changes, switch branches, open the project again — annoying.

**gwt** creates a [Git worktree](https://git-scm.com/docs/git-worktree) for any branch and opens it in a fresh editor window. Your current work stays untouched.

## How to Use

1. Drop `git-worktree-open.ps1` into your project (or anywhere you like)
2. Open a terminal inside your Git repo
3. Run it:

```powershell
.\git-worktree-open.ps1
```

4. Type the branch name when prompted — that's it!

The script will:
- Create a worktree folder next to your repo (e.g., `my-project-feature-B/`)
- Detect your editor automatically
- Open the worktree in a new window

You end up with two windows, both pushing to the same remote:
```
Window 1: my-project [feature-A]
Window 2: my-project-feature-B [feature-B]
```

> **Tip:** If the branch doesn't exist yet, the script will offer to create it for you off your current branch.

## Supported Editors

The script auto-detects whichever editor you're running it from:

| Editor | Detected |
|--------|----------|
| VS Code | ✅ |
| VS Code Insiders | ✅ |
| Cursor | ✅ |
| Windsurf | ✅ |
| IntelliJ IDEA | ✅ |
| WebStorm | ✅ |
| PyCharm | ✅ |
| GoLand | ✅ |
| Rider | ✅ |
| PhpStorm | ✅ |
| Sublime Text | ✅ |
| Zed | ✅ |

If it can't detect your editor, it'll print the folder path so you can open it manually.

## How It Works (briefly)

1. Figures out your repo root and current branch
2. Asks which branch you want to work on
3. Creates a Git worktree as a sibling folder (same parent directory as your repo)
4. Walks up the process tree to figure out which editor launched the terminal
5. Opens the worktree folder in a new editor window

No global installs. No dependencies beyond Git and PowerShell.

## Notes

- **Windows + PowerShell** — this script is built for Windows. It uses PowerShell-specific features like process tree walking and Windows-specific editor paths.
- **Git required** — make sure `git` is available in your PATH.
- If you get an execution policy error, run: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`
