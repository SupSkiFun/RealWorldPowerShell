<#
    Advanced Function written to demonstrate
    poor verb usage.
#>

function Get-FileInfo
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $file
	)

    Process
    {
        Remove-Item -Path $file -Confirm:$false
    }
}