<#
    ManualTestCase
#>
$TestCase = "Worklog_Test1.ps1"
Write-Host "Testcase: $TestCase" -ForegroundColor Yellow

$TestDir = $PSScriptRoot

$ProjDir = Split-Path -Path $TestDir -Parent


. $ProjDir\Load-Worklog.ps1

$WorklogFile = "$TestDir\test1-worklog.txt"
if(Test-Path $WorklogFile) {Remove-Item -Path $WorklogFile}

Add-TimeWorklogItem -WorkType admin -Project itsm -TicketID '' -Comment 'comment' -CustomWorklogFile $WorklogFile
Add-OffWorklogItem -CustomWorklogFile $WorklogFile

$Lines = Get-Content $WorklogFile

$Lines

if($Lines.Count -eq 10) {
    Write-Host "$TestCase OK" -ForegroundColor Green
} else {
    Write-Host "$TestCase Failed" -ForegroundColor Red
}