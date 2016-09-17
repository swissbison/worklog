<#
    ManualTestCase
#>
$TestCase = "Worklog_Test3.ps1"
Write-Host "Testcase: $TestCase" -ForegroundColor Yellow

$TestDir = $PSScriptRoot

$ProjDir = Split-Path -Path $TestDir -Parent


. $ProjDir\Load-Worklog.ps1


$WorklogFile = "$TestDir\test3-worklog.txt"
if(Test-Path $WorklogFile) {Remove-Item -Path $WorklogFile}

Add-WorklogLine '02:00 code itsm this is a comment1' -CustomWorklogFile $WorklogFile
Add-WorklogLine '03:00 mgmt itshop this is a comment2' -CustomWorklogFile $WorklogFile
Add-WorklogLine '01:00 mgmt itshop OTRS#ID#1000001 this is a comment2' -CustomWorklogFile $WorklogFile
Add-WorklogLine 'mgmt itshop this is a comment2' -CustomWorklogFile $WorklogFile
Add-WorklogLine 'code itsm this is a comment1' -CustomWorklogFile $WorklogFile
Add-WorklogLine 'spec itsm KB#10002 this is a comment1' -CustomWorklogFile $WorklogFile
Add-WorklogLine 'off' -CustomWorklogFile $WorklogFile

$Lines = Get-Content $WorklogFile

$Lines

if($Lines.Count -eq 15) {
    Write-Host "$TestCase OK" -ForegroundColor Green
} else {
    Write-Host "$TestCase Failed" -ForegroundColor Red
}