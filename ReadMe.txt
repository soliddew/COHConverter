

Usage:

Extract to c:\powershell\COHConverter , attribute file paths are hardcoded right now because lazy.

Open COHUtility.ps1 in Powershell ISE

Set $DBQueryPath to your DBQuery.exe if you wish to import characters through the script. 

Any characters files (from dbquery) in the folder set to $CharacterFolderPath will be converted, with a .converted and .validation file generated for each. A sample is provided.

Uncomment Import-CharacterFileDB if your database is set up and you want to import the newly converted file.  

------

There may be more Attributes to check for but these seemed like the major ones
I didn't do much validaton on Properties (Ents,Ents2) because they are either going to work or not and must be solved through the client either way.

COHConvert.psm1 provides functions and classes to work with the character data.

This is silly and not geat and will be remade with CE :)

To do: 
--Needs to look up Auth Information from database to translate AuthId for characters, so it needs a little bit of SQL helper. This would help importing a lot
--Needs Export-CharacterFileDB to make a nice transfer loop (would require DB to be online...)
--Needs more accessible and editable properties
--Must make BadgeStats deletion faster
--Validate needs to have the get logic decoupled ,pure lazniess