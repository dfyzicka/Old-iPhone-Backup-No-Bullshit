**[English](#english) | [Русский](#russian)**

## <a name="russian"></a>Русский
### Предыстория
Дано: **iPhone 7 Plus на 512 ГБ** и **Windows 11**.
Задача: Скинуть всё медиа (папку DCIM) на комп.
Проблема: Это ад.
* Проводник зависает при попытке скопировать всё разом.
* Процесс прерывается ошибкой «Устройство недоступно» в рандомном месте без логов.
* Окно копирования висит вечно на «Вычисление времени...».

Стандартный командлет PowerShell `Copy-Item` не работает с MTP-устройствами, так как пути типа `Этот компьютер\iPhone\...` виртуальные. Мне нужно было решение, которое копирует рекурсивно, сохраняет структуру папок `DCIM\100APPLE`, фильтрует странные дубликаты и не падает на больших видеофайлах.

### Техническое решение
Скрипт использует Windows **Shell.Application** COM-объект для работы с драйвером MTP, но с особой логикой, найденной методом проб и ошибок:

*   **Режим «Пулемета» (Burst Mode):** Вместо того чтобы ждать завершения каждого файла (слишком медленно) или отправлять тысячи команд сразу (драйвер падает), скрипт отправляет команды копирования пачками по **19 файлов**, затем делает паузу **3 секунды**. Можно попробовать увеличить скорость, но мне было лень, поэтому оставил так.
*   **Нативная очередь Windows:** Для маленьких файлов (фото) пачки пролетают быстро. Для больших файлов (видео) Windows сама открывает нативное диалоговое окно копирования, автоматически блокируя скрипт, пока ресурсы не освободятся. Это работает как естественный балансировщик нагрузки. Звучит как костыли — так оно и есть, но работает.
*   **Фильтр фантомных дублей:** iPhone часто показывает один и тот же файл дважды через MTP (например, `IMG_0404.AAE` дублируется). Скрипт фильтрует дубликаты по имени, чтобы предотвратить надоедливые окна «Файл уже существует».

### Как использовать

**1. Скачайте `Backup-iPhone.ps1`.**

**2. При необходимости подкрутите настройки в начале файла:**
   ```powershell
   $BatchSize = 19        # Сколько файлов кидать за раз
   $BatchDelaySec = 3     # Пауза между пачками (сек)
  ```
**3.Запустите в PowerShell:**
```
# Обычный запуск (AAE копируются)
.\Backup-iPhone.ps1 -DestRoot "E:\Backup"

# Не копировать мусор .AAE
.\Backup-iPhone.ps1 -DestRoot "E:\Backup" -SkipAAE

# Если запускаете не первый раз: включить пропуск узе скопированных файлов
.\Backup-iPhone.ps1 -DestRoot "E:\Backup" -SkipExisting

# Если упало на половине: Начать с папки 105APPLE + пропуск предыдущих
.\Backup-iPhone.ps1 -DestRoot "E:\Backup" -StartFolder "105APPLE" -SkipExisting
```

| Параметр      | Описание                                          | По умолчанию            |
| ------------- | ------------------------------------------------- | ----------------------- |
| -PhoneName    | Имя устройства в "Этот компьютер"                 | "Apple iPhone"          |
| -SourcePath   | Внутренний путь к медиа                           | "Internal Storage\\DCIM" |
| -DestRoot     | Папка назначения на ПК                            | "E:\\iPhone_Backup"     |
| -SkipExisting | Пропускать уже существующие файлы на диске ПК     | False                   |
| -SkipAAE      | Не копировать файлы .AAE                          | False                   |
| -StartFolder  | Имя папки, с которой начать (например "105APPLE") | "" (с начала)           |


### FAQ / Частые вопросы
Q: Скрипт пишет "Sent", но файлов в папке нет?
A: Подождите. Скрипт отправляет команды в очередь Windows. Если файлов много, Windows может обрабатывать их с задержкой. Не отключайте телефон сразу после завершения скрипта, дайте ему еще минут 5-10 на "дописывание" хвостов.

Q: Зачем нужны файлы .AAE?
A: Это файлы метаданных с вашими правками (фильтры, кадрирование). На Windows они бесполезны (ПК видит только оригинал). Вы можете отключить их копирование флагом -SkipAAE.

### Disclaimer
Используйте на свой страх и риск. Скрипт только создает копии ваших файлов. Он ничего не удаляет с исходного устройства.

---

## <a name="english"></a>English

### The Backstory
Given: **iPhone 7 Plus (512GB)** and **Windows 11**.
Task: Backup all media (DCIM folder) to PC.
Problem: It's hell.
1. Windows Explorer crashes when trying to copy everything at once.
2. The process aborts with "Device Unreachable" errors randomly without logs.
3. The copy dialog hangs forever on "Calculating time...".

Standard PowerShell `Copy-Item` fails with MTP devices because paths like `This PC\iPhone\...` are virtual. I needed a solution that copies recursively, preserves the `DCIM\100APPLE` folder structure, filters out weird duplicates, and doesn't crash on large video files.

### Technical Solution
The script uses the Windows **Shell.Application** COM object to interface with the MTP driver, but with a unique logic discovered through trial and error:

*   **"Burst Mode":** Instead of waiting for each file (too slow) or spamming thousands of commands (crashes the driver), the script sends copy commands in batches of **19 files**, then **pauses for 3 seconds**. You could try increasing the speed, but I was too lazy to test limits, so I left it as is.
*   **Native Windows Queue:** For small files (photos), batches fly through. For large files (videos), Windows automatically opens its native copy dialog, blocking the script until resources are freed. This acts as a natural load balancer. Sounds like a kludge (and it is), but it works.
*   **Phantom Duplicate Filter:** iPhone often shows the same file twice via MTP (e.g., `IMG_0404.AAE` appearing twice). The script filters duplicates by name to prevent annoying "File already exists" popups.

### Usage

1. Download `Backup-iPhone.ps1`.
2. Open it in a text editor. You can tweak queue settings if needed:

 ```powershell
   $BatchSize = 19        # Files per burst
   $BatchDelaySec = 3     # Pause in seconds
 ```
   
**3.Run via PowerShell:**

  ```
# Standard run (copies everything including AAE)
.\Backup-iPhone.ps1 -DestRoot "E:\Backup"

# Do not copy .AAE garbage
.\Backup-iPhone.ps1 -DestRoot "E:\Backup" -SkipAAE

# Resume: Skip files that already exist on PC
.\Backup-iPhone.ps1 -DestRoot "E:\Backup" -SkipExisting

# Crash recovery: Start from specific folder (e.g. 105APPLE) + Skip existing
.\Backup-iPhone.ps1 -DestRoot "E:\Backup" -StartFolder "105APPLE" -SkipExisting

 ```

| Parameter     | Description                                  | Default                 |
| ------------- | -------------------------------------------- | ----------------------- |
| -PhoneName    | Device name in "This PC"                     | "Apple iPhone"          |
| -SourcePath   | Internal path to media                       | "Internal Storage\\DCIM" |
| -DestRoot     | Destination folder on PC                     | "E:\\iPhone_Backup"     |
| -SkipExisting | Skip files already on disk                   | False                   |
| -SkipAAE      | Do not copy .AAE files                       | False                   |
| -StartFolder  | Start from specific folder (e.g. "105APPLE") | "" (from start)         |

### FAQ
Q: Script says "Sent", but folder is empty?
A: Wait. The script sends commands to the Windows queue. If there are many files, Windows might process them with a delay. Do not disconnect the phone immediately after the script finishes; give it another 5-10 minutes to flush the buffer.

Q: Why do I need .AAE files?
A: These are metadata files with your edits (filters, crops). They are useless on Windows (PC sees only the original). You can disable copying them with the -SkipAAE flag.

### Disclaimer
Use at your own risk. This script creates copies of your files. It does not delete anything from the source device.
