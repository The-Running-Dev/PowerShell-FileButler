function Get-FilesToOrganize {
    param(
        [Parameter()][object] $config,
        [Parameter()][string] $rule,
        [Parameter()][string] $directory
    )
    $files = @()
    $filesToOrganize = [ordered]@{ }
    $matchedFiles = @()

    $supportedExtensions = $config.Rules.Extensions -Join '|'
    $excludeDirectories = $config.ExcludeDirectories -Join '|'
    $excludeFilenames = $config.ExcludeFilenames

    if (-not $directory) {
        $directory = $config.Directory
    }

    if (-not (Test-Path $directory -PathType Container)) {
        Write-Error "Directory Not Found $directory..."
        return
    }

    if ($directory -eq $config.Directory) {
        # Only apply the excluded directories
        # and excluded files if we are working with
        # the drectory in the config file
        $allFiles = Get-ChildItem $directory -File -Recurse | `
            Where-Object { `
                $_.DirectoryName -notmatch $excludeDirectories `
                -and $_.Name -notmatch $excludeFilenames `
                -and $_.Extension -match $supportedExtensions
        }
    }
    else {
        $allFiles = Get-ChildItem $directory -File -Recurse | `
            Where-Object Extension -match $supportedExtensions
    }

    # For all files,
    # escape the braces in the file/directory name,
    # or Get-Item does not work
    $allFiles | `
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
                    $_.Name -match $nameContains `
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

    # If a rule name is specified,
    # limit the scope of the rules to just the one chosen
    if ($rule) {
        return $filesToOrganize[$rule]
    }

    return $filesToOrganize
}

function Get-OrganizeConfig {
    param(
        [Parameter()][string] $configDir = (Join-Path $PSScriptRoot 'Config'),
        [Parameter()][string] $handlers = (Join-Path $PSScriptRoot 'Handlers'),
        [Parameter()][string] $logDir = (Join-Path $PSScriptRoot 'Logs'),
        [Parameter()][string] $configFile = (Join-Path $PSScriptRoot 'Config\Downloads.config')
    )

    $config = Get-ConfigFromJson $configFile
    $config.RunTimeStamp = $((Get-Date -Format s) -Replace ':|T', '.')
    $config.LogFile = Join-Path $logDir "Files-$timeStamp.log"
    $config.ExcludeFilenames = $config.ExcludeFilenames -Join '|'
    $config.WorkingDir = $ExecutionContext.InvokeCommand.ExpandString($config.WorkingDir)

    $config.Rules | ForEach-Object {
        $_.NameContains = $_.MatchRules.NameContains -Join '|'
        $_.Extensions = $_.MatchRules.Extensions -Join '|'
        $_.Enabled = [System.Convert]::ToBoolean($_.Enabled)
        $_.Priority = [System.Convert]::ToInt16($_.Priority)

        if ($_.Destination -match '^~/') {
            $_.Destination = Join-Path $env:HOME ($_.Destination -Replace '~/', '')
        }
        elseif (-not [System.IO.Path]::IsPathRooted($_.Destination)) {
            $_.Destination = Join-Path $config.Directory $_.Destination
        }

        if ($_.RenameConfig -match '^~/') {
            $_.RenameConfig = Join-Path $env:HOME ($_.RenameConfig -Replace '~/', '')
        }
        elseif ($_.RenameConfig -and (-not [System.IO.Path]::IsPathRooted($_.RenameConfig))) {
            $_.RenameConfig = Join-Path $configDir $_.RenameConfig
        }

        if ($_.Handler -match '^~/') {
            $_.Handler = Join-Path $env:HOME ($_.Handler -Replace '~/', '')
        }
        elseif ($_.Handler -and (-not [System.IO.Path]::IsPathRooted($_.Handler))) {
            $_.Handler = Join-Path $handlers $_.Handler
        }

        if ($_.RenameConfig -and -not (Test-Path $_.RenameConfig)) {
            $_.RenameConfig = ''
        }

        if (-not (Test-Path $_.Handler)) {
            $_.Enabled = $false
        }
    }

    New-Item -ItemType Directory $config.WorkingDir -ErrorAction SilentlyContinue | Out-Null

    $config.Rules = $config.Rules | Where-Object Enabled | Sort-Object @{ E = { $_.Priority } }

    return $config
}