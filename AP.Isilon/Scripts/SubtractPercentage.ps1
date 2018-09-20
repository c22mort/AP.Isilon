#==================================================================================
# Script: 	SubtractPercentage.ps1
# Date:		12/07/18
# Author: 	Andi Patrick
# Purpose:	Subtracts Number1 from Number2.
#==================================================================================

# Named Parameters
param($Number, $Total)

#Start by setting up API object.
$api = New-Object -comObject 'MOM.ScriptAPI'

#Create a property bag.
$bag = $api.CreatePropertyBag()

# Create Result
$Result = $Total - $Number
[Double]$Percentage = ($Result / $Total) * 100
[math]::Round($Percentage,2)

# Add Result to Property Bag
$bag.AddValue('Percentage', $Percentage)

# Return Property Bag
#$api.Return($bag) # Used for debugging
$bag