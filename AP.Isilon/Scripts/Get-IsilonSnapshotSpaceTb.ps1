#==================================================================================
# Script: 	Get-IsilonSnapshotSpaceTb.ps1
# Date:		03/08/18
# Author: 	Andi Patrick
# Purpose:	Uses SharpSnmpLib to get Isilon Cluster Snapshot space used, 
#			returniing as PropertyBag
#==================================================================================
param($ClusterIP,$ClusterName,$Community)

#Constants used for event logging
$SCRIPT_NAME			= 'Get-IsilonSnapshotSpaceTb.ps1'
$EVENT_LEVEL_ERROR 		= 1
$EVENT_LEVEL_WARNING 	= 2
$EVENT_LEVEL_INFO 		= 4
$SCRIPT_STARTED			= 4621
$SCRIPT_ENDED			= 4622
$SCRIPT_ERROR			= 4623

# Load SharpSNMPLib
[reflection.assembly]::LoadFrom( (Resolve-Path "C:\PowershellSCOM\SNMP\SharpSnmpLib.dll") )

#Start by setting up API object.
$api = New-Object -comObject 'MOM.ScriptAPI'

# Log That Script Has Started
$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_STARTED,$EVENT_LEVEL_INFO,"Script Started `r`n Discovering Snapshot Space for $ClusterName ($ClusterIP)")

# Use SNMP v2
$ver = [Lextm.SharpSnmpLib.VersionCode]::V2
$walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree

# Create endpoint for SNMP server
$ip = [System.Net.IPAddress]::Parse($ClusterIP)
$svr = New-Object System.Net.IpEndPoint ($ip, 161)

# OIDs used
[string]$SnapshotsOID = ".1.3.6.1.4.1.12124.1.13.3.1.5" # .iso.org.dod.internet.private.enterprises.isilon.cluster.snapshots.snapshotTable.snapshotEntry

Try {

    # Get Disk Bays via SNMP
    $SnapshotResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $SnapshotsOID , $SnapshotResults, 10000, $walkMode)

	[double]$TotalSnapshotSpace = 0

    # Loop through Results
    For($i=0; $i -lt $SnapshotResults.Count;$i++) {

		# Get Properties
		[uint64]$SnapshotSize = [uint64]$SnapShotResults[$i].Data.ToString()
		$TotalSnapshotSpace = $TotalSnapshotSpace + [double]($SnapshotSize / 1000000000000)
    }

} Catch {
    # Log Error
    $api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ERROR,$EVENT_LEVEL_ERROR,"$ClusterName ($ClusterIP) $_")
    Return $null
}

#Create a property bag.
$bag = $api.CreatePropertyBag()
		
# Add Result to Property Bag
$bag.AddValue("TotalSnapshotSpace", [math]::Round($TotalSnapshotSpace, 2))

#Return the PropertyBag.
#$api.Return($bag)
$bag

# Log That Script Has Finished
$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ENDED,$EVENT_LEVEL_INFO,"Script Finished `r`n Discovering Snapshot Space on $ClusterName ($ClusterIP)")