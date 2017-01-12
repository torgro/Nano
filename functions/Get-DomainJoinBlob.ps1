function Get-DomainJoinBlob
{
[cmdletbinding()]
Param
(
    $DomainController
    ,
    $DomainName
    ,
    $Credential
    ,
    $ComputerName
)
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"

    if (-not [string]::IsNullOrWhiteSpace($DomainController))
    {
        $newSession = @{
            ComputerName = $DomainController
        }

        if ($Credential)
        {
            $newSession.Add("Credential",$Credential)
        }

        Write-Verbose -Message "$f -  Create Session"
        $dcSession = New-PSSession @newSession
    }

    $blobFileName = "$ComputerName.blob"

    $localblobFilePath= Join-Path -Path $env:TEMP -ChildPath $blobFileName

    Write-Verbose -Message "$f -  BlobFile is [$blobFilePath]"

    if ($dcSession)
    {
        $tempPath = Invoke-Command -Session $DCsession -ScriptBlock { $env:TEMP }
        $blobFilePath = Join-Path -Path $tempPath -ChildPath $blobFileName
        Write-Verbose -Message "$f -  Remote blob path is [$blobFilePath]"
    }
    $safeDomainName =  $DomainName | Get-SafeString
    $safeComputerName = $ComputerName | Get-SafeString
    $safeBlogFilePath = $blobFilePath | Get-SafeString
    
    $cmd = "djoin.exe /Provision /Domain '$safeDomainName' /Machine '$safeComputerName' /SaveFile '$safeBlogFilePath'"

    if ($dcSession)
    {
        try
        {
            Write-Verbose -Message "$f -  Invoking command [$cmd]"
            $results = Invoke-Command -Session $dcSession -ScriptBlock { Invoke-Expression $using:cmd }
            $successText = "Successfully provisioned [$ComputerName] in the domain [$DomainName]."        
            
            foreach($line in $results)
            {
                if (-not [string]::IsNullOrWhiteSpace($line))
                {
                    Write-Verbose -Message "$f -  Djoin.exe output: [$line]"
                }
            }

            $resultString = $results | Out-String

            if (-not $resultString.Contains($successText))
            {
                throw "$f - ERROR: Djoin.exe did not return success $resultString"
            }
            
            Write-Verbose -Message "$f -  Copy file [$blobFilePath] from remote Session to [$localblobFilePath]"
            Copy-Item -FromSession $dcSession -Path $blobFilePath -Destination $localblobFilePath -ErrorAction Stop
        }
        catch
        {
            throw $_.exception
        }
        Finally
        {
            Write-Verbose -Message "$f -  Removing session"
            Remove-PSSession -Session $dcSession
        }
    }
    else
    {
        Write-Verbose -Message "$f -  Harvesting blob from local computer"
        Invoke-Expression $cmd
    }

    Write-Verbose -Message "$f -  Outputting blob file [$localblobFilePath]"
    Get-ChildItem -Path $localblobFilePath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    Write-Verbose -Message "$f - END"
}