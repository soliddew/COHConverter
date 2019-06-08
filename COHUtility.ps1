using module c:\powershell\COHConverter\COHConverter.psm1 
remove-module cohconverter
import-module c:\powershell\COHConverter\COHConverter.psm1 

######Setup
$DBQueryPath = 'c:\cohsource\bin\dbquery.exe'
#$CharacterFilePath = 'c:\powershell\COHConverter\custodes.txt'
$CharacterFilePath = 'F:\COH\characters\Honkler.txt'

#Attribute data MUST be loaded here before anything else will work
$i24BadgeDefData = Import-COHDefFile "C:\powershell\COHConverter\attributes\badges.def"
$i24VarAttributeData = import-csv 'C:\powershell\COHConverter\attributes\vars.attribute' -Header id,name -Delimiter ' '
$i24BadgeAttributeData =  import-csv 'C:\powershell\COHConverter\attributes\badges.attribute' -Header id,name -Delimiter ' '
$i24BadgeStatsAttributeData =  import-csv 'C:\powershell\COHConverter\attributes\badgestats.attribute' -Header id,name -Delimiter ' '
$i25VarAttributeData = import-csv 'C:\powershell\COHConverter\i25attributes\vars.attribute' -Header id,name -Delimiter ' '
$i25BadgeAttributeData = import-csv 'C:\powershell\COHConverter\i25attributes\badges.attribute' -Header id,name -Delimiter ' '
######

##Build a loop around this, however you want to control it. Get-ChildItem a directory, run it on a single character, pull from a text file with paths...

$CharacterData = Import-COHCharacter -CharacterFilePath $CharacterFilePath

#Uncomment if you want to check (visually) before pruning
#Validate-COHCharcterData $CharacterData

$CharacterData = Prune-COHCharacterData $CharacterData

Export-COHCharacter -CharacterData $characterdata -path "$($CharacterFilePath).Converted"

#comment this out if you want to QC before importing
Import-CharacterFileDB -CharacterFilePath "$($CharacterFilePath).Converted" -DBQueryPath $DBQueryPath

#how to handle AuthID look up? 


