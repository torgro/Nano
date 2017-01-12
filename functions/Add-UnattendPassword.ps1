function Add-UnattendPassword
{
[cmdletbinding()]
Param
(
    [Parameter(Mandatory)]
    [pscredential]$Credential
    ,
    [Parameter(Mandatory)]
    [System.Xml.XmlDocument]$XMLDoc
)
    $xmlNameSpace = $XMLDoc.unattend.NamespaceURI
    $XmlSettings = $XMLDoc.CreateElement("settings", $xmlNameSpace)
    $xmlUnattend = $XMLDoc.unattend


    $XmlSettings.SetAttribute("pass", "offlineServicing")
    $null = $XmlUnattended.AppendChild($XmlSettings)
    $XmlComponent = $XMLDoc.CreateElement("component", $xmlNameSpace)
    $XmlComponent.SetAttribute("name", "Microsoft-Windows-Shell-Setup")
    $XmlComponent.SetAttribute("processorArchitecture", "amd64")
    $XmlComponent.SetAttribute("publicKeyToken", "31bf3856ad364e35")
    $XmlComponent.SetAttribute("language", "neutral")
    $XmlComponent.SetAttribute("versionScope", "nonSxS")
    $null = $XmlSettings.AppendChild($XmlComponent)
    $XmlUserAccounts = $XMLDoc.CreateElement("OfflineUserAccounts", $xmlNameSpace)
    $null = $XmlComponent.AppendChild($XmlUserAccounts)

    $XmlAdministratorPassword = $XMLDoc.CreateElement("OfflineAdministratorPassword", $xmlNameSpace)
    $null = $XmlUserAccounts.AppendChild($XmlAdministratorPassword)
    
    $XmlValue = $XMLDoc.CreateElement("Value", $xmlNameSpace)
    $AdministratorPassword = $Credential.GetNetworkCredential().Password
    $XmlText = $XMLDoc.CreateTextNode([Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("$($AdministratorPassword)OfflineAdministratorPassword")))
    $null = $XmlValue.AppendChild($XmlText)
    $null = $XmlAdministratorPassword.AppendChild($XmlValue)

    $XmlPlainText = $XMLDoc.CreateElement("PlainText", $xmlNameSpace)
    $XmlPassword = $XMLDoc.CreateTextNode("false")
    $null = $XmlPlainText.AppendChild($XmlPassword)
    $null = $XmlAdministratorPassword.AppendChild($XmlPlainText)
    $XMLDoc
}