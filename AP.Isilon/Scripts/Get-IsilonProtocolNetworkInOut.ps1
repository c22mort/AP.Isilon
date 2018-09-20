#==================================================================================
# Script: 	Get-IsilonProtocolNetworkInOut.ps1
# Date:		03/08/18
# Author: 	Andi Patrick
# Purpose:	Uses SharpSnmpLib to get Isilon Protocol Network IO
#			Input/Output defined by Parameter
#			Returns Multiple PropertyBags, one per Disk
#==================================================================================
param($ClusterName,$NodeName,$NodeIP,$Community,$InOrOut)

#Constants used for event logging
$SCRIPT_NAME			= 'Get-IsilonProtocolNetworkInOut.ps1'
$EVENT_LEVEL_ERROR 		= 1
$EVENT_LEVEL_WARNING 	= 2
$EVENT_LEVEL_INFO 		= 4
$SCRIPT_STARTED			= 4661
$SCRIPT_ENDED			= 4662
$SCRIPT_ERROR			= 4663

# Load SharpSNMPLib
[reflection.assembly]::LoadFrom( (Resolve-Path "C:\PowershellSCOM\SNMP\SharpSnmpLib.dll") )

#Start by setting up API object.
$api = New-Object -comObject 'MOM.ScriptAPI'

# Log That Script Has Started
$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_STARTED,$EVENT_LEVEL_INFO,"Script Started `r`n Collecting Protocol Network $InOrOut IO for $ClusterName $NodeName ($NodeIP)")

# Use SNMP v2
$ver = [Lextm.SharpSnmpLib.VersionCode]::V2
$walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree

# Create endpoint for SNMP server
$ip = [System.Net.IPAddress]::Parse($NodeIP)
$svr = New-Object System.Net.IpEndPoint ($ip, 161)

# OIDs used
[string]$ProtocolNameOID = ".1.3.6.1.4.1.12124.2.2.10.1.1" # .iso.org.dod.internet.private.enterprises.isilon.node.nodePerformance.nodeProtocolPerfTable.nodeProtocolPerfEntry.protocolName
[string]$ProtocolInboundOID = ".1.3.6.1.4.1.12124.2.2.10.1.8" # .iso.org.dod.internet.private.enterprises.isilon.node.nodePerformance.nodeProtocolPerfTable.nodeProtocolPerfEntry.inBitsPerSecond
[string]$ProtocolOutboundOID = ".1.3.6.1.4.1.12124.2.2.10.1.13" # .iso.org.dod.internet.private.enterprises.isilon.node.nodePerformance.nodeProtocolPerfTable.nodeProtocolPerfEntry.outBitsPerSecond

Try {

    # Get Disk Bays via SNMP
    $ProtocolNameResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $ProtocolNameOID , $ProtocolNameResults, 10000, $walkMode)

    $ProtocolIOResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 

	if ($InOrOut.ToLower() -eq "inbound") {
	    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $ProtocolInboundOID , $ProtocolIOResults, 10000, $walkMode)		
	} else {
	    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $ProtocolOutboundOID , $ProtocolIOResults, 10000, $walkMode)		
	}

    # Loop through Results
    For($i=0; $i -lt $ProtocolNameResults.Count;$i++) {
		
		#Create a property bag.
		$bag = $api.CreatePropertyBag()
		
		# Get Properties
		[string]$ProtocolName = $ProtocolNameResults[$i].Data.ToString()
		[double]$ProtocolIO = [math]::Round([double]($ProtocolIOResults[$i].Data.ToString() / 1024 / 1024), 4)
		$bag.AddValue("ProtocolName", $ProtocolName)
		$bag.AddValue("Value", $ProtocolIO)
		#$api.Return($bag)
		$bag
	}
	
	# Log That Script Has Started
	$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ENDED,$EVENT_LEVEL_INFO,"Script Finished `r`n Collecting Protocol Network $InOrOut IO for $ClusterName $NodeName ($NodeIP)")

} Catch {
    # Log Error
    $api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ERROR,$EVENT_LEVEL_ERROR,"$ClusterName $NodeName ($NodeIP) $_")
    Return $null
}
