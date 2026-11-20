[CmdletBinding()]
param(
    [ValidateSet("lint", "build", "run")]
    [string]$Mode = "run",

    [string]$Testbench = "ALU_tb.sv",

    [string]$Top = "ALU_tb",

    [string]$BuildDir = "obj_dir"
)

$ErrorActionPreference = "Stop"

$Verilator = Get-Command verilator -ErrorAction SilentlyContinue
if (-not $Verilator) {
    throw "Verilator was not found in PATH. Add the Verilator bin directory to PATH and try again."
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$TestbenchPath = Join-Path $ScriptDir $Testbench
if (-not (Test-Path $TestbenchPath)) {
    throw "Testbench not found: $TestbenchPath"
}

$AluPath = Join-Path $ScriptDir "ALU.sv"
if (-not (Test-Path $AluPath)) {
    throw "ALU source not found: $AluPath"
}

$Arguments = @(
    "--Wall",
    "--timing",
    "--top-module", $Top,
    "--Mdir", $BuildDir,
    $AluPath,
    $TestbenchPath
)

if ($Mode -eq "lint") {
    & $Verilator.Source --lint-only @Arguments
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Write-Host "Verilator lint passed."
    exit 0
}

& $Verilator.Source --binary @Arguments
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$Executable = Join-Path $BuildDir "V$Top"
if ([System.Environment]::OSVersion.Platform -eq "Win32NT") {
    $Executable += ".exe"
}

if (-not (Test-Path $Executable)) {
    throw "Verilator executable was not created: $Executable"
}

if ($Mode -eq "build") {
    Write-Host "Verilator build passed: $Executable"
    exit 0
}

& $Executable
exit $LASTEXITCODE
