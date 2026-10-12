<#
.SYNOPSIS
    Script tự động quản lý ứng dụng Fastnetr và sao lưu hệ thống IMS.
.DESCRIPTION
    Dự án độc lập gói gọn trong 1 file duy nhất (không sinh thêm file/thư mục phụ):
    1. SAO LƯU DỮ LIỆU IMS (THỨ HAI HÀNG TUẦN LÚC 05:00 SÁNG):
       - Sao lưu dữ liệu IMS từ D:\IMS_SETUP\BACKUP sang F:\Backup Ims bằng Robocopy đa luồng.
       - Tách biệt thời điểm hoặc chạy trước Fastnetr để tránh nghẽn đĩa I/O.
    2. KHỞI ĐỘNG LẠI FASTNETR (HÀNG NGÀY LÚC 07:45 SÁNG):
       - Tắt êm và dọn sạch triệt để các cửa sổ lỗi popup modal bị treo.
       - Tự động dọn dẹp các file rác, file tạm, file khóa (.tmp, .lck, .bad, .err).
       - Khởi động lại ứng dụng tại D:\FASTNETR\FASTNETR.EXE vào thời điểm các PGD huyện đã mở máy (07:45 sáng).
.PARAMETER ForceBackup
    Ép buộc chạy sao lưu IMS ngay lập tức (bỏ qua điều kiện thứ Hai).
.PARAMETER SkipRestart
    Bỏ qua bước tắt/bật lại phần mềm Fastnetr (chỉ thực hiện sao lưu IMS).
.PARAMETER OnlyRestart
    Chỉ khởi động lại Fastnetr (dùng để hẹn giờ lúc 07:45 sáng hàng ngày).
.PARAMETER OnlyBackup
    Chỉ sao lưu IMS (dùng để hẹn giờ lúc 05:00 sáng Thứ Hai).
.EXAMPLE
    .\BackupIMS.ps1 -OnlyRestart
    Chạy khởi động lại Fastnetr an toàn lúc 07:45 sáng.
.EXAMPLE
    .\BackupIMS.ps1 -OnlyBackup
    Chạy sao lưu dữ liệu IMS lúc 05:00 sáng thứ Hai.
.EXAMPLE
    .\BackupIMS.ps1
    Chạy tự động mặc định (sao lưu IMS nếu là thứ Hai và sau đó khởi động lại Fastnetr).
#>

[CmdletBinding()]
param(
    [switch]$ForceBackup,
    [switch]$SkipRestart,
    [switch]$OnlyRestart,
    [switch]$OnlyBackup
)

# Cấu hình UTF-8 cho console để hiển thị tiếng Việt có dấu chuẩn xác
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ==============================================================================
# CẤU HÌNH ĐƯỜNG DẪN
# ==============================================================================
$FastnetExePath     = "D:\FASTNETR\FASTNETR.EXE"
$FastnetProcessName = "Fastnetr"

$SourceBaseDir      = "D:\IMS_SETUP\BACKUP"
$DestinationBaseDir = "F:\Backup Ims"
$RetentionDays      = 30  # Số ngày lưu trữ trên ổ F (Đặt 0 nếu không muốn xóa cũ)

# Xử lý cờ tham số
if ($OnlyRestart) {
    $SkipRestart = $false
}
if ($OnlyBackup) {
    $SkipRestart = $true
}

# Hàm in thông báo có màu và thời gian
function Write-Status {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")][string]$Level = "INFO"
    )
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    switch ($Level) {
        "INFO"    { Write-Host "[$time] [INFO] $Message" -ForegroundColor Cyan }
        "WARN"    { Write-Host "[$time] [WARN] $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "[$time] [ERROR] $Message" -ForegroundColor Red }
        "SUCCESS" { Write-Host "[$time] [SUCCESS] $Message" -ForegroundColor Green }
    }
}

Write-Host "==================================================================" -ForegroundColor DarkGray
Write-Status "BẮT ĐẦU TIẾN TRÌNH HỆ THỐNG" "INFO"

# ==============================================================================
# PHẦN 1: SAO LƯU HỆ THỐNG IMS (CHẠY TRƯỚC ĐỂ TRÁNH TRANH CHẤP ĐĨA VỚI FASTNETR)
# ==============================================================================
if (-not $OnlyRestart) {
    Write-Status "--- BƯỚC 1: KIỂM TRA & SAO LƯU DỮ LIỆU IMS ---" "INFO"

    $currentDate = Get-Date
    $currentDay  = $currentDate.DayOfWeek

    if ($currentDay -eq 'Monday' -or $ForceBackup -or $OnlyBackup) {
        if ($ForceBackup -and $currentDay -ne 'Monday') {
            Write-Status "Kích hoạt sao lưu cưỡng bức (-ForceBackup) vào $currentDay." "WARN"
        } elseif ($OnlyBackup) {
            Write-Status "Kích hoạt chế độ chuyên biệt sao lưu IMS (-OnlyBackup)." "INFO"
        } else {
            Write-Status "Hôm nay là Thứ Hai - Tiến hành sao lưu dữ liệu IMS tuần vừa qua." "INFO"
        }

        try {
            # Lấy bản backup của ngày hôm qua (Chủ Nhật)
            $yesterday = $currentDate.AddDays(-1)
            $folderName = $yesterday.ToString("ddMMyyyy")
            $sourcePath = Join-Path $SourceBaseDir $folderName
            $destinationPath = Join-Path $DestinationBaseDir $folderName

            # Kiểm tra thư mục nguồn
            if (-not (Test-Path $sourcePath)) {
                Write-Status "KHÔNG tìm thấy thư mục nguồn: '$sourcePath'. Vui lòng kiểm tra lại hệ thống IMS." "WARN"
            } else {
                # Kiểm tra ổ đích F:
                $destDrive = [System.IO.Path]::GetPathRoot($DestinationBaseDir)
                if (-not (Test-Path $destDrive)) {
                    throw "Ổ đĩa đích '$destDrive' không khả dụng hoặc chưa được cắm/kết nối!"
                }

                # Tạo thư mục đích nếu chưa tồn tại
                if (-not (Test-Path $destinationPath)) {
                    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
                }

                Write-Status "Đang sao chép từ '$sourcePath' sang '$destinationPath' bằng Robocopy..." "INFO"

                # Robocopy đa luồng (/MT:8), tự retry 3 lần (/R:3 /W:5)
                $robocopyArgs = @(
                    "`"$sourcePath`"",
                    "`"$destinationPath`"",
                    "/E", "/R:3", "/W:5", "/MT:8", "/NP", "/NDL", "/NFL"
                )
                $proc = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -NoNewWindow -PassThru

                if ($proc.ExitCode -lt 8) {
                    Write-Status "Sao lưu IMS thành công! (Mã thoát Robocopy: $($proc.ExitCode))" "SUCCESS"
                } else {
                    Write-Status "Robocopy gặp lỗi trong quá trình sao chép (Mã thoát: $($proc.ExitCode))" "ERROR"
                }

                # Dọn dẹp backup cũ trên ổ F (Retention)
                if ($RetentionDays -gt 0 -and (Test-Path $DestinationBaseDir)) {
                    $cutoffDate = $currentDate.AddDays(-$RetentionDays)
                    Get-ChildItem -Path $DestinationBaseDir -Directory | Where-Object {
                        $_.Name -match '^\d{8}$' -and ($_.CreationTime -lt $cutoffDate -or $_.LastWriteTime -lt $cutoffDate)
                    } | ForEach-Object {
                        try {
                            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
                            Write-Status "Đã xóa bản backup cũ quá $RetentionDays ngày: '$($_.Name)'" "INFO"
                        } catch {
                            Write-Status "Không thể xóa bản backup cũ '$($_.Name)': $($_.Exception.Message)" "WARN"
                        }
                    }
                }
            }
        } catch {
            Write-Status "Lỗi trong tiến trình sao lưu IMS: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-Status "Hôm nay là $currentDay (không phải thứ Hai). Bỏ qua bước sao lưu IMS." "INFO"
    }
} else {
    Write-Status "Bỏ qua bước sao lưu IMS theo tham số -OnlyRestart." "INFO"
}

# ==============================================================================
# PHẦN 2: KHỞI ĐỘNG LẠI FASTNETR (HÀNG NGÀY - KHUYẾN NGHỊ CHẠY LÚC 07:45 SÁNG)
# ==============================================================================
if (-not $SkipRestart -and -not $OnlyBackup) {
    Write-Status "--- BƯỚC 2: KHỞI ĐỘNG LẠI PHẦN MỀM FASTNETR ---" "INFO"
    
    # 2.1 Tắt tiến trình an toàn và dọn sạch toàn bộ các cửa sổ lỗi treo/cascade
    Write-Status "Đang kiểm tra tiến trình '$FastnetProcessName'..." "INFO"
    try {
        $processes = Get-Process -Name $FastnetProcessName -ErrorAction SilentlyContinue
        if ($processes) {
            Write-Status "Gửi yêu cầu đóng cửa sổ ứng dụng '$FastnetProcessName'..." "INFO"
            $processes | ForEach-Object {
                try { $_.CloseMainWindow() | Out-Null } catch {}
            }
            # Chờ tối đa 3 giây xem tiến trình có tự thoát được không
            Start-Sleep -Seconds 3

            # Nếu tiến trình còn tồn tại (do bị kẹt bởi các hộp thoại modal lỗi hoặc treo socket):
            $stillRunning = Get-Process -Name $FastnetProcessName -ErrorAction SilentlyContinue
            if ($stillRunning) {
                Write-Status "Đang dọn dứt điểm tiến trình và giải phóng các cửa sổ lỗi popup modal..." "INFO"
                $stillRunning | Stop-Process -Force -ErrorAction SilentlyContinue
                & taskkill.exe /F /IM "${FastnetProcessName}.exe" /T 2>&1 | Out-Null
            }
            Write-Status "Đã giải phóng hoàn toàn tiến trình '$FastnetProcessName.exe'." "SUCCESS"
        } else {
            Write-Status "Tiến trình '$FastnetProcessName.exe' hiện không chạy." "INFO"
        }
    } catch {
        Write-Status "Lỗi khi tắt tiến trình: $($_.Exception.Message)" "WARN"
    }

    # Chờ 10 giây để Windows giải phóng hoàn toàn socket mạng (TCP TIME_WAIT) và file lock (Antivirus)
    Write-Status "Chờ 10 giây để hệ thống giải phóng cổng mạng socket và ổn định tài nguyên..." "INFO"
    Start-Sleep -Seconds 10

    # 2.2 Dọn dẹp file rác, file lỗi, file khóa và Bật lại phần mềm
    if (Test-Path $FastnetExePath) {
        try {
            $workingDir = Split-Path -Path $FastnetExePath -Parent

            # Dọn dẹp file tạm (.tmp, .lck, .bad, .err) có thể bị kẹt hoặc hỏng do phiên làm việc trước
            try {
                $junkFiles = Get-ChildItem -Path $workingDir -Include "*.tmp", "*.lck", "*.bad", "*.err" -File -Recurse -ErrorAction SilentlyContinue
                if ($junkFiles) {
                    $junkFiles | Remove-Item -Force -ErrorAction SilentlyContinue
                    Write-Status "Đã dọn dẹp $($junkFiles.Count) file rác (.tmp, .lck) tồn đọng trong '$workingDir'." "INFO"
                }
            } catch {}

            Start-Process -FilePath $FastnetExePath -WorkingDirectory $workingDir
            Write-Status "Đã khởi động lại thành công: '$FastnetExePath'" "SUCCESS"
        } catch {
            Write-Status "Không thể khởi động '$FastnetExePath': $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-Status "CẢNH BÁO: Không tìm thấy file thực thi tại '$FastnetExePath'!" "WARN"
    }
} else {
    Write-Status "Bỏ qua bước khởi động lại Fastnetr theo tham số lựa chọn." "INFO"
}

Write-Status "TIẾN TRÌNH KẾT THÚC." "SUCCESS"
Write-Host "==================================================================" -ForegroundColor DarkGray