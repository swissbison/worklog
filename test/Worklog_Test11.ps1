<#
    ManualTestCase
#>
$TestCase = "Worklog_Test11.ps1"
Write-Host "Testcase: $TestCase" -ForegroundColor Yellow

$TestDir = $PSScriptRoot

$ProjDir = Split-Path -Path $TestDir -Parent

. $ProjDir\Load-Worklog.ps1

$WorklogFile = "$TestDir\test11-worklog-initial.txt"

Write-Host "Scenario: Date report" -ForegroundColor Yellow
Show-WorklogReport -GroupingProperty Date -CustomWorklogFile $WorklogFile

Write-Host "Scenario: WorkType report" -ForegroundColor Yellow
Show-WorklogReport -GroupingProperty WorkType -CustomWorklogFile $WorklogFile

Write-Host "Scenario: Project report" -ForegroundColor Yellow
Show-WorklogReport -GroupingProperty Project -CustomWorklogFile $WorklogFile