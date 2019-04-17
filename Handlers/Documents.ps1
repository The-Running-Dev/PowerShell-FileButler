param(
    [Parameter()][object] $config,
    [Parameter()][switch] $whatIf
)

& (Join-Path $PSScriptRoot 'Generic.ps1') 'Documents' $config -whatIf:$whatIf