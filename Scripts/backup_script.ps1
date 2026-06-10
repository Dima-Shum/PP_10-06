# =====================================================
# backup_BD.ps1 - Резервное копирование базы данных BD
# =====================================================

$DB_NAME = "bd"
$DB_USER = "postgres"
$env:PGPASSWORD = "1234"
$BACKUP_DIR = "C:\Users\User\Desktop\Backups"
$TIMESTAMP = (Get-Date).ToString("yyyyMMdd_HHmmss")
$BACKUP_FILE = "$BACKUP_DIR\${DB_NAME}_$TIMESTAMP.backup"

# Тот же путь, что работал для educore_db
$env:Path += ";E:\PostgreSQL\bin"

# Создаём папку для бэкапов
if (!(Test-Path -Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Force -Path $BACKUP_DIR
}

Write-Host "Запуск резервного копирования базы данных $DB_NAME..."

# Запуск pg_dump
pg_dump.exe -U $DB_USER -h localhost -p 5432 -F c -b -v -f $BACKUP_FILE $DB_NAME

# Проверка результата
if ($LASTEXITCODE -eq 0) {
    Write-Host "Резервная копия успешно создана: $BACKUP_FILE" -ForegroundColor Green
} else {
    Write-Error "Ошибка при создании резервной копии!"
}