#==================================================================================
# Script: 	Discover-IsilonDisks.ps1
# Date:		03/08/18
# Author: 	Andi Patrick
# Purpose:	UsesSharpSnmpLib to get Discover Isilon Disks, returning them as 
#           Multiple PropertyBags
#==================================================================================
param($SourceId,$ManagedEntityId,$NodeIP,$NodeName,$ClusterName,$Community)

#Constants used for event logging
$SCRIPT_NAME			= 'Discover-IsilonDisks.ps1'
$EVENT_LEVEL_ERROR 		= 1
$EVENT_LEVEL_WARNING 	= 2
$EVENT_LEVEL_INFO 		= 4
$SCRIPT_STARTED			= 4601
$SCRIPT_ENDED			= 4602
$SCRIPT_ERROR			= 4603

# Load SharpSNMPLib
[reflection.assembly]::LoadFrom( (Resolve-Path "C:\PowershellSCOM\SNMP\SharpSnmpLib.dll") )

#Start by setting up API object.
$api = New-Object -comObject 'MOM.ScriptAPI'
$discoveryData = $api.CreateDiscoveryData(0, $SourceId, $ManagedEntityId)

# Log That Script Has Started
$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_STARTED,$EVENT_LEVEL_INFO,"Script Started `r`n Discovering Disks for $ClusterName $NodeName ($NodeIP)")

# Use SNMP v2
$ver = [Lextm.SharpSnmpLib.VersionCode]::V2
$walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree


# Create endpoint for SNMP server
$ip = [System.Net.IPAddress]::Parse($NodeIP)
$svr = New-Object System.Net.IpEndPoint ($ip, 161)

# OIDs used
[string]$DiskBayOID = ".1.3.6.1.4.1.12124.2.52.1.1" # .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskBay
[string]$DeviceNameOID = ".1.3.6.1.4.1.12124.2.52.1.4" # .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskDeviceName
[string]$ModelNumberOID = ".1.3.6.1.4.1.12124.2.52.1.6" # .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskModel
[string]$SerialNumberOID = ".1.3.6.1.4.1.12124.2.52.1.7" # .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskSerialNumber
[string]$FirmwareVersionOID = ".1.3.6.1.4.1.12124.2.52.1.8" # .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskFirmwareVersion
[string]$DiskSizeOID = ".1.3.6.1.4.1.12124.2.52.1.9" # .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskSizeBytes

Try {

    # Get Disk Bays via SNMP
    $DiskBayResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $DiskBayOID , $DiskBayResults, 3000, $walkMode)

    # Get Disk DeviceName via SNMP
    $DeviceNameResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $DeviceNameOID , $DeviceNameResults, 3000, $walkMode)

    # Get Disk ModelNumber via SNMP
    $ModelNumberResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $ModelNumberOID , $ModelNumberResults, 3000, $walkMode)

    # Get Disk SerialNumber via SNMP
    $SerialNumberResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $SerialNumberOID , $SerialNumberResults, 3000, $walkMode)

    # Get Disk FirmwareVersion via SNMP
    $FirmwareVersionResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $FirmwareVersionOID , $FirmwareVersionResults, 3000, $walkMode)

    # Get Disk DiskSize via SNMP
    $DiskSizeResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $DiskSizeOID , $DiskSizeResults, 3000, $walkMode)

    # Loop through Results
    For($i=0; $i -lt $DiskBayResults.Count;$i++) {

		# Get Properties
		[int]$DiskIndex= [int]$DiskBayResults[$i].Data.ToString()
		[string]$DiskName = "Disk$DiskIndex"
        [string]$DeviceName = $DeviceNameResults[$i].Data.ToString()
        [string]$ModelNumber = $ModelNumberResults[$i].Data.ToString()
        [string]$SerialNumber = $SerialNumberResults[$i].Data.ToString()
        [string]$FirmwareVersion = $FirmwareVersionResults[$i].Data.ToString()
        [uint64]$DiskSize = [uint64]$DiskSizeResults[$i].Data.ToString() / 1000000000

		# Convert SATA Disks to 8 times reported size
		if ($ModelNumber.StartsWith("HUS")) {$DiskSize = ($DiskSize * 8)}

		# Create an Isilon Disk instance for each Disk.
		$instance = $discoveryData.CreateClassInstance("$MPElement[Name='AP.Isilon.Disk']$")
		# Add DisplayName (System.Entity)
		$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $DiskName)
		# Add ClusterName (KEY Property of parent)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Cluster']/Name$", $ClusterName)
		# Add NodeName (KEY Property of parent)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Node']/Name$", $NodeName)

		# Add Our Properties
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Disk']/Index$", $DiskIndex)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Disk']/Name$", $DiskName)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Disk']/DeviceName$", $DeviceName)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Disk']/ModelNumber$", $ModelNumber)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Disk']/SerialNumber$", $SerialNumber)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Disk']/FirmwareVersion$", $FirmwareVersion)
		$instance.AddProperty("$MPElement[Name='AP.Isilon.Disk']/Size$", $DiskSize)

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
$DisksDiscovered = $DiskBayResults.Count
$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ENDED,$EVENT_LEVEL_INFO,"Script Finished `r`n $DisksDiscovered Disks Discovered on $ClusterName $NodeName ($NodeIP)")
