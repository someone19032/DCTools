@echo off
chcp 65001 >nul
title DCTools - By kao_someone on DC
:start
title DCTools - By kao_someone on DC
cls
call :banner

:banner
for /f %%A in ('"prompt $H &echo on &for %%B in (1) do rem"') do set BS=%%A
set "spaces=          "
echo.
echo.
echo [34m                                             ╔╦╗╦╔═╗╔═╗╔═╗╦═╗╔╦╗
echo [38;5;33m                                              ║║║╚═╗║  ║ ║╠╦╝ ║║
echo [34m                                              ╩╝╩╚═╝╚═╝╚═╝╩╚══╩╝
echo [34m                                               ╔╦╗╔═╗╔═╗╦  ╔═╗
echo [38;5;33m                                                ║ ║ ║║ ║║  ╚═╗
echo [34m                                                ╩ ╚═╝╚═╝╩═╝╚═╝
echo.
echo.
echo           ╔═══(1) Webhook
echo           ╠═══(2) ID Checker
echo           ╠═══(3) Create Webhook (With Bot)
echo           ╠═══(4) Bot Controller
echo           ╚╗
echo            ╠══(5) Quit
set /p input=.%BS%%spaces% ╚══════^>

if /I %input% EQU 1 goto :webhook
if /I %input% EQU 3 goto :webhook2
if /I %input% EQU 4 goto :botcontrol
if /I %input% EQU 5 exit
if /I %input% EQU 2 echo Sorry this isnt done yet&pause&goto :start

:webhook2
cls
setlocal enabledelayedexpansion

:: Prompt for bot token, server ID, and channel ID
set /p bot_token="Enter your bot token: "
set /p server_id="Enter your server ID: "
set /p channel_id="Enter your channel ID: "

:: Define the API URL for creating a webhook
set url=https://discord.com/api/v10/channels/%channel_id%/webhooks

:: Define the webhook creation payload (you can customize the name and avatar)
:: Ensure that the JSON is properly escaped
set payload={\"name\": \"MyWebhook\", \"avatar\": \"\"}

:: Send the POST request to create the webhook
echo Creating webhook...
curl -X POST %url% ^
     -H "Authorization: Bot %bot_token%" ^
     -H "Content-Type: application/json" ^
     -d "%payload%"

echo Webhook created successfully!
pause
goto :start

:webhook
title Webhook Menu
cls
setlocal enabledelayedexpansion

:spam
:: Prompt for Webhook URL
echo Enter the Discord Webhook URL:
set /p webhook=

:: Prompt for Custom Username (optional)
echo Enter a custom username (Leave blank for default):
set /p username=

:: Prompt for Custom Avatar URL (optional)
echo Enter a custom avatar URL (Leave blank for default):
set /p avatar_url=

:: Prompt for Message Content
echo Enter the message to send (Supports Markdown):
set /p message=

:: Initialize JSON Payload
set json_payload={

:: Add content (the main message)
set json_payload=!json_payload!"content":"%message%"

:: Add username if specified
if not "%username%"=="" set json_payload=!json_payload!,"username":"%username%"

:: Add avatar URL if specified
if not "%avatar_url%"=="" set json_payload=!json_payload!,"avatar_url":"%avatar_url%"

:: Close the JSON payload
set json_payload=!json_payload!}

:: Show the full payload (optional, for debugging)
echo JSON Payload:
echo !json_payload!

:: Escape the JSON string for curl by replacing spaces and quotes
set "escaped_json=!json_payload:"=\"!"

:: Send the message using curl
echo Sending message...
curl -X POST -H "Content-Type: application/json" -d "!escaped_json!" "%webhook%"

:: Confirm the message has been sent
echo Message sent to webhook.

:: Ask if the user wants to spam
echo Do you want to spam the webhook (yes/no)?
set /p spam_choice=

if /i "%spam_choice%"=="no"  goto :start
if /i "%spam_choice%"=="yes" goto :startspam
    :startspam
    echo Enter the time to stop spamming (in seconds):
    set /p stop_time=

    :: Get current system time in seconds since start of day
    for /f "tokens=1-4 delims=:." %%a in ("%time%") do (
        set /a start_time=%%a*3600 + %%b*60 + %%c
    )

    :: Convert user input time to seconds
    set /a stop_time_seconds=%stop_time%

    :: Start spamming every 0.5 seconds
    set /a counter=0

    :spam_loop
    curl -X POST -H "Content-Type: application/json" -d "!escaped_json!" "%webhook%"
    echo Spam message sent. Spam count: !counter!
    set /a counter+=1
    timeout /t 0.5 >nul

    :: Calculate current system time in seconds since start of day
    for /f "tokens=1-4 delims=:." %%a in ("%time%") do (
        set /a current_time=%%a*3600 + %%b*60 + %%c
    )

    :: Calculate elapsed time in seconds
    set /a elapsed_time=%current_time% - %start_time%

    if %elapsed_time% lss %stop_time_seconds% goto spam_loop

    echo Spam stopped after !counter! messages.
)

:: Ask the user if they want to continue spamming
echo Do you want to continue spamming? (yes/no)
set /p continue_spam_choice=

if /i "%continue_spam_choice%"=="yes" goto :spam
if /i "%continue_spam_choice%"=="no" goto :start

:: In case of invalid input, return to the start
goto :start


:botcontrol
cd /d %~dp0

cls
echo ==========================
echo     DISCORD BOT MENU
echo ==========================
echo 1. Enter bot token
echo 2. Enter client ID
echo 3. Generate invite link
echo 4. Run the bot
echo 5. Exit
echo ==========================
set /p choice=Choose an option (1-5): 

if "%choice%"=="1" goto set_token
if "%choice%"=="2" goto set_clientid
if "%choice%"=="3" goto invite
if "%choice%"=="4" goto runbot
if "%choice%"=="5" goto exit
goto main

:set_token
set /p TOKEN=Enter bot token: 
echo DISCORD_BOT_TOKEN=%TOKEN% > .env
echo Token saved to .env!
pause
goto main

:set_clientid
set /p CLIENTID=Enter client ID: 
echo %CLIENTID% > .clientid
echo Client ID saved!
pause
goto main

:invite
if not exist .clientid (
    echo No client ID found. Please set it first.
    pause
    goto main
)
set /p PERMS=Enter permission integer (default 0): 
if "%PERMS%"=="" set PERMS=0
set /p CLIENTID=<.clientid
set LINK=https://discord.com/oauth2/authorize?client_id=%CLIENTID%&scope=bot&permissions=%PERMS%
echo Invite link:
echo %LINK%
start "" "%LINK%"
pause
goto main

:runbot
if not exist .env (
    echo .env not found. Please set bot token first.
    pause
    goto main
)
echo Launching bot...
python bot.py
echo Bot exited.
pause
goto :start

:end
pause
