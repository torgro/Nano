Function New-Unattend
{
[cmdletbinding()]
Param
(
    [Parameter(Mandatory)]
    [pscredential]$AdministratorPassword
)

    $Xml = New-Object -TypeName Xml
    $XmlNs = "urn:schemas-microsoft-com:unattend"
    
    $XmlDecl = $Xml.CreateXmlDeclaration("1.0", "utf-8", $Null)
    $XmlRoot = $Xml.DocumentElement
    $null = $Xml.InsertBefore($XmlDecl, $XmlRoot)

    $XmlUnattended = $Xml.CreateElement("unattend", $XmlNs)
    $XmlUnattended.SetAttribute("xmlns:wcm", "http://schemas.microsoft.com/WMIConfig/2002/State")
    $XmlUnattended.SetAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
    $null = $Xml.AppendChild($XmlUnattended)

    $xml = Add-UnattendPassword -Credential $AdministratorPassword -XMLDoc $xml

    $xml
}