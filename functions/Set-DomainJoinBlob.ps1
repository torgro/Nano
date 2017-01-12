function Set-DomainJoinBlob
{
[cmdletbinding()]
Param(
    [string]$BlobFilePath
    ,
    [string]$MountPointPath
)
$f = $MyInvocation.InvocationName
Write-Verbose -Message "$f - START"

if (-not (Test-Path -Path $BlobFilePath))
{
    Write-Error -Message "Error - BlobFile [$BlobFilePath] was not found" -ErrorAction Stop
}

if(-not (Test-Path -Path $MountPointPath))
{
    Write-Error -Message "Error - Mountpoint [$MountPointPath] was not found" -ErrorAction Stop
}
$safeBlobFilePath = $BlobFilePath | Get-SafeString
$safeMountPointPath = $MountPointPath | Get-SafeString

$cmd = "djoin.exe /RequestODJ /LoadFile '$safeBlobFilePath' /WindowsPath '$safeMountPointPath\Windows'"

Write-Verbose -Message "$f -  Invoking [$cmd]"

$results = Invoke-Expression -Command $cmd
$successText = "The operation completed successfully."        

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

Write-Verbose -Message "$f - END"

}