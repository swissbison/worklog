#Requires -Version 4.0
<#
        .SYNOPSIS
        <tbd>

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
    'ID-PPF', 
    'ID-PPF-PM', 
    'ITSM', 
    'ITShop', 
    'STO'
    'Proj1', 
    'Proj2',
    'Proj3'
)

$WorklogTicketPrefix = @(
    'OTRS#', 
    'KB#',
    'Tick#'
)
