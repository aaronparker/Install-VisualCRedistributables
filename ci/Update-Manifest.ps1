<#
    .SYNOPSIS
        Update manifest for newer VcRedist 2019 versions
#>
[OutputType()]
Param (
    $Version = "2019"
)

# Get an array of VcRedists from the curernt manifest and the installed VcRedists
$CurrentManifest = Get-Content -Path $VcManifest | ConvertFrom-Json
$InstalledVcRedists = Get-InstalledVcRedist

# Filter the VcRedists for the target version and compare against what has been installed
ForEach ($ManifestVcRedist in ($CurrentManifest.Supported | Where-Object { $_.Release -eq $Version })) {
    $InstalledItem = $InstalledVcRedists | Where-Object { ($_.Release -eq $ManifestVcRedist.Release) -and ($_.Architecture -eq $ManifestVcRedist.Architecture) }

    # If the manifest version of the VcRedist is lower than the installed version, the manifest is out of date
    If (($InstalledItem.Count -gt 0) -and ($InstalledItem.Version -gt $ManifestVcRedist.Version)) {
        Write-Host " "
        Write-Host -ForegroundColor Cyan "VcRedist manifest is out of date."
        Write-Host -ForegroundColor Cyan "Installed version:`t$($InstalledItem.Version)"
        Write-Host -ForegroundColor Cyan "Manifest version:`t$($ManifestVcRedist.Version)"

        # Find the index of the VcRedist in the manifest and update it's properties
        $Index = $CurrentManifest.Supported::IndexOf($CurrentManifest.Supported.ProductCode, $ManifestVcRedist.ProductCode)
        $CurrentManifest.Supported[$Index].ProductCode = $InstalledItem.ProductCode
        $CurrentManifest.Supported[$Index].Version = $InstalledItem.Version

        # Create output variable 
        $output = $InstalledItem.Version
        $FoundNewVersion = $True
    }
}

# If a version was found and were aren't in the master branch
If (($FoundNewVersion) -and ($env:APPVEYOR_REPO_BRANCH -ne 'master')) {

    # Convert to JSON and export to the module manifest
    try {
        Write-Host -ForegroundColor Cyan "Updating module manifest with VcRedist $output."
        $CurrentManifest | ConvertTo-Json | Set-Content -Path $VcManifest -Force
    }
    catch {
        Write-Error "Failed to conver to JSON and write back to the manifest."
        Break
    }
    finally {

        # Publish the new version back to Master on GitHub
        Try {
            # Set up a path to the git.exe cmd, import posh-git to give us control over git
            $env:Path += ";$env:ProgramFiles\Git\cmd"
            Import-Module posh-git -ErrorAction Stop

            # Dot source Invoke-Process.ps1. Prevent 'RemoteException' error when running specific git commands
            . $projectRoot\ci\Invoke-Process.ps1

            # Configure the git environment
            git config --global credential.helper store
            Add-Content -Path (Join-Path $env:USERPROFILE ".git-credentials") -Value "https://$($env:GitHubKey):x-oauth-basic@github.com`n"
            git config --global user.email "$($env:APPVEYOR_REPO_COMMIT_AUTHOR_EMAIL)"
            git config --global user.name "$($env:APPVEYOR_REPO_COMMIT_AUTHOR)"
            git config --global core.autocrlf true
            git config --global core.safecrlf false

            # Push changes to GitHub
            Invoke-Process -FilePath "git" -ArgumentList "checkout $env:APPVEYOR_REPO_BRANCH"
            git add --all
            git status
            git commit -s -m "Manifest update VcRedist $Version - $FoundVersion"
            Invoke-Process -FilePath "git" -ArgumentList "push origin $env:APPVEYOR_REPO_BRANCH"
            Write-Host "Manifest Update for $FoundVersion pushed to GitHub." -ForegroundColor Cyan
        }
        Catch {
            # Sad panda; it broke
            Write-Warning "Push to GitHub failed."
            Throw $_
        }
    }
}
