param([switch]$Verify)
$ErrorActionPreference = 'Stop'
$candidates = @()
foreach ($name in @('python','python3','py')) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -notlike '*\WindowsApps\*') { $candidates += $cmd.Source }
}
$candidates += @(Get-ChildItem -Path "$env:LOCALAPPDATA\Python\pythoncore-*\python.exe","$env:LOCALAPPDATA\Programs\Python\Python*\python.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
foreach ($candidate in $candidates | Select-Object -Unique) {
    & $candidate -c 'import sys,sqlite3; sys.exit(0 if sys.version_info >= (3,10) and sqlite3.sqlite_version_info >= (3,37) else 1)' 2>$null
    if ($LASTEXITCODE -eq 0) {
        $arguments = @((Join-Path $PSScriptRoot 'run.py'))
        if ($Verify) { $arguments += '--verify' }
        & $candidate @arguments
        exit $LASTEXITCODE
    }
}
throw 'Instala Python 3.10+ con SQLite 3.37+, o ejecuta run.py con un intérprete compatible.'
