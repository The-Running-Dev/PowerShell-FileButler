param(
    [Parameter()][object] $config,
    [Parameter()][switch] $whatIf
)

. (Join-Path $PSScriptRoot '../Functions.ps1')

$rule = 'Cleanup'

if (-not $config) {
    $config = Get-OrganizeConfig
}

# Deal with files that belong to this rule
Get-FilesToOrganize $config $rule | Remove-Item -WhatIf:$whatIf

# Get a list of all files that match the defined rules
$allFilesToBeOrganized = Get-FilesToOrganize $config

Get-ChildItem $config.Directory | `
    Where-Object { `
        $_.FullName -notin $allFilesToBeOrganized `
        -and $_.Name -notin $config.ExcludeDirectories `
        -and $_.Name -notmatch $config.ExcludeFilenames `
        -and -not (Test-Path "$($_.FullName)\*")
} | `
    Select-Object -Property @{ Name = 'Path'; Expression = { $_.FullName -Replace '(\[|\])', '`$1' } } | `
    Select-Object -ExpandProperty Path | `
    ForEach-Object {
        Remove-Item $_ -WhatIf:$whatIf
}

$tailRecursion = {
    param($path)

    foreach ($childDirectory in Get-ChildItem -Force -LiteralPath $path -Directory) {
        & $tailRecursion -Path $childDirectory.FullName
    }

    $currentChildren = Get-ChildItem -Force -LiteralPath $path

    if ($currentChildren -eq $null) {
        Remove-Item -Force -LiteralPath $path
    }
}

$parent = (Get-Item $config.WorkingDir).Parent.FullName
& $tailRecursion -Path $parent