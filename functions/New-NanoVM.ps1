function New-NanoVM
{
[cmdletbinding()]
Param(
    [string]$BaseVHDpath
    ,
    [string]$MountPointPath
    ,
    [string]$VMname
    ,
    [string]$DesinationVHDpath
    ,
    [INT]$Memory
    ,
    [string]$SwitchName
    ,
    [int]$Generation = 2
    ,
    [switch]$StartVM
    ,
    [string]$DomainJoinBlobFile
    ,
    [Parameter(Mandatory)]
    [pscredential]$NanoServerAdministratorPassword
)

    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"

    if ([string]::IsNullOrWhiteSpace($VMname))
    {
        $VMname = (New-Guid) -replace "-",""
    }

    if(-not (Test-Path -Path $DesinationVHDpath))
    {
        $null = New-Item -Path $DesinationVHDpath -ItemType Directory
    }

    $DesinationVHDpath = Join-Path -Path $DesinationVHDpath -ChildPath "$VMname" | Join-Path -ChildPath "$VMname.vhdx"

    if (Test-Path -Path $DesinationVHDpath)
    {
        $Msg = "ERROR - Destination [$destination] exists"   
        Write-Error -Message $msg -ErrorAction Stop
    }

    Write-Verbose -Message "$f -  Creating unattend.xml"

    $unattendFile = "$env:temp\unattend.xml"

    $xml = New-Unattend -AdministratorPassword $NanoServerAdministratorPassword

    Write-Verbose -Message "$f -  Saving at [$unattendFile]"
    Save-Unattend -XmlDoc $xml -FilePath $unattendFile

    Write-Verbose -Message "$f -  Does the baseVHDpath exists"

    if(-not (Test-Path -Path $BaseVHDpath))
    {
        Write-Error -Message "Error - BaseVHD not found at [$BaseVHDpath]" -ErrorAction Stop
    }

    Write-Verbose -Message "$f -  Checking for destination parent path [$DesinationVHDpath]"

    if(-not (Test-Path -Path ($DesinationVHDpath | Split-Path)))
    {
        Write-Verbose -Message "$f -  Creating destination parent path"
        $null = New-Item -Path ($DesinationVHDpath | Split-Path) -ItemType Directory
    }

    Write-Verbose -Message "$f -  Copying VHD"

    Copy-Item -Path $BaseVHDpath -Destination $DesinationVHDpath -ErrorAction Stop

    if (-not (Test-Path -Path $MountPointPath))
    {
        new-item -Path $MountPointPath -ItemType Directory -ErrorAction Stop
    }

    Write-Verbose -Message "$f -  Mounting image from [$DesinationVHDpath]"

    Mount-DiskImage -ImagePath $DesinationVHDpath -NoDriveLetter

    try
    {
        write-verbose -Message "$f -  Creating a mountpoint at [$MountPointPath]"
        if(-not (Test-Path -Path $MountPointPath))
        {
            Write-Verbose -Message "$f -  Creating mountpoint folder"
            $null = New-Item -Path $MountPointPath -ItemType Directory
        }
        Write-Verbose -Message "$f -  Getting diskimage [$DesinationVHDpath]"
        $disk = Get-DiskImage -ImagePath $DesinationVHDpath | Get-Disk

        if (-not $disk)
        {
            throw "Unable to find a disk"
        }

        Write-Verbose -Message "$f -  Getting partitions of type IFS or Basic"
        $partition = $disk | Get-Partition | Where-Object { $_.Type -eq "IFS" -or $_.Type -eq "Basic" }

        if (-not $partition)
        {
            throw "Unable to find a partition"
        }

        Write-Verbose -Message "$f -  Adding partition access for [$MountPointPath]"
        $partition | Add-PartitionAccessPath -AccessPath $MountPointPath -ErrorAction Stop
    }
    catch
    {
        $ex = $_.Exception
        Write-Verbose -Message "$f -  Error during disk mounting, $($ex.message)"
        Dismount-DiskImage -ImagePath $DesinationVHDpath
        Throw $_.exception
    }

    try
    {    
        $safeMountPoint = $MountPointPath | Get-SafeString
        $command = "dism.exe /Image:'$safeMountPoint' /Apply-Unattend:'$unattendFile'"
        
        Write-Verbose -Message "$f -  Executing [$command]"
        $results = Invoke-Expression -Command $command

        $successText = "The operation completed successfully."        
                
        foreach($line in $results)
        {
            if (-not [string]::IsNullOrWhiteSpace($line))
            {
                Write-Verbose -Message "$f -  dism.exe output: [$line]"
            }
        }

        $resultString = $results | Out-String

        if (-not $resultString.Contains($successText))
        {
            throw "$f - ERROR: Djoin.exe did not return success $resultString"
        }

        if (-not [string]::IsNullOrWhiteSpace($DomainJoinBlobFile))
        {
            if (Test-Path -Path $DomainJoinBlobFile)
            {             
                $safeBlobFile = $DomainJoinBlobFile | Get-SafeString
                Set-DomainJoinBlob -BlobFilePath $safeBlobFile -MountPointPath $safeMountPoint
            }
            else 
            {
                Write-Warning -Message "Unable to find Domain blob file [$DomainJoinBlobFile]. Computer will not join a domain!"
            }
        }

        Write-Verbose -Message "$f -  Removing mountpoint, getting disk for [$DesinationVHDpath]"
        $disk = Get-DiskImage -ImagePath $DesinationVHDpath | Get-Disk

        if (-not $disk)
        {
            throw "Unable to find a disk"
        }

        Write-Verbose -Message "$f -  Getting partition of type IFS or Basic"
        $partition = $disk | Get-Partition | Where-Object { $_.Type -eq "IFS" -or $_.Type -eq "Basic" }

        if (-not $partition)
        {
            throw "Unable to find a partition"
        }

        Write-Verbose -Message "$f -  Removing partition access path [$MountPointPath]"
        $partition | Remove-PartitionAccessPath -AccessPath $MountPointPath -ErrorAction Stop
    }
    finally
    {
        Dismount-DiskImage -ImagePath $DesinationVHDpath
    }

    if (Test-Path -Path $unattendFile)
    {
        Write-Verbose -Message "$f -  Removing [$unattendFile]"
        Remove-Item -Path $unattendFile -Confirm:$false -Force
    }

    if (-not [string]::IsNullOrWhiteSpace($DomainJoinBlobFile))
    {
        if (Test-Path -Path $DomainJoinBlobFile)
        {
            Write-Verbose -Message "$f -  Removing [$DomainJoinBlobFile]"
            Remove-Item -Path $DomainJoinBlobFile -Confirm:$false -Force
        }
    }

    Write-Verbose -Message "$f -  Creating VM [$VMname]"

    $vm = New-VM -Name $VMname -MemoryStartupBytes $Memory -VHDPath $DesinationVHDpath -SwitchName $SwitchName -Generation $Generation

    if ($StartVM)
    {
        $null = Start-VM -VM $vm
    }

    $vm
}