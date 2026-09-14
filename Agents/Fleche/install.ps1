# Flèche — installazione su Windows
#
# Rileva l'interprete Python, scrive hooks.json, verifica che gli hook
# funzionino davvero.
#
# Su Windows il nome dell'interprete è il problema principale: `python3` di
# norma non esiste, l'eseguibile è `python` oppure `py -3`. Un hooks.json che
# dice `python3` non parte — e non lo segnala: l'azione passa e il sistema
# sembra funzionare senza applicare alcun controllo.

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$py = $null
foreach ($c in @("python", "python3", "py")) {
    $cmd = Get-Command $c -ErrorAction SilentlyContinue
    if ($null -eq $cmd) { continue }
    try {
        $v = & $c -c "import sys;print(sys.version_info[0])" 2>$null
        if ($v -eq "3") { $py = $c; break }
    } catch { continue }
}

if ($null -eq $py) {
    Write-Host "X nessun interprete Python 3 trovato." -ForegroundColor Red
    Write-Host "  Fleche richiede Python 3. Installalo da python.org o dallo Store,"
    Write-Host "  assicurandoti di spuntare 'Add python.exe to PATH'."
    exit 1
}

& $py (Join-Path $here "tools\setup.py")
exit $LASTEXITCODE
