param(
    [Parameter(Mandatory)][string] $rule,
    [Parameter()][object] $config,
    [Parameter()][switch] $whatIf
)

if (-not $config) {
    $config = Get-OrganizeConfig
}

$config.Rules | `
    Where-Object Name -eq $rule | `
    ForEach-Object {
        $renameConfig = $_.RenameConfig
        $destination = $_.Destination
    }

if ($renameConfig) {
    Get-FilesToOrganize $config $rule | `
        Get-RenameList -ConfigFile $renameConfig -DestinationDir $config.WorkingDir | `
        Move-File -WhatIf:$whatIf

    Get-FilesToOrganize $config $rule $config.WorkingDir | `
        Move-FileToDirectory -DestinationDir $destination -WhatIf:$whatIf
}
else {
    Get-FilesToOrganize $config $rule | `
        Move-FileToDirectory -DestinationDir $destination -WhatIf:$whatIf
}