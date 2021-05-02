Function InstallVIB
{
	$ww = Get-VMHost -Name $vmh[0]
	$rr = $ww |
		Get-VIB -Name NetAppNasPlugin -ErrorAction SilentlyContinue
	if (-not ($rr))
	{
		$ww |
			Install-VIB -URL $vurl -Confirm:$false
	}
}