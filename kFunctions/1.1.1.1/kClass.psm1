class K8sAPI
{
    static $uria = 'apis/'

    static [psobject] GetApiInfo ( [string] $mainurl )
    {
        $apis =  Invoke-RestMethod -Method Get -Uri $mainurl
        return $apis
    }

    static [psobject] GetResourceInfo ( [string] $url )
    {
        $resq = Invoke-RestMethod -Method Get -Uri $url
        $resi = $resq.resources.Where({$_.name -notmatch "/"})
        return $resi
    }

    static [pscustomobject] MakeObj (
            [string] $nom ,
            [psobject] $grv ,
            [psobject] $res ,
            [string] $prv
        )
    {
        $gvv = $grv.groupVersion

        $lo = [PSCustomObject]@{
            GroupName = $nom
            GroupVersion = $gvv
            Version = $grv.version
            PreferredVersion = ( $prv -eq $gvv ? $true : $false )
            ResourceName = $res.name
            ResourceKind = $res.kind
            ShortName = $res.shortNames
            NameSpaced = $res.namespaced
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.Kubernetes.API.Info')
        return $lo
    }
}