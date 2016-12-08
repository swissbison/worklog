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

Add-TimeWorklogItem -WorkType 'admin' -Project 'Proj1' -TicketID '' -Comment 'comment' -CustomWorklogFile $WorklogFile
Add-OffWorklogItem -CustomWorklogFile $WorklogFile

$Lines = Get-Content $WorklogFile

$Lines

if($Lines.Count -eq 10)
{
    Write-Host "$TestCase OK" -ForegroundColor Green
}
else
{
    Write-Host "$TestCase Failed" -ForegroundColor Red
}

$Result = Show-WorklogReport -GroupingProperty Date -CustomWorklogFile $WorklogFile -ReturnObject $True

$Result

if("$($Result.TotaledTime)" -eq '00:00:00' -and $Result.WorklogItems.WorkType -eq 'admin')
{
    Write-Host "Result of $TestCase OK" -ForegroundColor Green
}
else
{
    Write-Host "Result of $TestCase Failed" -ForegroundColor Red
}
