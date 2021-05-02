using module .\kClass.psm1

<#
.SYNOPSIS
Produces an object of Kubernetes API Groups and Resources.
.DESCRIPTION
Produces an object of Kubernetes API Groups and Resources via proxied connection.
Combines the output of (kubectl api-resources) and (kubectl api-versions).
See Notes and Examples.
.PARAMETER Uri
URI that has been proxied via kubectl.
.INPUTS
URI that has been proxied via kubectl.
.OUTPUTS
pscustombobject SupSkiFun.Kubernetes.API.Info
.NOTES
1.  PowerShell 7 Required because a ternary operator is used.  Using a version lower than 7 will error akin to:
        PreferredVersion = ( $prv -eq $gvv ? $true : $false )
        Unexpected token '?' in expression or statement.
2.  For the command to work properly
    Ensure that the API has been proxied, akin to:  kubectl proxy --port 8888 &
    Run the command, returning the information into a variable:  $myVar = Get-K8sAPIInfo
3.  The DefaultDisplayPropertySet = "GroupName","GroupVersion","ResourceKind","ResourceName"
    To see all properties, issue either:
        $myVar | Format-List -Property *
        $myVar | Select-Object -Property *
.EXAMPLE
Before this Advanced Function will work, a proxy to the API must be configured.

Note any free port above 1024 can be used; if using a port different than 8888, substitute accordingly in both references below.
    kubectl proxy --port 8888 &

Once the proxy is established:
    $myVar = Get-K8sAPIInfo -Uri http://localhost:8888

Display the Default Property Set of all Groups / Resources:
    $myVar

Display all Properties of all Groups / Resources:
    $myVar | Format-List -Property *

Display all Preferred Version Groups / Resources:
    $myVar | Where-Object -Property PreferredVersion -eq $true
        or
    $myVar | Where-Object -Property PreferredVersion -eq $true | fl *

Display all Groups / Resources within the apps group:
    $myVar | Where-Object -Property GroupName -eq apps
        or
    $myVar | Where-Object -Property GroupName -eq apps | fl *

Display all Groups / Resources matching the ResourceKind Role:
    $myVar | Where-Object -Property ResourceKind -match role
        or
    $myVar | Where-Object -Property ResourceKind -match role | fl *
#>

Function Get-K8sAPIInfo
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true , ValueFromPipeline = $true)]
        [Uri] $Uri
    )

    Begin
    {
        if ( ([uri] $uri).IsAbsoluteUri -eq $false )
        {
            Write-Output "Terminating.  Non-valid URL detected.  Submitted URL:  $uri"
            break
        }

        $mainurl = ($($Uri.AbsoluteUri)+$([K8sAPI]::uria))
    }

    Process
    {
        $apis = [K8sAPI]::GetApiInfo($mainurl)

        foreach ($api in $apis.groups)
        {
            $prv = $api.preferredVersion.groupVersion
            $grvs = $api.versions
            foreach ($grv in $grvs)
            {
                $url = $($mainurl)+$($grv.groupVersion)
                $resi = [K8sAPI]::GetResourceInfo($url)
                foreach ($res in $resi)
                {
                    $lo = [K8sAPI]::MakeObj($api.name , $grv , $res , $prv)
                    $lo
                }
            }
        }
    }

    End
    {
        $TypeData = @{
            TypeName = 'SupSkiFun.Kubernetes.API.Info'
            DefaultDisplayPropertySet = "GroupName","GroupVersion","ResourceKind","ResourceName"
        }
        Update-TypeData @TypeData -Force
    }
}