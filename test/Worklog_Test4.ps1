﻿<#
    ManualTestCase
#>
$TestCase = "Worklog_Test4.ps1"
Write-Host "Testcase: $TestCase" -ForegroundColor Yellow

$TestDir = $PSScriptRoot

$ProjDir = Split-Path -Path $TestDir -Parent


. $ProjDir\Load-Worklog.ps1


$WorklogFile = "$TestDir\test4-worklog.txt"
if(Test-Path $WorklogFile) {Remove-Item -Path $WorklogFile}
Copy-Item -Path "$TestDir\test4-worklog-initial.txt" -Destination $WorklogFile

Add-TimeWorklogItem -WorkType 'admin' -Project 'ID-PPF' -TicketID '' -Comment 'test1 - ok' -CustomWorklogFile $WorklogFile
Add-TimeWorklogItem -WorkType 'meet' -Project 'ID-PPF' -TicketID '' -Comment 'test2 - ok' -CustomWorklogFile $WorklogFile
Add-TimeWorklogItem -WorkType 'mgmt' -Project 'itshop' -TicketID 'OTRS#ID#16000123' -Comment 'test3 - ok' -CustomWorklogFile $WorklogFile
Add-OffWorklogItem
Add-TimeWorklogItem -WorkType 'educ' -Project 'ID-PPF' -TicketID '' -Comment 'test4 - ok' -CustomWorklogFile $WorklogFile
Add-TimeWorklogItem -WorkType 'arch' -Project 'itsm' -TicketID '' -Comment 'test5 - ok' -CustomWorklogFile $WorklogFile
Add-TimeWorklogItem -WorkType 'spec' -Project 'itsm' -TicketID 'KB#ID#1001' -Comment 'test6 - ok' -CustomWorklogFile $WorklogFile
Add-TimeWorklogItem -WorkType 'code' -Project 'itsm' -TicketID '' -Comment 'test7 - ok' -CustomWorklogFile $WorklogFile
Add-TimeWorklogItem -WorkType 'test' -Project 'itsm' -TicketID '' -Comment 'test8 - ok' -CustomWorklogFile $WorklogFile
Add-TimeWorklogItem -WorkType 'docu' -Project 'STO' -TicketID '' -Comment 'test9 - ok' -CustomWorklogFile $WorklogFile
Add-OffWorklogItem

Add-DurationWorklogItem -DurationTime '01:30' -WorkType 'admin' -Project 'ID-PPF' -TicketID '' -Comment 'test11' -CustomWorklogFile $WorklogFile
Add-DurationWorklogItem -DurationTime '01:30' -WorkType 'meet' -Project 'ID-PPF' -TicketID '' -Comment 'test12 - ok' -CustomWorklogFile $WorklogFile
Add-DurationWorklogItem -DurationTime '01:30' -WorkType 'mgmt' -Project 'itshop' -TicketID 'OTRS#ID#16000123' -Comment 'test13 - ok' -CustomWorklogFile $WorklogFile
Add-DurationWorklogItem -DurationTime '01:30' -WorkType 'educ' -Project 'ID-PPF' -TicketID '' -Comment 'test14 - ok' -CustomWorklogFile $WorklogFile
Add-DurationWorklogItem -DurationTime '01:30' -WorkType 'arch' -Project 'itsm' -TicketID '' -Comment 'test15 - ok' -CustomWorklogFile $WorklogFile
Add-DurationWorklogItem -DurationTime '01:30' -WorkType 'spec' -Project 'itsm' -TicketID 'KB#ID#1001' -Comment 'test16 - ok' -CustomWorklogFile $WorklogFile
Add-DurationWorklogItem -DurationTime '01:30' -WorkType 'code' -Project 'itsm' -TicketID '' -Comment 'test17 - ok' -CustomWorklogFile $WorklogFile
Add-DurationWorklogItem -DurationTime '01:30' -WorkType 'test' -Project 'itsm' -TicketID '' -Comment 'test18 - ok' -CustomWorklogFile $WorklogFile
Add-DurationWorklogItem -DurationTime '01:30' -WorkType 'docu' -Project 'STO' -TicketID '' -Comment 'test19 - ok' -CustomWorklogFile $WorklogFile

$Lines = Show-WorklogReport -GroupingProperty Date -CustomWorklogFile $WorklogFile

$Lines

if($Lines.Count -gt 0) {
    Write-Host "$TestCase OK" -ForegroundColor Green
} else {
    Write-Host "$TestCase Failed" -ForegroundColor Red
}