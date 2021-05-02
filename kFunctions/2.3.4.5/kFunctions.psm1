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
1.  Command works both locally (Linux) and remotely (Linux or Windows).
2.  For this Advanced Function to work properly:
    a) Ensure that the API has been proxied:
        Start-Job -ScriptBlock {kubectl proxy --port 8888}
    b) Run the command, returning the information into a variable:
        $myVar = Get-K8sAPIInfo -Uri http://localhost:8888
3.  The DefaultDisplayPropertySet = "GroupName","GroupVersion","ResourceKind","ResourceName"
    To see all properties, issue either:
        $myVar | Format-List -Property *
        $myVar | Select-Object -Property *
4. If using microK8s it may be necessary to run 'microk8s kubectl' in place of 'kubectl'.
.EXAMPLE
Please Read:

Note: Any free port above 1024 can be used; if using a port different than 8888, substitute accordingly.
Note: If using microK8s it may be necessary to run 'microk8s kubectl' in place of 'kubectl'.

Before this Advanced Function will work, a proxy to the API must be configured.
    Start-Job -ScriptBlock {kubectl proxy --port 8888}

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

        $urla = ($($Uri.AbsoluteUri)+$([K8sAPI]::uria))
        $urlc = ($($Uri.AbsoluteUri)+$([K8sAPI]::uric))
    }

    Process
    {
        $apic = [K8sAPI]::GetApiInfo($urlc)
        $rr = $apic.resources |
            Where-Object -Property Name -NotMatch "/"
        foreach ($ap in $rr)
        {
            $lo = [K8sAPI]::MakeObj($apic.kind , $apic.groupVersion , $ap )
            $lo
        }

        $apis = [K8sAPI]::GetApiInfo($urla)
        foreach ($api in $apis.groups)
        {
            $prv = $api.preferredVersion.groupVersion
            $grvs = $api.versions
            foreach ($grv in $grvs)
            {
                $url = $($urla)+$($grv.groupVersion)
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