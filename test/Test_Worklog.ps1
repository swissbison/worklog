<#
    Worklog_Tests.ps1
#>

$WorkingDir = $PSScriptRoot

. $WorkingDir\Worklog.ps1

$WorklogFile = "$WorkingDir\test1-worklog.txt"
if(Test-Path $WorklogFile) {Remove-Item -Path $WorklogFile}

Add-TimeWorklogItem -WorkType admin -Project itsm -TicketID '' -Comment 'comment' -CustomWorklogFile $WorklogFile
Add-OffWorklogItem -CustomWorklogFile $WorklogFile

"--> Begin of $WorklogFile"
Get-Content $WorklogFile
"<-- End of $WorklogFile"

$WorklogFile = "$WorkingDir\test2-worklog.txt"

Add-TimeWorklogItem -WorkType admin -Project itsm -TicketID '' -Comment 'comment' -CustomWorklogFile $WorklogFile
Add-OffWorklogItem -CustomWorklogFile $WorklogFile
"--> Begin of $WorklogFile"
Get-Content $WorklogFile
"<-- End of $WorklogFile"

$WorklogFile = "$WorkingDir\test3-worklog.txt"
if(Test-Path $WorklogFile) {Remove-Item -Path $WorklogFile}
Add-WorklogLine '02:00 code itsm this is a comment1' -CustomWorklogFile $WorklogFile
Add-WorklogLine '03:00 mgmt itshop this is a comment2' -CustomWorklogFile $WorklogFile
Add-WorklogLine '01:00 mgmt itshop OTRS#ID#1000001 this is a comment2' -CustomWorklogFile $WorklogFile
Add-WorklogLine 'mgmt itshop this is a comment2' -CustomWorklogFile $WorklogFile
Add-WorklogLine 'code itsm this is a comment1' -CustomWorklogFile $WorklogFile
Add-WorklogLine 'spec itsm KB#10002 this is a comment1' -CustomWorklogFile $WorklogFile
Add-WorklogLine 'off' -CustomWorklogFile $WorklogFile
"--> Begin of $WorklogFile"
Get-Content $WorklogFile
"<-- End of $WorklogFile"

<#

$WorklogLines = ReadWorklogFile -WorklogFile $WorklogFile

"--0--"
$WorklogItems = $WorklogLines | % {ConvertWorklogLine -WorklogLine $_}
$WorklogItems |  % { Write-WorklogItem -WorklogItem $_ }
"--0--"

"--1--"
$ArrayOfDateGroupedItems = GroupWorklogItems -GroupingProperty Date -WorklogItems $WorklogItems
foreach($GroupedItems in $ArrayOfDateGroupedItems) {
    Write-GroupedWorklogItems -GroupedWorklogItems $GroupedItems
}
"--1--"

"--2--"
$ArrayOfNormalizedItems = ConvertDurationIntoTimeWorklogItems -WorklogItems $WorklogItems
$ArrayOfNormalizedItems |  % { Write-WorklogItem -WorklogItem $_ }
"--2--"

"--3--"
$ArrayOfDateGroupedItems = GroupWorklogItems -GroupingProperty Date -WorklogItems $ArrayOfNormalizedItems
Write-ArrayOfGroupedWorklogItems -ArrayOfGroupedWorklogItems $ArrayOfDateGroupedItems
"--3--"

"--4--"
$ArrayOfWorkTypeGroupedItems = GroupWorklogItems -GroupingProperty WorkType -WorklogItems $ArrayOfNormalizedItems
Write-ArrayOfGroupedWorklogItems -ArrayOfGroupedWorklogItems $ArrayOfWorkTypeGroupedItems
"--4--"

"--5--"
$ArrayOfProjectGroupedItems = GroupWorklogItems -GroupingProperty Project -WorklogItems $ArrayOfNormalizedItems
Write-ArrayOfGroupedWorklogItems -ArrayOfGroupedWorklogItems $ArrayOfProjectGroupedItems
"--5--"

"--6--"
$ArrayOfTicketIDGroupedItems = GroupWorklogItems -GroupingProperty TicketID -WorklogItems $ArrayOfNormalizedItems
Write-ArrayOfGroupedWorklogItems -ArrayOfGroupedWorklogItems $ArrayOfTicketIDGroupedItems
"--6--"

"--7--"
$ArrayOfTotaledDateGroupedItems = GroupAndSumUpWorklogItems -GroupingProperty Date -WorklogItems $ArrayOfNormalizedItems
Write-ArrayOfGroupedWorklogItems -ArrayOfGroupedWorklogItems $ArrayOfTotaledDateGroupedItems
"--7--"

"--8--"
$ArrayOfTotaledProjectGroupedItems = GroupAndSumUpWorklogItems -GroupingProperty Project -WorklogItems $ArrayOfNormalizedItems
Write-ArrayOfGroupedWorklogItems -ArrayOfGroupedWorklogItems $ArrayOfTotaledProjectGroupedItems
"--8--"

"--9--"
$ArrayOfTotaledTicketIDGroupedItems = GroupAndSumUpWorklogItems -GroupingProperty TicketID -WorklogItems $ArrayOfNormalizedItems
Write-ArrayOfGroupedWorklogItems -ArrayOfGroupedWorklogItems $ArrayOfTotaledTicketIDGroupedItems
"--9--"

#>