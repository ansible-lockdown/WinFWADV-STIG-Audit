[CmdletBinding()]
param (
      [string] $group,
      [string] $outfile
)


# Set Variables for Audit
$BENCHMARK = "STIG"
$AUDIT_BIN = "C:\vagrant\goss.exe"
$AUDIT_FILE = "WNFWA\goss.yml"
$AUDIT_VARS = "WNFWA\$BENCHMARK.yml"
$AUDIT_CONTENT_LOCATION = "C:\vagrant"
$AUDIT_CONTENT_VERSION = "WNFWA-$BENCHMARK-Audit"
$AUDIT_CONTENT_DIR = "$AUDIT_CONTENT_LOCATION\$AUDIT_CONTENT_VERSION"
$AUDIT_OUTPUT = "$AUDIT_CONTENT_LOCATION\audit_$os_hostname_$epoch.json"

# Allow Alpha version to run
$env:GOSS_USE_ALPHA=1

# Discover if workstation
$ostypecode=(Get-WmiObject -Class Win32_OperatingSystem).ProductType
if (ostypecode -ne 3){
    $OS_TYPE=Server
}
else{
    $OS_TYPE=Workstation
}


# Epoch time is required (as per Unix based from UTC)
$audit_time = ([Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s")))

# output file

# Set up AUDIT_OUT
#$outfile
if ([string]::IsNullOrEmpty($outfile)){
    $AUDIT_OUT = "$AUDIT_OUTPUT"
    }
else {
    $AUDIT_OUT = "$outfile"
    }

$AUDIT_ERR = "$AUDIT_CONTENT_LOCATION\audit_$os_hostname_$epoch.err"

# create empty file - dont output
New-Item -ItemType file $AUDIT_OUT | Out-Null
New-Item -ItemType file $AUDIT_ERR | Out-Null

# Set up config

$domain_member=(Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
$domain_policy_enable=(Get-ItemProperty  HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile).PSObject.Properties.Name -contains 'EnableFirewall'
$private_policy_enable=(Get-ItemProperty  HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile).PSObject.Properties.Name -contains 'EnableFirewall'
$public_policy_enable=(Get-ItemProperty  HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile).PSObject.Properties.Name -contains 'EnableFirewall'

$os_name=((Get-CimInstance -ClassName CIM_OperatingSystem).Caption ) -replace ' ','_'
$machine_uuid=(Get-CimInstance -Class Win32_ComputerSystemProduct).UUID
$epoch=$audit_time
$os_locale=((Get-TimeZone).Id) -replace ' ','_'
$os_version=(([System.Environment]::OSVersion.Version).build)
$os_hostname=(hostname)
$system_type="$OS_TYPE"


$AUDIT_JSON_VARS = "{ 'benchmark':`'$BENCHMARK`','machine_uuid': `'$machine_uuid`','epoch': `'$epoch`', 'os_deployment_type': `'$system_type`',  'os_locale': `'$os_locale`', 'os_release': `'$os_version`', 'os_distribution': `'$os_name`', 'os_hostname': `'$os_hostname`', 'auto_group': `'$auto_group`', 'domain_member': `'$domain_member`'}"

# run audit
# appears when parent job exits before children - the goss run is typical of this behaviour

# This runs the job, waits for its children to complete and outputs to file
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "$AUDIT_BIN"
$pinfo.RedirectStandardError = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.UseShellExecute = $false
$pinfo.Arguments = "--gossfile $AUDIT_CONTENT_DIR\$AUDIT_FILE --vars $AUDIT_CONTENT_DIR\$AUDIT_VARS  --vars-inline `"$AUDIT_JSON_VARS`" v --format json --format-options pretty"
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()
$p.WaitForExit()


# Write to relevant output to file
Write-Output "$stdout" | Out-File -FilePath "$AUDIT_OUT"
Write-Output "$stderr" | Out-File -FilePath "$AUDIT_ERR"

# Summary of Output

if ( Select-String $BENCHMARK $AUDIT_OUT )
    { 
       $audit_summary=Get-Content "$AUDIT_OUT" -tail 8
       Write-Host "Audit Successful`n"
       Write-Host "$audit_summary"
       Write-Host "`nComplete audit file can be found at $AUDIT_OUT"
    }
else
    {
       Write-Host "Fail Audit - There were issues when running the audit please investigate $AUDIT_OUT" 
    }