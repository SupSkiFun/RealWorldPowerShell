class aClass
{
    static $Type = 'A'

    static [PSCustomObject] MakeEC2IObj ([psobject] $obj )
    {
        $lo = [pscustomobject]@{
            Name = ($obj.Tags |
                Where-Object {$_.Key -match "Name"}).Value
            ID = $obj.InstanceId
            PrivateIP = $obj.PrivateIpAddress
            PublicIP = $obj.PublicIpAddress
            PublicDNS = $obj.PublicDnsName
            Type = $obj.InstanceType.Value
            SecurityGroupName = $obj.SecurityGroups.GroupName
            SecurityGroupID = $obj.SecurityGroups.GroupId
            Tags = $obj.Tags
            State = $obj.State.Name
            SubnetID = $obj.SubnetId
            VpcID = $obj.VpcId
            Object = $obj
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.AWS.EC2Instance.Info')
        return $lo
    }

    static [psobject] MakeR53Change ([string] $Action, [psobject] $rr)
    {
        $rc = [Amazon.Route53.Model.Change]::new()
        $rc.Action = $Action
        $rc.ResourceRecordSet = $rr
        return $rc
    }

    static [pscustomobject] MakeR53Obj ([psobject] $rs)
    {
        $lo = [pscustomobject]@{
            FQDN = $rs.Name
            IP = $rs.ResourceRecords.Value
            Type = $rs.Type
            TTL = $rs.TTL
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.AWS.R53.Record.Info')
        return $lo
    }

    static [pscustomobject] MakeR53Obj ([psobject] $rc, [psobject] $rv, [string] $HostedZoneId)
    {
        $lo = [pscustomobject]@{
            FQDN = $rc.ResourceRecordSet.Name
            IP = $rc.ResourceRecordSet.ResourceRecords.Value
            Action = $rc.Action
            Type = $rc.ResourceRecordSet.Type
            TTL = $rc.ResourceRecordSet.TTL
            ZoneID = $HostedZoneId
            JobID = $rv.ID
            Status = $rv.Status
            SubmittedAt = $rv.SubmittedAt
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.AWS.R53.A.Record.Info')
        return $lo
    }

    static [psobject] MakeR53ResRec ([string] $FQDN, [Int32] $TTL, [ipaddress] $IP)
    {
        $rr = [Amazon.Route53.Model.ResourceRecordSet]::new()
        $rr.Name = $FQDN
        $rr.Type = [aClass]::Type
        $rr.TTL = $TTL
        $rr.ResourceRecords.Add(@{Value = $IP})
        return $rr
    }

    static [PSCustomObject] MakeVPCObj ([psobject] $obj , [hashtable] $exh )
    {
        $lo = [pscustomobject]@{
            Name = ($obj.Tags |
                Where-Object {$_.Key -match "Name"}).Value
            CidrBlock = $obj.CidrBlock
            VpcID = $obj.VpcId
            DhcpOptionsId = $obj.DhcpOptionsId
            IsDefault = $obj.IsDefault
            State = $obj.State.Value
            Tags = $obj.Tags
            DnsHostNames = $exh.'DnsHostNames'
            DnsResolution = $exh.'DnsResolution'
            OwnerId = $obj.OwnerId
            Object = $obj
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.AWS.VPC.Info')
        return $lo
    }
}