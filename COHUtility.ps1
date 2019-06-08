using module c:\powershell\COHConverter\COHConverter.psm1 
remove-module cohconverter
import-module c:\powershell\COHConverter\COHConverter.psm1 
#####Attribute data MUST be loaded here before anything else will work
$i24BadgeDefData = Import-COHDefFile "C:\powershell\COHConverter\attributes\badges.def"
$i24VarAttributeData = import-csv 'C:\powershell\COHConverter\attributes\vars.attribute' -Header id,name -Delimiter ' '
$i24BadgeAttributeData =  import-csv 'C:\powershell\COHConverter\attributes\badges.attribute' -Header id,name -Delimiter ' '
$i24BadgeStatsAttributeData =  import-csv 'C:\powershell\COHConverter\attributes\badgestats.attribute' -Header id,name -Delimiter ' '
$i25VarAttributeData = import-csv 'C:\powershell\COHConverter\i25attributes\vars.attribute' -Header id,name -Delimiter ' '
$i25BadgeAttributeData = import-csv 'C:\powershell\COHConverter\i25attributes\badges.attribute' -Header id,name -Delimiter ' '
##
$DBQueryPath = 'c:\cohsource\bin\dbquery.exe'
$CharacterFilePath = 'c:\powershell\COHConverter\custodes.txt'
$CharacterFolderPath = 'C:\powershell\COHConverter\characters'
######

$Characters = Get-ChildItem $CharacterFolderPath -Filter '*.txt'
 
##Build a loop around this, however you want to control it. Get-ChildItem a directory, run it on a single character, pull from a text file with paths...
foreach($character in $characters)
    {
        try{
            write-host "Converting $($character.Name)"
            $CharacterData = Import-COHCharacter -CharacterFilePath $Character.fullname

            #dump joined badges table, missing badgestats, and missing attributes. 
            Validate-COHCharcterData $CharacterData | out-file "$($character.fullname).validation" # out
            #Delete records from the character that don't match our loaded attributes
            $CharacterData = Prune-COHCharacterData $CharacterData
            Export-COHCharacter -CharacterData $characterdata -path "$($character.fullname).Converted"
   
            #Uncomment this out if you want to import the character using the DBQuery tool, you must have a running server.
            #if the character exists it will be made with a 1 at the end, authID will need to be changed tho..
            #prepare a look up table in SQL before hand and update what you can with join if its a lot
            #Import-CharacterFileDB -CharacterFilePath "$($CharacterFilePath).Converted" -DBQueryPath $DBQueryPath

        }
        catch
        {
            write-host $_.exception
            $_.exception | out-file "$($character.fullname).error"
        }
}


#how to handle AuthID look up? 


