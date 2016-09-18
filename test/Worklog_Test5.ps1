<#
    ManualTestCase
#>
$TestCase = "Worklog_Test4.ps1"
Write-Host "Testcase: $TestCase" -ForegroundColor Yellow

$TestDir = $PSScriptRoot

$ProjDir = Split-Path -Path $TestDir -Parent


. $ProjDir\Load-Worklog.ps1


$WorklogFile = "$TestDir\test5-worklog.txt"
if(Test-Path $WorklogFile) {Remove-Item -Path $WorklogFile}

$SuccessCount = 0
try{
    Add-TimeWorklogItem -WorkType 'bad-worktype' -Project 'ID-PPF' -TicketID '' -Comment 'test21 - fail' -CustomWorklogFile $WorklogFile
} catch {
    $_
    $SuccessCount = $SuccessCount + 1
}
try{
    Add-TimeWorklogItem -WorkType 'meet' -Project 'bad-project' -TicketID '' -Comment 'test22 - fail' -CustomWorklogFile $WorklogFile
} catch {
    $_
    $SuccessCount = $SuccessCount + 1
}
try{
    Add-TimeWorklogItem -WorkType 'mgmt' -Project 'itshop' -TicketID 'bad-ticket' -Comment 'test23 - fail' -CustomWorklogFile $WorklogFile
} catch {
    $_
    $SuccessCount = $SuccessCount + 1
}

if($SuccessCount -eq 3) {
    Write-Host "$TestCase OK" -ForegroundColor Green
} else {
    Write-Host "$TestCase Failed" -ForegroundColor Red
}