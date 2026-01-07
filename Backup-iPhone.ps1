param(
    [string]$PhoneName = "Apple iPhone",
    [string]$SourcePath = "Internal Storage\DCIM",
    [string]$DestRoot = "E:\iPhone_Backup",
    [switch]$SkipExisting,
    [switch]$SkipAAE  
)

# === НАСТРОЙКИ ===
$BatchSize = 19         
$BatchDelaySec = 3     
# =================

$Shell = New-Object -ComObject Shell.Application
$Global:Counter = 0

# --- 1. Поиск iPhone ---
$Phone = $Shell.NameSpace(17).Items() | Where-Object { $_.Name -eq $PhoneName }
if (-not $Phone) { Write-Error "Устройство '$PhoneName' не найдено!"; exit 1 }

# --- 2. Вход в папку ---
$CurrentObj = $Phone
$PathParts = $SourcePath -split '\\' | Where-Object { $_ -ne "" }
foreach ($part in $PathParts) {
    if ($CurrentObj -is [string] -or $CurrentObj.Type -eq "System Folder") { $FolderData = $Shell.NameSpace($CurrentObj.Path) }
    elseif ($CurrentObj.IsFolder) { $FolderData = $CurrentObj.GetFolder }
    else { $FolderData = $Shell.NameSpace($CurrentObj.Path) }
    if (-not $FolderData) { Write-Error "Ошибка доступа"; exit 1 }
    $NextItem = $FolderData.Items() | Where-Object { $_.Name -eq $part }
    if (-not $NextItem) { Write-Error "Папка '$part' не найдена"; exit 1 }
    $CurrentObj = $NextItem
}
$SourceFolderItem = $CurrentObj
Write-Host "Источник: $($SourceFolderItem.Name)" -ForegroundColor Green

if (-not (Test-Path $DestRoot)) { New-Item -ItemType Directory -Path $DestRoot -Force | Out-Null }

# --- Функция ---
function Copy-FolderRecursive {
    param($FolderItem, [string]$LocalDestPath)

    $FolderObj = $FolderItem.GetFolder
    if (-not $FolderObj) { return }

    $items = $FolderObj.Items() | Sort-Object Name
    $FolderName = $FolderItem.Name

    # Хеш для дублей
    $ProcessedNames = @{} 

    foreach ($item in $items) {
        if ($item.IsFolder) {
            $subDest = Join-Path $LocalDestPath $item.Name
            if (-not (Test-Path $subDest)) { New-Item -ItemType Directory -Path $subDest -Force | Out-Null }
            Copy-FolderRecursive -FolderItem $item -LocalDestPath $subDest
        }
        else {
            $Name = $item.Name
            
            # --- ФИЛЬТР AAE ---
            if ($SkipAAE -and ($Name -like "*.AAE" -or $Name -like "*.aae")) {
                Write-Host "[$FolderName] $Name (SKIP AAE)" -ForegroundColor DarkGray
                continue
            }

            # --- ФИЛЬТР ДУБЛЕЙ ---
            if ($ProcessedNames.ContainsKey($Name)) {
                Write-Host "[$FolderName] $Name (ДУБЛЬ - ИГНОР)" -ForegroundColor DarkGray
                continue
            }
            $ProcessedNames[$Name] = $true

            # --- SKIP СУЩЕСТВУЮЩИХ ---
            $destFile = Join-Path $LocalDestPath $Name
            if ($SkipExisting -and (Test-Path $destFile)) {
                continue
            }

            try {
                $LocalFolder = $Shell.NameSpace($LocalDestPath)
                $LocalFolder.CopyHere($item, 0x10) 
                
                $Global:Counter++
                Write-Host "[$FolderName] $Name -> Sent ($Global:Counter)" -ForegroundColor Cyan
                
                if ($Global:Counter % $BatchSize -eq 0) {
                    Write-Host "=== Пауза $BatchDelaySec сек... ===" -ForegroundColor Yellow
                    Start-Sleep -Seconds $BatchDelaySec
                } else {
                    Start-Sleep -Milliseconds 200 
                }
            }
            catch {
                Write-Host " ERR: $_" -ForegroundColor Red
            }
        }
    }
}

Write-Host "=== Старт ===" -ForegroundColor Yellow
Copy-FolderRecursive -FolderItem $SourceFolderItem -LocalDestPath $DestRoot
Write-Host "=== Готово ===" -ForegroundColor Yellow
