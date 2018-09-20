#==================================================================================
# Script: 	TestConnection.ps1
# Date:		12/07/18
# Author: 	Andi Patrick
# Purpose:	TestsConnection to a Given IP Address
#==================================================================================

# Named Parameters
param($IPAddress)

#Start by setting up API object.
$api = New-Object -comObject 'MOM.ScriptAPI'

#Create a property bag.
$bag = $api.CreatePropertyBag()


[int]$buffersize = 32
$buffer=([system.text.encoding]::ASCII).getbytes("a"*$buffersize)
$options = new-object system.net.networkinformation.pingoptions
$options.TTL = 10
$options.DontFragment = $DontFragment

[int]$IsAlive = 0
$ping = new-object system.net.networkinformation.ping

For ($i=0; $i -le 2; $i++) {
    try
    {
        $reply = $ping.Send($IPAddress,5,$buffer,$options)    
    }
    catch
    {
        $IsAlive = 0
    }

    if ($reply.status -eq "Success")
    {
        $IsAlive = 1
        Break
    }
}

# Add Result to Property Bag
$bag.AddValue('IsAlive', $IsAlive)

# Return Property Bag
#$api.Return($bag)
$bag