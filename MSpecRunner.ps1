param(
	$buildDirectory = $(throw "build results directory must be provided"),
	$testAssmPattern = "*Behaviours.dll" # replace with *.dll to test everything -- this is quite slow!
)
# Test against all the dlls we can find, report any failures.
#todo: configurable pattern for test assemblies?

$script_dir = Split-Path -parent $MyInvocation.MyCommand.Definition
$mspec = "$script_dir/bin/mspec-clr4.exe"
$results = "$buildDirectory\_PoshNUnit_Results.xml"

$dlls = ls -Filter $testAssmPattern -Path $buildDirectory

if (Test-Path $results) { rm $results }

pushd $buildDirectory
& $mspec -s --xml=$results $dlls | out-null
popd

if (-not (Test-Path $results)) {
	Write-Host "No test results found" -fo yellow
	return
}

Write-Host "Reading results: " -NoNewline
## TODO: update this for MSpec output structure
$tests = Select-Xml -Path "$results" -Xpath '//test-case' | %{ $_.Node }
$passed = 0
$failed = 0
$other = 0
$tests | %{
	if ($_.success -eq "True") {$passed++}
	elseif ($_.success -eq "False") {$failed++}
	else {$other++}
}
Write-Host "$passed tests passed " -fo green -NoNewline
if ($other -gt 0) {Write-Host "$other inconclusive or ignored " -fo yellow -NoNewline}
if ($failed -gt 0) {Write-Host "$failed failed " -fo red -NoNewLine}
Write-Host ";"
$tests | %{ if ($_.success -eq "False") {
	Write-Host $_.name -fo red
}}

