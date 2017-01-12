function Get-SafeString
{
[cmdletbinding()]
Param(
    [Parameter(ValueFromPipeline)]
    [string[]]
    $Inputobject
)
begin
{
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"
}

process
{
    foreach($line in $Inputobject)
    {
        Write-Verbose -Message "$f -  Processing [$line]"
        [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($line)
    }
}

End
{
    Write-Verbose -Message "$f - END"
}
}