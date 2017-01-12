function Save-Unattend
{
[cmdletbinding()]
Param(
    [Parameter(ValueFromPipeline,Mandatory)]
    [System.Xml.XmlDocument]$XmlDoc
    ,
    [Parameter(Mandatory)]
    [string]$FilePath
)

    $resolvedPath = Resolve-Path -Path (Split-Path -Path $FilePath -Parent)
    $fileName = Split-Path -Path $FilePath -Leaf

    if (-not (Test-Path -Path $resolvedPath))
    {
        Write-Error -Message "Folder [$resolvedPath] does not exists" -ErrorAction Stop
    }

    $resolvedPath = Join-Path -Path $resolvedPath -ChildPath $fileName

    if (-not $XmlDoc)
    {
        Write-Error -Message "XMLDoc is null" -ErrorAction Stop
    }

    Write-Verbose -Message "Saving to [$resolvedPath]"
    $XmlDoc.Save($resolvedPath)
}