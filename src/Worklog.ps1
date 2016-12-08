#Requires -Version 4.0
<#
        .SYNOPSIS
        This is a powershell re-implementation of the worklog idea originally developed by Erich Obermühlner (http://obermuhlner.ch).
        The idea behind worklog is to have an easy way to capture a log of your spent time on different working tasks.
        Based on the captured log, one can create reports showing on what and how long it was worked on.

        .NOTES
        File Name  : Worklog.ps1 
        Author     : Paul Signer (psig@gmx.ch)
        Date       : 07.12.2016
        Version    : 1.4

        .HISTORY
        Version    : 1.4 (07.12.2016) - Improved coding style, added OnOfftime feature, added WorklogSettings.ps1 file
        Version    : 1.3 (29.11.2016) - Improve coding style, some bug fixes, added more options
        Version    : 1.2 (22.11.2016) - Improve coding style, remove duplicates, some bug fixes
        Version    : 1.1 (29.08.2016) - The new version is version 1.0 modified to be a cmdlet.

        .EXAMPLES
        Format of worklog.txt
        Date       T/D Time   WorkType  Project   Ticket       Comment
        2016/09/01 T   07:00  admin     Proj1      Tick#16309  answer question
        2016/09/01 T   12:00  off
        2016/09/01 T   12:00  code      Proj2      Tick#ID102  work on powershell tools   
        2016/09/01 T   18:00  off
        2016/09/02 D   01:30  admin     Proj3                  groups meeting
        2016/09/02 D   04:00  educ      Proj3                  learn about javascript
        2016/09/02 D   03:30  code      Proj1      Tick#ID102  work on powershell tools

        Meaning of workog item properties
        Date     : yyyy/mm/dd
        T_D      : T - Time / D - Duration
        Time     : hh:mm
        WorkType : type of work items, to be defined in worklog_params.ps1
        Project  : project name, to be defined in worklog_params.ps1
        Ticket   : optional, but used prefix defined in worklog_params.ps1
        Comment  : optional free text

        Cmdlet to add a worklog entry
        Add-WorklogLine 'admin Proj1 Work comment'
        Add-WorklogLine '08:30 admin Proj1 Work comment'
        Add-WorklogLine 'D02:00 admin Proj1 Work comment'

        Cmdlet to get a report of worklog entries
        Show-WorklogReport -GroupingPropery Date

#>

#region "settings"
$WorkingDirParam = $PSScriptRoot
$WorklogFileParam = "$WorkingDirParam\worklog.txt"
$WorklogSettingFile = "$WorkingDirParam\WorklogSettings.ps1"

try { . $WorklogSettingFile } catch { Write-Error -Message "No WorklogSetting.ps1 found in $WorklogSettingFile! Only loaded defaults"}

# Worklog WorkType should be defined in WorklogSettings.ps1, if not define some defaults
if(!$WorklogWorkType) 
{
    $WorklogWorkType = @(
        'admin', 
        'meet', 
        'educ', 
        'code', 
        'docu'
    )
}
# add WorkType 'off' as mandatory element
$WorklogTypeOff = 'off'
$WorklogWorkType += $WorklogTypeOff

# Worklog Project should be defined in WorklogSettings.ps1, if not define some defaults
if(!$WorklogProject)
{
    $WorklogProject = @(
        'Proj1', 
        'Proj2',
        'Proj3'
    )
}

# Worklog Ticket Prefix should be defined in WorklogSettings.ps1, if not define some defaults
if(!$WorklogTicketPrefix)
{
    $WorklogTicketPrefix = @(
        'Tick#'
    )
}
# add prefix 'n.a.' as mandatory element
$WorklogTicketNo = 'n.a.'
$WorklogTicketPrefix += $WorklogTicketNo
#endregion

#region "base functions"
function Script:GetWorklogDayHeader 
{
    $CurrentDate = date
    $WorklogDayHeaderTemplate = '### {0} {1:yyyy}/{1:MM}/{1:dd} ###'
    $WorklogDayHeader = $WorklogDayHeaderTemplate -f $CurrentDate.DayOfWeek, $CurrentDate
    $WorklogDayHeader
}

function Script:GetCurrentDateAsString 
{
    $CurrentDate = date
    $Date = '{0:yyyy}/{0:MM}/{0:dd}' -f $CurrentDate.Date
    $Date
}

function Script:GetCurrentTimeAsString 
{
    $CurrentDate = date
    $Time = '{0:HH}:{0:mm}' -f $CurrentDate
    $Time
}

function Script:ReadWorklogFile 
{
    Param(
        $WorklogFile
    )
    $Lines = Get-Content $WorklogFile
    $CleanedLines = $Lines |
    ForEach-Object -Process {
        $_.Trim()
    } |
    Where-Object -FilterScript {
        $_ -notlike '#*' -and $_ -notlike ''
    }
    $CleanedLines
}

function Script:GetWorklogFileHeader 
{
    Param(
        $WorklogFile
    )
    $DateAndTime = (GetCurrentDateAsString) + ' - ' + (GetCurrentTimeAsString)
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

function Script:GetWorklogFile 
{
    Param(
        $CustomWorklogFile
    )

    if($CustomWorklogFile) 
    {
        # check for custom worklog file, if not existing create it
        $WorklogFile = $CustomWorklogFile
        # if file exists --> use it / if file does not exist --> create it
        if(!(Test-Path $CustomWorklogFile)) 
        {
            Add-Content -Value $(GetWorklogFileHeader -WorklogFile $WorklogFile) -Path $WorklogFile
        }
    }
    else 
    {
        # no custom worklog file, use default worklog file, if not existing create it
        $WorklogFile = $WorklogFileParam
        # if file exists --> use it / if file does not exist --> create it
        if(!(Test-Path $WorklogFileParam)) 
        {
            Add-Content -Value $(GetWorklogFileHeader -WorklogFile $WorklogFile) -Path $WorklogFile
        }
    }
    $WorklogFile
}

function Script:GetLastLine 
{
    Param(
        $WorklogFile
    )
    $WorklogLines = Get-Content -Path $WorklogFile
    for($i = ($WorklogLines.Count-1); $i -gt 0; $i--) 
    {
        if($WorklogLines[$i].Length -gt 0) 
        {
            return $WorklogLines[$i]
            break
        }
    }
}

function Script:IsTicketIDValid 
{
    Param(
        $PotentialTicketID
    )
    $WorklogTicketPrefix | Where-Object -FilterScript {
        $PotentialTicketID -like "$_*"
    }
}

function Script:IsTimeValid 
{
    Param(
        $PotentialTime
    )
    $RegEx = '(\d{2}:\d{2})'
    if($PotentialTime -match $RegEx) 
    {
        $IsValid = $True
    }
    else 
    {
        $IsValid = $False
    }
    $IsValid
}

function Script:IsDurationTime 
{
    Param(
        $PotentialTime
    )
    $RegExDuration = '([dD]\d{2}:\d{2})'
    if($PotentialTime -match $RegExDuration) 
    {
        $IsDuration = $True
    }
    else 
    {
        $IsDuration = $False
    } 
    $IsDuration
}

function Script:GetComment 
{
    Param(
        $ArrayOfToken,
        $BeginIndex
    )
    $Comment = $Null
    for($i = $BeginIndex; $i -lt $ArrayOfToken.Count; $i++) 
    {
        if($Comment -eq $Null) 
        {
            $Comment = $ArrayOfToken[$i]
        }
        else 
        {
            $Comment = $Comment + ' ' + $ArrayOfToken[$i]
        }
    }
    $Comment
}

function Script:ValidateGroupingProperty 
{
    Param(
        [Parameter(Mandatory = $True)]
        [ValidateSet('WorkType','Project','TicketID')]
        $GroupingProperty,
        [Parameter(Mandatory = $True)]
        $PropertyValue
    )
    if($GroupingProperty -eq 'WorkType') 
    {
        if(!($WorklogWorkType -contains $PropertyValue)) 
        {
            Throw("Invalid WorkType property: $PropertyValue")
        }
    }
    if($GroupingProperty -eq 'Project') 
    {
        if(!($WorklogProject -contains $PropertyValue)) 
        {
            Throw("Invalid Project property: $PropertyValue")
        }
    }
    if($GroupingProperty -eq 'TicketID') 
    {
        if($PropertyValue -and ($PropertyValue.Length -gt 0)) 
        {
            if(!(IsTicketIDValid -PotentialTicketID $PropertyValue)) 
            {
                Throw("Invalid TicketID property: $PropertyValue")
            }
        }
    }
}
#endregion

#region "single workitem functions"
function Script:ConvertWorklogLine 
{
    Param(
        $WorklogLine
    )
    $ArrayOfToken = $WorklogLine.Split(' ')

    $Date = $ArrayOfToken[0]
    $T_D = $ArrayOfToken[1]
    $Time = $ArrayOfToken[2]
    $WorkType = $ArrayOfToken[3]
    if($WorkType -eq $WorklogTypeOff) 
    {
        $Project = ''
        $TicketID = ''
        $Comment = ''
    }
    else 
    {
        $Project = $ArrayOfToken[4]
        if(IsTicketIDValid -PotentialTicketID $ArrayOfToken[5]) 
        {
            $TicketID = $ArrayOfToken[5]
            $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 6
        }
        else 
        {
            $TicketID = $WorklogTicketNo
            $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 5
        }
    }

    $WorklogLineAsHashtable = @{
        Date     = $Date
        T_D      = $T_D
        Time     = $Time
        WorkType = $WorkType
        Project  = $Project
        TicketID = $TicketID
        Comment  = $Comment
    }

    try 
    {
        ValidateWorklogItem -WorklogItem $WorklogLineAsHashtable
    }
    catch 
    {
        $Message = "$($_.ErrorMessage)" + $(Write-WorklogItem -WorklogItem $WorklogLineAsHashtable)
        Write-Host -Object $Message -ForegroundColor Red
    }

    $WorklogLineAsHashtable
}

function Script:ValidateWorklogItem 
{
    Param(
        $WorklogItem
    )
    $WorkType = $WorklogItem.WorkType
    $Project = $WorklogItem.Project
    $TicketID = $WorklogItem.TicketId
    ValidateGroupingProperty -GroupingProperty WorkType -PropertyValue $WorkType
    if($WorkType -ne 'off') 
    {
        ValidateGroupingProperty -GroupingProperty Project -PropertyValue $Project
        $TicketID = $WorklogItem.TicketID
        if($TicketID) 
        {
            ValidateGroupingProperty -GroupingProperty TicketID -PropertyValue $TicketID
        }
    }
}

function script:GetOnOffTimeString
{
    Param(
        $WorklogItems
    )
    
    $OnOffMessage = ''
    if($WorklogItems -and $WorklogItems.getType().Name -eq @().getType().Name) #check if $WorklogItems_ exists & is of Type Array
    {
        $ItemCount = $WorklogItems.Count
        for($i = 0;$i -lt $ItemCount; $i++) 
        {
            if($WorklogItems[$i].T_D -eq 'T') 
            {
                if($i -eq 0)
                {
                    $OnOffMessage += $WorklogItems[$i].Time
                    $OnOffMessage += '-'
                }
                else
                {
                    if($WorklogItems[$i].WorkType -eq 'off')
                    {
                        $OnOffMessage += $WorklogItems[$i].Time
                        $OnOffMessage += ' '
                        $i++
                        if($WorklogItems[$i])
                        {
                            $OnOffMessage += $WorklogItems[$i].Time
                            $OnOffMessage += '-'
                        }
                    }
                } 
            }
            else #$WorklogItems[i$].T_D -eq 'D'
            {
                # do nothing
            }
        }
    }
    else #single WorkItem
    { 
        if($WorklogItems.T_D -eq 'T') 
        {
            Write-Error -Message "Single WorklogItem with T_D=T not valid: $($WorklogItems.Values)"
            $OnOffMessage += 'invalid time'
        }
        else 
        {
            #$WorklogItems_[i$].T_D -eq 'D'
            Write-Debug -Message "Single WorkItem with T_D=D not considered: $WorklogItems.Values"
        }
    }
    $OnOffMessage.Trim()
}

function Script:Write-WorklogItem 
{
    Param(
        $WorklogItem
    )
    $ItemTemplate = '{0,10} {1,1} {2,5} {3,-5} {4,-10} {5,-15} {6}'
    $ItemTemplate -f $WorklogItem.Date, $WorklogItem.T_D, $WorklogItem.Time, $WorklogItem.WorkType, $WorklogItem.Project, $WorklogItem.TicketID, $WorklogItem.Comment
}

function Script:ConvertTimeIntoDurationItem 
{
    Param(
        $StartItem,
        $EndItem
    )
    try
    {
        $StartTime = New-TimeSpan -Hours $StartItem.Time.Split(':')[0] -Minutes $StartItem.Time.Split(':')[1]
        $EndTime = New-TimeSpan -Hours $EndItem.Time.Split(':')[0] -Minutes $EndItem.Time.Split(':')[1]
    }
    catch
    {
        $StartItem.Values
        $EndItem.Values
    }
    $Time = '{0:hh}:{0:mm}' -f ($EndTime - $StartTime)

    $TimeItem = @{
        Date     = $StartItem.Date
        T_D      = 'D'
        Time     = $Time
        WorkType = $StartItem.WorkType
        Project  = $StartItem.Project
        TicketID = $StartItem.TicketID
        Comment  = $StartItem.Comment
    }
    $TimeItem
}

function Script:AddNewDayLine 
{
    Param(
        $WorklogFile
    )
    $LastLine = GetLastLine -WorklogFile $WorklogFile
    $LastItem = ConvertWorklogLine -WorklogLine $LastLine
    $LastItem.Date
}

function Script:ConvertTimeIntoDurationWorklogItems 
{
    Param(
        $WorklogItems
    )

    $ConvertedWorklogItems = @()
    
    if($WorklogItems -and $WorklogItems.getType().Name -eq @().getType().Name) 
    {
        $ItemCount = $WorklogItems.Count
        
        for($i = 0;$i -lt $ItemCount; $i++) 
        {
            if($WorklogItems[$i].T_D -eq 'T') 
            {
                if(($WorklogItems[$i].WorkType) -ne 'off') 
                {
                    $TimeItem = ConvertTimeIntoDurationItem -StartItem $WorklogItems[$i] -EndItem $WorklogItems[$i+1]
                    $ConvertedWorklogItems += $TimeItem
                }
            }
            else 
            {
                #$DurationItem[i$].T_D -eq 'T'
                $ConvertedWorklogItems += $WorklogItems[$i]
            }
        }
    }
    else 
    { 
        if($WorklogItems.T_D -eq 'T') 
        {
            Write-Error -Message "Single WorklogItem with T_D=T not valid: $WorklogItems.Values"
        }
        else 
        {
            #$DurationItem[i$].T_D -eq 'T'
            $ConvertedWorklogItems += $WorklogItems
        }
    }
    $ConvertedWorklogItems
}

#endregion

#region "grouped worklog item functions"
function Script:GroupWorklogItems 
{
    Param(
        [ValidateSet('Date','WorkType','Project','TicketID')]
        $GroupingProperty,
        $WorklogItems
    )

    $ArrayOfProperties = $WorklogItems.$GroupingProperty
    $ArrayOfUniqueProperties = $ArrayOfProperties |
    Sort-Object |
    Get-Unique
 
    $ArrayOfGroupedWorklogItems = @()
    if($GroupingProperty -eq 'Date')
    {
        foreach($Prop in $ArrayOfUniqueProperties) 
        {
            $SelectedItems = $WorklogItems | Where-Object -FilterScript {
                $_.$GroupingProperty -eq $Prop 
            }

            $OnOffTime  = Script:GetOnOffTimeString -WorklogItems $SelectedItems

            $SelectedItems = Script:ConvertTimeIntoDurationWorklogItems -WorklogItems $SelectedItems

            $GroupedWorklogItems = @{
                GroupingProperty = $Prop
                OnOffTime = $OnOffTime
                WorklogItems     = $SelectedItems
            }
            $ArrayOfGroupedWorklogItems += $GroupedWorklogItems
        }
    }
    else
    {
        $DurationWorkItems = Script:ConvertTimeIntoDurationWorklogItems -WorklogItems $WorklogItems

        foreach($Prop in $ArrayOfUniqueProperties) 
        {
            $SelectedItems = $DurationWorkItems | Where-Object -FilterScript {
                $_.$GroupingProperty -eq $Prop 
            }

            $GroupedWorklogItems = @{
                GroupingProperty = $Prop
                WorklogItems     = $SelectedItems
            }
            $ArrayOfGroupedWorklogItems += $GroupedWorklogItems
        }
    }
    $ArrayOfGroupedWorklogItems
}

function Script:Write-GroupedWorklogItems 
{
    Param(
        $GroupedWorklogItems,
        $OnlyGroupHeader=$False
    )
    $gwi = $GroupedWorklogItems

    $TotaledHours = 0
    $Minutes = 0
    if($gwi.TotaledTime) 
    {
        $Days = $gwi.TotaledTime.Days
        $Hours = $gwi.TotaledTime.Hours
        $Minutes = $gwi.TotaledTime.Minutes
        if($Days -gt 0) 
        {
            $HoursAsString = $Days * 24 + $Hours
        }
        else 
        {
            $HoursAsString = ('{0:hh}' -f $gwi.TotaledTime)
        }
        $MinutesAsString = ('{0:mm}' -f $gwi.TotaledTime)

        if($gwi.OnOffTime)
        {
            '{0,-10} TotaledTime: {1}:{2} [{3}]' -f $gwi.GroupingProperty, $HoursAsString, $MinutesAsString, $gwi.OnOffTime
        }
        else
        {
            '{0,-10} TotaledTime: {1}:{2}' -f $gwi.GroupingProperty, $HoursAsString, $MinutesAsString
        }
    }
    else 
    {
        '{0,-10} [{1}]' -f $gwi.GroupingProperty,$gwi.OnOffTime
    }
    if($OnlyGroupHeader -eq $False)
    {
        $ItemTemplate = '           {0,1} {1,5} {2,-5} {3,-10} {4,-15} {5}'
        $gwi.WorklogItems | Sort-Object { $_.Project,$_.WorkType } | ForEach-Object -Process {
            $ItemTemplate -f $_.T_D, $_.Time, $_.WorkType, $_.Project, $_.TicketID, $_.Comment
        }
    }
}

function Script:Write-ArrayOfGroupedWorklogItems 
{
    Param(
        $ArrayOfGroupedWorklogItems,
        $OnlyGroupHeader=$False
    )
    foreach($GroupedItems in $ArrayOfGroupedWorklogItems) 
    {
        Write-GroupedWorklogItems -GroupedWorklogItems $GroupedItems -OnlyGroupHeader $OnlyGroupHeader
    }
}


function Script:GroupAndSumUpWorklogItems 
{
    Param(
        [ValidateSet('Date','WorkType','Project','TicketID')]
        $GroupingProperty,
        $WorklogItems
    )
    # group WorklogItems (Workitems will be normalized (--> only duration items) and grouped)
    $ArrayOfGroupedItems = GroupWorklogItems -GroupingProperty $GroupingProperty -WorklogItems $WorklogItems

    $ArrayOfGroupedAndSummedUpWorklogItems = @()

    foreach($GroupedItems in $ArrayOfGroupedItems) 
    {
        $WorklogItems_ = $GroupedItems.WorklogItems
        $ItemCount = $WorklogItems_.Count

        $TimeTotal = New-TimeSpan -Hours 0 -Minutes 0

        if($WorklogItems_ -and $WorklogItems_.getType().Name -eq @().getType().Name) 
        {
            for($i = 0;$i -lt $ItemCount; $i++) 
            {
                $TimeAsString = $WorklogItems_[$i].Time
                $Time = New-TimeSpan -Hours $TimeAsString.Split(':')[0] -Minutes $TimeAsString.Split(':')[1]
                $TimeTotal = $TimeTotal + $Time
            }
            $GroupedItems.Add('TotaledTime',$TimeTotal)

            $ArrayOfGroupedAndSummedUpWorklogItems += $GroupedItems
        }
        else 
        {
            $TimeAsString = $WorklogItems_.Time
            if($TimeAsString)
            {
                $Time = New-TimeSpan -Hours $TimeAsString.Split(':')[0] -Minutes $TimeAsString.Split(':')[1]
                $TimeTotal = $TimeTotal + $Time
            }
            $GroupedItems.Add('TotaledTime',$TimeTotal)

            $ArrayOfGroupedAndSummedUpWorklogItems += $GroupedItems
        }
    }
    $ArrayOfGroupedAndSummedUpWorklogItems
}


function Script:AddWorklogLineToFile  
{
    Param(
        $WorklogFile,
        $WorklogLine
    )

    $LastLine = GetLastLine -WorklogFile $WorklogFile

    
    if(!$LastLine.StartsWith('#')) 
    {
        #Check if line is not a comment
        $WorklogItem = ConvertWorklogLine -WorklogLine $LastLine

        $CurrentDate = GetCurrentDateAsString
        if($WorklogItem.Date -ne $CurrentDate) 
        {
            # if day changed, create new day header
            Add-Content -Path $WorklogFile -Value ''
            $WorklogDayHeader = GetWorklogDayHeader
            Add-Content -Path $WorklogFile -Value $WorklogDayHeader
        }
    }
    else 
    {
        #Check type of comment
        if($LastLine.StartsWith('###')) 
        {
            # if worklog day header do nothing
        }
        else 
        {
            # if worklog file header start with new day header
            Add-Content -Path $WorklogFile -Value ''
            $WorklogDayHeader = GetWorklogDayHeader
            Add-Content -Path $WorklogFile -Value $WorklogDayHeader
        }
    }
    Add-Content -Path $WorklogFile -Value $WorklogLine
}

#endregion

#region "private cmdlet"
function New-WorklogItem 
{
    Param(
        [Parameter(Position = 0, Mandatory = $True)]
        $WorkType,
        [Parameter(Position = 1, Mandatory = $True)]
        $Project,
        [Parameter(Position = 2, Mandatory = $True)]
        $TicketID,
        [Parameter(Position = 3, Mandatory = $True)]
        $Comment,
        [Parameter(ParameterSetName = 'Time')]
        [switch]$Time,
        [Parameter(ParameterSetName = 'Time', Mandatory = $False)]
        $ManualTime,
        [Parameter(ParameterSetName = 'Duration')]
        [switch]$Duration,
        [Parameter(ParameterSetName = 'Duration', Mandatory = $True)]
        $DurationTime,
        [Parameter(Mandatory = $False)]
        $CustomWorklogFile
    )
    $CurrentDate = date
    $CurrentDateAsString = GetCurrentDateAsString
    if($Time) 
    {
        $T_D = 'T'
        if($ManualTime) 
        {
            $TimeValue = $ManualTime
        }
        else 
        {
            $TimeValue = '{0:HH}:{0:mm}' -f $CurrentDate
        }
    }
    elseif($Duration) 
    {
        $T_D = 'D'
        $TimeValue = $DurationTime
    }
    validateGroupingProperty -GroupingProperty WorkType -PropertyValue $WorkType
    if($WorkType -eq $WorklogTypeOff) 
    {
        $T_D = 'T'
        if($ManualTime) 
        {
            $TimeValue = $ManualTime
        }
        else 
        {
            $TimeValue = '{0:HH}:{0:mm}' -f $CurrentDate
        }
    }
    else 
    {
        validateGroupingProperty -GroupingProperty Project -PropertyValue $Project
        validateGroupingProperty -GroupingProperty TicketID -PropertyValue $TicketID
    }

    if($TicketID -and $TicketID.Length -gt 0) 
    {
        $WorklogLine = '{0} {1} {2} {3} {4} {5} {6}' -f $CurrentDateAsString, $T_D, $TimeValue, $WorkType, $Project, $TicketID, $Comment
    }
    else 
    {
        $WorklogLine = '{0} {1} {2} {3} {4} {5}' -f $CurrentDateAsString, $T_D, $TimeValue, $WorkType, $Project, $Comment
    }
    Write-Host -Object $WorklogLine -ForegroundColor Yellow
    $WorklogFile = GetWorklogFile -CustomWorklogFile $CustomWorklogFile
    AddWorklogLineToFile -WorklogFile $WorklogFile -WorklogLine $WorklogLine
}

function Add-TimeWorklogItem 
{
    Param(
        [Parameter(Mandatory = $True)]
        $WorkType,
        [Parameter(Mandatory = $True)]
        $Project,
        [Parameter(Mandatory = $False)]
        $TicketID = '',
        [Parameter(Mandatory = $True)]
        $Comment,
        [Parameter(Mandatory = $False)]
        $CustomWorklogFile
    )
    New-WorklogItem -WorkType $WorkType -Project $Project -TicketID $TicketID -Comment $Comment -Time -CustomWorklogFile $CustomWorklogFile
}

function Add-OffWorklogItem 
{
    Param(
        $CustomWorklogFile
    )
    New-WorklogItem -WorkType $WorklogTypeOff -Project '' -TicketID '' -Comment '' -Time -CustomWorklogFile $CustomWorklogFile
}

function Add-DurationWorklogItem 
{
    Param(
        [Parameter(Mandatory = $True)]
        $DurationTime,
        [Parameter(Mandatory = $True)]
        $WorkType,
        [Parameter(Mandatory = $True)]
        $Project,
        [Parameter(Mandatory = $False)]
        $TicketID = '',
        [Parameter(Mandatory = $True)]
        $Comment,
        [Parameter(Mandatory = $False)]
        $CustomWorklogFile
    )
    New-WorklogItem -WorkType $WorkType -Project $Project -TicketID $TicketID -Comment $Comment -Duration -DurationTime $DurationTime -CustomWorklogFile $CustomWorklogFile
}
#endregion

#region "public cmdlet"
function Add-WorklogLine 
{
    Param(
        [Parameter(Position = 0, Mandatory = $True)]
        $WorklogLine,
        [Parameter(Mandatory = $False)]
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

            Scenario 2: worklog line indicates a duration entry
            - line starts with duration
            d09:30 mgmt  itshop KB#ID128 Create new task for Fabio
            Tokens: [0]    [1]   [2]    [3]      [4]
    #>
    $ArrayOfToken = $WorklogLine.Split(' ')

    $IsDurationLine = IsDurationTime -PotentialTime $ArrayOfToken[0]
    if($IsDurationLine) 
    {
        $Time = $ArrayOfToken[0].Substring(1) # remove leading character
        $WorkType = $ArrayOfToken[1]
        $Project = $ArrayOfToken[2]
        if(IsTicketIDValid -PotentialTicketID $ArrayOfToken[3]) 
        {
            $TicketID = $ArrayOfToken[3]
            $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 4
        }
        else 
        {
            $TicketID = ''
            $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 3
        }
        New-WorklogItem -WorkType $WorkType -Project $Project -TicketID $TicketID -Comment $Comment -Duration -DurationTime $Time -CustomWorklogFile $CustomWorklogFile
    }
    else 
    {
        # Time line
        $IsManualTime = IsTimeValid -PotentialTime $ArrayOfToken[0]
        if($IsManualTime) 
        {
            $ManualTime = $ArrayOfToken[0]
            $WorkType = $ArrayOfToken[1]
            if($WorkType -eq $WorklogTypeOff) 
            {
                $Project = ''
                $TicketID = ''
                $Comment = ''
            }
            else 
            {
                $Project = $ArrayOfToken[2]
                if(IsTicketIDValid -PotentialTicketID $ArrayOfToken[3]) 
                {
                    $TicketID = $ArrayOfToken[3]
                    $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 4
                }
                else 
                {
                    $TicketID = ''
                    $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 3
                }
            }
            New-WorklogItem -WorkType $WorkType -Project $Project -TicketID $TicketID -Comment $Comment -Time -ManualTime $ManualTime -CustomWorklogFile $CustomWorklogFile
        }
        else 
        {
            $WorkType = $ArrayOfToken[0]
            if($WorkType -eq $WorklogTypeOff) 
            {
                $Project = ''
                $TicketID = ''
                $Comment = ''
            }
            else 
            {
                $Project = $ArrayOfToken[1]
                if(IsTicketIDValid -PotentialTicketID $ArrayOfToken[2]) 
                {
                    $TicketID = $ArrayOfToken[2]
                    $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 3
                }
                else 
                {
                    $TicketID = ''
                    $Comment = GetComment -ArrayOfToken $ArrayOfToken -BeginIndex 2
                }
            }
            New-WorklogItem -WorkType $WorkType -Project $Project -TicketID $TicketID -Comment $Comment -Time -CustomWorklogFile $CustomWorklogFile
        }
    }
}

function Show-WorklogReport 
{
    Param(
        [ValidateSet('All','Date','WorkType','Project','TicketID')]
        [Parameter(Mandatory = $True)]
        $GroupingProperty,
        $CustomWorklogFile,
        $ReturnObject=$False
    )
    $WorklogLines = ReadWorklogFile -WorklogFile (GetWorklogFile -CustomWorklogFile $CustomWorklogFile)
    $WorklogItems = $WorklogLines | ForEach-Object -Process {
        ConvertWorklogLine -WorklogLine $_
    }

    switch($GroupingProperty) {
        'Date' 
        {
            $GroupedWorklogItems = GroupAndSumUpWorklogItems -GroupingProperty Date -WorklogItems $WorklogItems
        }
        'WorkType' 
        {
            $GroupedWorklogItems = GroupAndSumUpWorklogItems -GroupingProperty WorkType -WorklogItems $WorklogItems
        }
        'Project' 
        {
            $GroupedWorklogItems = GroupAndSumUpWorklogItems -GroupingProperty Project -WorklogItems $WorklogItems
        }
        'TicketID' 
        {
            $GroupedWorklogItems = GroupAndSumUpWorklogItems -GroupingProperty TicketID -WorklogItems $WorklogItems
        }
        'All' 
        {

        }
        default 
        {

        }
    }
    if($ReturnObject -eq $True)
    {
        $GroupedWorklogItems
    }
    else
    {
        Write-ArrayOfGroupedWorklogItems -ArrayOfGroupedWorklogItems $GroupedWorklogItems
    }
}
#endregion