<#
    ManualTestCase
#>
$TestCase = "Worklog_Test10.ps1"
Write-Host "Testcase: $TestCase" -ForegroundColor Yellow

$TestDir = $PSScriptRoot

$ProjDir = Split-Path -Path $TestDir -Parent

. $ProjDir\Load-Worklog.ps1

$WorklogFile = "$TestDir\test2-worklog-initial.txt"

$Lines = Show-WorklogReport -GroupingProperty Date -CustomWorklogFile $WorklogFile

$Lines

if($Lines.Count -eq 11) {
    Write-Host "$TestCase OK" -ForegroundColor Green
} else {
    Write-Host "$TestCase Failed" -ForegroundColor Red
}