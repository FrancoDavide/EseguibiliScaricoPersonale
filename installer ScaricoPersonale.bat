@echo off
chcp 65001 > nul

echo === ESTRATTORE SMART UNIVERSALE COMPLETO ===
echo.

:: 1. Rilevamento automatico del file publish.zip
if exist "publish.zip" (
    set "zip_path=%~dp0publish.zip"
    echo [OK] File publish.zip rilevato automaticamente.
) else (
    echo [ERRORE] File 'publish.zip' non trovato nella cartella corrente!
    echo.
    pause
    exit
)
echo.

:: 2. Richiesta della cartella di destinazione principale
set /p "dest_path=1. Trascina qui la cartella di destinazione e premi Invio: "
set "dest_path=%dest_path:"=%"
echo.

:: 3. Richiesta del file Excel
set /p "excel_path=2. Trascina qui il file Excel da inserire e premi Invio: "
set "excel_path=%excel_path:"=%"
echo.

echo FASE 1: Estrazione archivi e allineamento cartelle...
echo.

:: 4. Creazione cartella temporanea pulita
powershell -Command "$tempDir = Join-Path $env:TEMP 'zip_extract_temp'; if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }; $null = New-Item -ItemType Directory -Path $tempDir -Force"

:: 5. Estrazione del file publish.zip
powershell -Command "$tempDir = Join-Path $env:TEMP 'zip_extract_temp'; Expand-Archive -Path '%zip_path%' -DestinationPath $tempDir -Force"

:: 6. Copia del contenuto nella destinazione reale (entra dentro 'publish' dello ZIP se presente)
powershell -Command "$realDest = '%dest_path%'; if ((Split-Path $realDest -Leaf) -ne 'publish') { $realDest = Join-Path $realDest 'publish' }; if (-not (Test-Path $realDest)) { $null = New-Item -ItemType Directory -Path $realDest -Force }; $tempSrc = Join-Path $env:TEMP 'zip_extract_temp'; if (Test-Path (Join-Path $tempSrc 'publish')) { $tempSrc = Join-Path $tempSrc 'publish' }; Get-ChildItem -Path $tempSrc | ForEach-Object { Copy-Item $_.FullName -Destination $realDest -Recurse -Force }"

:: 7. Sblocco di sicurezza dei file per evitare blocchi o restrizioni di Windows
powershell -Command "$realDest = '%dest_path%'; if ((Split-Path $realDest -Leaf) -ne 'publish') { $realDest = Join-Path $realDest 'publish' }; Get-ChildItem -Path $realDest -Recurse | Unblock-File; Write-Host '[OK] File sbloccati dalle restrizioni di sicurezza!'"

:: 8. Pausa di sincronizzazione hardware per consolidare i file sul disco
powershell -Command "Start-Sleep -Seconds 2"

echo.
echo FASE 2: Pulizia, gestione Excel e configurazione JSON...
echo.

:: 9. Rimozione dei file .pdb ricorsivamente nella destinazione
powershell -Command "$realDest = '%dest_path%'; if ((Split-Path $realDest -Leaf) -ne 'publish') { $realDest = Join-Path $realDest 'publish' }; Get-ChildItem -Path $realDest -Filter *.pdb -Recurse | Remove-Item -Force"

:: 10. Gestione file Excel (crea la cartella 'FILE GESTIONALI' dentro 'publish' se non esiste e copia il file)
powershell -Command "$realDest = '%dest_path%'; if ((Split-Path $realDest -Leaf) -ne 'publish') { $realDest = Join-Path $realDest 'publish' }; $targetExcelDir = Join-Path $realDest 'FILE GESTIONALI'; if (-not (Test-Path $targetExcelDir)) { $null = New-Item -ItemType Directory -Path $targetExcelDir -Force }; Copy-Item '%excel_path%' -Destination $targetExcelDir -Force"

:: 11. Aggiornamento pulito in UTF-8 senza BOM del file appsettings.json
powershell -Command "$realDest = '%dest_path%'; if ((Split-Path $realDest -Leaf) -ne 'publish') { $realDest = Join-Path $realDest 'publish' }; $jsonPath = Join-Path $realDest 'config\appsettings.json'; if (Test-Path $jsonPath) { $excelFileName = Split-Path '%excel_path%' -Leaf; $finalExcelPath = Join-Path $realDest \"FILE GESTIONALI\$excelFileName\"; $finalOutputDir = Join-Path $realDest 'FILE GESTIONALI'; $json = Get-Content $jsonPath -Raw | ConvertFrom-Json; $json.PercorsoFileFrontiera = $finalExcelPath; $json.PercorsoCartellaOutput = $finalOutputDir; $Utf8NoBom = New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($jsonPath, ($json | ConvertTo-Json -Depth 10), $Utf8NoBom); Write-Host '[OK] File appsettings.json configurato correttamente!' } else { Write-Warning 'File appsettings.json non trovato in config\appsettings.json' }"

echo.
echo FASE 3: Creazione collegamento sul Desktop da Amministratore...
echo.

:: 12. Creazione sicura del collegamento .lnk sul Desktop con flag Amministratore nativo (SU UNA RIGA)
powershell -Command "$realDest = '%dest_path%'; if ((Split-Path $realDest -Leaf) -ne 'publish') { $realDest = Join-Path $realDest 'publish' }; $exeFile = Get-ChildItem -Path $realDest -Filter 'ScaricoPersonale.exe' | Select-Object -First 1; if ($exeFile) { $desktopPath = [System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), 'ScaricoPersonale.lnk'); $ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut($desktopPath); $sc.TargetPath = $exeFile.FullName; $sc.WorkingDirectory = $realDest; $sc.Save(); $bytes = [System.IO.File]::ReadAllBytes($desktopPath); $bytes[21] = $bytes[21] -bor 32; [System.IO.File]::WriteAllBytes($desktopPath, $bytes); Write-Host '[OK] Collegamento da Amministratore creato sul tuo Desktop!' } else { Write-Warning 'File ScaricoPersonale.exe non trovato in publish.' }"

:: 13. Pulizia finale dei file temporanei
powershell -Command "$tempDir = Join-Path $env:TEMP 'zip_extract_temp'; if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }"

echo.
echo [OK] Procedura terminata con successo! L'ambiente è pronto e configurato.
echo.
pause
