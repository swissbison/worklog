#Requires -Version 4.0
<#
        .SYNOPSIS
        Externlaizes worklog settings for easier modification of the user specific
        WorkType, Project, TicketPrefix properties.
        This file needs to be in the same location as the Worklog.ps1 file

        .NOTES
        File Name  : WorklogSettings.ps1 
        Author     : Paul Signer (psig@gmx.ch)
        Date       : 07.12.2016
        Version    : 1.0

        .HISTORY
        Version    : 1.0 (07.12.2016) - Initial version of this file.
#>

$WorklogWorkType = @(
    'admin', 
    'meet', 
    'mgmt', 
    'educ', 
    'arch', 
    'spec', 
    'code', 
    'arch', 
    'docu', 
    'test', 
    'vac'
)

$WorklogProject = @(
    'MyOrg',
    'Proj1', 
    'Proj2',
    'Proj3'
)

$WorklogTicketPrefix = @(
    'OTRS#', 
    'KB#',
    'Tick#'
)
