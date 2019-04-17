param(
    [Parameter()][object] $config,
    [Parameter()][switch] $whatIf
)

& (Join-Path $PSScriptRoot 'Generic.ps1') 'Pictures' $config -whatIf:$whatIf