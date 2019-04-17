param(
    [Parameter()][string] $directory,
    [Parameter()][object] $config,
    [Parameter()][switch] $whatIf
)
. (Join-Path $PSScriptRoot './Functions.ps1')

Clear-Host

$config = Get-OrganizeConfig
$filesToOrganize = @{ }

if (-not $directory) {
    $directory = $config.Directory
}

$filesToOrganize = Get-FilesToOrganize -Config $config -Directory $directory

$filesToOrganize.Keys | ForEach-Object {
    "$($_)
=========="
    $filesToOrganize.$_.FullName
    "`n"
}
<#
param(
    [Parameter(Mandatory)][string] $directory,
    [Parameter()][object] $config,
    [Parameter()][switch] $whatIf
)
. (Join-Path $PSScriptRoot './Functions.ps1')

$config = Get-OrganizeConfig

$files = @()
$filesToOrganize = @{ }
$matchedFiles = @()
$directory = '/Volumes/ben/Downloads'

$supportedExtensions = $config.Rules.Extensions -Join '|'
$excludedDirectories = $config.ExcludeDirectories -Join '|'

Get-ChildItem $directory -File -Recurse | `
    Where-Object { `
        $_.Directory.FullName -notmatch $excludedDirectories `
        -and $_.Name -notmatch $config.ExcludeFilenames `
        -and $_.Extension -match $supportedExtensions
} | `
    Select-Object -Property @{ Name = 'Path'; Expression = { $_.FullName -Replace '(\[|\])', '`$1' } } | `
    Select-Object -ExpandProperty Path | `
    ForEach-Object {
    $files += Get-Item $_
}

$config.Rules | ForEach-Object {
    $ruleName = $_.Name
    $nameContains = $_.NameContains
    $extensions = $_.Extensions
    $filesToOrganize[$ruleName] = @()

    if ($nameContains) {
        $files | Where-Object { `
                $_.BaseName -match $nameContains `
                -and $_.Extension -match $extensions `
                -and $_.FullName -notin $matchedFiles
        } | ForEach-Object {
            $matchedFiles += $_.FullName
            $filesToOrganize[$ruleName] += $_
        }
    }
    else {
        $files | Where-Object { `
                $_.Extension -match $extensions `
                -and $_.FullName -notin $matchedFiles
        } | ForEach-Object {
            $matchedFiles += $_.FullName
            $filesToOrganize[$ruleName] += $_
        }
    }
}

$filesToOrganize.Keys | ForEach-Object {
    "$($_)
=========="
    $filesToOrganize.$_.FullName
    "`n"
}
#>