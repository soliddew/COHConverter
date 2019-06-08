Extract to c:\powershell\ , everything is hardcoded right now because lazy.

COHConvert.psm1 provides functions and classes to work with the character data.

COHUtility.ps1 loads attribute data, the definition file for badges, character data, and then runs the appropriate Validate- Commands. The Validate- commands can easily have wrapper to make it pretty

All Validate- commands have a -remove parameter that actually removes the found discrepancies from the CharacterData object. Otherwise it will just return the table of AttributeProperties (be warned, it's NOT the CharacterData object)

This is all silly and terrible and will be fixed hopefully. By fixed I mean remade with CE :)

--Needs to look up Auth Information from database to translate AuthId for characters, so it needs a little bit of SQL helper
--Needs Export-CharacterFileDB to make a nice transfer loop
--Replace Write-host with log
--Needs more validation and testing
--Recent badges needs to be REPLACED with the correct def indexes I believe, they come out all wrong
--Validate-BadgeStats is done in a really dumb way cause I can't get the LINQ to work for some reason, which means it's slow af.
--Validate needs to have the get logic decoupled ,pure lazniess