param(
	$buildDirectory = $(throw "build results directory must be provided"),
	$testAssmPattern = "*Acceptance.Tests.dll" # replace with *.dll to test everything -- this is quite slow!
)
# Test against all the dlls we can find, report any failures.
#todo: configurable pattern for test assemblies?

$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$mspec = "$script_dir/bin/mspec-clr4.exe"
$results = "$buildDirectory\_PoshNUnit_Results.xml"
echo $results

$dlls = ls -Filter $testAssmPattern -Path $buildDirectory

if (Test-Path $results) { rm $results }

pushd $buildDirectory
& $mspec -s --xml=$results $dlls | out-null
popd

if (-not (Test-Path $results)) {
	Write-Host "No test results found" -fo yellow
	(Get-Host).UI.RawUI.WindowTitle = "No tests?"
	return
}

Write-Host "Reading results: " -NoNewline
## TODO: update this for MSpec output structure
$concerns = Select-Xml -Path "$results" -XPath '//concern' | %{ $_.Node }

$passed = 0
$failed = 0
$other = 0
$failure_paths = ""
$inconclusive_paths = ""

$concerns | %{
	$concern = $_.name
	$_.context | %{
		$context = $_.name
		$_.specification | %{
			$spec = $_.name
			if ($_.status -eq "passed") {$passed++}
			elseif ($_.status -eq "failed") {
				$failed++
				$failure_paths += "$context $concern, $spec`r`n" # the reversal of context and concern name seems to read more clearly.
			} else {
				$other++
				$inconclusive_paths += "$context $concern, $spec`r`n"
			}
		}
	}
}

(Get-Host).UI.RawUI.WindowTitle = "P$passed, I$other, F$failed"

Write-Host "$passed tests passed " -fo green -NoNewline
if ($other -gt 0) {Write-Host "$other inconclusive or ignored " -fo yellow -NoNewline}
if ($failed -gt 0) {Write-Host "$failed failed " -fo red -NoNewLine}
Write-Host ";"
Write-Host $failure_paths -fo red -NoNewline
Write-Host $inconclusive_paths -fo yellow -NoNewline
