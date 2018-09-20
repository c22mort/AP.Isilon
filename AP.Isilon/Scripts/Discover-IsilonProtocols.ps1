#==================================================================================
# Script: 	Discover-IsilonProtocols.ps1
# Date:		03/08/18
# Author: 	Andi Patrick
# Purpose:	UsesSharpSnmpLib to get Discover Isilon Protocols, returning them as 
#           Multiple PropertyBags
#==================================================================================
param($SourceId,$ManagedEntityId,$NodeIP,$NodeName,$ClusterName,$Community)

#Constants used for event logging
$SCRIPT_NAME			= 'Discover-IsilonDisks.ps1'
$EVENT_LEVEL_ERROR 		= 1
$EVENT_LEVEL_WARNING 	= 2
$EVENT_LEVEL_INFO 		= 4
$SCRIPT_STARTED			= 4611
$SCRIPT_ENDED			= 4612
$SCRIPT_ERROR			= 4613

# Load SharpSNMPLib
[reflection.assembly]::LoadFrom( (Resolve-Path "C:\PowershellSCOM\SNMP\SharpSnmpLib.dll") )

#Start by setting up API object.
$api = New-Object -comObject 'MOM.ScriptAPI'
$discoveryData = $api.CreateDiscoveryData(0, $SourceId, $ManagedEntityId)

# Log That Script Has Started
$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_STARTED,$EVENT_LEVEL_INFO,"Script Started `r`n Discovering Protocols for $ClusterName $NodeName ($NodeIP)")

# Use SNMP v2
$ver = [Lextm.SharpSnmpLib.VersionCode]::V2
$walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree


# Create endpoint for SNMP server
$ip = [System.Net.IPAddress]::Parse($NodeIP)
$svr = New-Object System.Net.IpEndPoint ($ip, 161)

# OIDs used
[string]$ProtocolsOID = ".1.3.6.1.4.1.12124.2.2.10.1.1" # .iso.org.dod.internet.private.enterprises.isilon.node.nodePerformance.nodeProtocolPerfTable.nodeProtocolPerfEntry.protocolName

Try {

    # Get Disk Bays via SNMP
    $ProtocolResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $ProtocolsOID , $ProtocolResults, 3000, $walkMode)


    # Loop through Results
    For($i=0; $i -lt $ProtocolResults.Count;$i++) {

		# Get Properties
		[string]$ProtocolName=[string]$ProtocolResults[$i].Data.ToString()
		# Calculate OidSuffix
		[string]$ProtocolOidSuffix = [string]$ProtocolResults[$i].Id.ToString()
		$ProtocolOidSuffix = $ProtocolOidSuffix -replace $ProtocolsOID.Trim("."), ""


		# Create an Isilon Protocol instance for each Protocol.
		$instance = $discoveryData.CreateClassInstance("$MPElement[Name='AP.Isilon.Protocol']$")
		# Add DisplayName (System.Entity)
		$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $ProtocolName)
		# Add ClusterName (KEY Property of parent)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Cluster']/Name$", $ClusterName)
		# Add NodeName (KEY Property of parent)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Node']/Name$", $NodeName)

		# Add Our Properties
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Protocol']/Name$", $ProtocolName)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Protocol']/OidSuffix$", $ProtocolOidSuffix)

		# Add Instance To DiscoveryDate
		$discoveryData.AddInstance($instance)

    }

} Catch {
    # Log Error
    $api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ERROR,$EVENT_LEVEL_ERROR,"$ClusterName $NodeName ($NodeIP) $_")
    Return $null
}

#Return the discovery data.
$discoveryData

# Log That Script Has Finished
$ProtocolsDiscovered = $ProtocolResults.Count
$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ENDED,$EVENT_LEVEL_INFO,"Script Finished `r`n $ProtocolsDiscovered Protocols Discovered on $ClusterName $NodeName ($NodeIP)")
