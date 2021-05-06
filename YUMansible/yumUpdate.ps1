<#
    Needs Parameters, error checking, etc.  Working - fun test!
#>
$env:ANSIBLE_STDOUT_CALLBACK="json"
$pl =  ansible-playbook -i /home/ansible/YAML/hosts /home/ansible/YAML/yumUpdate.yml
$jj = $pl |
    ConvertFrom-Json
$jp = $jj.plays.tasks
foreach ($j in $jp)
{
    $th = ($j.hosts|
    Get-member -Type NoteProperty |
        Select-Object -Property Name).Name
    foreach ($t in $th)
    {
        $r1 = $jp.hosts.$t
        $lo = [PSCustomObject]@{
            HostName = $t
            Action = $r1.Action
            Changed = $r1.Changed
            Results = $r1.Results
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.Ansible.Yum.Info')
        $lo
    }
}