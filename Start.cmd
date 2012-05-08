@echo off
powershell -NoProfile -ExecutionPolicy ByPass ".\Watcher.ps1 -watchPath 'C:\work' -triggerScript '.\ChangeTrigger.ps1' "

