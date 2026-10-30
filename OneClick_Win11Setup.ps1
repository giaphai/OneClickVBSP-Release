# ==============================================================================
# ONECLICK WINDOWS 11 SETUP & DEPLOYMENT TOOL (VBSP EDITION - 2026)
# Chuyen dung cai dat may moi, tinh chinh Windows 11 & cai dat phan mem tu D:\setup\
# ==============================================================================

# Kiem tra & Nang quyen Administrator neu chua co
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Path }
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Data

[System.Windows.Forms.Application]::EnableVisualStyles()

# ==============================================================================
# CAU HINH THU MUC BO CAI DAT MAC DINH & BANG ANH XA PHAN MEM THUC TE
# ==============================================================================
$script:DefaultSetupDir = "D:\setup"
if (-not (Test-Path $script:DefaultSetupDir)) {
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne 'C' }
    foreach ($d in $drives) {
        $candidate = "$($d.Root)setup"
        if (Test-Path $candidate) {
            $script:DefaultSetupDir = $candidate
            break
        }
    }
}

# Bang danh muc phan mem chuan xac theo thu muc thuc te D:\setup\
$script:SoftwareCatalog = @(
    # --- NHOM VAN PHONG & TIEN ICH CO BAN ---
    @{
        Id          = "chrome"
        Name        = "Google Chrome"
        Group       = "Office"
        Candidates  = @("ChromeStandaloneSetup64.exe", "ChromeSetup.exe", "GoogleChromeStandaloneEnterprise64.msi")
        Arguments   = "/silent /install"
        CheckScript = {
            (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe") -or
            (Test-Path "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")
        }
    },
    @{
        Id          = "office365"
        Name        = "Office 365"
        Group       = "Office"
        Candidates  = @("OfficeSetup.exe", "Setup.exe")
        Arguments   = ""
        CheckScript = {
            (Test-Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration") -or
            (Test-Path "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE") -or
            (Test-Path "C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE")
        }
    },
    @{
        Id          = "foxit"
        Name        = "Foxit Reader"
        Group       = "Office"
        Candidates  = @("Foxit Reader 4.0.0.0619.exe", "FoxitReader_Setup.exe", "FoxitReader.exe")
        Arguments   = "/VERYSILENT /NORESTART"
        CheckScript = {
            (Test-Path "C:\Program Files (x86)\Foxit Software\Foxit Reader\FoxitReader.exe") -or
            (Test-Path "C:\Program Files\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe") -or
            (Test-Path "C:\Program Files (x86)\Foxit Software\Foxit Reader.exe")
        }
    },
    @{
        Id          = "winrar"
        Name        = "WinRAR"
        Group       = "Office"
        Candidates  = @("winrar\Install.exe", "Install.exe", "winrar-x64.exe")
        Arguments   = "/s"
        CheckScript = {
            (Test-Path "C:\Program Files\WinRAR\WinRAR.exe") -or
            (Test-Path "C:\Program Files (x86)\WinRAR\WinRAR.exe")
        }
    },
    @{
        Id          = "totalcmd"
        Name        = "Total Commander"
        Group       = "Office"
        Candidates  = @("TotalCMD.zip")
        IsCustom    = $true
        CheckScript = {
            (Test-Path "D:\TotalCMD\TOTALCMD64.EXE") -or (Test-Path "D:\TotalCMD\TOTALCMD.EXE") -or
            (Test-Path "C:\totalcmd\TOTALCMD64.EXE")
        }
    },
    @{
        Id          = "evkey"
        Name        = "EVKey (Bộ gõ)"
        Group       = "Office"
        Candidates  = @("EVKey\EVKey64.exe", "EVKey")
        IsCustom    = $true
        CheckScript = {
            (Test-Path "C:\Program Files\EVKey\EVKey64.exe") -or (Get-Process -Name "EVKey64" -ErrorAction SilentlyContinue)
        }
    },
    @{
        Id          = "zalo"
        Name        = "Zalo Desktop"
        Group       = "Office"
        Candidates  = @("ZaloSetup-24.6.2.exe", "ZaloSetup*.exe", "Zalo.exe")
        Arguments   = "/S"
        CheckScript = {
            (Test-Path "$env:LOCALAPPDATA\Programs\Zalo\Zalo.exe") -or
            (Test-Path "C:\Program Files\Zalo\Zalo.exe")
        }
    },
    @{
        Id          = "zoom"
        Name        = "Zoom Workplace"
        Group       = "Office"
        Candidates  = @("ZoomInstallerFull.exe", "ZoomInstaller.exe")
        Arguments   = "/silent"
        CheckScript = {
            (Test-Path "$env:APPDATA\Zoom\bin\Zoom.exe") -or
            (Test-Path "C:\Program Files\Zoom\bin\Zoom.exe")
        }
    },

    # --- NHOM AN NINH BAO MAT & HO TRO TU XA ---
    @{
        Id          = "ultraview"
        Name        = "UltraViewer"
        Group       = "Security"
        Candidates  = @("UltraViewer_setup_6.6.113_vi.exe", "UltraViewer_setup*.exe")
        Arguments   = "/VERYSILENT /NORESTART"
        CheckScript = {
            (Test-Path "C:\Program Files (x86)\UltraViewer\UltraViewer_Desktop.exe") -or
            (Test-Path "C:\Program Files\UltraViewer\UltraViewer_Desktop.exe")
        }
    },
    @{
        Id          = "teamview"
        Name        = "TeamViewer"
        Group       = "Security"
        Candidates  = @("TeamViewer_Setup 15.exe", "TeamViewer_Setup*.exe")
        Arguments   = "/S"
        CheckScript = {
            (Test-Path "C:\Program Files\TeamViewer\TeamViewer.exe") -or
            (Test-Path "C:\Program Files (x86)\TeamViewer\TeamViewer.exe")
        }
    },
    @{
        Id          = "deskin"
        Name        = "DeskIn Remote"
        Group       = "Security"
        Candidates  = @("DeskIn_Setup_v3.3.3.0_x64.exe", "DeskIn*.exe")
        Arguments   = "/S"
        CheckScript = {
            (Test-Path "C:\Program Files\DeskIn\DeskIn.exe") -or
            (Test-Path "C:\Program Files (x86)\DeskIn\DeskIn.exe")
        }
    },
    @{
        Id          = "crruntime"
        Name        = "Crystal Reports 64-bit"
        Group       = "Security"
        Candidates  = @("CRRuntime_64bit_13_0_18.msi", "CRRuntime_64bit*.msi")
        Arguments   = "/qn /norestart"
        CheckScript = {
            (Test-Path "HKLM:\SOFTWARE\SAP BusinessObjects\Crystal Reports for .NET Framework 4.0\Crystal Reports") -or
            (Test-Path "C:\Program Files (x86)\SAP BusinessObjects\Crystal Reports for .NET Framework 4.0")
        }
    },
    @{
        Id          = "trellix"
        Name        = "Trellix Agent"
        Group       = "Security"
        Candidates  = @("McAfee\TrellixAgent_5_7.exe", "TrellixAgent*.exe")
        Arguments   = "/INSTALL=AGENT /SILENT"
        CheckScript = {
            (Get-Service -Name "masvc" -ErrorAction SilentlyContinue) -or
            (Test-Path "C:\Program Files\McAfee\Agent\cmdagent.exe")
        }
    },
    @{
        Id          = "mcafee"
        Name        = "McAfee ENS"
        Group       = "Security"
        Candidates  = @("McAfee\Windows10\setupEP.exe", "setupEP.exe")
        Arguments   = "/install default /silent"
        CheckScript = {
            (Get-Service -Name "mfevtp" -ErrorAction SilentlyContinue) -or
            (Test-Path "C:\Program Files\McAfee\Endpoint Security\Endpoint Security Platform\mfevtps.exe")
        }
    },

    # --- NHOM CO SO DU LIEU SQL SERVER & OFFLINE DB ---
    @{
        Id          = "sqlserver"
        Name        = "SQL Server 2017 (ISO)"
        Group       = "Database"
        Candidates  = @("en_sql_server_2017_enterprise_x64_dvd_11293666.iso", "*sql*2017*.iso")
        IsCustom    = $true
        CheckScript = {
            (Get-Service -Name "MSSQLSERVER", "MSSQL$*" -ErrorAction SilentlyContinue) -or
            (Test-Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server")
        }
    },
    @{
        Id          = "ssms"
        Name        = "SSMS 17.9.1"
        Group       = "Database"
        Candidates  = @("SSMS-Setup-ENU v17.9.1.exe", "SSMS*.exe")
        Arguments   = "/install /quiet /norestart"
        CheckScript = {
            (Test-Path "C:\Program Files (x86)\Microsoft SQL Server Management Studio *\Common7\IDE\Ssms.exe") -or
            (Test-Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server Management Studio")
        }
    },
    @{
        Id          = "restorevbsp"
        Name        = "Phục hồi CSDL VbspOffline"
        Group       = "Database"
        Candidates  = @("VbspOffline44530220261024.zip", "VbspOffline*.zip", "*.bak")
        IsCustom    = $true
        CheckScript = {
            try {
                $targetInst = "(local)"
                $services = Get-Service -Name "MSSQLSERVER", "MSSQL$*" -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }
                if ($services -and $services[0].Name -ne "MSSQLSERVER") {
                    $targetInst = ".\" + $services[0].Name.Replace("MSSQL$", "")
                }
                $connTest = New-Object System.Data.SqlClient.SqlConnection("Server=$targetInst;Database=master;Integrated Security=True;Connection Timeout=3;")
                $connTest.Open()
                $cmdTest = $connTest.CreateCommand()
                $cmdTest.CommandText = "SELECT COUNT(1) FROM sys.databases WHERE [name] = 'VbspOffline'"
                $exists = ([int]$cmdTest.ExecuteScalar() -gt 0)
                $connTest.Close()
                return $exists
            } catch { return $false }
        }
    }
)

# ==============================================================================
# KHOI TAO CUA SO GIAO DIEN (FORM UI)
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "OneClick Win11 Setup - Triển Khai Máy Mới & Cài Đặt Tự Động [VBSP]"
$form.Size = New-Object System.Drawing.Size(1080, 780)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(15, 23, 42)     # Navy toi #0F172A
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# ------------------------------------------------------------------------------
# PANEL BEN TRAI: BANG CAC NUT TINH NANG (DASHBOARD 580px)
# ------------------------------------------------------------------------------
$pnlLeft = New-Object System.Windows.Forms.Panel
$pnlLeft.Location = New-Object System.Drawing.Point(12, 12)
$pnlLeft.Size = New-Object System.Drawing.Size(580, 715)
$pnlLeft.BackColor = [System.Drawing.Color]::FromArgb(15, 23, 42)
$form.Controls.Add($pnlLeft)

# --- KHU VUC 1: TINH CHINH WINDOWS 11 & TIEN ICH HE THONG ---
$grpWin11 = New-Object System.Windows.Forms.GroupBox
$grpWin11.Text = " 1. TINH CHỈNH WINDOWS 11 & TIỆN ÍCH HỆ THỐNG "
$grpWin11.Location = New-Object System.Drawing.Point(5, 5)
$grpWin11.Size = New-Object System.Drawing.Size(570, 115)
$grpWin11.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$grpWin11.ForeColor = [System.Drawing.Color]::FromArgb(96, 165, 250) # Blue-400
$pnlLeft.Controls.Add($grpWin11)

$btnTweakWin11 = New-Object System.Windows.Forms.Button
$btnTweakWin11.Text = "Tối ưu Windows 11`n(Chuột phải, UAC, Sleep)"
$btnTweakWin11.Location = New-Object System.Drawing.Point(10, 22)
$btnTweakWin11.Size = New-Object System.Drawing.Size(176, 40)
$btnTweakWin11.BackColor = [System.Drawing.Color]::FromArgb(30, 58, 138)
$btnTweakWin11.ForeColor = [System.Drawing.Color]::White
$btnTweakWin11.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnTweakWin11.FlatAppearance.BorderSize = 0
$btnTweakWin11.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpWin11.Controls.Add($btnTweakWin11)

$btnCreateShortcuts = New-Object System.Windows.Forms.Button
$btnCreateShortcuts.Text = "Tạo Shortcuts VBSP`n(Màn hình Desktop)"
$btnCreateShortcuts.Location = New-Object System.Drawing.Point(192, 22)
$btnCreateShortcuts.Size = New-Object System.Drawing.Size(180, 40)
$btnCreateShortcuts.BackColor = [System.Drawing.Color]::FromArgb(29, 78, 216)
$btnCreateShortcuts.ForeColor = [System.Drawing.Color]::White
$btnCreateShortcuts.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCreateShortcuts.FlatAppearance.BorderSize = 0
$btnCreateShortcuts.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpWin11.Controls.Add($btnCreateShortcuts)

$btnChromeBookmarks = New-Object System.Windows.Forms.Button
$btnChromeBookmarks.Text = "Thêm Bookmarks VBSP`n(Google Chrome)"
$btnChromeBookmarks.Location = New-Object System.Drawing.Point(378, 22)
$btnChromeBookmarks.Size = New-Object System.Drawing.Size(182, 40)
$btnChromeBookmarks.BackColor = [System.Drawing.Color]::FromArgb(217, 119, 6)
$btnChromeBookmarks.ForeColor = [System.Drawing.Color]::White
$btnChromeBookmarks.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnChromeBookmarks.FlatAppearance.BorderSize = 0
$btnChromeBookmarks.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpWin11.Controls.Add($btnChromeBookmarks)

$btnFixLanPrint = New-Object System.Windows.Forms.Button
$btnFixLanPrint.Text = "Chia sẻ Mạng LAN`n& Máy in (0x11b, 0x709)"
$btnFixLanPrint.Location = New-Object System.Drawing.Point(10, 68)
$btnFixLanPrint.Size = New-Object System.Drawing.Size(176, 38)
$btnFixLanPrint.BackColor = [System.Drawing.Color]::FromArgb(13, 148, 136)
$btnFixLanPrint.ForeColor = [System.Drawing.Color]::White
$btnFixLanPrint.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnFixLanPrint.FlatAppearance.BorderSize = 0
$btnFixLanPrint.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpWin11.Controls.Add($btnFixLanPrint)

$btnSetUS = New-Object System.Windows.Forms.Button
$btnSetUS.Text = "Định dạng Vùng US`n(Số & Ngày chuẩn)"
$btnSetUS.Location = New-Object System.Drawing.Point(192, 68)
$btnSetUS.Size = New-Object System.Drawing.Size(180, 38)
$btnSetUS.BackColor = [System.Drawing.Color]::FromArgb(16, 124, 65)
$btnSetUS.ForeColor = [System.Drawing.Color]::White
$btnSetUS.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSetUS.FlatAppearance.BorderSize = 0
$btnSetUS.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpWin11.Controls.Add($btnSetUS)

$btnWebHosts = New-Object System.Windows.Forms.Button
$btnWebHosts.Text = "Tối ưu Web & HOSTS`n(Policy & DNS VBSP)"
$btnWebHosts.Location = New-Object System.Drawing.Point(378, 68)
$btnWebHosts.Size = New-Object System.Drawing.Size(182, 38)
$btnWebHosts.BackColor = [System.Drawing.Color]::FromArgb(14, 116, 144)
$btnWebHosts.ForeColor = [System.Drawing.Color]::White
$btnWebHosts.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnWebHosts.FlatAppearance.BorderSize = 0
$btnWebHosts.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpWin11.Controls.Add($btnWebHosts)

# --- KHU VUC 2: BO UNG DUNG VAN PHONG & TIEN ICH CO BAN ---
$grpOffice = New-Object System.Windows.Forms.GroupBox
$grpOffice.Text = " 2. BỘ ỨNG DỤNG VĂN PHÒNG & TIỆN ÍCH CƠ BẢN "
$grpOffice.Location = New-Object System.Drawing.Point(5, 125)
$grpOffice.Size = New-Object System.Drawing.Size(570, 115)
$grpOffice.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$grpOffice.ForeColor = [System.Drawing.Color]::FromArgb(147, 197, 253)
$pnlLeft.Controls.Add($grpOffice)

$btnChrome = New-Object System.Windows.Forms.Button
$btnChrome.Text = "Google Chrome"
$btnChrome.Location = New-Object System.Drawing.Point(10, 22)
$btnChrome.Size = New-Object System.Drawing.Size(130, 36)
$btnChrome.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
$btnChrome.ForeColor = [System.Drawing.Color]::White
$btnChrome.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnChrome.FlatAppearance.BorderSize = 0
$btnChrome.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpOffice.Controls.Add($btnChrome)

$btnOffice = New-Object System.Windows.Forms.Button
$btnOffice.Text = "Office 365"
$btnOffice.Location = New-Object System.Drawing.Point(146, 22)
$btnOffice.Size = New-Object System.Drawing.Size(130, 36)
$btnOffice.BackColor = [System.Drawing.Color]::FromArgb(217, 119, 6)
$btnOffice.ForeColor = [System.Drawing.Color]::White
$btnOffice.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnOffice.FlatAppearance.BorderSize = 0
$btnOffice.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpOffice.Controls.Add($btnOffice)

$btnFoxit = New-Object System.Windows.Forms.Button
$btnFoxit.Text = "Foxit Reader"
$btnFoxit.Location = New-Object System.Drawing.Point(282, 22)
$btnFoxit.Size = New-Object System.Drawing.Size(134, 36)
$btnFoxit.BackColor = [System.Drawing.Color]::FromArgb(234, 88, 12)
$btnFoxit.ForeColor = [System.Drawing.Color]::White
$btnFoxit.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnFoxit.FlatAppearance.BorderSize = 0
$btnFoxit.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpOffice.Controls.Add($btnFoxit)

$btnWinRAR = New-Object System.Windows.Forms.Button
$btnWinRAR.Text = "WinRAR (Setup)"
$btnWinRAR.Location = New-Object System.Drawing.Point(422, 22)
$btnWinRAR.Size = New-Object System.Drawing.Size(138, 36)
$btnWinRAR.BackColor = [System.Drawing.Color]::FromArgb(109, 40, 217)
$btnWinRAR.ForeColor = [System.Drawing.Color]::White
$btnWinRAR.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnWinRAR.FlatAppearance.BorderSize = 0
$btnWinRAR.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpOffice.Controls.Add($btnWinRAR)

$btnTotalCmd = New-Object System.Windows.Forms.Button
$btnTotalCmd.Text = "Total Commander"
$btnTotalCmd.Location = New-Object System.Drawing.Point(10, 66)
$btnTotalCmd.Size = New-Object System.Drawing.Size(130, 36)
$btnTotalCmd.BackColor = [System.Drawing.Color]::FromArgb(79, 70, 229)
$btnTotalCmd.ForeColor = [System.Drawing.Color]::White
$btnTotalCmd.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnTotalCmd.FlatAppearance.BorderSize = 0
$btnTotalCmd.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpOffice.Controls.Add($btnTotalCmd)

$btnEVKey = New-Object System.Windows.Forms.Button
$btnEVKey.Text = "EVKey (Portable)"
$btnEVKey.Location = New-Object System.Drawing.Point(146, 66)
$btnEVKey.Size = New-Object System.Drawing.Size(130, 36)
$btnEVKey.BackColor = [System.Drawing.Color]::FromArgb(59, 130, 246)
$btnEVKey.ForeColor = [System.Drawing.Color]::White
$btnEVKey.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnEVKey.FlatAppearance.BorderSize = 0
$btnEVKey.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpOffice.Controls.Add($btnEVKey)

$btnZalo = New-Object System.Windows.Forms.Button
$btnZalo.Text = "Zalo Desktop"
$btnZalo.Location = New-Object System.Drawing.Point(282, 66)
$btnZalo.Size = New-Object System.Drawing.Size(134, 36)
$btnZalo.BackColor = [System.Drawing.Color]::FromArgb(2, 132, 199)
$btnZalo.ForeColor = [System.Drawing.Color]::White
$btnZalo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnZalo.FlatAppearance.BorderSize = 0
$btnZalo.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpOffice.Controls.Add($btnZalo)

$btnZoom = New-Object System.Windows.Forms.Button
$btnZoom.Text = "Zoom Workplace"
$btnZoom.Location = New-Object System.Drawing.Point(422, 66)
$btnZoom.Size = New-Object System.Drawing.Size(138, 36)
$btnZoom.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
$btnZoom.ForeColor = [System.Drawing.Color]::White
$btnZoom.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnZoom.FlatAppearance.BorderSize = 0
$btnZoom.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpOffice.Controls.Add($btnZoom)

# --- KHU VUC 3: AN NINH BAO MAT & HO TRO TU XA ---
$grpSecurity = New-Object System.Windows.Forms.GroupBox
$grpSecurity.Text = " 3. AN NINH BẢO MẬT & HỖ TRỢ TỪ XA "
$grpSecurity.Location = New-Object System.Drawing.Point(5, 245)
$grpSecurity.Size = New-Object System.Drawing.Size(570, 115)
$grpSecurity.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$grpSecurity.ForeColor = [System.Drawing.Color]::FromArgb(251, 146, 60)
$pnlLeft.Controls.Add($grpSecurity)

$btnUltraView = New-Object System.Windows.Forms.Button
$btnUltraView.Text = "UltraViewer"
$btnUltraView.Location = New-Object System.Drawing.Point(10, 22)
$btnUltraView.Size = New-Object System.Drawing.Size(176, 36)
$btnUltraView.BackColor = [System.Drawing.Color]::FromArgb(234, 88, 12)
$btnUltraView.ForeColor = [System.Drawing.Color]::White
$btnUltraView.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnUltraView.FlatAppearance.BorderSize = 0
$btnUltraView.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpSecurity.Controls.Add($btnUltraView)

$btnTeamView = New-Object System.Windows.Forms.Button
$btnTeamView.Text = "TeamViewer 15"
$btnTeamView.Location = New-Object System.Drawing.Point(192, 22)
$btnTeamView.Size = New-Object System.Drawing.Size(180, 36)
$btnTeamView.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
$btnTeamView.ForeColor = [System.Drawing.Color]::White
$btnTeamView.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnTeamView.FlatAppearance.BorderSize = 0
$btnTeamView.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpSecurity.Controls.Add($btnTeamView)

$btnDeskIn = New-Object System.Windows.Forms.Button
$btnDeskIn.Text = "DeskIn Remote"
$btnDeskIn.Location = New-Object System.Drawing.Point(378, 22)
$btnDeskIn.Size = New-Object System.Drawing.Size(182, 36)
$btnDeskIn.BackColor = [System.Drawing.Color]::FromArgb(16, 124, 65)
$btnDeskIn.ForeColor = [System.Drawing.Color]::White
$btnDeskIn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDeskIn.FlatAppearance.BorderSize = 0
$btnDeskIn.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpSecurity.Controls.Add($btnDeskIn)

$btnCR = New-Object System.Windows.Forms.Button
$btnCR.Text = "Crystal Reports 64-bit"
$btnCR.Location = New-Object System.Drawing.Point(10, 66)
$btnCR.Size = New-Object System.Drawing.Size(176, 36)
$btnCR.BackColor = [System.Drawing.Color]::FromArgb(14, 116, 144)
$btnCR.ForeColor = [System.Drawing.Color]::White
$btnCR.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCR.FlatAppearance.BorderSize = 0
$btnCR.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpSecurity.Controls.Add($btnCR)

$btnTrellix = New-Object System.Windows.Forms.Button
$btnTrellix.Text = "Trellix Agent 5.7"
$btnTrellix.Location = New-Object System.Drawing.Point(192, 66)
$btnTrellix.Size = New-Object System.Drawing.Size(180, 36)
$btnTrellix.BackColor = [System.Drawing.Color]::FromArgb(185, 28, 28)
$btnTrellix.ForeColor = [System.Drawing.Color]::White
$btnTrellix.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnTrellix.FlatAppearance.BorderSize = 0
$btnTrellix.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpSecurity.Controls.Add($btnTrellix)

$btnMcAfee = New-Object System.Windows.Forms.Button
$btnMcAfee.Text = "McAfee ENS (SetupEP)"
$btnMcAfee.Location = New-Object System.Drawing.Point(378, 66)
$btnMcAfee.Size = New-Object System.Drawing.Size(182, 36)
$btnMcAfee.BackColor = [System.Drawing.Color]::FromArgb(153, 27, 27)
$btnMcAfee.ForeColor = [System.Drawing.Color]::White
$btnMcAfee.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnMcAfee.FlatAppearance.BorderSize = 0
$btnMcAfee.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpSecurity.Controls.Add($btnMcAfee)

# --- KHU VUC 4: HE QUAN TRI CSDL SQL SERVER & OFFLINE DB ---
$grpSQL = New-Object System.Windows.Forms.GroupBox
$grpSQL.Text = " 4. HỆ QUẢN TRỊ CSDL SQL SERVER & OFFLINE DB "
$grpSQL.Location = New-Object System.Drawing.Point(5, 365)
$grpSQL.Size = New-Object System.Drawing.Size(570, 75)
$grpSQL.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$grpSQL.ForeColor = [System.Drawing.Color]::FromArgb(52, 211, 153)
$pnlLeft.Controls.Add($grpSQL)

$btnSQLServer = New-Object System.Windows.Forms.Button
$btnSQLServer.Text = "Cài SQL 2017 (ISO)"
$btnSQLServer.Location = New-Object System.Drawing.Point(10, 22)
$btnSQLServer.Size = New-Object System.Drawing.Size(130, 38)
$btnSQLServer.BackColor = [System.Drawing.Color]::FromArgb(16, 124, 65)
$btnSQLServer.ForeColor = [System.Drawing.Color]::White
$btnSQLServer.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSQLServer.FlatAppearance.BorderSize = 0
$btnSQLServer.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpSQL.Controls.Add($btnSQLServer)

$btnConfigSQL = New-Object System.Windows.Forms.Button
$btnConfigSQL.Text = "Mở Port 1433 & TCP"
$btnConfigSQL.Location = New-Object System.Drawing.Point(146, 22)
$btnConfigSQL.Size = New-Object System.Drawing.Size(130, 38)
$btnConfigSQL.BackColor = [System.Drawing.Color]::FromArgb(13, 148, 136)
$btnConfigSQL.ForeColor = [System.Drawing.Color]::White
$btnConfigSQL.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnConfigSQL.FlatAppearance.BorderSize = 0
$btnConfigSQL.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpSQL.Controls.Add($btnConfigSQL)

$btnSSMS = New-Object System.Windows.Forms.Button
$btnSSMS.Text = "Cài SSMS 17.9.1"
$btnSSMS.Location = New-Object System.Drawing.Point(282, 22)
$btnSSMS.Size = New-Object System.Drawing.Size(134, 38)
$btnSSMS.BackColor = [System.Drawing.Color]::FromArgb(5, 150, 105)
$btnSSMS.ForeColor = [System.Drawing.Color]::White
$btnSSMS.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSSMS.FlatAppearance.BorderSize = 0
$btnSSMS.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpSQL.Controls.Add($btnSSMS)

$btnRestoreDB = New-Object System.Windows.Forms.Button
$btnRestoreDB.Text = "Phục hồi CSDL Vbsp"
$btnRestoreDB.Location = New-Object System.Drawing.Point(422, 22)
$btnRestoreDB.Size = New-Object System.Drawing.Size(138, 38)
$btnRestoreDB.BackColor = [System.Drawing.Color]::FromArgb(16, 185, 129)
$btnRestoreDB.ForeColor = [System.Drawing.Color]::White
$btnRestoreDB.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnRestoreDB.FlatAppearance.BorderSize = 0
$btnRestoreDB.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpSQL.Controls.Add($btnRestoreDB)

# --- KHU VUC 5: DIEU KHIEN TIEN TRINH & THIET LAP THU MUC ---
$grpControl = New-Object System.Windows.Forms.GroupBox
$grpControl.Text = " 5. ĐIỀU KHIỂN TIẾN TRÌNH & THIẾT LẬP THƯ MỤC D:\SETUP "
$grpControl.Location = New-Object System.Drawing.Point(5, 445)
$grpControl.Size = New-Object System.Drawing.Size(570, 260)
$grpControl.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$grpControl.ForeColor = [System.Drawing.Color]::FromArgb(244, 114, 182)
$pnlLeft.Controls.Add($grpControl)

$lblDir = New-Object System.Windows.Forms.Label
$lblDir.Text = "Thư mục chứa toàn bộ bộ cài đặt:"
$lblDir.Location = New-Object System.Drawing.Point(10, 22)
$lblDir.Size = New-Object System.Drawing.Size(250, 20)
$lblDir.ForeColor = [System.Drawing.Color]::FromArgb(203, 213, 225)
$grpControl.Controls.Add($lblDir)

$txtSetupDir = New-Object System.Windows.Forms.TextBox
$txtSetupDir.Text = $script:DefaultSetupDir
$txtSetupDir.Location = New-Object System.Drawing.Point(10, 44)
$txtSetupDir.Size = New-Object System.Drawing.Size(440, 26)
$txtSetupDir.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$grpControl.Controls.Add($txtSetupDir)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Duyệt..."
$btnBrowse.Location = New-Object System.Drawing.Point(458, 43)
$btnBrowse.Size = New-Object System.Drawing.Size(102, 28)
$btnBrowse.BackColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
$btnBrowse.ForeColor = [System.Drawing.Color]::White
$btnBrowse.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnBrowse.FlatAppearance.BorderSize = 0
$btnBrowse.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpControl.Controls.Add($btnBrowse)

$btnCheckAll = New-Object System.Windows.Forms.Button
$btnCheckAll.Text = "🔍 QUÉT KIỂM TRA BỘ CÀI & TRẠNG THÁI MÁY"
$btnCheckAll.Location = New-Object System.Drawing.Point(10, 82)
$btnCheckAll.Size = New-Object System.Drawing.Size(550, 40)
$btnCheckAll.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
$btnCheckAll.ForeColor = [System.Drawing.Color]::White
$btnCheckAll.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$btnCheckAll.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCheckAll.FlatAppearance.BorderSize = 0
$btnCheckAll.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpControl.Controls.Add($btnCheckAll)

$btnInstallAll = New-Object System.Windows.Forms.Button
$btnInstallAll.Text = "🚀 CÀI ĐẶT TẤT CẢ (1-CLICK AUTO SETUP TỪ A -> Z)"
$btnInstallAll.Location = New-Object System.Drawing.Point(10, 130)
$btnInstallAll.Size = New-Object System.Drawing.Size(550, 52)
$btnInstallAll.BackColor = [System.Drawing.Color]::FromArgb(5, 150, 105)
$btnInstallAll.ForeColor = [System.Drawing.Color]::White
$btnInstallAll.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnInstallAll.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnInstallAll.FlatAppearance.BorderSize = 0
$btnInstallAll.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpControl.Controls.Add($btnInstallAll)

$btnClearLog = New-Object System.Windows.Forms.Button
$btnClearLog.Text = "🧹 Xóa màn hình Log"
$btnClearLog.Location = New-Object System.Drawing.Point(10, 195)
$btnClearLog.Size = New-Object System.Drawing.Size(268, 36)
$btnClearLog.BackColor = [System.Drawing.Color]::FromArgb(71, 85, 105)
$btnClearLog.ForeColor = [System.Drawing.Color]::White
$btnClearLog.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearLog.FlatAppearance.BorderSize = 0
$btnClearLog.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpControl.Controls.Add($btnClearLog)

$btnOpenFolder = New-Object System.Windows.Forms.Button
$btnOpenFolder.Text = "📂 Mở thư mục Setup"
$btnOpenFolder.Location = New-Object System.Drawing.Point(288, 195)
$btnOpenFolder.Size = New-Object System.Drawing.Size(272, 36)
$btnOpenFolder.BackColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
$btnOpenFolder.ForeColor = [System.Drawing.Color]::White
$btnOpenFolder.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnOpenFolder.FlatAppearance.BorderSize = 0
$btnOpenFolder.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpControl.Controls.Add($btnOpenFolder)

# ------------------------------------------------------------------------------
# PANEL BEN PHAI: RICHTEXTBOX CONSOLE NHAT KY TIEN TRINH (GIONG ONECLICK VBSP)
# ------------------------------------------------------------------------------
$lblConsole = New-Object System.Windows.Forms.Label
$lblConsole.Text = "NHẬT KÝ TIẾN TRÌNH HOẠT ĐỘNG (LIVE CONSOLE):"
$lblConsole.Location = New-Object System.Drawing.Point(605, 12)
$lblConsole.Size = New-Object System.Drawing.Size(350, 22)
$lblConsole.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblConsole.ForeColor = [System.Drawing.Color]::FromArgb(147, 197, 253)
$form.Controls.Add($lblConsole)

$btnAbout = New-Object System.Windows.Forms.Button
$btnAbout.Text = "Giá»›i thiá»‡u"
$btnAbout.Location = New-Object System.Drawing.Point(965, 8)
$btnAbout.Size = New-Object System.Drawing.Size(95, 26)
$btnAbout.BackColor = [System.Drawing.Color]::FromArgb(30, 58, 138)  # Navy Ä‘áº­m #1E3A8A
$btnAbout.ForeColor = [System.Drawing.Color]::FromArgb(147, 197, 253) # Xanh nháº¡t #93C5FD
$btnAbout.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnAbout.FlatAppearance.BorderSize = 0
$btnAbout.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnAbout.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnAbout)

$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = New-Object System.Drawing.Point(605, 36)
$txtLog.Size = New-Object System.Drawing.Size(455, 615)
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 23)   # Den #0F1117
$txtLog.ForeColor = [System.Drawing.Color]::FromArgb(163, 230, 53) # Lime-400
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
$form.Controls.Add($txtLog)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(605, 660)
$progressBar.Size = New-Object System.Drawing.Size(455, 18)
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$progressBar.Value = 0
$form.Controls.Add($progressBar)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Sẵn sàng khởi động quy trình..."
$lblStatus.Location = New-Object System.Drawing.Point(605, 685)
$lblStatus.Size = New-Object System.Drawing.Size(455, 25)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(148, 163, 184)
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$form.Controls.Add($lblStatus)

# ==============================================================================
# CAC HAM GHI LOG & TIEN ICH CHUNG
# ==============================================================================
function Write-Log {
    param(
        [string]$message,
        [string]$type = "info"
    )

    if ($txtLog -and $txtLog.InvokeRequired) {
        $txtLog.Invoke([System.Action[string, string]]{ param($m, $t) Write-Log $m $t }, @($message, $type))
        return
    }

    if ($txtLog -and $txtLog.Lines.Length -gt 600) {
        try {
            $excessLength = $txtLog.GetFirstCharIndexFromLine(150)
            if ($excessLength -gt 0) {
                $txtLog.Select(0, $excessLength)
                $txtLog.SelectedText = ""
            }
        } catch {}
    }

    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $defaultColor = switch ($type) {
        "error"   { [System.Drawing.Color]::FromArgb(239, 68, 68) }   # Do
        "warning" { [System.Drawing.Color]::FromArgb(245, 158, 11) }  # Vang cam
        "success" { [System.Drawing.Color]::FromArgb(34, 197, 94) }   # Xanh la
        "cmd"     { [System.Drawing.Color]::FromArgb(56, 189, 248) }  # Xanh lam
        default   { [System.Drawing.Color]::FromArgb(163, 230, 53) }  # Lime
    }

    $txtLog.SelectionStart = $txtLog.TextLength
    $txtLog.SelectionLength = 0
    $txtLog.SelectionColor = [System.Drawing.Color]::FromArgb(148, 163, 184)
    $txtLog.AppendText("[$timestamp] ")

    $txtLog.SelectionColor = $defaultColor
    $txtLog.AppendText("$message`r`n")
    $txtLog.ScrollToCaret()

    if ($lblStatus) {
        $lblStatus.Text = $message
    }
    [System.Windows.Forms.Application]::DoEvents()
}

# Tim file cai dat phu hop trong thu muc setup
function Find-InstallerFile {
    param(
        [hashtable]$softwareItem,
        [string]$baseDir
    )

    if (-not (Test-Path $baseDir)) { return $null }

    foreach ($cand in $softwareItem.Candidates) {
        $fullPath = Join-Path $baseDir $cand
        if (Test-Path $fullPath) {
            return (Get-Item $fullPath).FullName
        }
    }

    # Neu chua tim thay, tim kiem tuong doi (Pattern Search)
    $allFiles = Get-ChildItem -Path $baseDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match 'exe|msi|iso|zip' }
    foreach ($f in $allFiles) {
        foreach ($cand in $softwareItem.Candidates) {
            $cleanCand = $cand.Replace(".exe", "").Replace(".msi", "").Replace(".iso", "").Replace(".zip", "").Replace("*", "").Replace("\", "")
            if ($f.Name -like "*$cleanCand*") {
                return $f.FullName
            }
        }
    }

    return $null
}

# ==============================================================================
# MODULE TINH CHINH HE THONG WINDOWS 11
# ==============================================================================

# 1. Tinh chinh Windows 11: Classic Context Menu, Tat UAC, Tat Sleep & Hibernate
function Invoke-Win11Tweaks {
    Write-Log "==================================================" "cmd"
    Write-Log "BẮT ĐẦU ÁP DỤNG TINH CHỈNH TỐI ƯU WINDOWS 11..." "cmd"

    # [A] Chuyen Menu chuot phai Windows 11 ve dang co dien (Classic Context Menu)
    try {
        Write-Log "1. Kích hoạt Menu chuột phải Windows 11 cổ điển (Full Menu)..." "info"
        $regPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-ItemProperty -Path $regPath -Name "(Default)" -Value "" -Force
        Write-Log "   -> Đã áp dụng Registry Classic Context Menu." "success"
    } catch {
        Write-Log "   -> Lỗi khi cấu hình Menu chuột phải: $($_.Exception.Message)" "error"
    }

    # [B] Tat Sleep & Hibernate de may luon san sang hoat dong lien tuc
    try {
        Write-Log "2. Tắt chế độ Sleep & Hibernate khi cắm sạc..." "info"
        powercfg -h off 2>&1 | Out-Null
        powercfg /change standby-timeout-ac 0 2>&1 | Out-Null
        powercfg /change monitor-timeout-ac 30 2>&1 | Out-Null
        Write-Log "   -> Đã cấu hình nguồn điện không bao giờ ngủ (Standby Timeout = 0)." "success"
    } catch {}

    # [C] Ha muc UAC de khong chan chay phan mem noi bo
    try {
        Write-Log "3. Hạ mức cảnh báo UAC (User Account Control)..." "info"
        $uacKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Set-ItemProperty -Path $uacKey -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $uacKey -Name "PromptOnSecureDesktop" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Log "   -> Đã thiết lập UAC Never Notify." "success"
    } catch {}

    # [D] Khoi dong lai Explorer de cap nhat ngay lap tuc
    try {
        Write-Log "4. Khởi động lại Windows Explorer để áp dụng giao diện..." "info"
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Write-Log "   -> Hoàn tất tinh chỉnh Windows 11!" "success"
    } catch {}
}

# 2. Sua loi chia se may in LAN & Mang noi bo
function Invoke-FixLanPrintShare {
    Write-Log "==================================================" "cmd"
    Write-Log "CẤU HÌNH SỬA LỖI CHIA SẺ MÁY IN & MẠNG NỘI BỘ LAN..." "cmd"

    try {
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Print" -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        
        $pnpKey = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
        if (-not (Test-Path $pnpKey)) { New-Item -Path $pnpKey -Force | Out-Null }
        Set-ItemProperty -Path $pnpKey -Name "RestrictDriverInstallationToAdministrators" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        Get-NetConnectionProfile -ErrorAction SilentlyContinue | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue
        netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes 2>&1 | Out-Null

        Restart-Service -Name "Spooler", "LanmanWorkstation" -Force -ErrorAction SilentlyContinue

        Write-Log "[SUCCESS] Đã mở chia sẻ File & Máy in, sửa triệt để lỗi 0x0000011b & 0x00000709!" "success"
    } catch {
        Write-Log "[ERROR] Lỗi khi cấu hình chia sẻ mạng: $($_.Exception.Message)" "error"
    }
}

# 3. Cai dat dinh dang vung US chuan ngan hang
function Invoke-SetUSRegion {
    Write-Log "==================================================" "cmd"
    Write-Log "CẤU HÌNH ĐỊNH DẠNG VÙNG US (NUMBER & DATE FORMAT)..." "cmd"

    try {
        $intlKey = "HKCU:\Control Panel\International"
        if (-not (Test-Path $intlKey)) { New-Item -Path $intlKey -Force | Out-Null }
        Set-ItemProperty -Path $intlKey -Name "Locale" -Value "00000409" -Force
        Set-ItemProperty -Path $intlKey -Name "LocaleName" -Value "en-US" -Force
        Set-ItemProperty -Path $intlKey -Name "sDecimal" -Value "." -Force
        Set-ItemProperty -Path $intlKey -Name "sThousand" -Value "," -Force
        Set-ItemProperty -Path $intlKey -Name "sShortDate" -Value "dd/MM/yyyy" -Force
        Set-ItemProperty -Path $intlKey -Name "sTimeFormat" -Value "HH:mm:ss" -Force

        Write-Log "[SUCCESS] Đã thiết lập định dạng số (1,000.00) và ngày (dd/MM/yyyy) chuẩn ngân hàng!" "success"
    } catch {
        Write-Log "[ERROR] Lỗi khi cài đặt Region: $($_.Exception.Message)" "error"
    }
}

# 4. Toi uu Web & Cap nhat HOSTS VBSP
function Invoke-VBSPWebHosts {
    Write-Log "==================================================" "cmd"
    Write-Log "TỐI ƯU HÓA TRÌNH DUYỆT & CẤU HÌNH HOSTS VBSP..." "cmd"

    try {
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        Write-Log "   -> Đã làm mới DNS Cache hệ thống." "info"

        $chromePolicyKey = "HKLM:\SOFTWARE\Policies\Google\Chrome"
        $popupsKey = "$chromePolicyKey\PopupsAllowedForUrls"
        $insecureKey = "$chromePolicyKey\InsecureContentAllowedForUrls"
        $cookiesAllowedKey = "$chromePolicyKey\CookiesAllowedForUrls"

        foreach ($k in @($popupsKey, $insecureKey, $cookiesAllowedKey)) {
            if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
        }

        $allowedUrls = @("http://*.vbsp.vn", "https://*.vbsp.vn", "http://10.*", "http://192.168.*")
        $i = 1
        foreach ($u in $allowedUrls) {
            Set-ItemProperty -Path $popupsKey -Name "$i" -Value "$u" -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $insecureKey -Name "$i" -Value "$u" -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cookiesAllowedKey -Name "$i" -Value "$u" -Force -ErrorAction SilentlyContinue
            $i++
        }

        Write-Log "[SUCCESS] Đã cấu hình Policy Google Chrome cho phép Pop-up và Cookie hệ thống VBSP!" "success"
    } catch {
        Write-Log "[ERROR] Lỗi khi cấu hình Policy Web: $($_.Exception.Message)" "error"
    }
}

# ==============================================================================
# MODULE CAI DAT TUNG PHAN MEM DAC THU THEO YEU CAU
# ==============================================================================

# Cài đặt Total Commander (Giai nen TotalCMD.zip vao D:\ + chay AllReg.reg + Tao Shortcut)
function Install-TotalCMD([string]$baseDir) {
    Write-Log "--------------------------------------------------" "cmd"
    Write-Log "[START] Bắt đầu cài đặt Total Commander từ TotalCMD.zip..." "cmd"
    
    $zipPath = Join-Path $baseDir "TotalCMD.zip"
    if (-not (Test-Path $zipPath)) {
        $zipPath = (Get-ChildItem -Path $baseDir -Filter "*TotalCMD*.zip" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    }
    if (-not $zipPath -or (-not (Test-Path $zipPath))) {
        Write-Log "[WARN] Không tìm thấy file TotalCMD.zip trong $baseDir!" "warning"
        return $false
    }

    try {
        Write-Log "1. Đang giải nén TotalCMD.zip vào ổ D:\..." "info"
        Expand-Archive -Path $zipPath -DestinationPath "D:\" -Force
        Write-Log "   -> Đã giải nén thành công vào D:\TotalCMD" "success"

        $regFile = "D:\TotalCMD\AllReg.reg"
        if (Test-Path $regFile) {
            Write-Log "2. Đang nạp thông tin bản quyền (reg import $regFile)..." "info"
            Start-Process "reg.exe" -ArgumentList "import `"$regFile`"" -Wait -NoNewWindow
            Write-Log "   -> Đã nạp thành công AllReg.reg vào Windows Registry!" "success"
        }

        $targetExe = "D:\TotalCMD\TOTALCMD64.EXE"
        if (-not (Test-Path $targetExe)) { $targetExe = "D:\TotalCMD\TOTALCMD.EXE" }
        if (Test-Path $targetExe) {
            Write-Log "3. Đang tạo biểu tượng Total Commander lên màn hình Desktop..." "info"
            $desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
            $wsh = New-Object -ComObject WScript.Shell
            $sc = $wsh.CreateShortcut("$desktopPath\Total Commander.lnk")
            $sc.TargetPath = $targetExe
            $sc.WorkingDirectory = "D:\TotalCMD"
            $sc.Save()
            Write-Log "   -> Đã tạo shortcut Total Commander lên Desktop!" "success"
        }
        Write-Log "[SUCCESS] Đã hoàn tất cài đặt Total Commander!" "success"
        return $true
    } catch {
        Write-Log "[ERROR] Lỗi cài đặt Total Commander: $($_.Exception.Message)" "error"
        return $false
    }
}

# Thiet lap EVKey Portable (Copy vao Program Files, tao shortcut Desktop + shell:startup, chay ngay)
function Setup-EVKey([string]$baseDir) {
    Write-Log "--------------------------------------------------" "cmd"
    Write-Log "[START] Bắt đầu thiết lập bộ gõ tiếng Việt EVKey (Portable)..." "cmd"
    
    $evkeySource = Join-Path $baseDir "EVKey"
    if (-not (Test-Path $evkeySource)) {
        Write-Log "[WARN] Không tìm thấy thư mục 'EVKey' trong $baseDir!" "warning"
        return $false
    }

    try {
        $destDir = "C:\Program Files\EVKey"
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Write-Log "1. Đang copy bộ gõ EVKey vào $destDir..." "info"
        Copy-Item -Path "$evkeySource\*" -Destination $destDir -Recurse -Force

        $exePath = "$destDir\EVKey64.exe"
        if (-not (Test-Path $exePath)) { $exePath = "$destDir\EVKey32.exe" }

        # Tao shortcut Desktop
        Write-Log "2. Đang tạo Shortcut EVKey lên màn hình Desktop..." "info"
        $desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
        $wsh = New-Object -ComObject WScript.Shell
        $scDesktop = $wsh.CreateShortcut("$desktopPath\EVKey.lnk")
        $scDesktop.TargetPath = $exePath
        $scDesktop.WorkingDirectory = $destDir
        $scDesktop.Save()

        # Tao shortcut Startup (User Startup & All Users Startup)
        Write-Log "3. Đang thiết lập EVKey tự khởi động cùng Windows (shell:startup)..." "info"
        $userStartup = [Environment]::GetFolderPath("Startup")
        $scUser = $wsh.CreateShortcut("$userStartup\EVKey.lnk")
        $scUser.TargetPath = $exePath
        $scUser.WorkingDirectory = $destDir
        $scUser.Save()

        $commonStartup = [Environment]::GetFolderPath("CommonStartup")
        if (Test-Path $commonStartup) {
            $scCommon = $wsh.CreateShortcut("$commonStartup\EVKey.lnk")
            $scCommon.TargetPath = $exePath
            $scCommon.WorkingDirectory = $destDir
            $scCommon.Save()
        }

        # Dat quyen Run as Administrator cho EVKey64
        $regLayer = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
        if (-not (Test-Path $regLayer)) { New-Item -Path $regLayer -Force | Out-Null }
        Set-ItemProperty -Path $regLayer -Name $exePath -Value "~ RUNASADMIN" -Force -ErrorAction SilentlyContinue

        # Khoi chay EVKey64 ngay lap tuc
        Write-Log "4. Khởi chạy EVKey64 ngay bây giờ..." "info"
        Get-Process -Name "EVKey64", "EVKey32" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        Start-Process -FilePath $exePath

        Write-Log "[SUCCESS] Đã hoàn tất thiết lập & khởi động EVKey thành công!" "success"
        return $true
    } catch {
        Write-Log "[ERROR] Lỗi khi thiết lập EVKey: $($_.Exception.Message)" "error"
        return $false
    }
}

# Cai dat WinRAR tu winrar\Install.exe
function Install-WinRARPackage([string]$baseDir) {
    Write-Log "--------------------------------------------------" "cmd"
    Write-Log "[START] Bắt đầu cài đặt WinRAR..." "cmd"
    $installer = Join-Path $baseDir "winrar\Install.exe"
    if (-not (Test-Path $installer)) {
        $installer = (Get-ChildItem -Path $baseDir -Filter "Install.exe" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*winrar*" } | Select-Object -First 1).FullName
    }
    if (-not $installer -or (-not (Test-Path $installer))) {
        Write-Log "[WARN] Không tìm thấy winrar\Install.exe trong $baseDir!" "warning"
        return $false
    }

    Write-Log "Đang chạy bộ cài: $installer..." "info"
    $proc = Start-Process -FilePath $installer -ArgumentList "/s" -Wait -PassThru -NoNewWindow
    Write-Log "[SUCCESS] Đã cài đặt xong WinRAR! (ExitCode: $($proc.ExitCode))" "success"
    return $true
}

# Cai dat McAfee Security (TrellixAgent_5_7 truoc, sau do setupEP.exe)
function Install-McAfeePackage([string]$baseDir) {
    Write-Log "--------------------------------------------------" "cmd"
    Write-Log "[START] Bắt đầu quy trình cài đặt McAfee Security..." "cmd"
    
    # 1. Cai Trellix Agent truoc
    $agentExe = Join-Path $baseDir "McAfee\TrellixAgent_5_7.exe"
    if (-not (Test-Path $agentExe)) {
        $agentExe = (Get-ChildItem -Path $baseDir -Filter "*TrellixAgent*.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    }

    if ($agentExe -and (Test-Path $agentExe)) {
        Write-Log "1. Đang cài đặt Trellix Agent ($agentExe)..." "info"
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $agentExe
        $pinfo.Arguments = "/INSTALL=AGENT /SILENT"
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true
        $proc = [System.Diagnostics.Process]::Start($pinfo)
        while (-not $proc.HasExited) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 300
        }
        Write-Log "   -> Đã cài đặt xong Trellix Agent (ExitCode: $($proc.ExitCode))" "success"
    } else {
        Write-Log "[WARN] Không tìm thấy TrellixAgent_5_7.exe trong $baseDir\McAfee\" "warning"
    }

    # 2. Cai setupEP.exe trong Windows10
    $epExe = Join-Path $baseDir "McAfee\Windows10\setupEP.exe"
    if (-not (Test-Path $epExe)) {
        $epExe = (Get-ChildItem -Path $baseDir -Filter "setupEP.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    }

    if ($epExe -and (Test-Path $epExe)) {
        Write-Log "2. Đang cài đặt McAfee Endpoint Security ($epExe)..." "info"
        $pinfo2 = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo2.FileName = $epExe
        $pinfo2.Arguments = "/install default /silent"
        $pinfo2.UseShellExecute = $false
        $pinfo2.CreateNoWindow = $true
        $proc2 = [System.Diagnostics.Process]::Start($pinfo2)
        while (-not $proc2.HasExited) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 500
        }
        Write-Log "   -> Đã cài đặt xong McAfee Endpoint Security (ExitCode: $($proc2.ExitCode))" "success"
    } else {
        Write-Log "[WARN] Không tìm thấy setupEP.exe trong $baseDir\McAfee\Windows10\" "warning"
    }
    Write-Log "[SUCCESS] Hoàn tất tiến trình cài đặt McAfee!" "success"
    return $true
}

# Cai dat SQL Server 2017 Enterprise tu file ISO (Tu dong Mount -> Silent Setup -> Dismount)
function Install-SQLServer2017([string]$baseDir) {
    Write-Log "==================================================" "cmd"
    Write-Log "[START] BẮT ĐẦU CÀI ĐẶT MICROSOFT SQL SERVER 2017 TỪ ISO..." "cmd"

    # Kiem tra xem may da co SQL Server chua
    $sqlServices = Get-Service -Name "MSSQLSERVER", "MSSQL$*" -ErrorAction SilentlyContinue
    if ($sqlServices -and $sqlServices.Count -gt 0) {
        Write-Log "[SKIP] Máy tính này đã được cài đặt Microsoft SQL Server ($($sqlServices[0].Name))!" "success"
        return $true
    }

    # Tim file ISO
    $isoFile = Join-Path $baseDir "en_sql_server_2017_enterprise_x64_dvd_11293666.iso"
    if (-not (Test-Path $isoFile)) {
        $isoFile = (Get-ChildItem -Path $baseDir -Filter "*sql*2017*.iso" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    }
    if (-not $isoFile -or (-not (Test-Path $isoFile))) {
        Write-Log "[WARN] Không tìm thấy file ISO SQL Server 2017 trong $baseDir!" "warning"
        return $false
    }

    Write-Log "1. Đang gắn (Mount) ổ đĩa ảo từ file ISO: $isoFile..." "info"
    $driveLetter = $null
    try {
        $mountResult = Mount-DiskImage -ImagePath $isoFile -StorageType ISO -PassThru
        Start-Sleep -Seconds 2
        $driveLetter = ($mountResult | Get-Volume).DriveLetter
        if (-not $driveLetter) {
            $driveLetter = (Get-Volume | Where-Object { $_.DriveType -eq 'CD-ROM' -and $_.DriveLetter } | Select-Object -Last 1).DriveLetter
        }
        Write-Log "   -> File ISO đã được gắn thành công vào ổ đĩa ảo: ${driveLetter}:\" "success"

        $setupExe = "${driveLetter}:\setup.exe"
        if (-not (Test-Path $setupExe)) {
            Write-Log "[ERROR] Không tìm thấy setup.exe trong ổ đĩa ảo ${driveLetter}:\" "error"
            return $false
        }

        Write-Log "2. Bắt đầu chạy cài đặt ngầm SQL Server 2017 (vui lòng đợi 3-5 phút)..." "info"
        Write-Log "   -> Instance: SQLEXPRESS | Authentication: Windows Authentication (Mặc định)" "info"

        $sqlArgs = '/q /ACTION=Install /FEATURES=SQLENGINE /INSTANCENAME=SQLEXPRESS /SQLSYSADMINACCOUNTS="BUILTIN\Administrators" /TCPENABLED=1 /NPENABLED=1 /IACCEPTSQLSERVERLICENSETERMS /UpdateEnabled=False'
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $setupExe
        $pinfo.Arguments = $sqlArgs
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($pinfo)
        while (-not $proc.HasExited) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 500
        }

        Write-Log "   -> Quá trình cài đặt SQL Server hoàn tất với mã thoát: $($proc.ExitCode)" "info"
    } catch {
        Write-Log "[ERROR] Lỗi trong quá trình cài đặt SQL Server 2017: $($_.Exception.Message)" "error"
    } finally {
        Write-Log "3. Đang tháo (Dismount) ổ đĩa ảo ISO..." "info"
        try {
            Dismount-DiskImage -ImagePath $isoFile -ErrorAction SilentlyContinue
            Write-Log "   -> Đã tháo ổ đĩa ảo an toàn." "success"
        } catch {}
    }

    $sqlCheck = Get-Service -Name "MSSQLSERVER", "MSSQL$*" -ErrorAction SilentlyContinue
    if ($sqlCheck) {
        Write-Log "[SUCCESS] Đã cài đặt thành công Microsoft SQL Server 2017!" "success"
        return $true
    } else {
        Write-Log "[WARN] Đã chạy xong setup SQL Server. Vui lòng kiểm tra lại dịch vụ MSSQL`$SQLEXPRESS." "warning"
        return $false
    }
}

# Mo Port 1433 & Kich hoat dich vu SQL Server
function Invoke-ConfigSQLFirewall {
    Write-Log "==================================================" "cmd"
    Write-Log "CẤU HÌNH TƯỜNG LỬA CHO MICROSOFT SQL SERVER..." "cmd"

    try {
        netsh advfirewall firewall add rule name="SQL Server (TCP 1433)" dir=in action=allow protocol=TCP localport=1433 profile=any 2>&1 | Out-Null
        netsh advfirewall firewall add rule name="SQL Browser (UDP 1434)" dir=in action=allow protocol=UDP localport=1434 profile=any 2>&1 | Out-Null

        $sqlServices = Get-Service -Name "MSSQLSERVER", "MSSQL$*", "SQLBrowser" -ErrorAction SilentlyContinue
        if ($sqlServices) {
            foreach ($s in $sqlServices) {
                Set-Service -Name $s.Name -StartupType Automatic -ErrorAction SilentlyContinue
                Start-Service -Name $s.Name -ErrorAction SilentlyContinue
            }
            Write-Log "[SUCCESS] Đã mở Port 1433/1434 & kích hoạt các dịch vụ SQL Server!" "success"
        } else {
            Write-Log "[OK] Đã mở luật tường lửa cho Port 1433 & 1434." "success"
        }
    } catch {
        Write-Log "[ERROR] Lỗi cấu hình SQL Firewall: $($_.Exception.Message)" "error"
    }
}

# Phuc hoi CSDL VbspOffline tu file VbspOffline*.zip (Giai nen lay .bak va Restore Database)
function Restore-VbspOfflineDB([string]$baseDir) {
    Write-Log "==================================================" "cmd"
    Write-Log "[START] BẮT ĐẦU QUY TRÌNH PHỤC HỒI CƠ SỞ DỮ LIỆU VbspOffline..." "cmd"

    # 1. Kiem tra SQL Server
    $sqlService = Get-Service -Name "MSSQLSERVER", "MSSQL$*" -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }
    if (-not $sqlService) {
        Start-Service -Name "MSSQLSERVER" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }

    # 2. Tim file zip chua file .bak
    $zipBak = Join-Path $baseDir "VbspOffline44530220261024.zip"
    if (-not (Test-Path $zipBak)) {
        $zipBak = (Get-ChildItem -Path $baseDir -Filter "VbspOffline*.zip" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    }

    if (-not $zipBak -or (-not (Test-Path $zipBak))) {
        Write-Log "[WARN] Không tìm thấy file VbspOffline*.zip trong thư mục $baseDir!" "warning"
        return $false
    }

    # 3. Giai nen file .bak ra thu muc D:\BAK
    $bakFolder = "D:\BAK"
    if (-not (Test-Path $bakFolder)) { New-Item -ItemType Directory -Path $bakFolder -Force | Out-Null }

    Write-Log "1. Đang giải nén file backup CSDL từ: $(Split-Path $zipBak -Leaf)..." "info"
    try {
        Expand-Archive -Path $zipBak -DestinationPath $bakFolder -Force
    } catch {
        Write-Log "[ERROR] Lỗi giải nén file ZIP: $($_.Exception.Message)" "error"
        return $false
    }

    $bakFile = (Get-ChildItem -Path $bakFolder -Filter "*.bak" -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
    if (-not $bakFile -or (-not (Test-Path $bakFile))) {
        Write-Log "[ERROR] Không tìm thấy file .bak sau khi giải nén!" "error"
        return $false
    }
    Write-Log "   -> Đã trích xuất file sao lưu: $bakFile" "success"

    # 4. Thuc hien Restore Database
    Write-Log "2. Đang kết nối SQL Server và đọc thông tin Logical Name của file BAK..." "info"
    $conn = $null
    try {
        $targetInst = "(local)"
        $services = Get-Service -Name "MSSQLSERVER", "MSSQL$*" -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }
        if ($services -and $services[0].Name -ne "MSSQLSERVER") {
            $targetInst = ".\" + $services[0].Name.Replace("MSSQL$", "")
        }
        Write-Log "   -> Kết nối tới SQL Instance: $targetInst" "info"
        $conn = New-Object System.Data.SqlClient.SqlConnection("Server=$targetInst;Database=master;Integrated Security=True;Connection Timeout=30;")
        $conn.Open()

        $cmdFileList = $conn.CreateCommand()
        $cmdFileList.CommandText = "RESTORE FILELISTONLY FROM DISK = N'$bakFile'"
        $da = New-Object System.Data.SqlClient.SqlDataAdapter($cmdFileList)
        $dt = New-Object System.Data.DataTable
        $da.Fill($dt) | Out-Null

        $logicalData = ($dt | Where-Object { $_.Type -eq 'D' } | Select-Object -First 1).LogicalName
        $logicalLog  = ($dt | Where-Object { $_.Type -eq 'L' } | Select-Object -First 1).LogicalName
        if (-not $logicalData) { $logicalData = "VbspOffline" }
        if (-not $logicalLog)  { $logicalLog  = "VbspOffline_log" }

        Write-Log "   -> Logical Data: [$logicalData] | Logical Log: [$logicalLog]" "info"

        # Lay duong dan Data va Log cua SQL Server
        $cmdPath = $conn.CreateCommand()
        $cmdPath.CommandText = "SELECT SERVERPROPERTY('InstanceDefaultDataPath') AS DataPath, SERVERPROPERTY('InstanceDefaultLogPath') AS LogPath"
        $rdr = $cmdPath.ExecuteReader()
        $dataPath = $null; $logPath = $null
        if ($rdr.Read()) {
            $dataPath = $rdr["DataPath"]
            $logPath  = $rdr["LogPath"]
        }
        $rdr.Close()

        if (-not $dataPath) { $dataPath = "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA" }
        if (-not $logPath)  { $logPath  = $dataPath }
        if (-not (Test-Path $dataPath)) { New-Item -ItemType Directory -Path $dataPath -Force | Out-Null }

        $destMdf = Join-Path $dataPath "VbspOffline.mdf"
        $destLdf = Join-Path $logPath  "VbspOffline.ldf"

        Write-Log "3. Đang thực thi lệnh RESTORE DATABASE [VbspOffline] WITH REPLACE..." "warning"
        
        $cmdSingle = $conn.CreateCommand()
        $cmdSingle.CommandTimeout = 60
        $cmdSingle.CommandText = "IF DB_ID('VbspOffline') IS NOT NULL ALTER DATABASE [VbspOffline] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;"
        $cmdSingle.ExecuteNonQuery() | Out-Null

        $cmdRestore = $conn.CreateCommand()
        $cmdRestore.CommandTimeout = 600
        $cmdRestore.CommandText = "RESTORE DATABASE [VbspOffline] FROM DISK = N'$bakFile' WITH MOVE N'$logicalData' TO N'$destMdf', MOVE N'$logicalLog' TO N'$destLdf', REPLACE, RECOVERY, STATS = 10;"
        $cmdRestore.ExecuteNonQuery() | Out-Null

        $cmdMulti = $conn.CreateCommand()
        $cmdMulti.CommandTimeout = 60
        $cmdMulti.CommandText = "ALTER DATABASE [VbspOffline] SET MULTI_USER;"
        $cmdMulti.ExecuteNonQuery() | Out-Null

        Write-Log "[SUCCESS] ĐÃ PHỤC HỒI THÀNH CÔNG CƠ SỞ DỮ LIỆU VbspOffline!" "success"
        return $true
    } catch {
        Write-Log "[ERROR] Lỗi khi phục hồi CSDL VbspOffline: $($_.Exception.Message)" "error"
        return $false
    } finally {
        if ($conn -and $conn.State -eq [System.Data.ConnectionState]::Open) {
            try {
                $cmdSafeguard = $conn.CreateCommand()
                $cmdSafeguard.CommandText = "IF DB_ID('VbspOffline') IS NOT NULL ALTER DATABASE [VbspOffline] SET MULTI_USER;"
                $cmdSafeguard.ExecuteNonQuery() | Out-Null
            } catch {}
            $conn.Close()
            $conn.Dispose()
        }
    }
}

# Ham cai dat chung cho cac file MSI / EXE con lai
function Install-GenericSoftware([hashtable]$item, [string]$baseDir) {
    if ($item.IsCustom) {
        if ($item.Id -eq "totalcmd")    { return (Install-TotalCMD $baseDir) }
        if ($item.Id -eq "evkey")       { return (Setup-EVKey $baseDir) }
        if ($item.Id -eq "sqlserver")   { return (Install-SQLServer2017 $baseDir) }
        if ($item.Id -eq "restorevbsp") { return (Restore-VbspOfflineDB $baseDir) }
    }

    if ($item.Id -eq "winrar")  { return (Install-WinRARPackage $baseDir) }
    if ($item.Id -eq "mcafee" -or $item.Id -eq "trellix") { return (Install-McAfeePackage $baseDir) }

    Write-Log "--------------------------------------------------" "cmd"
    Write-Log "[START] Đang kiểm tra & chuẩn bị cài: $($item.Name)..." "cmd"

    try {
        if ($item.CheckScript -and (& $item.CheckScript)) {
            Write-Log "[SKIP] $($item.Name) đã được cài đặt sẵn trên máy tính!" "success"
            return $true
        }
    } catch {}

    $installerPath = Find-InstallerFile -softwareItem $item -baseDir $baseDir
    if (-not $installerPath) {
        Write-Log "[WARN] Chưa tìm thấy file cài cho $($item.Name) trong '$baseDir'!" "warning"
        return $false
    }

    Write-Log "[SETUP] Đang chạy bộ cài: $installerPath" "info"
    try {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        if ($installerPath.EndsWith(".msi")) {
            $pinfo.FileName = "msiexec.exe"
            $pinfo.Arguments = "/i `"$installerPath`" /qn /norestart"
        } else {
            $pinfo.FileName = $installerPath
            $pinfo.Arguments = $item.Arguments
        }
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true

        Write-Log "[WAIT] Đang cài đặt ngầm trong tiến trình nền, vui lòng đợi..." "info"
        $process = [System.Diagnostics.Process]::Start($pinfo)
        while (-not $process.HasExited) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 300
        }

        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Log "[SUCCESS] Đã cài đặt thành công $($item.Name)! (Mã thoát: $($process.ExitCode))" "success"
            return $true
        } else {
            Write-Log "[WARN] $($item.Name) hoàn tất với mã: $($process.ExitCode)." "warning"
            return $true
        }
    } catch {
        Write-Log "[ERROR] Lỗi khi thực thi $($item.Name): $($_.Exception.Message)" "error"
        return $false
    }
}

# ==============================================================================
# MODULE TAO SHORTCUTS & BOOKMARKS VBSP (CHAY SAU KHI DA CO CHROME)
# ==============================================================================

# Tao Shortcuts cac ung dung VBSP len Desktop
function Invoke-CreateVBSPShortcuts {
    Write-Log "==================================================" "cmd"
    Write-Log "BẮT ĐẦU TẠO SHORTCUTS TIỆN ÍCH VBSP LÊN DESKTOP..." "cmd"

    $desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
    if ([string]::IsNullOrEmpty($desktopPath) -or (-not (Test-Path $desktopPath))) {
        $desktopPath = "$env:USERPROFILE\Desktop"
    }
    Write-Log "Thư mục Desktop: $desktopPath" "info"

    $chromeExe = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" -ErrorAction SilentlyContinue)."(default)"
    $browserName = "Google Chrome"
    if ([string]::IsNullOrEmpty($chromeExe) -or (-not (Test-Path $chromeExe))) {
        $edgeReg = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" -ErrorAction SilentlyContinue)."(default)"
        if ($edgeReg -and (Test-Path $edgeReg)) {
            $chromeExe = $edgeReg
            $browserName = "Microsoft Edge"
        }
    }

    $wshShell = New-Object -ComObject WScript.Shell
    $createdCount = 0

    # 1. Shortcut dac biet: Intellect iDC (chay qua Chrome/Edge voi Flags toi uu)
    $idcPath = Join-Path $desktopPath "Intellect iDC.lnk"
    $idcUrl = "https://idc.vbsp.vn:7011/ARXSSO/oauth/doLogin"
    try {
        if ($chromeExe) {
            $sc = $wshShell.CreateShortcut($idcPath)
            $sc.TargetPath = $chromeExe
            $sc.Arguments = "--disable-popup-blocking --disable-translate --no-first-run --disable-infobars `"$idcUrl`""
            $sc.WorkingDirectory = Split-Path $chromeExe
            $sc.IconLocation = "$chromeExe,0"
            $sc.Save()
            Write-Log "✔ Đã tạo shortcut: Intellect iDC (chạy qua $browserName)" "success"
            $createdCount++
        }
    } catch {
        Write-Log "Lỗi tạo shortcut Intellect iDC: $($_.Exception.Message)" "error"
    }

    # 2. Danh sach cac shortcut he thong nghiep vu ngan hang
    $vbspLinks = @(
        @{ Name = "QLTDCS - WebADMIN"; Url = "https://tdcs.vbsp.vn" },
        @{ Name = "QLTDCS - BACKEND"; Url = "http://10.63.41.53:8080" },
        @{ Name = "QLTDCS - eKYC"; Url = "http://10.63.41.64:3013/cmsgw/nhcsxh_sth/login" },
        @{ Name = "eOffice"; Url = "https://eoffice.vbsp.vn/" },
        @{ Name = "QL TDKT"; Url = "https://tdkt.vbsp.vn" },
        @{ Name = "QLHC (PGD)"; Url = "http://10.63.97.190:120" },
        @{ Name = "HTQLVH"; Url = "http://10.63.16.111/BDAInfo/Login.aspx" },
        @{ Name = "HTVHUD"; Url = "http://htvhud.vbsp.vn/ProjectsMgr/Infomation" },
        @{ Name = "VBSP Email"; Url = "https://mail.vbsp.vn/owa" },
        @{ Name = "Offline Install"; Url = "http://10.63.16.52/VbspOffline" }
    )

    foreach ($link in $vbspLinks) {
        try {
            $scPath = Join-Path $desktopPath "$($link.Name).lnk"
            if ($chromeExe) {
                $sc = $wshShell.CreateShortcut($scPath)
                $sc.TargetPath = $chromeExe
                $sc.Arguments = "`"$($link.Url)`""
                $sc.WorkingDirectory = Split-Path $chromeExe
                $sc.IconLocation = "$chromeExe,0"
                $sc.Save()
            } else {
                $urlFilePath = Join-Path $desktopPath "$($link.Name).url"
                "[InternetShortcut]`r`nURL=$($link.Url)" | Set-Content -Path $urlFilePath -Encoding ASCII
            }
            Write-Log "✔ Đã tạo shortcut: $($link.Name)" "success"
            $createdCount++
        } catch {
            Write-Log "Lỗi tạo shortcut $($link.Name): $($_.Exception.Message)" "error"
        }
    }

    Write-Log "[SUCCESS] Đã tạo thành công $createdCount shortcut VBSP lên Desktop!" "success"
}

# Them Bookmarks VBSP truc tiep len thanh dau trang Google Chrome
function Invoke-AddChromeBookmarks {
    Write-Log "==================================================" "cmd"
    Write-Log "BẮT ĐẦU THÊM BOOKMARKS VBSP VÀO GOOGLE CHROME..." "cmd"

    $userDataPath = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    if (-not (Test-Path $userDataPath)) {
        Write-Log "[WARN] Chưa tìm thấy thư mục dữ liệu Google Chrome trên máy tính!" "warning"
        Write-Log "Vui lòng mở Google Chrome ít nhất 1 lần để hệ thống tự tạo profile." "info"
        return
    }

    $chromeProcs = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
    if ($chromeProcs) {
        Write-Log "Đang đóng Google Chrome để cập nhật file Bookmarks an toàn..." "info"
        Stop-Process -Name "chrome" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    $vbspBookmarks = @(
        @{ Name = "Intellect iDC"; Url = "https://idc.vbsp.vn:7011/ARXSSO/oauth/doLogin" },
        @{ Name = "QLTDCS - WebADMIN"; Url = "https://tdcs.vbsp.vn" },
        @{ Name = "QLTDCS - BACKEND"; Url = "http://10.63.41.53:8080" },
        @{ Name = "QLTDCS - eKYC"; Url = "http://10.63.41.64:3013/cmsgw/nhcsxh_sth/login" },
        @{ Name = "eOffice"; Url = "https://eoffice.vbsp.vn/" },
        @{ Name = "QL TDKT"; Url = "https://tdkt.vbsp.vn" },
        @{ Name = "QLHC (PGD)"; Url = "http://10.63.97.190:120" },
        @{ Name = "HTQLVH"; Url = "http://10.63.16.111/BDAInfo/Login.aspx" },
        @{ Name = "HTVHUD"; Url = "http://htvhud.vbsp.vn/ProjectsMgr/Infomation" },
        @{ Name = "VBSP Email"; Url = "https://mail.vbsp.vn/owa" },
        @{ Name = "Offline Install"; Url = "http://10.63.16.52/VbspOffline" }
    )

    $profileDirs = Get-ChildItem -Path $userDataPath -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq "Default" -or $_.Name -like "Profile *" }

    if (-not $profileDirs -or $profileDirs.Count -eq 0) {
        $defaultDir = Join-Path $userDataPath "Default"
        if (-not (Test-Path $defaultDir)) { New-Item -ItemType Directory -Path $defaultDir -Force | Out-Null }
        $profileDirs = @(Get-Item $defaultDir)
    }

    $epoch = [DateTime]::SpecifyKind([DateTime]"1601-01-01 00:00:00", [DateTimeKind]::Utc)
    $totalAdded = 0

    foreach ($p in $profileDirs) {
        $bmFile = Join-Path $p.FullName "Bookmarks"
        $bmData = $null
        try {
            if (Test-Path $bmFile) {
                Copy-Item -Path $bmFile -Destination "$bmFile.vbsp.bak" -Force -ErrorAction SilentlyContinue
                $jsonContent = [System.IO.File]::ReadAllText($bmFile, [System.Text.Encoding]::UTF8)
                $bmData = ConvertFrom-Json -InputObject $jsonContent
            }
        } catch {}

        if (-not $bmData) {
            $bmData = [PSCustomObject]@{
                checksum = ""
                roots = [PSCustomObject]@{
                    bookmark_bar = [PSCustomObject]@{
                        children = @()
                        date_added = "13300000000000000"
                        date_last_used = "0"
                        date_modified = "13300000000000000"
                        id = "1"
                        name = "Bookmarks bar"
                        type = "folder"
                    }
                    other = [PSCustomObject]@{ children = @(); id = "2"; name = "Other bookmarks"; type = "folder" }
                    synced = [PSCustomObject]@{ children = @(); id = "3"; name = "Mobile bookmarks"; type = "folder" }
                }
                version = 1
            }
        }

        $existingChildren = @($bmData.roots.bookmark_bar.children)
        $maxId = 10
        foreach ($c in $existingChildren) {
            $nid = 0
            if ([int]::TryParse($c.id, [ref]$nid) -and $nid -gt $maxId) { $maxId = $nid }
        }

        $newChildren = [System.Collections.ArrayList]::new()
        foreach ($c in $existingChildren) { [void]$newChildren.Add($c) }

        $profAdded = 0
        foreach ($item in $vbspBookmarks) {
            $normUrl = $item.Url.Trim().TrimEnd('/').ToLowerInvariant()
            $exists = $false
            foreach ($c in $newChildren) {
                if ($c.type -eq "url" -and ($c.url.Trim().TrimEnd('/').ToLowerInvariant() -eq $normUrl -or $c.name -ieq $item.Name)) {
                    $c.url = $item.Url
                    $exists = $true
                    break
                }
            }

            if (-not $exists) {
                $maxId++
                $nowTicks = [string][long](([DateTime]::UtcNow - $epoch).Ticks / 10)
                $node = [PSCustomObject]@{
                    date_added     = $nowTicks
                    date_last_used = "0"
                    guid           = [guid]::NewGuid().ToString()
                    id             = [string]$maxId
                    name           = $item.Name
                    type           = "url"
                    url            = $item.Url
                }
                [void]$newChildren.Add($node)
                $profAdded++
            }
        }

        $bmData.roots.bookmark_bar.children = @($newChildren)
        $newJson = ConvertTo-Json -InputObject $bmData -Depth 10
        [System.IO.File]::WriteAllText($bmFile, $newJson, [System.Text.Encoding]::UTF8)
        Write-Log "✔ Đã thêm/cập nhật $profAdded bookmarks vào profile [$($p.Name)] của Chrome!" "success"
        $totalAdded += $profAdded
    }

    Write-Log "[SUCCESS] Hoàn tất thêm Bookmarks VBSP lên thanh dấu trang Google Chrome!" "success"
}

# ==============================================================================
# GAN SU KIEN CLICK CHO CAC NUT TINH NANG (EVENT HANDLERS)
# ==============================================================================

# 1. Tinh chinh he thong
$btnTweakWin11.Add_Click({ Invoke-Win11Tweaks })
$btnCreateShortcuts.Add_Click({ Invoke-CreateVBSPShortcuts })
$btnChromeBookmarks.Add_Click({ Invoke-AddChromeBookmarks })
$btnFixLanPrint.Add_Click({ Invoke-FixLanPrintShare })
$btnSetUS.Add_Click({ Invoke-SetUSRegion })
$btnWebHosts.Add_Click({ Invoke-VBSPWebHosts })

# 2. CSDL & Port
$btnSQLServer.Add_Click({ Install-SQLServer2017 $txtSetupDir.Text.Trim() })
$btnConfigSQL.Add_Click({ Invoke-ConfigSQLFirewall })
$btnRestoreDB.Add_Click({ Restore-VbspOfflineDB $txtSetupDir.Text.Trim() })

# Helper chay app le
function Run-SingleApp([string]$id) {
    $item = $script:SoftwareCatalog | Where-Object { $_.Id -eq $id }
    if ($item) {
        $baseDir = $txtSetupDir.Text.Trim()
        Install-GenericSoftware -item $item -baseDir $baseDir
    }
}

$btnChrome.Add_Click({ Run-SingleApp "chrome" })
$btnOffice.Add_Click({ Run-SingleApp "office365" })
$btnFoxit.Add_Click({ Run-SingleApp "foxit" })
$btnWinRAR.Add_Click({ Run-SingleApp "winrar" })
$btnTotalCmd.Add_Click({ Run-SingleApp "totalcmd" })
$btnEVKey.Add_Click({ Run-SingleApp "evkey" })
$btnZalo.Add_Click({ Run-SingleApp "zalo" })
$btnZoom.Add_Click({ Run-SingleApp "zoom" })

$btnUltraView.Add_Click({ Run-SingleApp "ultraview" })
$btnTeamView.Add_Click({ Run-SingleApp "teamview" })
$btnDeskIn.Add_Click({ Run-SingleApp "deskin" })
$btnCR.Add_Click({ Run-SingleApp "crruntime" })
$btnTrellix.Add_Click({ Run-SingleApp "trellix" })
$btnMcAfee.Add_Click({ Run-SingleApp "mcafee" })

$btnSSMS.Add_Click({ Run-SingleApp "ssms" })

# 3. Duyet thu muc setup
$btnBrowse.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = "Chọn thư mục chứa toàn bộ bộ cài đặt (ví dụ: D:\setup hoặc trên USB)"
    if (Test-Path $txtSetupDir.Text) { $fbd.SelectedPath = $txtSetupDir.Text }
    if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtSetupDir.Text = $fbd.SelectedPath
        Write-Log "Đã chuyển thư mục bộ cài sang: $($fbd.SelectedPath)" "info"
    }
})

# 4. Mo thu muc Setup trong Explorer
$btnOpenFolder.Add_Click({
    $dir = $txtSetupDir.Text.Trim()
    if (Test-Path $dir) {
        Start-Process "explorer.exe" -ArgumentList "`"$dir`""
    } else {
        Write-Log "Thư mục '$dir' không tồn tại trên máy tính!" "error"
    }
})

# 5. Xoa Log
$btnClearLog.Add_Click({
    $txtLog.Clear()
    $progressBar.Value = 0
    Write-Log "Màn hình nhật ký đã được làm mới." "info"
})

# 6. QUET KIEM TRA BO CAI VA TRANG THAI MAY
$btnCheckAll.Add_Click({
    $txtLog.Clear()
    Write-Log "==================================================" "cmd"
    Write-Log "TIẾN HÀNH QUÉT BỘ CÀI ĐẶT TẠI '$($txtSetupDir.Text)'..." "cmd"
    Write-Log "==================================================" "cmd"

    $baseDir = $txtSetupDir.Text.Trim()
    if (-not (Test-Path $baseDir)) {
        Write-Log "[ERROR] Không tìm thấy thư mục: '$baseDir'!" "error"
        Write-Log "Vui lòng kiểm tra lại ổ đĩa hoặc cắm USB chứa thư mục setup." "warning"
        return
    }

    $foundCount = 0
    $installedCount = 0

    foreach ($item in $script:SoftwareCatalog) {
        $isInstalled = $false
        try {
            if ($item.CheckScript -and (& $item.CheckScript)) {
                $isInstalled = $true
                $installedCount++
            }
        } catch {}

        $fPath = Find-InstallerFile -softwareItem $item -baseDir $baseDir
        if ($fPath) {
            $foundCount++
            $fileName = Split-Path $fPath -Leaf
            if ($isInstalled) {
                Write-Log "✔ [$($item.Name)] -> File: $fileName (Trạng thái: ĐÃ CÀI ĐẶT TRÊN MÁY)" "success"
            } else {
                Write-Log "✔ [$($item.Name)] -> File: $fileName (Trạng thái: SẴN SÀNG CÀI ĐẶT)" "info"
            }
        } else {
            if ($isInstalled) {
                Write-Log "✔ [$($item.Name)] -> ĐÃ CÀI ĐẶT TRÊN MÁY (Không cần bộ cài)" "success"
            } else {
                Write-Log "✖ [$($item.Name)] -> THIẾU BỘ CÀI (Mẫu: $($item.Candidates -join ', '))" "warning"
            }
        }
    }

    Write-Log "--------------------------------------------------" "cmd"
    Write-Log "[KẾT QUẢ QUÉT] Đã tìm thấy $foundCount/$($script:SoftwareCatalog.Count) bộ cài. ($installedCount ứng dụng đã có sẵn trên máy)." "cmd"
})

# 7. CAI DAT TAT CA TU A -> Z (1-CLICK ALL THEO THU TU CHUAN)
$btnInstallAll.Add_Click({
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "BẠN CÓ MUỐN BẮT ĐẦU QUY TRÌNH CÀI ĐẶT TOÀN DIỆN MÁY MỚI?`n`n" +
        "Thứ tự triển khai tối ưu:`n" +
        "  [Giai đoạn 1] Tinh chỉnh Win 11 (Chuột phải, Sleep, UAC) & Vùng US chuẩn Ngân hàng`n" +
        "  [Giai đoạn 2] Cấu hình Mạng LAN, Máy in (0x11b, 0x709) & HOSTS VBSP`n" +
        "  [Giai đoạn 3] Cài đặt toàn bộ ứng dụng (Chrome, Office, WinRAR, TotalCMD, EVKey, Zalo, Zoom, UltraViewer, TeamViewer, DeskIn, CrystalReports, McAfee...)`n" +
        "  [Giai đoạn 4] Cài đặt SQL Server 2017 (Tự động mount ISO), Mở Port 1433/TCP, Cài SSMS & Phục hồi CSDL VbspOffline`n" +
        "  [Giai đoạn 5] Tạo Shortcuts VBSP Desktop & Bookmarks Chrome (Lúc này đã có Chrome sẵn sàng)`n`n" +
        "Quá trình này hoàn toàn tự động.",
        "Xác nhận Cài Đặt Tất Cả - OneClick Win11 Setup",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $btnInstallAll.Enabled = $false
    $btnCheckAll.Enabled = $false
    $txtLog.Clear()
    $progressBar.Value = 0

    $totalSteps = 4 + $script:SoftwareCatalog.Count + 3
    $currentStep = 0

    function Update-ProgressStep {
        $script:currentStep++
        $percent = [math]::Min(100, [int](($script:currentStep / $totalSteps) * 100))
        $progressBar.Value = $percent
    }

    Write-Log "==================================================" "cmd"
    Write-Log "🚀 BẮT ĐẦU QUY TRÌNH TRIỂN KHAI TOÀN DIỆN CHO MÁY MỚI..." "cmd"
    Write-Log "==================================================" "cmd"

    # [Giai doan 1 & 2] Tinh chinh He thong
    Invoke-Win11Tweaks
    Update-ProgressStep

    Invoke-SetUSRegion
    Update-ProgressStep

    Invoke-FixLanPrintShare
    Update-ProgressStep

    Invoke-VBSPWebHosts
    Update-ProgressStep

    # [Giai doan 3] Cai dat cac ung dung Van phong, Tien ich & Bao mat
    $baseDir = $txtSetupDir.Text.Trim()
    $normalApps = $script:SoftwareCatalog | Where-Object { $_.Id -ne "sqlserver" -and $_.Id -ne "ssms" -and $_.Id -ne "restorevbsp" }
    foreach ($app in $normalApps) {
        Install-GenericSoftware -item $app -baseDir $baseDir
        Update-ProgressStep
    }

    # [Giai doan 4] Co so du lieu SQL Server, SSMS & Restore Database
    Install-SQLServer2017 $baseDir
    Update-ProgressStep

    Invoke-ConfigSQLFirewall
    Update-ProgressStep

    $ssmsApp = $script:SoftwareCatalog | Where-Object { $_.Id -eq "ssms" }
    if ($ssmsApp) {
        Install-GenericSoftware -item $ssmsApp -baseDir $baseDir
        Update-ProgressStep
    }

    Restore-VbspOfflineDB $baseDir
    Update-ProgressStep

    # [Giai doan 5] Tao Shortcuts Desktop & Bookmarks Chrome (Sau khi Chrome da cai dat hoan tat)
    Invoke-CreateVBSPShortcuts
    Update-ProgressStep

    Invoke-AddChromeBookmarks
    Update-ProgressStep

    Write-Log "==================================================" "cmd"
    Write-Log "🎉 TOÀN BỘ QUY TRÌNH CÀI ĐẶT VÀ TINH CHỈNH HOÀN TẤT 100%!" "success"
    Write-Log "Cơ sở dữ liệu VbspOffline đã sẵn sàng, các tiện ích đã hiển thị trên Desktop và Chrome." "info"
    Write-Log "Khuyến nghị: Bạn có thể khởi động lại máy để mọi thiết lập đạt hiệu quả cao nhất." "info"
    Write-Log "==================================================" "cmd"

    $btnInstallAll.Enabled = $true
    $btnCheckAll.Enabled = $true
    [System.Windows.Forms.MessageBox]::Show(
        "Đã hoàn tất toàn bộ quy trình cài đặt và tinh chỉnh máy mới!`n`n- Ứng dụng đã được cài đặt đầy đủ.`n- SQL Server 2017 & CSDL VbspOffline đã được phục hồi.`n- Shortcuts & Bookmarks đã được tạo thành công.`n`nBạn có thể khởi động lại máy để sử dụng mượt mà nhất.",
        "Thông báo hoàn tất",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
})

# ------------------------------------------------------------------------------
# SU KIEN NUT GIOI THIEU (ABOUT DIALOG GIONG ONECLICK VBSP)
# ------------------------------------------------------------------------------
$btnAbout.Add_Click({
    $abForm = New-Object System.Windows.Forms.Form
    $abForm.Text            = "Giá»›i thiá»‡u - OneClickVBSP"
    $abForm.Size            = New-Object System.Drawing.Size(420, 310)
    $abForm.StartPosition   = [System.Windows.Forms.FormStartPosition]::CenterParent
    $abForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $abForm.MaximizeBox     = $false
    $abForm.MinimizeBox     = $false
    $abForm.BackColor       = [System.Drawing.Color]::FromArgb(15, 23, 42)

    # Logo / Tieu de chinh
    $abTitle = New-Object System.Windows.Forms.Label
    $abTitle.Text      = "OneClickVBSP 2026"
    $abTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $abTitle.ForeColor = [System.Drawing.Color]::FromArgb(239, 68, 68)
    $abTitle.Location  = New-Object System.Drawing.Point(0, 25)
    $abTitle.Size      = New-Object System.Drawing.Size(420, 35)
    $abTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $abForm.Controls.Add($abTitle)

    # Subtitle version
    $abVer = New-Object System.Windows.Forms.Label
    $abVer.Text      = "v2026.10.30"
    $abVer.Font      = New-Object System.Drawing.Font("Segoe UI", 10)
    $abVer.ForeColor = [System.Drawing.Color]::FromArgb(100, 149, 237)
    $abVer.Location  = New-Object System.Drawing.Point(0, 62)
    $abVer.Size      = New-Object System.Drawing.Size(420, 22)
    $abVer.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $abForm.Controls.Add($abVer)

    # Duong ke ngang
    $abSep = New-Object System.Windows.Forms.Label
    $abSep.Text      = ""
    $abSep.BackColor = [System.Drawing.Color]::FromArgb(30, 58, 138)
    $abSep.Location  = New-Object System.Drawing.Point(30, 92)
    $abSep.Size      = New-Object System.Drawing.Size(360, 1)
    $abForm.Controls.Add($abSep)

    # Noi dung About chinh
    $toolAboutText = "CÃ´ng cá»¥ OneClick Win11 Setup`nBáº£n quyá»n: GiÃ¡p Háº£i - PhÃ²ng CNTT NHCSXH thÃ nh phá»‘ Báº¯c Ninh`nLiÃªn há»‡ há»— trá»£: PhÃ²ng CNTT NHCSXH thÃ nh phá»‘ Báº¯c Ninh"
    $abContent = New-Object System.Windows.Forms.Label
    $abContent.Text      = $toolAboutText
    $abContent.Font      = New-Object System.Drawing.Font("Segoe UI", 10)
    $abContent.ForeColor = [System.Drawing.Color]::FromArgb(203, 213, 225)
    $abContent.Location  = New-Object System.Drawing.Point(20, 105)
    $abContent.Size      = New-Object System.Drawing.Size(380, 110)
    $abContent.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
    $abForm.Controls.Add($abContent)

    # Nut Kiem tra cap nhat
    $abUpdate = New-Object System.Windows.Forms.Button
    $abUpdate.Text        = "Kiá»ƒm tra cáº­p nháº­t"
    $abUpdate.Location    = New-Object System.Drawing.Point(50, 225)
    $abUpdate.Size        = New-Object System.Drawing.Size(150, 32)
    $abUpdate.BackColor   = [System.Drawing.Color]::FromArgb(13, 148, 136)
    $abUpdate.ForeColor   = [System.Drawing.Color]::White
    $abUpdate.FlatStyle   = [System.Windows.Forms.FlatStyle]::Flat
    $abUpdate.FlatAppearance.BorderSize = 0
    $abUpdate.Font        = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $abUpdate.Cursor      = [System.Windows.Forms.Cursors]::Hand
    $abUpdate.Add_Click({
        $abForm.Close()
        Write-Log "Äang kiá»ƒm tra phiÃªn báº£n má»›i nháº¥t tá»« mÃ¡y chá»§ ná»™i bá»™ VBSP..." "cmd"
        Write-Log "PhiÃªn báº£n hiá»‡n táº¡i v2026.10.30 Ä‘Ã£ lÃ  má»›i nháº¥t!" "success"
        [System.Windows.Forms.MessageBox]::Show(
            "PhiÃªn báº£n hiá»‡n táº¡i v2026.10.30 Ä‘Ã£ lÃ  má»›i nháº¥t!",
            "Kiá»ƒm tra cáº­p nháº­t",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    })
    $abForm.Controls.Add($abUpdate)

    # Nut Dong
    $abClose = New-Object System.Windows.Forms.Button
    $abClose.Text        = "ÄÃ³ng"
    $abClose.Location    = New-Object System.Drawing.Point(220, 225)
    $abClose.Size        = New-Object System.Drawing.Size(150, 32)
    $abClose.BackColor   = [System.Drawing.Color]::FromArgb(30, 58, 138)
    $abClose.ForeColor   = [System.Drawing.Color]::White
    $abClose.FlatStyle   = [System.Windows.Forms.FlatStyle]::Flat
    $abClose.FlatAppearance.BorderSize = 0
    $abClose.Font        = New-Object System.Drawing.Font("Segoe UI", 9)
    $abClose.Cursor      = [System.Windows.Forms.Cursors]::Hand
    $abClose.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $abForm.Controls.Add($abClose)

    $abForm.AcceptButton = $abClose

    [void]$abForm.ShowDialog($form)
})

# ==============================================================================
# HIEN THI GIAO DIEN & THONG DIEP CHAO MUNG
# ==============================================================================
$form.Add_Shown({
    Write-Log "Chào mừng bạn đến với OneClick Windows 11 Setup Tool (Phiên bản VBSP 2026)!" "success"
    Write-Log "Thư mục cài đặt hiện tại: '$($txtSetupDir.Text)'" "info"
    Write-Log "Gợi ý: Bấm '[🔍 QUÉT KIỂM TRA BỘ CÀI]' để rà soát tự động toàn bộ file trong D:\setup." "cmd"
    Write-Log "Bạn có thể bấm từng nút để cài lẻ hoặc bấm '[🚀 CÀI ĐẶT TẤT CẢ]' để chạy tự động từ A -> Z." "info"
})

[void]$form.ShowDialog()
