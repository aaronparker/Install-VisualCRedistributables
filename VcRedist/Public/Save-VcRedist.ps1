Function Save-VcRedist {
    <#
        .EXTERNALHELP VcRedist-help.xml
    #>
    [Alias("Get-VcRedist")]
    [CmdletBinding(SupportsShouldProcess = $True, HelpURI = "https://stealthpuppy.com/vcredist/save-vcredist/")]
    [OutputType([System.Management.Automation.PSObject])]
    Param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline)]
        [ValidateNotNull()]
        [System.Management.Automation.PSObject] $VcList,

        [Parameter(Mandatory = $False, Position = 1)]
        [ValidateScript( { If (Test-Path -Path $_ -PathType 'Container') { $True } Else { Throw "Cannot find path $_" } })]
        [System.String] $Path = (Resolve-Path -Path $PWD),

        [Parameter(Mandatory = $False)]
        [System.ObsoleteAttribute("This parameter should no longer be used. Invoke-WebRequest is used for all download operations.")]
        [System.Management.Automation.SwitchParameter] $ForceWebRequest,

        [Parameter(Mandatory = $False)]
        [System.ObsoleteAttribute("This parameter should no longer be used. Invoke-WebRequest is used for all download operations.")]
        [ValidateSet('Foreground', 'High', 'Normal', 'Low')]
        [System.String] $Priority = "Foreground",

        [Parameter(Mandatory = $False, Position = 3)]
        [System.String] $Proxy,

        [Parameter(Mandatory = $False, Position = 4)]
        [System.Management.Automation.PSCredential]
        $ProxyCredential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter(Mandatory = $False)]
        [System.Management.Automation.SwitchParameter] $NoProgress
    )

    Begin { 

        # Disable the Invoke-WebRequest progress bar for faster downloads
        If ($PSBoundParameters.ContainsKey("Verbose") -and !($PSBoundParameters.ContainsKey("NoProgress"))) {
            $ProgressPreference = "Continue"
        }
        Else {
            $ProgressPreference = "SilentlyContinue"
        }
        
        # Enable TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    Process {

        # Loop through each Redistributable and download to the target path
        ForEach ($VcRedist in $VcList) {

            # Build the path to save the VcRedist into
            # Target folder structure
            $folder = [System.IO.Path]::Combine((Resolve-Path -Path $Path), $VcRedist.Release, $VcRedist.Version, $VcRedist.Architecture)

            # Create the folder to store the downloaded file. Skip if it exists
            Write-Verbose -Message "$($MyInvocation.MyCommand): Test folder: [$folder]."
            If (Test-Path -Path $folder -ErrorAction "SilentlyContinue") {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Folder [$folder] exists. Skipping."
            }
            Else {
                If ($PSCmdlet.ShouldProcess($folder, "Create")) {
                    try {
                        $params = @{
                            Path        = $folder
                            Type        = "Directory"
                            Force       = $True
                            ErrorAction = "SilentlyContinue"
                        }
                        New-Item @params > $Null
                    }
                    catch [System.Exception] {
                        Write-Warning -Message "$($MyInvocation.MyCommand): Failed to create folder: [$folder]."
                        Throw $_.Exception.Message
                    }
                }
            }
            
            # Test whether the VcRedist is already on disk
            $target = Join-Path -Path $folder -ChildPath $(Split-Path -Path $VcRedist.Download -Leaf)
            Write-Verbose -Message "$($MyInvocation.MyCommand): Testing target: $($target)"

            If (Test-Path -Path $target -PathType "Leaf" -ErrorAction "SilentlyContinue") {
                $ProductVersion = $(Get-FileMetadata -Path $target).ProductVersion
                
                # If the target Redistributable is already downloaded, compare the version
                If (($VcRedist.Version -gt $ProductVersion) -or ($Null -eq $ProductVersion)) {
                    
                    # Download the newer version
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Manifest version: [$($VcRedist.Version)] > file version: [$ProductVersion]."
                    $download = $True
                }
                Else {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Manifest version: [$($VcRedist.Version)] matches file version: [$ProductVersion]."
                    $download = $False
                }
            }
            Else {
                $download = $True
            }

            # The VcRedist needs to be downloaded
            If ($download) {
                If ($PSCmdlet.ShouldProcess($VcRedist.Download, "Invoke-WebRequest")) {
                    
                    try {
                        
                        # Download the file
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Download VcRedist: [$($VcRedist.Release), $($VcRedist.Architecture), $($VcRedist.Version)]"
                        $iwrParams = @{
                            Uri             = $VcRedist.Download
                            OutFile         = $target
                            UseBasicParsing = $True
                            ErrorAction     = "SilentlyContinue"
                        }
                        If ($PSBoundParameters.ContainsKey("Proxy")) {
                            $iwrParams.Proxy = $Proxy
                        }
                        If ($PSBoundParameters.ContainsKey("ProxyCredential")) {
                            $iwrParams.ProxyCredential = $ProxyCredential
                        }
                        Invoke-WebRequest @iwrParams
                        $Downloaded = $True
                    }
                    catch [System.Exception] {
                        Write-Warning -Message "$($MyInvocation.MyCommand): Failed to download: [$($VcRedist.Name)]."
                        Write-Warning -Message "$($MyInvocation.MyCommand): URL: [$($VcRedist.Download)]."
                        Write-Warning -Message "$($MyInvocation.MyCommand): Download failed with: [$($_.Exception.Message)]"
                        $Downloaded = $False
                    }

                    # Return the $VcList array on the pipeline so that we can act on what was downloaded
                    # Add the Path property pointing to the downloaded file
                    If ($Downloaded) {
                        $VcRedist | Add-Member -MemberType "NoteProperty" -Name "Path" -Value $target
                        Write-Output -InputObject $VcRedist
                    }
                }
            }
            Else {
                # Return the $VcList array on the pipeline so that we can act on what was downloaded
                # Add the Path property pointing to the downloaded file
                Write-Verbose -Message "$($MyInvocation.MyCommand): [$($target)] exists."
                $VcRedist | Add-Member -MemberType "NoteProperty" -Name "Path" -Value $target
                Write-Output -InputObject $VcRedist
            }
        }
    }

    End { }
}
