#==================================================================================
# Script: 	Monitor-IsilonLicences.ps1
# Date:		03/08/18
# Author: 	Andi Patrick
# Purpose:	UsesSharpSnmpLib to get Get Isilon licences, returning them as 
#           Multiple PropertyBags (SUPPORTS COOKDOWN)
#==================================================================================
param($ClusterIP,$ClusterName,$Community)

#Constants used for event logging
$SCRIPT_NAME			= 'Monitor-IsilonLicences.ps1'
$EVENT_LEVEL_ERROR 		= 1
$EVENT_LEVEL_WARNING 	= 2
$EVENT_LEVEL_INFO 		= 4
$SCRIPT_STARTED			= 4631
$SCRIPT_ENDED			= 4632
$SCRIPT_ERROR			= 4633

# Load SharpSNMPLib
[reflection.assembly]::LoadFrom( (Resolve-Path "C:\PowershellSCOM\SNMP\SharpSnmpLib.dll") )

#Start by setting up API object.
$api = New-Object -comObject 'MOM.ScriptAPI'

# Log That Script Has Started
$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_STARTED,$EVENT_LEVEL_INFO,"Script Started `r`n Monitoring Licences for $ClusterName ($ClusterIP)")

# Use SNMP v2
$ver = [Lextm.SharpSnmpLib.VersionCode]::V2
$walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree

# Create endpoint for SNMP server
$ip = [System.Net.IPAddress]::Parse($ClusterIP)
$svr = New-Object System.Net.IpEndPoint ($ip, 161)

# OIDs used
[string]$LicenceNamesOID = ".1.3.6.1.4.1.12124.1.5.1.1.2" # .iso.org.dod.internet.private.enterprises.isilon.cluster.licenses.licenseTable.licenseEntry.licenseModuleName
[string]$LicenceStatusOID = ".1.3.6.1.4.1.12124.1.5.1.1.3" # .iso.org.dod.internet.private.enterprises.isilon.cluster.licenses.licenseTable.licenseEntry.licenseStatus

Try {

    # Get Licence Names via SNMP
    $LicenceNameResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $LicenceNamesOID , $LicenceNameResults, 3000, $walkMode)
    # Get Licence Status via SNMP
    $LicenceStatusResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $LicenceStatusOID , $LicenceStatusResults, 3000, $walkMode)


    # Loop through Results
    For($i=0; $i -lt $LicenceNameResults.Count;$i++) {

		# Get Properties
        [string]$LicenceName = $LicenceNameResults[$i].Data.ToString()
        [int]$LicenceStatusIndex = $LicenceStatusResults[$i].Data.ToString()
		[string]$LicenceHealth = ""
        switch ($LicenceStatusIndex)
        {
            -2 {$LicenceHealth = "UNHEALTHY"}
            -1 {$LicenceHealth = "UNHEALTHY"}
            0 {$LicenceHealth = "HEALTHY"}
            1 {$LicenceHealth = "HEALTHY"}
        }

		#Create a property bag.
		$bag = $api.CreatePropertyBag()

		# Add Result to Property Bag
		$bag.AddValue("LicenceName", $LicenceName)
		$bag.AddValue("LicenceHealth", $LicenceHealth)

		#Return the PropertyBag.
		#$api.Return($bag)
		$bag
    }
	
	$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ENDED,$EVENT_LEVEL_INFO,"Script Finished on $ClusterName ($ClusterIP)")

} Catch {
    # Log Error
    Write-Host $_
    $api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ERROR,$EVENT_LEVEL_ERROR,"$ClusterName ($ClusterIP) $_")
    Return $null
}

