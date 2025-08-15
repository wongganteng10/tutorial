@echo off
title Smart SSH Connection Tool
color 0a
setlocal enabledelayedexpansion

:: ======================================
:: File untuk menyimpan koneksi sebelumnya
:: ======================================
set "CONNECTION_FILE=%~dp0ssh_connections.txt"

:: ======================================
:: MENU UTAMA
:: ======================================
:MENU
cls
echo =====================================
echo       Smart SSH Connection Tool
echo =====================================
echo 1. Koneksi ke server
echo 2. Copy public key ke server
echo 3. Hapus key milik user Windows (lokal)
echo 4. Buat SSH key baru
echo 5. Pilih koneksi sebelumnya
echo 6. Test semua SSH key
echo 7. Hapus known_hosts
echo 0. Keluar
echo =====================================

:GET_MAIN_MENU_INPUT
set "MENU_CHOICE="
set /p "MENU_CHOICE=Pilih menu [0-7]: "

if "%MENU_CHOICE%"=="" (
    echo [ERROR] Harap masukkan pilihan
    goto GET_MAIN_MENU_INPUT
)

echo %MENU_CHOICE%|findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Input harus angka!
    goto GET_MAIN_MENU_INPUT
)

set /a MENU_CHOICE=%MENU_CHOICE% 2>nul
if %MENU_CHOICE% equ 0 goto EXIT
if %MENU_CHOICE% equ 1 goto CONNECT_MENU
if %MENU_CHOICE% equ 2 goto COPY_KEY_MENU
if %MENU_CHOICE% equ 3 goto DELETE_LOCAL_KEY
if %MENU_CHOICE% equ 4 goto GENERATE_KEY_MENU
if %MENU_CHOICE% equ 5 goto PREVIOUS_CONNECTION_MENU
if %MENU_CHOICE% equ 6 goto TEST_ALL_KEYS_MENU
if %MENU_CHOICE% equ 7 goto DELETE_KNOWN_HOSTS

echo [ERROR] Pilihan tidak valid!
goto GET_MAIN_MENU_INPUT

:: ======================================
:: Koneksi ke server - Menu
:: ======================================
:CONNECT_MENU
cls
echo =====================================
echo      Koneksi Ke Server
echo =====================================
echo 1. Masukkan server manual
echo 2. Pilih dari daftar koneksi sebelumnya
echo 0. Kembali ke Menu Utama
echo =====================================

:GET_CONNECT_CHOICE
set "CONNECT_CHOICE="
set /p "CONNECT_CHOICE=Pilih opsi [0-2]: "

if "%CONNECT_CHOICE%"=="" (
    echo [ERROR] Harap masukkan pilihan
    goto GET_CONNECT_CHOICE
)

echo %CONNECT_CHOICE%|findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Input harus angka!
    goto GET_CONNECT_CHOICE
)

set /a CONNECT_CHOICE=%CONNECT_CHOICE% 2>nul
if %CONNECT_CHOICE% equ 0 goto MENU
if %CONNECT_CHOICE% equ 1 goto CONNECT_MANUAL
if %CONNECT_CHOICE% equ 2 goto PREVIOUS_CONNECTION_MENU

echo [ERROR] Pilihan tidak valid!
goto GET_CONNECT_CHOICE

:: ======================================
:: Input credential manual
:: ======================================
:INPUT_CREDENTIAL
set "SRV_USER="
set "SRV_IP="
set "SRV_PORT="

:GET_USER_INPUT
set /p "SRV_USER=Masukkan username [default: ubuntu]: "
if "%SRV_USER%"=="" set "SRV_USER=ubuntu"

:GET_IP_INPUT
set /p "SRV_IP=Masukkan IP address [default: 192.168.10.108]: "
if "%SRV_IP%"=="" set "SRV_IP=192.168.10.108"

:GET_PORT_INPUT
set /p "SRV_PORT=Masukkan port SSH [default: 22]: "
if "%SRV_PORT%"=="" set "SRV_PORT=22"
goto :eof

:: ======================================
:: Koneksi manual
:: ======================================
:CONNECT_MANUAL
call :INPUT_CREDENTIAL
goto DO_CONNECT

:: ======================================
:: Proses koneksi
:: ======================================
:DO_CONNECT
echo [INFO] Mengecek koneksi ke %SRV_IP%...
ping -n 1 %SRV_IP% >nul
if errorlevel 1 (
    echo [ERROR] Tidak dapat terhubung ke %SRV_IP%.
    pause
    goto CONNECT_MENU
)

:: Simpan koneksi ke file jika belum ada
if not exist "%CONNECTION_FILE%" (
    >"%CONNECTION_FILE%" echo %SRV_USER%@%SRV_IP%
) else (
    findstr /x /c:"%SRV_USER%@%SRV_IP%" "%CONNECTION_FILE%" >nul || >>"%CONNECTION_FILE%" echo %SRV_USER%@%SRV_IP%
)

:GET_USE_KEY_INPUT
set "USE_KEY="
set /p "USE_KEY=Gunakan SSH key? (y/n) [default: n]: "
if /i "%USE_KEY%"=="y" (
    :: Coba semua tipe key yang tersedia
    for %%k in (rsa ecdsa ed25519 dsa) do (
        set "KEY_FILE=%USERPROFILE%\.ssh\id_%%k"
        if exist "!KEY_FILE!" (
            echo [INFO] Mencoba dengan id_%%k...
            ssh -o "PreferredAuthentications publickey" -i "!KEY_FILE!" -p %SRV_PORT% %SRV_USER%@%SRV_IP%
            if !errorlevel! == 0 goto MENU
        )
    )
    echo [ERROR] Semua SSH key gagal, fallback ke password...
)
ssh -p %SRV_PORT% %SRV_USER%@%SRV_IP%
goto MENU

:: ======================================
:: Copy Public Key Menu
:: ======================================
:COPY_KEY_MENU
cls
echo =====================================
echo         Copy Public Key ke Server
echo =====================================
echo 1. Masukkan username, IP, port SSH manual
echo 2. Pilih dari daftar koneksi sebelumnya
echo 0. Kembali ke Menu Utama
echo =====================================

:GET_COPY_CHOICE_INPUT
set "COPY_CHOICE="
set /p "COPY_CHOICE=Pilih opsi [0-2]: "

if "%COPY_CHOICE%"=="" (
    echo [ERROR] Harap masukkan pilihan
    goto GET_COPY_CHOICE_INPUT
)

echo %COPY_CHOICE%|findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Input harus angka!
    goto GET_COPY_CHOICE_INPUT
)

set /a COPY_CHOICE=%COPY_CHOICE% 2>nul
if %COPY_CHOICE% equ 0 goto MENU
if %COPY_CHOICE% equ 1 (
    call :INPUT_CREDENTIAL
    goto SELECT_KEY_TO_COPY
)
if %COPY_CHOICE% equ 2 goto PREVIOUS_CONNECTION_MENU_COPY

echo [ERROR] Pilihan tidak valid!
goto GET_COPY_CHOICE_INPUT

:: ======================================
:: Pilih Public Key yang akan dicopy
:: ======================================
:SELECT_KEY_TO_COPY
cls
echo =====================================
echo      Pilih Public Key yang akan dicopy
echo =====================================
set /a KEY_INDEX=0

:: Cari semua public key yang tersedia
for %%F in ("%USERPROFILE%\.ssh\*.pub") do (
    set /a KEY_INDEX+=1
    set "KEY[!KEY_INDEX!]=%%F"
    echo !KEY_INDEX!. %%~nF
)
echo 0. Kembali
echo =====================================

:GET_KEY_CHOICE_INPUT
set "KEY_CHOICE="
set /p "KEY_CHOICE=Pilih key [1-!KEY_INDEX!] atau 0 untuk kembali: "

if "%KEY_CHOICE%"=="" (
    echo [ERROR] Harap masukkan pilihan
    goto GET_KEY_CHOICE_INPUT
)

echo %KEY_CHOICE%|findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Input harus angka!
    goto GET_KEY_CHOICE_INPUT
)

set /a KEY_CHOICE=%KEY_CHOICE% 2>nul
if %KEY_CHOICE% equ 0 goto COPY_KEY_MENU
if %KEY_CHOICE% lss 1 (
    echo [ERROR] Pilihan tidak valid
    pause
    goto GET_KEY_CHOICE_INPUT
)
if %KEY_CHOICE% gtr %KEY_INDEX% (
    echo [ERROR] Pilihan tidak valid
    pause
    goto GET_KEY_CHOICE_INPUT
)

set "PUB_KEY=!KEY[%KEY_CHOICE%]!"
goto COPY_KEY

:: ======================================
:: Copy Key
:: ======================================
:COPY_KEY
echo [INFO] Mengirim public key %PUB_KEY% ke server %SRV_USER%@%SRV_IP%...

:: Coba dengan SSH key terlebih dahulu
set "PRIV_KEY=%PUB_KEY:.pub=%"
if exist "%PRIV_KEY%" (
    echo [TRY] Mencoba dengan autentikasi key...
    type "%PUB_KEY%" | ssh -i "%PRIV_KEY%" -p %SRV_PORT% %SRV_USER%@%SRV_IP% "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    if not errorlevel 1 (
        echo [SUKSES] Key berhasil dicopy menggunakan autentikasi key.
        pause
        goto COPY_KEY_MENU
    )
)

:: Jika gagal, coba dengan password
echo [INFO] Mencoba dengan autentikasi password...
type "%PUB_KEY%" | ssh -p %SRV_PORT% %SRV_USER%@%SRV_IP% "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
if errorlevel 1 (
    echo [ERROR] Gagal meng-copy public key ke server.
) else (
    echo [SUKSES] Key berhasil dicopy menggunakan password.
)
pause
goto COPY_KEY_MENU

:: ======================================
:: Daftar koneksi sebelumnya (untuk menu 5)
:: ======================================
:PREVIOUS_CONNECTION_MENU
cls
echo =====================================
echo      Daftar koneksi sebelumnya
echo =====================================
if not exist "%CONNECTION_FILE%" (
    echo [INFO] Belum ada koneksi tersimpan.
    pause
    goto MENU
)

set /a INDEX=0
for /f "tokens=*" %%A in ('type "%CONNECTION_FILE%"') do (
    set /a INDEX+=1
    set "CONN[!INDEX!]=%%A"
    echo !INDEX!. %%A
)
echo 0. Kembali ke Menu Utama
echo =====================================

:GET_CONNECTION_INPUT
set "CHOICE="
set /p "CHOICE=Pilih koneksi [1-!INDEX!] atau 0 untuk kembali: "

if "%CHOICE%"=="" (
    echo [ERROR] Harap masukkan pilihan
    goto GET_CONNECTION_INPUT
)

echo %CHOICE%|findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Input harus angka!
    goto GET_CONNECTION_INPUT
)

set /a IDX=%CHOICE% 2>nul
if %IDX% equ 0 goto MENU
if %IDX% lss 1 (
    echo [ERROR] Nomor tidak valid!
    goto GET_CONNECTION_INPUT
)
if %IDX% gtr %INDEX% (
    echo [ERROR] Nomor tidak tersedia!
    goto GET_CONNECTION_INPUT
)

set "SELECTED_CONN=!CONN[%IDX%]!"
if not defined SELECTED_CONN (
    echo [ERROR] Koneksi tidak valid!
    goto GET_CONNECTION_INPUT
)

:: Split koneksi yang dipilih
for /f "tokens=1,2 delims=@" %%u in ("%SELECTED_CONN%") do (
    set "SRV_USER=%%u"
    set "SRV_IP=%%v"
)
set "SRV_PORT=22"
echo.
echo Menggunakan koneksi: %SRV_USER%@%SRV_IP%

:GET_CONN_PORT_INPUT
set /p "SRV_PORT=Masukkan port SSH [default: 22]: "
if "%SRV_PORT%"=="" set "SRV_PORT=22"

:: Langsung lanjut ke koneksi
goto DO_CONNECT

:: ======================================
:: Daftar koneksi sebelumnya untuk Copy Key
:: ======================================
:PREVIOUS_CONNECTION_MENU_COPY
cls
echo =====================================
echo      Daftar koneksi sebelumnya
echo =====================================
if not exist "%CONNECTION_FILE%" (
    echo [INFO] Belum ada koneksi tersimpan.
    pause
    goto COPY_KEY_MENU
)

set /a INDEX=0
for /f "tokens=*" %%A in ('type "%CONNECTION_FILE%"') do (
    set /a INDEX+=1
    set "CONN[!INDEX!]=%%A"
    echo !INDEX!. %%A
)
echo 0. Kembali ke Menu Copy Key
echo =====================================

:GET_COPY_CONN_INPUT
set "CHOICE="
set /p "CHOICE=Pilih koneksi [1-!INDEX!] atau 0 untuk kembali: "

if "%CHOICE%"=="" (
    echo [ERROR] Harap masukkan pilihan
    goto GET_COPY_CONN_INPUT
)

echo %CHOICE%|findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Input harus angka!
    goto GET_COPY_CONN_INPUT
)

set /a IDX=%CHOICE% 2>nul
if %IDX% equ 0 goto COPY_KEY_MENU
if %IDX% lss 1 (
    echo [ERROR] Pilihan tidak valid.
    pause
    goto GET_COPY_CONN_INPUT
)
if %IDX% gtr %INDEX% (
    echo [ERROR] Pilihan tidak valid.
    pause
    goto GET_COPY_CONN_INPUT
)

if not defined CONN[%IDX%] (
    echo [ERROR] Pilihan tidak valid.
    pause
    goto GET_COPY_CONN_INPUT
)

for /f "tokens=1,2 delims=@" %%u in ("!CONN[%IDX%]!") do (
    set "SRV_USER=%%u"
    set "SRV_IP=%%v"
)
set "SRV_PORT=22"
echo Menggunakan koneksi: %SRV_USER%@%SRV_IP%

:GET_COPY_PORT_INPUT
set /p "SRV_PORT=Masukkan port SSH [default: 22]: "
if "%SRV_PORT%"=="" set "SRV_PORT=22"

goto SELECT_KEY_TO_COPY

:: ======================================
:: Generate SSH Key Menu
:: ======================================
:GENERATE_KEY_MENU
cls
echo =====================================
echo          Buat SSH Key Baru
echo =====================================
echo 1. RSA 4096-bit (paling kompatibel)
echo 2. Ed25519 (paling aman)
echo 3. ECDSA (nistp256)
echo 4. DSA (tidak direkomendasikan)
echo 0. Kembali ke Menu Utama
echo =====================================

:GET_GEN_CHOICE_INPUT
set "GEN_CHOICE="
set /p "GEN_CHOICE=Pilih opsi [0-4]: "

if "%GEN_CHOICE%"=="" (
    echo [ERROR] Harap masukkan pilihan
    goto GET_GEN_CHOICE_INPUT
)

echo %GEN_CHOICE%|findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Input harus angka!
    goto GET_GEN_CHOICE_INPUT
)

set /a GEN_CHOICE=%GEN_CHOICE% 2>nul
if %GEN_CHOICE% equ 0 goto MENU
if %GEN_CHOICE% equ 1 (
    set "KEY_TYPE=rsa"
    set "KEY_BITS=4096"
    goto GENERATE_KEY
)
if %GEN_CHOICE% equ 2 (
    set "KEY_TYPE=ed25519"
    set "KEY_BITS="
    goto GENERATE_KEY
)
if %GEN_CHOICE% equ 3 (
    set "KEY_TYPE=ecdsa"
    set "KEY_BITS=256"
    goto GENERATE_KEY
)
if %GEN_CHOICE% equ 4 (
    set "KEY_TYPE=dsa"
    set "KEY_BITS=1024"
    goto GENERATE_KEY
)

echo [ERROR] Pilihan tidak valid!
goto GET_GEN_CHOICE_INPUT

:: ======================================
:: Generate SSH Key
:: ======================================
:GENERATE_KEY
set "SSH_DIR=%USERPROFILE%\.ssh"
if not exist "%SSH_DIR%" mkdir "%SSH_DIR%"

set "KEY_PRIV=%SSH_DIR%\id_%KEY_TYPE%"
set "KEY_PUB=%SSH_DIR%\id_%KEY_TYPE%.pub"

if exist "%KEY_PRIV%" (
    echo [WARNING] Key sudah ada di %KEY_PRIV%.
    
    :GET_OVERWRITE_INPUT
    set "OVERWRITE="
    set /p "OVERWRITE=Hapus dan buat baru? (y/n) [default: n]: "
    if /i "%OVERWRITE%"=="y" (
        del "%KEY_PRIV%" >nul 2>&1
        del "%KEY_PUB%" >nul 2>&1
    ) else (
        goto GENERATE_KEY_MENU
    )
)

echo [INFO] Membuat SSH key baru tipe %KEY_TYPE%...
if "%KEY_BITS%"=="" (
    ssh-keygen -t %KEY_TYPE% -f "%KEY_PRIV%" -N ""
) else (
    ssh-keygen -t %KEY_TYPE% -b %KEY_BITS% -f "%KEY_PRIV%" -N ""
)

if errorlevel 1 (
    echo [ERROR] Gagal membuat SSH key.
    pause
    goto GENERATE_KEY_MENU
)
echo [OK] SSH key berhasil dibuat di %KEY_PRIV%.
echo Public key: %KEY_PUB%
pause
goto GENERATE_KEY_MENU

:: ======================================
:: Test semua SSH key - Menu
:: ======================================
:TEST_ALL_KEYS_MENU
cls
echo =====================================
echo       Test Semua SSH Key
echo =====================================
echo 1. Masukkan server manual
echo 2. Pilih dari daftar koneksi sebelumnya
echo 0. Kembali ke Menu Utama
echo =====================================

:GET_TEST_MENU_INPUT
set "TEST_MENU_CHOICE="
set /p "TEST_MENU_CHOICE=Pilih opsi [0-2]: "

if "%TEST_MENU_CHOICE%"=="" (
    echo [ERROR] Harap masukkan pilihan
    goto GET_TEST_MENU_INPUT
)

echo %TEST_MENU_CHOICE%|findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Input harus angka!
    goto GET_TEST_MENU_INPUT
)

set /a TEST_MENU_CHOICE=%TEST_MENU_CHOICE% 2>nul
if %TEST_MENU_CHOICE% equ 0 goto MENU
if %TEST_MENU_CHOICE% equ 1 (
    call :INPUT_CREDENTIAL
    goto TEST_ALL_KEYS
)
if %TEST_MENU_CHOICE% equ 2 goto TEST_PREVIOUS_CONNECTION

echo [ERROR] Pilihan tidak valid!
goto GET_TEST_MENU_INPUT

:: ======================================
:: Test koneksi sebelumnya
:: ======================================
:TEST_PREVIOUS_CONNECTION
cls
echo =====================================
echo      Daftar koneksi untuk Test
echo =====================================
if not exist "%CONNECTION_FILE%" (
    echo [INFO] Belum ada koneksi tersimpan.
    pause
    goto TEST_ALL_KEYS_MENU
)

set /a INDEX=0
for /f "tokens=*" %%A in ('type "%CONNECTION_FILE%"') do (
    set /a INDEX+=1
    set "CONN[!INDEX!]=%%A"
    echo !INDEX!. %%A
)
echo 0. Kembali
echo =====================================

:GET_TEST_CONN_INPUT
set "CHOICE="
set /p "CHOICE=Pilih koneksi [1-!INDEX!] atau 0 untuk kembali: "

if "%CHOICE%"=="" (
    echo [ERROR] Harap masukkan pilihan
    goto GET_TEST_CONN_INPUT
)

echo %CHOICE%|findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Input harus angka!
    goto GET_TEST_CONN_INPUT
)

set /a IDX=%CHOICE% 2>nul
if %IDX% equ 0 goto TEST_ALL_KEYS_MENU
if %IDX% lss 1 (
    echo [ERROR] Nomor tidak valid!
    goto GET_TEST_CONN_INPUT
)
if %IDX% gtr %INDEX% (
    echo [ERROR] Nomor tidak tersedia!
    goto GET_TEST_CONN_INPUT
)

set "SELECTED_CONN=!CONN[%IDX%]!"
if not defined SELECTED_CONN (
    echo [ERROR] Koneksi tidak valid!
    goto GET_TEST_CONN_INPUT
)

:: Split koneksi yang dipilih
for /f "tokens=1,2 delims=@" %%u in ("%SELECTED_CONN%") do (
    set "SRV_USER=%%u"
    set "SRV_IP=%%v"
)
set "SRV_PORT=22"
echo.
echo Menggunakan koneksi: %SRV_USER%@%SRV_IP%

:GET_TEST_PORT_INPUT
set /p "SRV_PORT=Masukkan port SSH [default: 22]: "
if "%SRV_PORT%"=="" set "SRV_PORT=22"

:: Lanjut ke test semua key
goto TEST_ALL_KEYS

:: ======================================
:: Test semua SSH key
:: ======================================
:TEST_ALL_KEYS
cls
echo =====================================
echo       Test Semua SSH Key yang Ada
echo =====================================
echo Server: %SRV_USER%@%SRV_IP%:%SRV_PORT%
echo.

for %%k in (rsa ecdsa ed25519 dsa) do (
    set "KEY_FILE=%USERPROFILE%\.ssh\id_%%k"
    if exist "!KEY_FILE!" (
        echo [TEST] Mencoba koneksi dengan id_%%k...
        ssh -o "PreferredAuthentications publickey" -i "!KEY_FILE!" -p %SRV_PORT% %SRV_USER%@%SRV_IP% "echo 'Sukses terhubung dengan id_%%k'"
        if errorlevel 1 (
            echo [GAGAL] id_%%k tidak bekerja
        ) else (
            echo [SUKSES] id_%%k berfungsi dengan baik
        )
        echo.
    )
)
pause
goto TEST_ALL_KEYS_MENU

:: ======================================
:: Hapus SSH Key Lokal (Menu 3)
:: ======================================
:DELETE_LOCAL_KEY
cls
echo =====================================
echo      Hapus SSH Key Lokal
echo =====================================
echo [PERINGATAN] Ini akan menghapus semua SSH key di %USERPROFILE%\.ssh
echo 1. Backup semua key lalu hapus
echo 2. Hapus langsung tanpa backup
echo 0. Kembali ke Menu Utama
echo =====================================

:GET_DEL_CHOICE_INPUT
set "DEL_CHOICE="
set /p "DEL_CHOICE=Pilih opsi [0-2]: "

if "%DEL_CHOICE%"=="" (
    echo [ERROR] Harap masukkan pilihan
    goto GET_DEL_CHOICE_INPUT
)

echo %DEL_CHOICE%|findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Input harus angka!
    goto GET_DEL_CHOICE_INPUT
)

set /a DEL_CHOICE=%DEL_CHOICE% 2>nul
if %DEL_CHOICE% equ 0 goto MENU
if %DEL_CHOICE% equ 1 goto CHECK_AND_BACKUP
if %DEL_CHOICE% equ 2 goto DELETE_WITHOUT_BACKUP

echo [ERROR] Pilihan tidak valid!
goto GET_DEL_CHOICE_INPUT

:CHECK_AND_BACKUP
:: Cek apakah ada SSH key yang bisa dibackup
set "KEY_EXIST=0"
for %%k in (rsa ecdsa ed25519 dsa) do (
    if exist "%USERPROFILE%\.ssh\id_%%k" (
        set "KEY_EXIST=1"
    )
)

if %KEY_EXIST% equ 0 (
    echo [INFO] Tidak ada SSH key yang ditemukan untuk dibackup
    goto DELETE_WITHOUT_BACKUP
)

:: Buat timestamp yang reliable
for /f "tokens=2 delims==" %%G in ('wmic os get localdatetime /value') do set "datetime=%%G"
set "backup_date=%datetime:~6,2%-%datetime:~4,2%-%datetime:~0,4%"
set "backup_time=%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%"
set "BACKUP_DIR=%USERPROFILE%\.ssh\backup_keys\backup_%backup_date%_%backup_time%"

if not exist "%USERPROFILE%\.ssh\backup_keys\" mkdir "%USERPROFILE%\.ssh\backup_keys\"
mkdir "%BACKUP_DIR%"

:: Backup semua key
set "BACKUP_COUNT=0"
for %%k in (rsa ecdsa ed25519 dsa) do (
    if exist "%USERPROFILE%\.ssh\id_%%k" (
        copy "%USERPROFILE%\.ssh\id_%%k" "%BACKUP_DIR%\" >nul
        copy "%USERPROFILE%\.ssh\id_%%k.pub" "%BACKUP_DIR%\" >nul
        set /a BACKUP_COUNT+=1
    )
)

echo [SUKSES] %BACKUP_COUNT% key telah dibackup ke:
echo %BACKUP_DIR%
goto DELETE_WITHOUT_BACKUP

:DELETE_WITHOUT_BACKUP
set "SSH_DIR=%USERPROFILE%\.ssh"
if not exist "%SSH_DIR%" (
    echo [INFO] Direktori SSH tidak ditemukan.
    pause
    goto MENU
)

echo [INFO] Menghapus semua SSH key...
del "%SSH_DIR%\id_*" >nul 2>&1
del "%SSH_DIR%\id_*.pub" >nul 2>&1
echo [OK] Semua SSH key telah dihapus.
pause
goto MENU

:: ======================================
:: Hapus known_hosts (Menu 7)
:: ======================================
:DELETE_KNOWN_HOSTS
cls
echo =====================================
echo      Hapus known_hosts
echo =====================================
echo [PERINGATAN] Ini akan menghapus:
echo %USERPROFILE%\.ssh\known_hosts
echo %USERPROFILE%\.ssh\known_hosts.old
echo.
echo 1. Backup lalu hapus
echo 2. Hapus langsung tanpa backup
echo 0. Kembali ke Menu Utama
echo =====================================

:GET_KNOWN_HOSTS_CHOICE
set "KH_CHOICE="
set /p "KH_CHOICE=Pilih opsi [0-2]: "

if "%KH_CHOICE%"=="" (
    echo [ERROR] Harap masukkan pilihan
    goto GET_KNOWN_HOSTS_CHOICE
)

echo %KH_CHOICE%|findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Input harus angka!
    goto GET_KNOWN_HOSTS_CHOICE
)

set /a KH_CHOICE=%KH_CHOICE% 2>nul
if %KH_CHOICE% equ 0 goto MENU
if %KH_CHOICE% equ 1 goto BACKUP_KNOWN_HOSTS
if %KH_CHOICE% equ 2 goto DELETE_KNOWN_HOSTS_NOW

echo [ERROR] Pilihan tidak valid!
goto GET_KNOWN_HOSTS_CHOICE

:BACKUP_KNOWN_HOSTS
:: Buat timestamp untuk backup
for /f "tokens=2 delims==" %%G in ('wmic os get localdatetime /value') do set "datetime=%%G"
set "backup_date=%datetime:~6,2%-%datetime:~4,2%-%datetime:~0,4%"
set "backup_time=%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%"
set "BACKUP_DIR=%USERPROFILE%\.ssh\backup_known_hosts\backup_known_hosts_%backup_date%_%backup_time%"

:: Buat direktori backup jika belum ada
if not exist "%USERPROFILE%\.ssh\backup_known_hosts\" mkdir "%USERPROFILE%\.ssh\backup_known_hosts\"
mkdir "%BACKUP_DIR%"

:: Backup file known_hosts jika ada
set "BACKUP_COUNT=0"
if exist "%USERPROFILE%\.ssh\known_hosts" (
    copy "%USERPROFILE%\.ssh\known_hosts" "%BACKUP_DIR%\" >nul
    set /a BACKUP_COUNT+=1
)
if exist "%USERPROFILE%\.ssh\known_hosts.old" (
    copy "%USERPROFILE%\.ssh\known_hosts.old" "%BACKUP_DIR%\" >nul
    set /a BACKUP_COUNT+=1
)

if %BACKUP_COUNT% gtr 0 (
    echo [SUKSES] %BACKUP_COUNT% file known_hosts telah dibackup ke:
    echo %BACKUP_DIR%
) else (
    echo [INFO] Tidak ada file known_hosts yang ditemukan untuk dibackup
)

:DELETE_KNOWN_HOSTS_NOW
:: Hapus file known_hosts
set "DEL_COUNT=0"
if exist "%USERPROFILE%\.ssh\known_hosts" (
    del "%USERPROFILE%\.ssh\known_hosts" >nul 2>&1
    set /a DEL_COUNT+=1
)
if exist "%USERPROFILE%\.ssh\known_hosts.old" (
    del "%USERPROFILE%\.ssh\known_hosts.old" >nul 2>&1
    set /a DEL_COUNT+=1
)

if %DEL_COUNT% gtr 0 (
    echo [OK] %DEL_COUNT% file known_hosts telah dihapus
) else (
    echo [INFO] Tidak ada file known_hosts yang ditemukan
)
pause
goto MENU

:: ======================================
:: Keluar
:: ======================================
:EXIT
endlocal
exit /b 0