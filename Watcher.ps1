param($watchPath = $(throw "Watch path is required"), $triggerScript = $(throw "Trigger script is required"))
# watch a file changes in the current directory, 
# execute all tests when a file is changed or renamed

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchPath
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $false
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName

$watch_filter = [System.IO.WatcherChangeTypes]::Changed -bor [System.IO.WatcherChangeTypes]::Renamed -bOr [System.IO.WatcherChangeTypes]::Created -bOr [System.IO.WatcherChangeTypes]::Deleted

(Get-Host).UI.RawUI.WindowTitle = "Watching $watchPath"
Write-Host "Watching $watchPath for changes. Press [ctrl]-C to exit"

$ignore = (".svn", ".suo", ".user", "_resharper", ".cache", "\bin\", "\obj\") #todo: push out to a config file


while($true){
	$result = $watcher.WaitForChanged($watch_filter, 1000);
	if($result.TimedOut){
		continue;
	}

	$ignore | ?{ $result.Name.ToLower().Contains($_) } | %{continue}

	Clear-Host
	$time = [System.DateTime]::Now
	Write-Host "$time -- Change in $($result.Name)"
	(Get-Host).UI.RawUI.WindowTitle = "Working..."

	& $triggerScript "$watchPath\$($result.Name)"

	$time = [System.DateTime]::Now
	Write-Host "$time -- Continuing to watch $watchPath. Press [ctrl]-C to exit"
}

