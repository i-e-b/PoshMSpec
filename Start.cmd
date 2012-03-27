@echo off
powershell -NoProfile -ExecutionPolicy ByPass ".\Watcher.ps1 -watchPath 'C:\Gits' -triggerScript '.\ChangeTrigger.ps1' "

