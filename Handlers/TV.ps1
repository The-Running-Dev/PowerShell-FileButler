param(
    [Parameter()][object] $config,
    [Parameter()][switch] $skipTranscode,
    [Parameter()][switch] $skipMove,
    [Parameter()][switch] $skipRecycle,
    [Parameter()][switch] $whatIf
)

. (Join-Path $PSScriptRoot '../Functions.ps1')

if (-not $config) {
    $config = Get-OrganizeConfig
}

$rule = 'TV Shows'
$encodingParams = '--encoder vt_h265 --mp4 --no-log --target 1500 --quiet -H two-pass -H turbo -H verbose 0'
$recycleDirectory = Join-Path $config.WorkingDir 'Recycle'
$workingDir = Join-Path $config.WorkingDir 'TV'
$transcodedDirectory = Join-Path $workingDir 'Transcoded'

$filesToTranscode = @()
$filesToMove = @()
$filesToRecycle = @()

$config.Rules | `
    Where-Object Name -eq $rule | `
    ForEach-Object {
    $renameConfig = $_.RenameConfig
    $destination = $_.Destination
}

Get-FilesToOrganize $config $rule | ForEach-Object {
    if (-not $skipTranscode) {
        $xml = [xml](& mediainfo "$($_.FullName)" --Output=XML)
        $info = $xml.MediaInfo.media.track | `
            Select-Object -First 1 -Skip 1 | `
            Select-Object -Property Format, @{ Name = 'Bitrate'; Expression = { [int]($_.Bitrate / 1000) } }, Width, Height

        $format = $info.Format
        $bitrate = $info.Bitrate
        $width = $info.Width
        $height = $info.Height

        if ($_.Extension -eq '.mkv') {
            $filesToTranscode += @{ Path = $_.FullName; Item = $_; Params = $encodingParams }
        }
        else {
            $filesToMove += $_
        }
    }
    else {
        $filesToMove += $_
    }
}

if ($filesToTranscode.Count -gt 0) {
    New-Item -ItemType Directory $transcodedDirectory -ErrorAction SilentlyContinue | Out-Null

    $filesToTranscode | ForEach-Object {
        $sourceFile = $_.Path
        $outputFile = Join-Path $transcodedDirectory "$($_.Item.BaseName).mp4"
        $params = $_.Params
        $arguments = "`"$sourceFile`" $params --output `"$outputFile`""

        if (-not $whatIf) {
            Start-Process 'transcode-video' $arguments -Wait
        }

        if ([System.IO.File]::Exists($outputFile)) {
            $filesToRecycle += $_.Item.FullName
        }
    }
}

if (Test-Path $workingDir) {
    Get-FilesToOrganize $config $rule $workingDir | `
        Get-RenameList -ConfigFile $renameConfig -destinationDir $destination | `
        Move-File -WhatIf:$whatIf
}

if (-not $skipRecycle) {
    $filesToRecycle | Move-FileToDirectory -DestinationDir $recycleDirectory -WhatIf:$whatIf
}
else {
    $filesToRecycle | Remove-Item -ErrorAction SilentlyContinue -WhatIf:$whatIf
}

if (Test-Path $transcodedDirectory) {
    If (-not (Get-ChildItem $transcodedDirectory)) {
        Remove-Item $transcodedDirectory -Recurse -ErrorAction SilentlyContinue -WhatIf:$whatIf
    }
}

If (-not (Get-ChildItem $workingDir -Recurse)) {
    Remove-Item $workingDir -Recurse -ErrorAction SilentlyContinue -WhatIf:$whatIf
}