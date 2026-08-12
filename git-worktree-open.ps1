# git-worktree-open.ps1 (gwt.ps1)
# Run from any Git repo terminal. Creates a worktree and opens it in your current editor.

# 1) Auto-detect repo root and current branch
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Host "ERROR: Not inside a Git repository." -ForegroundColor Red
    exit 1
}

$currentBranch = git rev-parse --abbrev-ref HEAD 2>$null

Write-Host ""
Write-Host "Repo   : $repoRoot"
Write-Host "Branch : $currentBranch"
Write-Host ""

# 2) Ask for target branch
$targetBranch = Read-Host "Enter branch name for the new worktree"
if (-not $targetBranch) {
    Write-Host "ERROR: No branch name provided." -ForegroundColor Red
    exit 1
}

# 3) Build worktree path (sibling folder)
$repoName = Split-Path $repoRoot -Leaf
$parentDir = Split-Path $repoRoot -Parent
$folderName = $targetBranch -replace '/', '-'
$worktreePath = Join-Path $parentDir "$repoName-$folderName"

# 4) If worktree already exists, just open it
if (Test-Path $worktreePath) {
    Write-Host "Worktree already exists at: $worktreePath" -ForegroundColor Yellow
} else {
    # 5) Create the worktree
    git show-ref --verify --quiet "refs/heads/$targetBranch" 2>$null
    $localExists = $LASTEXITCODE -eq 0

    if ($localExists) {
        Write-Host "Creating worktree for existing local branch..."
        git worktree add $worktreePath $targetBranch
    } else {
        git fetch origin 2>$null
        git show-ref --verify --quiet "refs/remotes/origin/$targetBranch" 2>$null
        $remoteExists = $LASTEXITCODE -eq 0

        if ($remoteExists) {
            Write-Host "Creating worktree tracking remote branch..."
            git worktree add $worktreePath $targetBranch
        } else {
            $create = Read-Host "Branch '$targetBranch' not found. Create new branch off '$currentBranch'? (y/n)"
            if ($create -eq 'y') {
                git worktree add -b $targetBranch $worktreePath
            } else {
                Write-Host "Aborted."
                exit 1
            }
        }
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to create worktree." -ForegroundColor Red
        exit 1
    }
}

# 6) Auto-detect editor and find its executable
function Find-EditorExe {
    param([string]$editorName)

    $jetbrainsBase = "$env:LOCALAPPDATA\JetBrains\Toolbox\scripts"
    $programFiles = $env:ProgramFiles
    $programFilesX86 = ${env:ProgramFiles(x86)}

    switch ($editorName) {
        "IntelliJ" {
            $paths = @(
                "$jetbrainsBase\idea.cmd",
                (Get-ChildItem "$programFiles\JetBrains\IntelliJ*\bin\idea64.exe" -ErrorAction SilentlyContinue | Sort-Object -Descending | Select-Object -First 1)
            )
        }
        "WebStorm" {
            $paths = @(
                "$jetbrainsBase\webstorm.cmd",
                (Get-ChildItem "$programFiles\JetBrains\WebStorm*\bin\webstorm64.exe" -ErrorAction SilentlyContinue | Sort-Object -Descending | Select-Object -First 1)
            )
        }
        "PyCharm" {
            $paths = @(
                "$jetbrainsBase\pycharm.cmd",
                (Get-ChildItem "$programFiles\JetBrains\PyCharm*\bin\pycharm64.exe" -ErrorAction SilentlyContinue | Sort-Object -Descending | Select-Object -First 1)
            )
        }
        "GoLand" {
            $paths = @(
                "$jetbrainsBase\goland.cmd",
                (Get-ChildItem "$programFiles\JetBrains\GoLand*\bin\goland64.exe" -ErrorAction SilentlyContinue | Sort-Object -Descending | Select-Object -First 1)
            )
        }
        "Rider" {
            $paths = @(
                "$jetbrainsBase\rider.cmd",
                (Get-ChildItem "$programFiles\JetBrains\Rider*\bin\rider64.exe" -ErrorAction SilentlyContinue | Sort-Object -Descending | Select-Object -First 1)
            )
        }
        "PhpStorm" {
            $paths = @(
                "$jetbrainsBase\phpstorm.cmd",
                (Get-ChildItem "$programFiles\JetBrains\PhpStorm*\bin\phpstorm64.exe" -ErrorAction SilentlyContinue | Sort-Object -Descending | Select-Object -First 1)
            )
        }
        "VS Code" { return "code" }
        "VS Code Insiders" { return "code-insiders" }
        "Cursor" { return "cursor" }
        "Windsurf" { return "windsurf" }
        "Sublime Text" { return "subl" }
        "Zed" { return "zed" }
        default { return $null }
    }

    foreach ($p in $paths) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    return $null
}

function Get-Editor {
    $editorMap = @(
        @{ Pattern = "idea";           Name = "IntelliJ" },
        @{ Pattern = "idea64";         Name = "IntelliJ" },
        @{ Pattern = "webstorm";       Name = "WebStorm" },
        @{ Pattern = "webstorm64";     Name = "WebStorm" },
        @{ Pattern = "pycharm";        Name = "PyCharm" },
        @{ Pattern = "pycharm64";      Name = "PyCharm" },
        @{ Pattern = "goland";         Name = "GoLand" },
        @{ Pattern = "goland64";       Name = "GoLand" },
        @{ Pattern = "rider";          Name = "Rider" },
        @{ Pattern = "rider64";        Name = "Rider" },
        @{ Pattern = "phpstorm";       Name = "PhpStorm" },
        @{ Pattern = "phpstorm64";     Name = "PhpStorm" },
        @{ Pattern = "cursor";         Name = "Cursor" },
        @{ Pattern = "windsurf";       Name = "Windsurf" },
        @{ Pattern = "Code - Insiders"; Name = "VS Code Insiders" },
        @{ Pattern = "Code";           Name = "VS Code" },
        @{ Pattern = "sublime_text";   Name = "Sublime Text" },
        @{ Pattern = "zed";            Name = "Zed" }
    )

    # Walk up process tree
    try {
        $proc = Get-Process -Id $PID -ErrorAction SilentlyContinue
        $visited = @{}
        while ($proc) {
            if ($visited.ContainsKey($proc.Id)) { break }
            $visited[$proc.Id] = $true
            $procName = $proc.ProcessName.ToLower()
            foreach ($editor in $editorMap) {
                if ($procName -eq $editor.Pattern.ToLower()) {
                    return $editor.Name
                }
            }
            $proc = $proc.Parent
        }
    } catch {}

    # Fallback: check running processes
    $running = Get-Process -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName -Unique
    foreach ($editor in $editorMap) {
        if ($running -contains $editor.Pattern) {
            return $editor.Name
        }
    }

    return $null
}

$editorName = Get-Editor

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Worktree ready:"
Write-Host "  $worktreePath [$targetBranch]" -ForegroundColor Cyan
Write-Host ""

if ($editorName) {
    $editorExe = Find-EditorExe $editorName
    if ($editorExe) {
        Write-Host "Detected: $editorName" -ForegroundColor Yellow
        Write-Host "Opening new window..."
        & $editorExe $worktreePath
    } else {
        Write-Host "Detected $editorName but couldn't find its executable." -ForegroundColor Red
        Write-Host "Open this folder manually: $worktreePath"
    }
} else {
    Write-Host "Could not detect your editor. Open this folder manually:" -ForegroundColor Yellow
    Write-Host "  $worktreePath"
}

Write-Host ""
Write-Host "You now have:"
Write-Host "  Window 1: $repoRoot [$currentBranch]"
Write-Host "  Window 2: $worktreePath [$targetBranch]"
Write-Host ""
Write-Host "Both push to the same remote."
