# =====================================================
# restore_BD.ps1 - Восстановление базы данных BD
# =====================================================

$DB_NAME = "BD"
$DB_USER = "postgres"
$BACKUP_DIR = "C:\Users\User\Desktop"

# Добавляем путь к PostgreSQL
$env:Path = "C:\Program Files\PostgreSQL\18\bin;$env:Path"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Восстановление базы данных $DB_NAME" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Проверяем, существует ли папка с бэкапами
if (-not (Test-Path $BACKUP_DIR)) {
    Write-Error "Папка $BACKUP_DIR не существует!"
    exit 1
}

# Показываем список доступных бэкапов
Write-Host "`nДоступные бэкапы:" -ForegroundColor Cyan
$backups = Get-ChildItem -Path $BACKUP_DIR -Filter "BD_backup_*.backup" | Sort-Object LastWriteTime -Descending

if ($backups.Count -eq 0) {
    Write-Error "Нет бэкапов в папке $BACKUP_DIR"
    exit 1
}

for ($i = 0; $i -lt $backups.Count; $i++) {
    $b = $backups[$i]
    $size = [math]::Round($b.Length / 1MB, 2)
    Write-Host "[$i] $($b.Name) - $($b.LastWriteTime) - ${size} MB"
}

# Выбор бэкапа
$index = Read-Host "`nВыберите номер бэкапа для восстановления"
if ($index -notmatch '^\d+$' -or $index -ge $backups.Count) {
    Write-Error "Неверный номер"
    exit 1
}

$backupFile = $backups[$index].FullName
Write-Host "Выбран бэкап: $backupFile" -ForegroundColor Yellow

# Запрос пароля
$password = Read-Host "`nВведите пароль пользователя $DB_USER" -AsSecureString
$env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

try {
    Write-Host "`nВосстановление базы данных..." -ForegroundColor Cyan
    
    # Завершаем все соединения с базой BD
    Write-Host "Завершаем активные соединения..." -ForegroundColor Yellow
    psql.exe -U $DB_USER -h localhost -p 5432 -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();" 2>$null
    
    # Удаляем старую базу (если существует)
    Write-Host "Удаляем старую базу $DB_NAME..." -ForegroundColor Yellow
    psql.exe -U $DB_USER -h localhost -p 5432 -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>$null
    
    # Создаём новую базу
    Write-Host "Создаём новую базу $DB_NAME..." -ForegroundColor Yellow
    psql.exe -U $DB_USER -h localhost -p 5432 -d postgres -c "CREATE DATABASE $DB_NAME WITH ENCODING='UTF8';" 2>$null
    
    # Восстанавливаем из бэкапа
    Write-Host "Восстанавливаем данные..." -ForegroundColor Yellow
    pg_restore.exe -U $DB_USER -h localhost -p 5432 -d $DB_NAME -c --if-exists -v $backupFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ База данных успешно восстановлена!" -ForegroundColor Green
        
        # Проверка: сколько пользователей восстановлено?
        $count = psql.exe -U $DB_USER -h localhost -p 5432 -d $DB_NAME -t -c "SELECT COUNT(*) FROM users;" 2>$null
        if ($count) {
            Write-Host "📊 Восстановлено пользователей: $count" -ForegroundColor Green
        }
    } else {
        Write-Error "❌ Ошибка при восстановлении!"
    }
}
finally {
    $env:PGPASSWORD = ""
}

Write-Host "`nНажмите любую клавишу для выхода..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")