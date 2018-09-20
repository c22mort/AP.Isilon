#==================================================================================
# Script: 	Discover-AmbientTempSensor.ps1
# Date:		03/08/18
# Author: 	Andi Patrick
# Purpose:	UsesSharpSnmpLib to get Discover Isilon AmbientTempSensor, returning as 
#           PropertyBag
#==================================================================================
param($SourceId,$ManagedEntityId,$NodeIP,$NodeName,$ClusterName,$Community)

#Constants used for event logging
$SCRIPT_NAME			= 'Discover-AmbientTempSensor.ps1'
$EVENT_LEVEL_ERROR 		= 1
$EVENT_LEVEL_WARNING 	= 2
$EVENT_LEVEL_INFO 		= 4
$SCRIPT_STARTED			= 4641
$SCRIPT_ENDED			= 4642
$SCRIPT_ERROR			= 4643

# Load SharpSNMPLib
[reflection.assembly]::LoadFrom( (Resolve-Path "C:\PowershellSCOM\SNMP\SharpSnmpLib.dll") )

#Start by setting up API object.
$api = New-Object -comObject 'MOM.ScriptAPI'
$discoveryData = $api.CreateDiscoveryData(0, $SourceId, $ManagedEntityId)

# Log That Script Has Started
$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_STARTED,$EVENT_LEVEL_INFO,"Script Started `r`n Discovering AmbientTempSensor for $ClusterName $NodeName ($NodeIP)")

# Use SNMP v2
$ver = [Lextm.SharpSnmpLib.VersionCode]::V2
$walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree


# Create endpoint for SNMP server
$ip = [System.Net.IPAddress]::Parse($NodeIP)
$svr = New-Object System.Net.IpEndPoint ($ip, 161)

# OIDs used
[string]$TempSensorNameOID = ".1.3.6.1.4.1.12124.2.54.1.2" # .iso.org.dod.internet.private.enterprises.isilon.node.tempSensorTable.tempSensorEntry.tempSensorName

Try {

    # Get TempSensor Names via SNMP
    $TempSensorNameResults = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]' 
    [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $TempSensorNameOID , $TempSensorNameResults, 3000, $walkMode)

    # Loop through Results
    For($i=0; $i -lt $TempSensorNameResults.Count;$i++) {

		# Get Properties
		[string]$TempSensorName = $TempSensorNameResults[$i].Data.ToString()
		[string]$TempSensorIndex = $TempSensorNameResults[$i].Id.ToString()
		$TempSensorIndex = $TempSensorIndex -replace $TempSensorNameOID.Trim('.'), ""
		$TempSensorIndex = $TempSensorIndex.Trim('.')

		if ($TempSensorName.ToLower() -like 'ambient_temp'  ){
		
			# Create an Isilon Disk instance for each Disk.
			$instance = $discoveryData.CreateClassInstance("$MPElement[Name='AP.Isilon.TempSensor']$")
			# Add DisplayName (System.Entity)
			$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $TempSensorName)
			# Add ClusterName (KEY Property of parent)
			$instance.AddProperty("$MPElement[Name='AP.Isilon.Cluster']/Name$", $ClusterName)
			# Add NodeName (KEY Property of parent)
			$instance.AddProperty("$MPElement[Name='AP.Isilon.Node']/Name$", $NodeName)

			# Add Our Properties
			$instance.AddProperty("$MPElement[Name='AP.Isilon.TempSensor']/Name$", $TempSensorName)
			$instance.AddProperty("$MPElement[Name='AP.Isilon.TempSensor']/Index$", [int]$TempSensorIndex)

			# Add Instance To DiscoveryDate
			$discoveryData.AddInstance($instance)
		}


    }

} Catch {
    # Log Error
    $api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ERROR,$EVENT_LEVEL_ERROR,"$ClusterName $NodeName ($NodeIP) $_")
    Return $null
}

#Return the discovery data.
$discoveryData

# Log That Script Has Finished
$api.LogScriptEvent($SCRIPT_NAME,$SCRIPT_ENDED,$EVENT_LEVEL_INFO,"Script Finished on $ClusterName $NodeName ($NodeIP)")
