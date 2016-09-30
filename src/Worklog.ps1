<#
Worklog.ps1

Date       T/D Time   WorkType  Project   Ticket      Comment
2016/09/01 T   07:00  admin     IT Shop   OTRS#160987 answer question
2016/09/01 T   12:00  off
2016/09/01 T   12:00  code      ITSM      KB#ID102    work on powershell tools   
2016/09/01 T   18:00  off

2016/09/02 D   01:30  admin     ID-PPF-PM             groups meeting
2016/09/02 D   04:00  educ      ID-PPF-PM             learn about javascript
2016/09/02 D   03:30  code      ITSM      KB#ID102    work on powershell tools

Date     : yyyy/mm/dd
T_D      : T - Time / D - Duration
Time     : hh:mm
WorkType : type of work items, to be defined in worklog_params.ps1
Project  : project name, to be defined in worklog_params.ps1
Ticket   : optional, but used prefix defined in worklog_params.ps1
Comment  : optional free text

#>

$WorkingDirParam = $PSScriptRoot
$WorklogFileParam = "$WorkingDirParam\worklog.txt"

$WorklogTypeOff = 'off'
$WorklogWorkType = @(
 	"$WorklogTypeOff",
	'admin',
    'meet',
    'mgmt',
   	'educ',
	'arch',
	'spec',
	'code',
	'arch',
	'docu',
	'educ',
    'test'
)

$WorklogProject = @(
	'ID-PPF',
	'ITSM',
	'ITShop',
    'STO'
)

$WorklogTicketNo = 'n.a.'
$WorklogTicketPrefix = @(
    'n.a.',
	'OTRS#',
	'KB#'
)

function Script:GetWorklogDayHeader {
    $CurrentDate = date
    $WorklogDayHeaderTemplate = "### {0} {1:yyyy}/{1:MM}/{1:dd} ###"
    $WorklogDayHeader = $WorklogDayHeaderTemplate -f $CurrentDate.DayOfWeek,$CurrentDate
    $WorklogDayHeader
}

function Script:GetCurrentDateAsString {
    $CurrentDate = date
    $Date = "{0:yyyy}/{0:MM}/{0:dd}" -f $CurrentDate.Date
    $Date
}

function Script:GetCurrentTimeAsString {
    $CurrentDate = date
    $Time = "{0:HH}:{0:mm}" -f $CurrentDate
    $Time
}

function Script:ReadWorklogFile {
    Param(
        $WorklogFile
    )
    $Lines = Get-Content $WorklogFile
    $CleanedLines = $Lines | % {$_.Trim()} | ? {$_ -notlike '#*' -and $_ -notlike ''}
    $CleanedLines
}

function Script:IsTicketIDValid {
    Param(
        $PotentialTicketID
    )
    $WorklogTicketPrefix | ? {$PotentialTicketID -like "$_*"}
}

function Script:IsTimeValid {
    Param(
        $PotentialTime
    )
    $RegEx = '(\d{2}:\d{2})'
    if($PotentialTime -match $RegEx) {
        $IsValid = $True
    } else {
        $IsValid = $False
    }
    $IsValid
}

function Script:IsDurationTime {
    Param(
        $PotentialTime
    )
	$RegExDuration = '([dD]\d{2}:\d{2})'
    if($PotentialTime -match $RegExDuration) {
        $IsDuration = $True
    } else {
        $IsDuration = $False
    } 
    $IsDuration
}

function Script:GetComment {
    Param(
        $ArrayOfToken,
        $BeginIndex
    )
    for($i = $BeginIndex; $i -lt $ArrayOfToken.Count; $i++) {
        if($Comment -eq $Null) {
            $Comment = $ArrayOfToken[$i]
        } else {
            $Comment = $Comment + ' ' + $ArrayOfToken[$i]
        }
    }
    $Comment
}

function Script:ValidateWorklogItem {
    Param(
        $WorklogItem
    )
    $WorkType = $WorklogItem.WorkType
    ValidateGroupingProperty -GroupingProperty WorkType -PropertyValue $WorkType
    if($WorkType -ne 'off') {
        ValidateGroupingProperty -GroupingProperty Project -PropertyValue $Project
        $TicketID = $WorklogItem.TicketID
        if($TicketID) {
            ValidateGroupingProperty -GroupingProperty TicketID -PropertyValue $TicketID
        }
    }
}

function Script:GetWorklogFileHeader {
    Param(
        $WorklogFile
    )
    $DateAndTime = (GetCurrentDateAsString) + " - " + (GetCurrentTimeAsString)
    $WorklogFileHeader = @"
# worklog © 2016 by Paul Signer
#
# This file '$WorklogFile' was created by
# worklog r0.1 (build r0.1 2016-09-05)
# $DateAndTime
# 
"@
    $WorklogFileHeader
}

function Script:ConvertWorklogLine {
    Param(
        $WorklogLine
    )
    $ArrayOfToken = $WorklogLine.Split(' ')

    $Date = $ArrayOfToken[0]
    $T_D = $ArrayOfToken[1]
    $Time = $ArrayOfToken[2]
    $WorkType = $ArrayOfToken[3]
    if($WorkType -eq $WorklogTypeOff) {
        $Project = ''
        $TicketID = ''
        $Comment = ''
    } else {
        $Project = $ArrayOfToken[4]
        if(IsTicketIDValid -PotentialTicketID $ArrayOfToken[5]) {
            $TicketID = $ArrayOfToken[5]
            $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 6
        } else {
            $TicketID = $WorklogTicketNo
            $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 5
        }
    }

    $WorklogLineAsHashtable = @{
        Date=$Date;
        T_D=$T_D;
        Time=$Time;
        WorkType=$WorkType;
        Project=$Project;
        TicketID=$TicketID;
        Comment=$Comment
    }

    try {
        ValidateWorklogItem -WorklogItem $WorklogLineAsHashtable
    } catch {
        $Message = "$($_.ErrorMessage)" + $(Write-WorklogItem -WorklogItem $WorklogLineAsHashtable)
        Write-Host $Message -ForegroundColor Red
    }

    $WorklogLineAsHashtable
}

function Script:GroupWorklogItems {
    Param(
        [ValidateSet('Date','WorkType','Project','TicketID')]
        $GroupingProperty,
        $WorklogItems
    )

    $ArrayOfProperties = $WorklogItems.$GroupingProperty
    $ArrayOfUniqueProperties = $ArrayOfProperties | Sort-Object | Get-Unique
 
    $ArrayOfGroupedWorklogItems = @();
    foreach($Prop in $ArrayOfUniqueProperties) {
        $SelectedItems = $WorklogItems | ? { $_.$GroupingProperty -eq $Prop }

        $GroupedWorklogItems = @{
            GroupingProperty = $Prop;
            WorklogItems = $SelectedItems
        }
        $ArrayOfGroupedWorklogItems += $GroupedWorklogItems
    }
    $ArrayOfGroupedWorklogItems
}

function Script:Write-WorklogItem {
    Param(
        $WorklogItem
    )
    $ItemTemplate = "{0,10} {1,1} {2,5} {3,-5} {4,-10} {5,-15} {6}"
    $ItemTemplate -f $WorklogItem.Date,$WorklogItem.T_D,$WorklogItem.Time,$WorklogItem.WorkType,$WorklogItem.Project,$WorklogItem.TicketID,$WorklogItem.Comment
}

function Script:Write-GroupedWorklogItems {
    Param(
        $GroupedWorklogItems
    )
    $gwi = $GroupedWorklogItems

    $TotaledHours = 0
    $Minutes = 0
    if($gwi.TotaledTime) {
        $Days = $gwi.TotaledTime.Days
        $Hours = $gwi.TotaledTime.Hours
        $Minutes = $gwi.TotaledTime.Minutes
        if($Days -gt 0) {
            $HoursAsString = $Days * 24 + $Hours
        } else {
            $HoursAsString = ("{0:hh}" -f $gwi.TotaledTime)
        }
        $MinutesAsString = ("{0:mm}" -f $gwi.TotaledTime)

        "{0,-10} TotaledTime: {1}:{2}" -f $gwi.GroupingProperty,$HoursAsString,$MinutesAsString
    } else {
        "{0,-10}" -f $gwi.GroupingProperty
    }
    $ItemTemplate = "           {0,1} {1,5} {2,-5} {3,-10} {4,-15} {5}"
    $gwi.WorklogItems | % {$ItemTemplate -f $_.T_D,$_.Time,$_.WorkType,$_.Project,$_.TicketID,$_.Comment}
}

function Script:Write-ArrayOfGroupedWorklogItems {
    Param(
        $ArrayOfGroupedWorklogItems
    )
    foreach($GroupedItems in $ArrayOfGroupedWorklogItems) {
        Write-GroupedWorklogItems -GroupedWorklogItems $GroupedItems
    }
}

function Script:ConvertDurationIntoTimeWorklogItems {
    Param(
        $WorklogItems
    )
    $ArrayOfDateGroupedItems = GroupWorklogItems -GroupingProperty Date -WorklogItems $WorklogItems

    $ArrayOfOnlyTimeItems = @()

    foreach($GroupedItems in $ArrayOfDateGroupedItems) {
        $WorklogItems_ = $GroupedItems.WorklogItems
        if($WorklogItems_ -and $WorklogItems_.getType().Name -eq @().getType().Name) {
            $ItemCount = $WorklogItems_.Count
            for($i=0;$i -lt $ItemCount; $i++) {
                if($WorklogItems_[$i].T_D -eq 'T') {
                    if(($WorklogItems_[$i].WorkType) -ne 'off') {
                        $TimeItem = ConvertTimeIntoDurationItem -StartItem $WorklogItems_[$i] -EndItem $WorklogItems_[$i+1]
                        $ArrayOfOnlyTimeItems += $TimeItem
                    }
                } else { #$DurationItem[i$].T_D -eq 'T'
                    $ArrayOfOnlyTimeItems += $WorklogItems_[$i]
                }
            }
        } else { 
            if($WorklogItems_.T_D -eq 'T') {
                Write-Error "Single WorklogItem with T_D=T not valid: $WorklogItems_"
            } else { #$DurationItem[i$].T_D -eq 'T'
                $ArrayOfOnlyTimeItems += $WorklogItems_
            }
        }
    }
    $ArrayOfOnlyTimeItems
}

function Script:ConvertTimeIntoDurationItem {
    Param(
        $StartItem,
        $EndItem
    )
    $StartTime = New-TimeSpan -Hours $StartItem.Time.Split(':')[0] -Minutes $StartItem.Time.Split(':')[1]
    $EndTime = New-TimeSpan -Hours $EndItem.Time.Split(':')[0] -Minutes $EndItem.Time.Split(':')[1]

    $Time = "{0:hh}:{0:mm}" -f ($EndTime - $StartTime)

    $TimeItem = @{
        Date=$StartItem.Date;
        T_D='D';
        Time=$Time
        WorkType=$StartItem.WorkType;
        Project=$StartItem.Project;
        TicketID=$StartItem.TicketID;
        Comment=$StartItem.Comment
    }
    $TimeItem
}

function Script:GroupAndSumUpWorklogItems {
    Param(
        [ValidateSet('Date','WorkType','Project','TicketID')]
        $GroupingProperty,
        $WorklogItems
    )
    $ArrayOfGroupedItems = GroupWorklogItems -GroupingProperty $GroupingProperty -WorklogItems $WorklogItems

    $ArrayOfGroupedAndSummedUpWorklogItems = @()

    foreach($GroupedItems in $ArrayOfGroupedItems) {
        $WorklogItems_ = $GroupedItems.WorklogItems
        $ItemCount = $WorklogItems_.Count

        $TimeTotal = New-TimeSpan -Hours 0 -Minutes 0

        if($WorklogItems_ -and $WorklogItems_.getType().Name -eq @().getType().Name) {
            for($i=0;$i -lt $ItemCount; $i++) {
                $TimeAsString = $WorklogItems_[$i].Time
                $Time = New-TimeSpan -Hours $TimeAsString.Split(':')[0] -Minutes $TimeAsString.Split(':')[1]
                $TimeTotal = $TimeTotal + $Time
            }
            $GroupedItems.Add('TotaledTime',$TimeTotal)

            $ArrayOfGroupedAndSummedUpWorklogItems += $GroupedItems
        } else {
            $TimeAsString = $WorklogItems_.Time
            $Time = New-TimeSpan -Hours $TimeAsString.Split(':')[0] -Minutes $TimeAsString.Split(':')[1]
            $TimeTotal = $TimeTotal + $Time

            $GroupedItems.Add('TotaledTime',$TimeTotal)

            $ArrayOfGroupedAndSummedUpWorklogItems += $GroupedItems
        }
    }
    $ArrayOfGroupedAndSummedUpWorklogItems
}

function Script:GetLastLine {
    Param(
        $WorklogFile
    )
    $WorklogLines = Get-Content -Path $WorklogFile
    for($i = ($WorklogLines.Count-1); $i -gt 0; $i--) {
        if($WorklogLines[$i].Length -gt 0) {
            return $WorklogLines[$i]
            break
        }
    }
}

function Script:AddNewDayLine {
    Param(
        $WorklogFile
    )
    $LastLine = GetLastLine -WorklogFile $WorklogFile
    $LastItem = ConvertWorklogLine -WorklogLine $LastLine
    $LastItem.Date
}

function Script:ValidateGroupingProperty {
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateSet('WorkType','Project','TicketID')]
        $GroupingProperty,
        [Parameter(Mandatory=$True)]
        $PropertyValue
    )
    if($GroupingProperty -eq 'WorkType') {
        if(!($WorklogWorkType -contains $PropertyValue)) {
            Throw("Invalid WorkType property: $PropertyValue")
        }
    }
    if($GroupingProperty -eq 'Project') {
        if(!($WorklogProject -contains $PropertyValue)) {
            Throw("Invalid Project property: $PropertyValue")
        }
    }
    if($GroupingProperty -eq 'TicketID') {
        if($PropertyValue -and ($PropertyValue.Length -gt 0)) {
            if(!(IsTicketIDValid -PotentialTicketID $PropertyValue)) {
                Throw("Invalid TicketID property: $PropertyValue")
            }
        }
    }
}

function Script:GetWorklogFile {
    Param(
        $CustomWorklogFile
    )

    if($CustomWorklogFile) { # check for custom worklog file, if not existing create it
        $WorklogFile = $CustomWorklogFile
         # if file exists --> use it / if file does not exist --> create it
        if(!(Test-Path $CustomWorklogFile)) {
            Add-Content -Value $(GetWorklogFileHeader -WorklogFile $WorklogFile) -Path $WorklogFile        
        }
    } else { # no custom worklog file, use default worklog file, if not existing create it
        $WorklogFile = $WorklogFileParam
        # if file exists --> use it / if file does not exist --> create it
        if(!(Test-Path $WorklogFileParam)) {
            Add-Content -Value $(GetWorklogFileHeader -WorklogFile $WorklogFile) -Path $WorklogFile
        }
    }
    $WorklogFile
}

function Script:AddWorklogLineToFile  {
    Param(
        $WorklogFile,
        $WorklogLine
    )

    $LastLine = GetLastLine -WorklogFile $WorklogFile

    
    if(!$LastLine.StartsWith('#')) { #Check if line is not a comment
        $WorklogItem = ConvertWorklogLine -WorklogLine $LastLine

        $CurrentDate = GetCurrentDateAsString
        if($WorklogItem.Date -ne $CurrentDate) {
            # if day changed, create new day header
            Add-Content -Path $WorklogFile -Value ''
            $WorklogDayHeader = GetWorklogDayHeader
            Add-Content -Path $WorklogFile -Value $WorklogDayHeader
        }
    } else { #Check type of comment
        if($LastLine.StartsWith('###')) {
            # if worklog day header do nothing
        } else {
            # if worklog file header start with new day header
            Add-Content -Path $WorklogFile -Value ''
            $WorklogDayHeader = GetWorklogDayHeader
            Add-Content -Path $WorklogFile -Value $WorklogDayHeader
        }
    }
    Add-Content -Path $WorklogFile -Value $WorklogLine
}

function New-WorklogItem {
    Param(
        [Parameter(Position = 0, Mandatory=$True)]
        $WorkType,
        [Parameter(Position = 1, Mandatory=$True)]
        $Project,
        [Parameter(Position = 2, Mandatory=$True)]
        $TicketID,
        [Parameter(Position = 3, Mandatory=$True)]
        $Comment,
        [Parameter(ParameterSetName='Time')]
        [switch]$Time,
        [Parameter(ParameterSetName='Time', Mandatory=$False)]
        $ManualTime,
        [Parameter(ParameterSetName='Duration')]
        [switch]$Duration,
        [Parameter(ParameterSetName='Duration', Mandatory=$True)]
        $DurationTime,
        [Parameter(Mandatory=$False)]
        $CustomWorklogFile
    )
    $CurrentDate = date
    $CurrentDateAsString = GetCurrentDateAsString
    if($Time) {
        $T_D = 'T'
        if($ManualTime) {
            $TimeValue = $ManualTime
        } else {
            $TimeValue = "{0:HH}:{0:mm}" -f $CurrentDate
        }
    } elseif($Duration) {
        $T_D = 'D'
        $TimeValue = $DurationTime
    }
    validateGroupingProperty -GroupingProperty WorkType -PropertyValue $WorkType
    if($WorkType -eq $WorklogTypeOff) {
        $T_D = 'T'
        if($ManualTime) {
            $TimeValue = $ManualTime
        } else {
            $TimeValue = "{0:HH}:{0:mm}" -f $CurrentDate
        }
    } else {
        validateGroupingProperty -GroupingProperty Project -PropertyValue $Project
        validateGroupingProperty -GroupingProperty TicketID -PropertyValue $TicketID
    }

    if($TicketID -and $TicketID.Length -gt 0) {
        $WorklogLine = "{0} {1} {2} {3} {4} {5} {6}" -f $CurrentDateAsString,$T_D,$TimeValue,$WorkType,$Project,$TicketID,$Comment
    } else {
        $WorklogLine = "{0} {1} {2} {3} {4} {5}" -f $CurrentDateAsString,$T_D,$TimeValue,$WorkType,$Project,$Comment
    }
    Write-Host $WorklogLine -ForegroundColor Yellow
    $WorklogFile = GetWorklogFile -CustomWorklogFile $CustomWorklogFile
    AddWorklogLineToFile -WorklogFile $WorklogFile -WorklogLine $WorklogLine
}

function Add-TimeWorklogItem {
    Param(
        [Parameter(Mandatory=$True)]
        $WorkType,
        [Parameter(Mandatory=$True)]
        $Project,
        [Parameter(Mandatory=$False)]
        $TicketID = '',
        [Parameter(Mandatory=$True)]
        $Comment,
        [Parameter(Mandatory=$False)]
        $CustomWorklogFile
    )
    New-WorklogItem -WorkType $WorkType -Project $Project -TicketID $TicketID -Comment $Comment -Time -CustomWorklogFile $CustomWorklogFile
}

function Add-OffWorklogItem {
    Param(
        $CustomWorklogFile
    )
    New-WorklogItem -WorkType $WorklogTypeOff -Project '' -TicketID '' -Comment '' -Time -CustomWorklogFile $CustomWorklogFile
}

function Add-DurationWorklogItem {
    Param(
        [Parameter(Mandatory=$True)]
        $DurationTime,
        [Parameter(Mandatory=$True)]
        $WorkType,
        [Parameter(Mandatory=$True)]
        $Project,
        [Parameter(Mandatory=$False)]
        $TicketID = '',
        [Parameter(Mandatory=$True)]
        $Comment,
        [Parameter(Mandatory=$False)]
        $CustomWorklogFile
    )
    New-WorklogItem -WorkType $WorkType -Project $Project -TicketID $TicketID -Comment $Comment -Duration -DurationTime $DurationTime -CustomWorklogFile $CustomWorklogFile
}

function Add-WorklogLine {
    Param(
        [Parameter(Position = 0, Mandatory=$True)]
        $WorklogLine,
        [Parameter(Mandatory=$False)]
        $CustomWorklogFile
    )

    <#
	Scenario 1: worklog line indicates a time entry
	  - new entry using current time automatically
                mgmt  itshop KB#ID128 Create new task for Fabio
        Tokens: [0]   [1]    [2]      [3]
	  - new entry using manual time
                09:30 mgmt  itshop KB#ID128 Create new task for Fabio
        Tokens: [0]   [1]   [2]    [3]      [4]

    Scenario 1: worklog line indicates a duration entry
      - line starts with duration
                d09:30 mgmt  itshop KB#ID128 Create new task for Fabio
        Tokens: [0]    [1]   [2]    [3]      [4]
	#>
    $ArrayOfToken = $WorklogLine.Split(' ')

    $IsDurationLine = IsDurationTime -PotentialTime $ArrayOfToken[0]
    if($IsDurationLine) {
        $Time = $ArrayOfToken[0].Substring(1) # remove leading character
        $WorkType = $ArrayOfToken[1]
        $Project = $ArrayOfToken[2]
        if(IsTicketIDValid -PotentialTicketID $ArrayOfToken[3]) {
            $TicketID = $ArrayOfToken[3]
            $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 4
        } else {
            $TicketID = ''
            $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 3
        }
        New-WorklogItem -WorkType $WorkType -Project $Project -TicketID $TicketID -Comment $Comment -Duration -DurationTime $Time -CustomWorklogFile $CustomWorklogFile
    } else { # Time line
        $IsManualTime = IsTimeValid -PotentialTime $ArrayOfToken[0]
        if($IsManualTime) {
            $ManualTime = $ArrayOfToken[0]
            $WorkType = $ArrayOfToken[1]
            if($WorkType -eq $WorklogTypeOff) {
                $Project = ''
                $TicketID = ''
                $Comment = ''
            } else {
                $Project = $ArrayOfToken[2]
                if(IsTicketIDValid -PotentialTicketID $ArrayOfToken[3]) {
                    $TicketID = $ArrayOfToken[3]
                    $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 4
                } else {
                    $TicketID = ''
                    $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 3
                }
            }
            New-WorklogItem -WorkType $WorkType -Project $Project -TicketID $TicketID -Comment $Comment -Time -ManualTime $ManualTime -CustomWorklogFile $CustomWorklogFile
        } else {
            $WorkType = $ArrayOfToken[0]
            if($WorkType -eq $WorklogTypeOff) {
                $Project = ''
                $TicketID = ''
                $Comment = ''
            } else {
                $Project = $ArrayOfToken[1]
                if(IsTicketIDValid -PotentialTicketID $ArrayOfToken[2]) {
                    $TicketID = $ArrayOfToken[2]
                    $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 3
                } else {
                    $TicketID = ''
                    $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 2
                }
            }
            New-WorklogItem -WorkType $WorkType -Project $Project -TicketID $TicketID -Comment $Comment -Time -CustomWorklogFile $CustomWorklogFile
        }
    }
}

function Show-WorklogReport {
    Param(
        [ValidateSet('All','Date','WorkType','Project','TicketID')]
        [Parameter(Mandatory=$True)]
        $GroupingProperty,
        $CustomWorklogFile
    )
    $WorklogLines = ReadWorklogFile -WorklogFile (GetWorklogFile -CustomWorklogFile $CustomWorklogFile)
    $WorklogItems = $WorklogLines | % {ConvertWorklogLine -WorklogLine $_}
    $NormalizedWorklogItems = ConvertDurationIntoTimeWorklogItems -WorklogItems $WorklogItems

    switch($GroupingProperty) {
        'Date' {
            $GroupedWorklogItems = GroupAndSumUpWorklogItems -GroupingProperty Date -WorklogItems $NormalizedWorklogItems
        }
        'WorkType' {
            $GroupedWorklogItems = GroupAndSumUpWorklogItems -GroupingProperty WorkType -WorklogItems $NormalizedWorklogItems
        }
        'Project' {
            $GroupedWorklogItems = GroupAndSumUpWorklogItems -GroupingProperty Project -WorklogItems $NormalizedWorklogItems
        }
        'TicketID' {
            $GroupedWorklogItems = GroupAndSumUpWorklogItems -GroupingProperty TicketID -WorklogItems $NormalizedWorklogItems
        }
        'All' {
        }
        default {
        }
    }
    Write-ArrayOfGroupedWorklogItems -ArrayOfGroupedWorklogItems $GroupedWorklogItems

}