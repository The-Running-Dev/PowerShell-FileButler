param(
    [Parameter()][switch] $whatIf
)

. (Join-Path $PSScriptRoot './Functions.ps1')

Clear-Host

<#
Select-Object -Property @{ Name = 'Path'; Expression = { $_.FullName -Replace '(\[|\])', '`$1' } } | `
Select-Object -ExpandProperty Path | `
Out-File $fileLog -Append
#>

$config = Get-OrganizeConfig

$config.Rules | ForEach-Object {
    & $($_.Handler) -config $config -whatIf:$whatIf
}