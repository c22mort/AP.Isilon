#==================================================================================
# Script: 	ConvertBytesToTb.ps1
# Date:		12/07/18
# Author: 	Andi Patrick
# Purpose:	Converts Bytes to Tb 
#==================================================================================

# Named Parameters
param($Number)

#Start by setting up API object.
$api = New-Object -comObject 'MOM.ScriptAPI'

#Create a property bag.
$bag = $api.CreatePropertyBag()

# Add Value to Property Bag
$bag.AddValue('Number', [math]::Round([Double]($Number / 1024 / 1024 /1024 /1024 ),2))

# Return Property Bag
#$api.Return($bag)
$bag