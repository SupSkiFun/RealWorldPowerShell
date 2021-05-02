<#
    Advanced Function written to demonstrate
    poor implementation of SupportsShouldProcess.
#>
function Start-Adding
{
    [CmdletBinding(SupportsShouldProcess = $true ,
    ConfirmImpact = 'high')]
    param
    ( [Parameter(Mandatory = $true)] [int32] $number )

    Process
    {
        Write-Output "`n`tThis code executes regardless
            of -WhatIf or -Confirm:
                Result is $($number + 7)`n"
        if($PSCmdlet.ShouldProcess($number))
		{
            Write-Output "`n`tThis unimportant code is protected`n"
		}
    }
}