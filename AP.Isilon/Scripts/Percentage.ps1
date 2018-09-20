#==================================================================================
# Script: 	Percentage.ps1
# Date:		12/07/18
# Author: 	Andi Patrick
# Purpose:	Calculates Number1 as a percentage of Number2.
#==================================================================================

# Named Parameters
param($Number1, $Number2)

#Start by setting up API object.
$api = New-Object -comObject 'MOM.ScriptAPI'

#Create a property bag.
$bag = $api.CreatePropertyBag()

# Create Result
[Double]$Percentage = ($Number1 / $Number2) * 100
[math]::Round($Percentage,2)

# Add Result to Property Bag
$bag.AddValue('Percentage', $Percentage)

# Return Property Bag
#$api.Return($bag) # Used for debugging
$bag