#==================================================================================
# Script: 	Discover-IsilonLicences.ps1
# Date:		03/08/18
# Author: 	Andi Patrick
# Purpose:	UsesSharpSnmpLib to get Discover Isilon Licences, returning them as 
#           Multiple Discovery Insances
#==================================================================================
param($SourceId,$ManagedEntityId,$ClusterIP,$ClusterName,$Community)

#Constants used for event logging
$SCRIPT_NAME			= 'Discover-IsilonLicences.ps1'
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
$discoveryData = $api.CreateDiscoveryData(0, $SourceId, $ManagedEntityId)

# Log That Script Has Started
$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_STARTED,$EVENT_LEVEL_INFO,"Script Started `r`n Discovering Licences for $ClusterName ($ClusterIP)")

# Use SNMP v2
$ver = [Lextm.SharpSnmpLib.VersionCode]::V2
$walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree

# Create endpoint for SNMP server
$ip = [System.Net.IPAddress]::Parse($ClusterIP)
$svr = New-Object System.Net.IpEndPoint ($ip, 161)

# OIDs used
[string]$LicenceNamesOID = ".1.3.6.1.4.1.12124.1.5.1.1.2" # .iso.org.dod.internet.private.enterprises.isilon.cluster.licenses.licenseTable.licenseEntry.licenseModuleName
[string]$LicenceStatusOID = ".1.3.6.1.4.1.12124.1.5.1.1.3" # .iso.org.dod.internet.private.enterprises.isilon.cluster.licenses.licenseTable.licenseEntry.licenseStatus
[string]$LicenceExpirationOID = ".1.3.6.1.4.1.12124.1.5.1.1.4" # .iso.org.dod.internet.private.enterprises.isilon.cluster.licenses.licenseTable.licenseEntry.licenseExpirationDate

Try {

    # Get Licence Names via SNMP
    $LicenceNameResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $LicenceNamesOID , $LicenceNameResults, 3000, $walkMode)
    # Get Licence Status via SNMP
    $LicenceStatusResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $LicenceStatusOID , $LicenceStatusResults, 3000, $walkMode)
    # Get Licence ExpirationDate via SNMP
    $LicenceExpirationResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $LicenceExpirationOID , $LicenceExpirationResults, 3000, $walkMode)


    # Loop through Results
    For($i=0; $i -lt $LicenceNameResults.Count;$i++) {

		# Get Properties
        [string]$LicenceName = $LicenceNameResults[$i].Data.ToString()
        [int]$LicenceStatusIndex = $LicenceStatusResults[$i].Data.ToString()
        [string]$LicenceStatus = ""
        switch ($LicenceStatusIndex)
        {
            -2 {$LicenceStatus = "Inactive"}
            -1 {$LicenceStatus = "Expired"}
            0 {$LicenceStatus = "Activated"}
            1 {$LicenceStatus = "Evaluation"}
        }
        [uint64]$LicenceExpirationUnixEpoch = $LicenceExpirationResults[$i].Data.ToString()
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        [datetime]$LicenceExpiration = $origin.AddSeconds($LicenceExpirationUnixEpoch)

		# Create an Isilon Licence instance for each Licence.
		$instance = $discoveryData.CreateClassInstance("$MPElement[Name='AP.Isilon.Licence']$")
		# Add DisplayName (System.Entity)
		$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $LicenceName)
		# Add ClusterName (KEY Property of parent)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Cluster']/Name$", $ClusterName)

		# Add Licence Properties to Licence instance
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Licence']/Name$", $LicenceName)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Licence']/Status$", $LicenceStatus)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Licence']/ExpirationDate$", $LicenceExpiration)
		# Add Instance To DiscoveryDate
		$discoveryData.AddInstance($instance)

    }
	
	#Return the discovery data.
	$discoveryData

	# Log That Script Has Finished
	$LicencesDiscovered = $LicenceNameResults.Count
	$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ENDED,$EVENT_LEVEL_INFO,"Script Finished `r`n $LicencesDiscovered Licences Discovered on $ClusterName ($ClusterIP)")

} Catch {
    # Log Error
    Write-Host $_
    $api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ERROR,$EVENT_LEVEL_ERROR,"$ClusterName ($ClusterIP) $_")
    Return $null
}

