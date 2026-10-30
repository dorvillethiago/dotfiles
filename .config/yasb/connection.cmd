@echo off
rem Prints the connection state as JSON for the YASB "connection" widget.
rem Pings 1.1.1.1 instead of trusting the network profile, which stays "up" behind VPN adapters.
rem The JSON escapes are the Nerd Font md-earth / md-earth_off glyphs, kept ASCII for cmd.
"%SystemRoot%\System32\PING.EXE" -n 1 -w 1500 1.1.1.1 | "%SystemRoot%\System32\find.exe" "TTL=" >nul
if errorlevel 1 (
    echo {"icon": "\udb80\udde8", "status": "Offline"}
) else (
    echo {"icon": "\udb80\udde7", "status": "Connected"}
)
