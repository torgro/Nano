function New-NanoVHDx
{
[cmdletbinding()]
Param
(
    [Parameter(Mandatory = $True, Position=0)]
    [ValidateSet("Host","Guest")]
    $DeploymentType
    ,
    [Parameter(Mandatory = $True, Position=1)]
    [ValidateSet("DataCenter","Standard")]
    $Edition
    ,
    [string]$BasePath
    ,
    [ValidateScript({ Test-Path $_ })]
    [string]$MediaPath
    ,
    [ValidatePattern('\.(vhdx?|wim)$')]
    [string]$OutPutVHDxFilePath
    ,
    [pscredential]$AdministratorPassword
    ,
    [ValidateRange(512MB, 64TB)]
    [UInt64]$MaxSize = 4GB
)

$newNanoImage = @{
    DeploymentType = $DeploymentType
    Edition        = $Edition
    BasePath       = "$BasePath"
    MediaPath      = "$MediaPath"
    TargetPath     = "$OutPutVHDxFilePath"
    MaxSize        = $MaxSize
    Package        = "Microsoft-NanoServer-DSC-Package"
    AdministratorPassword = (ConvertTo-SecureString -AsPlainText -String $AdministratorPassword.GetNetworkCredential().Password -Force)
}

New-NanoServerImage @newNanoImage
}
