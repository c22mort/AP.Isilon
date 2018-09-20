#==================================================================================
# Script: 	Get-IsilonDiskIO.ps1
# Date:		03/08/18
# Author: 	Andi Patrick
# Purpose:	Uses SharpSnmpLib to get Isilon Disk IO
#			Read/Write defined by Parameter
#			Returns Multiple PropertyBags, one per Disk
#==================================================================================
param($ClusterName,$NodeName,$NodeIP,$Community,$ReadOrWrite)

#Constants used for event logging
$SCRIPT_NAME			= 'Get-IsilonDiskIO.ps1'
$EVENT_LEVEL_ERROR 		= 1
$EVENT_LEVEL_WARNING 	= 2
$EVENT_LEVEL_INFO 		= 4
$SCRIPT_STARTED			= 4651
$SCRIPT_ENDED			= 4652
$SCRIPT_ERROR			= 4653

# Load SharpSNMPLib
[reflection.assembly]::LoadFrom( (Resolve-Path "C:\PowershellSCOM\SNMP\SharpSnmpLib.dll") )

#Start by setting up API object.
$api = New-Object -comObject 'MOM.ScriptAPI'

# Log That Script Has Started
$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_STARTED,$EVENT_LEVEL_INFO,"Script Started `r`n Collecting Disk $ReadorWrite IO for $ClusterName $NodeName ($NodeIP)")

# Use SNMP v2
$ver = [Lextm.SharpSnmpLib.VersionCode]::V2
$walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree

# Create endpoint for SNMP server
$ip = [System.Net.IPAddress]::Parse($NodeIP)
$svr = New-Object System.Net.IpEndPoint ($ip, 161)

# OIDs used
[string]$DiskBayOID = ".1.3.6.1.4.1.12124.2.2.52.1.1" # .iso.org.dod.internet.private.enterprises.isilon.node.nodePerformance.diskPerfTable.diskPerfEntry.diskPerfBay
[string]$DiskReadOID = ".1.3.6.1.4.1.12124.2.2.52.1.5" # .iso.org.dod.internet.private.enterprises.isilon.node.nodePerformance.diskPerfTable.diskPerfEntry.diskPerfOutBitsPerSecond
[string]$DiskWriteOID = ".1.3.6.1.4.1.12124.2.2.52.1.4" # .iso.org.dod.internet.private.enterprises.isilon.node.nodePerformance.diskPerfTable.diskPerfEntry.diskPerfInBitsPerSecond

Try {

    # Get Disk Bays via SNMP
    $DiskBayResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $DiskBayOID , $DiskBayResults, 10000, $walkMode)

    $DiskIOResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 

	if ($ReadOrWrite.ToLower() -eq "read") {
	    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $DiskReadOID , $DiskIOResults, 10000, $walkMode)		
	} else {
	    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $DiskWriteOID , $DiskIOResults, 10000, $walkMode)		
	}

    # Loop through Results
    For($i=0; $i -lt $DiskBayResults.Count;$i++) {
		
		#Create a property bag.
		$bag = $api.CreatePropertyBag()
		
		# Get Properties
		[int]$DiskIndex = [int]$DiskBayResults[$i].Data.ToString()
		[double]$DiskIO = [math]::Round([double]($DiskIOResults[$i].Data.ToString() / 1024 / 8), 4)
		
		$bag.AddValue("DiskIndex", $DiskIndex)
		$bag.AddValue("Value", $DiskIO)
		#$api.Return($bag)
		$bag
	}
	
	# Log That Script Has Started
	$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ENDED,$EVENT_LEVEL_INFO,"Script Finished `r`n Collecting Disk $ReadorWrite IO for $ClusterName $NodeName ($NodeIP)")

} Catch {
    # Log Error
    $api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ERROR,$EVENT_LEVEL_ERROR,"$ClusterName $NodeName ($NodeIP) $_")
    Return $null
}
