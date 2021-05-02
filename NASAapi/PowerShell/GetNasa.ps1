class NasaFun
{
    static [double] GetAverage ( [psobject] $obj )
    {
        $avg = ($obj.psobject.properties.Value |
            Measure-Object -Average).Average
        return [Math]::Round($avg , 5)
    }

    static [pscustomobject] MakeObj ( [psobject] $obj )
    {
        $cad = $obj.close_approach_data[0]
        $lo = [pscustomobject]@{
            Name = $obj.name
            ID = $obj.id
            PotentiallyHazardous = $obj.is_potentially_hazardous_asteroid
            CloseApproachDateTime = $cad.close_approach_date_full
            MissDistanceInKM = [Math]::Round($cad.miss_distance.kilometers,5)
            AbsoluteMagnitudeH = $obj.absolute_magnitude_h
            DiameterInMeters = [NasaFun]::GetAverage($obj.estimated_diameter.meters)
            VelocityInKMpH = [Math]::Round($cad.relative_velocity.kilometers_per_hour,5)
            URL = $obj.nasa_jpl_url
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.NASA.Asteroid.Info')
        return $lo
    }
}

Function MakeDate
{
    <#
        PowerShell 7 can shorten to (Get-Date -UFormat "%F") ; below works for 5 or 7.
    #>
    Get-Date -UFormat %Y-%m-%d
}

Function SetConfig
{
    $apj = "application/json"
    $key = $env:NASA_API_KEY
    #$key = 'HARD_CODED_KEY_HERE'  if not using environment (line above)
    $script:url = 'https://api.nasa.gov/neo/rest/v1/feed'
    $script:hoy = MakeDate
    $script:msg = "Terminating.  Problem Accessing "+$url+" the below URL for asteroid information:"
    $script:heads = @{
        "Content-Type" =  $apj ;
        "Accept" = $apj
    }
    $script:params = @{
        "api_key"    = $key ;
        "start_date" = $hoy ;
        "end_date"   = $hoy
    }
}

Function GetInfo
{
    try
    {
        $res = Invoke-RestMethod -Method Get -Uri $url -Headers $heads -Body $params -ErrorVariable err
        $res.near_earth_objects.$hoy
    }
    catch
    {
        Write-Output $msg , $err.Message
        break
    }
}

Function ProcInfo
{
    Param($resp)
    foreach ($r in $resp)
    {
        $lo = [NasaFun]::MakeObj($r)
        $lo
    }
}

SetConfig
ProcInfo(GetInfo)