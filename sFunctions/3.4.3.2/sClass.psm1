class sClass
{
    static [pscustomobject] GetProtGrpInfo ([psobject] $pgrp)
    {
        $pgpn = $null
        $pgnm = $pgrp.GetInfo().Name.ToString()
        $pgvm = $pgrp.ListProtectedVms()
        $pgcn = $pgvm.Where({$_.NeedsConfiguration -eq $true}).VmName
        $pgfl = $pgvm.Where({$null -ne $_.Faults}).VmName
        $pgok = $pgrp.CheckConfigured()
        $pgst = $pgrp.GetProtectionState().ToString()

        switch ($pgok)
        {
            {$_ -eq $false -and $pgst -ne 'Shadowing'}
            {
                $pgpn = [sClass]::GetUnProtVM( ($pgrp.ListProtectedDatastores().Moref) , ($pgvm.VmName) )    #Change
                break
            }

            {$_ -eq $false -and $pgst -eq 'Shadowing'}
            {
                $pgpn = "See Help"
                break
            }
        }

        $lo = [pscustomobject]@{
            Name = $pgnm
            State = $pgst
            ConfigOK = $pgok
            ConfigNeeded = $pgcn
            ProtectionNeeded = $pgpn
            Faults = $pgfl
        }
        return $lo
    }

    static [psobject] GetUnProtVM ( [psobject] $pgds , [psobject] $pgvn )
    {
        $dss = Get-Datastore -id $pgds
        $vms = (Get-VM -Datastore $dss).Name
        $npt = $vms.Where({$pgvn -notcontains $_})

        if ($npt)
        {
            return $npt
        }
        else
        {
            return $null
        }
    }

    static [hashtable] MakeHash( [string] $quoi )
    {
        $src = $null
        $shash = @{}

        switch ($quoi)
        {
            ds { $src = Get-Datastore -Name * }
            ex { $src = Get-VMHost -Name * }
            vm { $src = Get-VM -Name * }
        }

        foreach ($s in $src)
        {
            $shash.add($s.Id , $s.Name)
        }
        return $shash
    }

    static [hashtable] MakePgHash ([psobject] $pgroups )
    {
        $pghash = @{}
        foreach ($p in $pgroups)
        {
            $pghash.Add($p.ListProtectedDatastores().Moref,$p)
        }
        return $pghash
    }

    static [pscustomobject] MakeObj( [string] $reason , [string] $VMname, [string] $VMmoref )
    {
        $nil = "None"
        $lo = [pscustomobject]@{
            VM = $VMname
            VMMoRef = $VMmoref
            Status = "Not Attempted. "+$reason
            Error = $nil
            Task = $nil
            TaskMoRef = $nil
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protect.Info')
        return $lo
    }

    static [pscustomobject] MakeObj( [psobject] $protstat , [string] $VMname, [string] $VMmoref , [string] $VMdsName)
    {
        $lo = [pscustomobject]@{
            VM = $VMname
            VMMoRef = $VMmoref
            Status = $protstat.Status.ToString()
            DataStore = $VMdsName
            ProtectionGroup = $protstat.ProtectionGroupName
            RecoveryPlan = $protstat.RecoveryPlanNames
            ProtectedVm	= $protstat.ProtectedVm
            PeerProtectedVm = $protstat.PeerProtectedVm
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.VM.Info')
        return $lo
    }

    static [pscustomobject] MakeObj( [string] $reason , [string] $VMname, [string] $VMmoref , [string] $VMdsName , [string] $nd )
    {
        $lo = [pscustomobject]@{
            VM = $VMname
            VMMoRef = $VMmoref
            Status = "Not Attempted. "+$reason
            DataStore = $VMdsName
            ProtectionGroup = $nd
            RecoveryPlan = $nd
            ProtectedVm	= $nd
            PeerProtectedVm = $nd
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.VM.Info')
        return $lo
    }

    static [pscustomobject] MakePGInfoObj ( [psobject] $pg )
    {
        $pginfo = $pg.GetInfo()
        $pgvms = $pg.ListProtectedVms().VMName
        $vmpgcnt = $pgvms.count

        $lo = [pscustomobject] @{
            ProtectionGroup = $pginfo.Name
            Description = $pginfo.Description
            Configured = $pg.CheckConfigured()
            State = $pg.GetProtectionState().ToString()
            Type = $pginfo.Type.ToString()
            Category = $pg.GetType().Name
            VMCount = $vmpgcnt
            VMNames = $pgvms
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protection.Group.Info')
        return $lo
    }

    static [pscustomobject] MakeRPInfoObj ( [psobject] $rp )
    {
        $arr1 = [System.Collections.Arraylist]::new()
        $arr2 = [System.Collections.Arraylist]::new()
        [int] $rpvmcnt = 0
        $rpinfo = $rp.GetInfo()
        $prgcnt = $rpinfo.ProtectionGroups.Count
        foreach ($pg in $rpinfo.ProtectionGroups)
        {
            $pgo = [sClass]::MakePGInfoObj($pg)
            $arr1.add($pgo)
            $qpg = [sClass]::QueryPGObj($pgo)
            $rpvmcnt += $qpg.Count
            if ($qpg.Name)
            {
                $arr2.add($qpg.Name)
            }
        }

        if ( $arr2 )
        {
            $MTpg = $true
        }
        elseif ($prgcnt -eq 0)
        {
            $MTpg = "NoProtectionGroupsExist"
        }
        else
        {
            $MTpg = $false
        }

        $lo = [pscustomobject]@{
            RecoveryPlan = $rpinfo.Name
            Description = $rpinfo.Description
            State = $rpinfo.State.ToString()
            Type = $rp.GetType().Name.ToString()
            RecoveryPlanVMCount = $rpvmcnt
            EmptyProtectionGroup = $MTpg
            EmptyProtectionGroupName = $arr2
            ProtectionGroupCount = $prgcnt
            ProtectionGroups = $arr1
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Recovery.Plan.Info')
        return $lo
    }

    static [hashtable] QueryPGObj ( [psobject] $pgo )
    {
        $nom = ""
        $vmc = $pgo.VMCount
        if ($vmc -eq 0)
        {
            $nom = $pgo.ProtectionGroup
        }
        $hash = @{
            Name = $nom
            Count = $vmc
        }
        return $hash
    }
}
