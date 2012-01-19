param($changedFile = $(throw "change triggering file must be provided"))
# Given an input path, we hunt up the directory structure for a .sln file.
# With that, we trigger a build of the .sln into a temp directory, and then
# pass on to a test running script.
# As far as possible, this script should show nothing on the console.

$ms_build_versions = @(ls "${env:windir}\Microsoft.NET\Framework*\v4.*\MSBuild.exe")
$ms_build = $ms_build_versions[0] # update this with the version of .Net to use #todo: autodetect for each .sln

function CreateTempDir($slnFile) {
	$name = Split-Path -Leaf $slnFile
	$hash = $slnFile.GetHashCode().ToString("x") # help prevent collision with same named solutions.
	$tmp = [System.IO.Path]::Combine($env:Temp, "PoshNUnit\$name_$hash")
	if (-not (Test-Path $tmp)) { mkdir $tmp | out-null }
	$tmp
}

function BuildToDirectory($slnFile, $targetDirectory) {
	& $ms_build "$slnFile" /p:OutDir="$targetDirectory\" | out-null
	if ($LASTEXITCODE -ne 0) {
		Write-Host "Build FAILED" -fo red
		exit 1
	} else {
		Write-Host "Build OK" -fo green
	}
}

function FindNearestSolution($src) {
	try {
		$matchCount = 0
		$trace = $src
		while ($matchCount -eq 0) {
			$trace = Split-Path -parent $trace
			if (-not (Test-Path $trace)) {continue}
			$match= ls -Filter "*.sln" -Path $trace
			$matchCount = ($match| Measure-Object).Count
		}
		if ($matchCount -gt 1) {throw "More than one solution at $trace"}
	} catch {
		Write-Host "Could not find a solution to build" -fo red
		return
	}
	"$trace\$match"
}

$sln = FindNearestSolution($changedFile)
if (!$sln) {return}
$output = CreateTempDir($sln)

BuildToDirectory -slnFile $sln -targetDirectory $output

return $output

