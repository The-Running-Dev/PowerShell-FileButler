param(
    [Parameter()][object] $config,
    [Parameter()][switch] $whatIf
)

$rule = 'Archives'
$existingFiles = @()

if (-not $config) {
    $config = Get-OrganizeConfig
}

$config.Rules | `
    Where-Object Name -eq $rule | `
    ForEach-Object {
        $renameConfig = $_.RenameConfig
        $destination = $_.Destination
    }

if (Test-Path $destination) {
    # Get a list of existing files
    $existingFiles = Get-ChildItem -File $destination | `
        Where-Object Name -notmatch ($config.ExcludeFilesContaining -Join '|') | `
        Select-Object -ExpandProperty FullName
}

& (Join-Path $PSScriptRoot 'Generic.ps1') $rule $config -whatIf:$whatIf

# Get all the new files in the
# destination directory and unzip them
Get-ChildItem -File $destination | `
    Where-Object FullName -notin $existingFiles | `
    ForEach-Object {
        $outputDir = Join-Path $destination $_.BaseName
        if ([System.IO.Directory]::Exists($destination)) {
            $outputDir = Join-Path $destination "$($_.BaseName)-$($config.RunTimeStamp)"
        }

        & unar $_.FullName -o $outputDir -q
        Remove-Item $_.FullName -WhatIf:$whatIf
}