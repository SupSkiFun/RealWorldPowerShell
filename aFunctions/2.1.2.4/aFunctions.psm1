using module .\aClass.psm1

<#
.SYNOPSIS
Creates or Deletes A records from a Route 53 Hosted Zone.
.DESCRIPTION
Creates or Deletes A records from a Route 53 Hosted Zone.  No other record types are supported.
Returns a pscustomobject for each record action, including submitted and returned information.
.NOTES
1. To delete a record, it is necessary to EXACTLY match the existing record, including TTL.
2. Show-R53Record can be piped into Set-R53ARecord to assist with deletions.  See Examples.
3. Record creation is limited to the parameters listed.  For more complex creations see Edit-R53ResourceRecordSet.
.PARAMETER Action
Mandatory. CREATE or DELETE.
.PARAMETER FQDN
Mandatory. Fully qualified name of the A record.  Example: myhost.mydomain.org
.PARAMETER HostedZoneId
Mandatory. AWS Zone ID of the record to create or delete.
.PARAMETER IP
Mandatory. IPv4 Address of the A record.  Example:. 10.10.10.10
.PARAMETER TTL
Optional. Time in seconds until cache expiration.  Defaults to 300 if no other value is specified.
.INPUTS
For deletion, output from Show-R53Record can be piped.  See Examples.
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.AWS.R53.A.Record.Info
.EXAMPLE
Create an A record:

First:  Return Specific Zone into a variable:
$myZone = Get-R53HostedZoneList | Where-Object -Property Name -Match "myDomain.org"

Second:
$myVar = Set-R53ARecord -Action CREATE -FQDN bogus3.myDomain.org -IP 172.17.21.23 -HostedZoneId $myZone.Id
.EXAMPLE
Delete an A record:

First:  Return Specific Zone into a variable:
$myZone = Get-R53HostedZoneList | Where-Object -Property Name -Match "myDomain.org"

Second:
$myVar = Set-R53ARecord -Action DELETE -FQDN bogus3.myDomain.org -IP 172.17.21.23 -HostedZoneId $myZone.Id
.EXAMPLE
Delete an A record using information from Show-R53Record:

First:  Return Specific Zone into a variable:
$myZone = Get-R53HostedZoneList | Where-Object -Property Name -Match "myDomain.org"

Second:  Retrieve / Process A records from a Specific Zone:
$myInfo = $myZone | Get-R53ResourceRecordSet  | Show-R53Record

Third:  Query for a specific record:
$myRecord = $myInfo | Where-Object -Property FQDN -Match "bogus3"

Fourth:  Delete the record
$myVar = $myRecord | Set-R53ARecord -Action DELETE -HostedZoneId $myZone.Id
.LINK
Get-R53HostedZoneList
Get-R53ResourceRecordSet
Edit-R53ResourceRecordSet
Show-R53Record
#>

Function Set-R53ARecord
{
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = "High")]

    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("CREATE", "DELETE")]
        [string] $Action,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $FQDN,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $HostedZoneId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ipaddress] $IP,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Int32] $TTL = 300
    )

    Process
    {
        if ($pscmdlet.ShouldProcess($FQDN, $Action))
        {
            $rr = [aClass]::MakeR53ResRec($FQDN, $TTL, $IP)
            $rc = [aClass]::MakeR53Change($Action, $rr)
            $rv = Edit-R53ResourceRecordSet -HostedZoneId $HostedZoneId -ChangeBatch_Change $rc
            $lo = [aClass]::MakeR53Obj($rc, $rv , $HostedZoneId)
            $lo
        }
    }
}

<#
.SYNOPSIS
Returns configuration information from EC2 Instances.
.DESCRIPTION
Returns a PSCUSTOMOBJECT of configuration information from EC2 Instances.
.NOTES
1) The object provided from Get-EC2Instance is stored in the NoteProperty Object.
2) The Name NoteProperty will be empty if an EC2 Instance name has not been specified.
3) Tags can be seen by returning the object into a variable (e.g. $myVar), then $myVar.Tags
4) Optimal JSON output is demonstrated in Example 4.
.PARAMETER EC2Instance
Mandatory. Output from AWS Get-EC2Instance (Module: AWS.Tools.EC2). See Examples.
[Amazon.EC2.Model.Reservation]
.INPUTS
AWS Instance from Get-EC2Instance [Amazon.EC2.Model.Reservation]
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.AWS.EC2Instance.Info
.EXAMPLE
Return a custom object from one EC2 Instance:
Get-EC2Instance -InstanceId i-0e90783335830aaaa | Show-EC2Instance
.EXAMPLE
Return a custom object from two EC2 Instances into a variable:
$myVar = Get-EC2Instance -InstanceId i-0e90783335830aaaa , i-0e20784445830bbbb | Show-EC2Instance
.EXAMPLE
Start all EC2 Instances with a name of "test":
(Get-EC2Instance | Show-EC2Instance | Where Name -match test).Object | Start-EC2Instance
.EXAMPLE
Return a custom object from one EC2 Instance, converting the output to JSON:
$myVar = Get-EC2Instance -InstanceId i-0e90783335830aaaa | Show-EC2Instance
$jVar = $myVar | Select-Object * -ExcludeProperty Object | ConvertTo-Json -Depth 4
.LINK
Get-EC2Instance
#>

Function Show-EC2Instance
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Amazon.EC2.Model.Reservation[]] $EC2Instance
    )

    Process
    {
        foreach ($e in $EC2Instance.Instances)
        {
            $lo = [aClass]::MakeEC2IObj($e)
            $lo
        }
    }
}

<#
.SYNOPSIS
Formats returned records from a Route 53 Hosted Zone.
.DESCRIPTION
Creates a PSCUSTOMOBJECT of returned records from a Route 53 Hosted Zone.
The custom object is much easier to view and work with.
.NOTES
The Get-R53ResourceRecordSet has a MaxLimit parameter that might need adjusting for large zones.
.PARAMETER RecordSets
Mandatory. Output from AWS Get-R53ResourceRecordSet (Module: AWS.Tools.Route53). See Examples.
[Amazon.Route53.Model.ListResourceRecordSetsResponse]
.INPUTS
AWS Route 53 Records from Get-R53ResourceRecordSet
[Amazon.Route53.Model.ListResourceRecordSetsResponse]
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.AWS.R53.Record.Info
.EXAMPLE
Retrieve and process records:

First:  Return Specific Zone into a variable:
$myZone = Get-R53HostedZoneList | Where-Object -Property Name -Match "myDomain.org"

Second:  Using a specific zone, retrieve records putting them into a pscustomobject.
$myVar = Get-R53ResourceRecordSet -HostedZoneId $myZone.Id | Show-R53Record
.EXAMPLE
Retrieve and process records, piping the zone:

First:  Return Specific Zone into a variable:
$myZone = Get-R53HostedZoneList | Where-Object -Property Name -Match "myDomain.org"

Second:  Using a specific zone, retrieve records putting them into a pscustomobject.
$myVar = $myZone | Get-R53ResourceRecordSet  | Show-R53Record
.EXAMPLE
HostedZoneID can be submitted manually if preferred:

$myVar = Get-R53ResourceRecordSet -HostedZoneId '/hostedzone/BigOldStringOfChars' | Show-R53Record
.LINK
Get-R53HostedZoneList
Get-R53ResourceRecordSet
#>

Function Show-R53Record
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Amazon.Route53.Model.ListResourceRecordSetsResponse] $RecordSets
    )

    Process
    {
        foreach ($rr in $RecordSets.ResourceRecordSets)
        {
            $lo = [aClass]::MakeR53Obj($rr)
            $lo
        }
    }
}

<#
.SYNOPSIS
Returns configuration information from VPC(s).
.DESCRIPTION
Returns a PSCUSTOMOBJECT of configuration information from VPC(s).
.NOTES
1) The object provided from Get-EC2Vpc is stored in the NoteProperty Object.
2) The Name NoteProperty will be empty if a VPC name has not been specified.
3) Tags can be seen by returning the object into a variable (e.g. $myVar), then $myVar.Tags
4) Optimal JSON output is demonstrated in Example 3.
.PARAMETER EC2Instance
Mandatory. Output from AWS Get-EC2Vpc (Module: AWS.Tools.EC2). See Examples.
[Amazon.EC2.Model.Vpc]
.INPUTS
AWS VPC from Get-EC2Vpc [Amazon.EC2.Model.Vpc]
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.AWS.VPC.Info
.EXAMPLE
Return a custom object from one VPC:
Get-EC2Vpc -VpcId vpc-77a1b77053c67aaaa | Show-EC2Vpc
.EXAMPLE
Return a custom object from two VPCs into a variable:
$myVar = Get-EC2Vpc -VpcId vpc-77a1b77053c67aaaa , vpc-77a1b77053c67bbbb  | Show-EC2Vpc
.EXAMPLE
Return a custom object from one VPC, converting the output to JSON:
$myVar = Get-EC2Vpc -VpcId vpc-77a1b77053c67aaaa | Show-EC2Vpc
$jVar = $myVar | Select-Object * -ExcludeProperty Object | ConvertTo-Json -Depth 4
.LINK
Get-EC2Vpc
#>

Function Show-EC2Vpc
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Amazon.EC2.Model.Vpc[]] $Vpc
    )

    Process
    {
        foreach ($vp in $vpc)
        {
            $dh = (Get-EC2VpcAttribute -VpcId $vp.vpcid -Attribute enableDnsHostnames).EnableDnsHostnames
            $ds = (Get-EC2VpcAttribute -VpcId $vp.vpcid -Attribute enableDnsSupport).EnableDnsSupport
            $vh = @{
                DnsHostNames = $dh
                DnsResolution = $ds
            }
            $lo = [aClass]::MakeVPCObj($vp , $vh)
            $lo
        }
    }
}