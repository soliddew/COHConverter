using module c:\powershell\COHConverter\COHConverter.psm1 
$DBQueryPath = 'c:\cohsource\bin\dbquery.exe'
$CharacterFilePath = 'c:\powershell\COHConverter\custodes.txt'

$i24BadgeDefData = Import-COHDefFile "C:\powershell\COHConverter\attributes\badges.def"
$i24VarAttributeData = import-csv 'C:\powershell\COHConverter\attributes\vars.attribute' -Header id,name -Delimiter ' '
$i24BadgeAttributeData =  import-csv 'C:\powershell\COHConverter\attributes\badges.attribute' -Header id,name -Delimiter ' '
$i24BadgeStatsAttributeData =  import-csv 'C:\powershell\COHConverter\attributes\badgestats.attribute' -Header id,name -Delimiter ' '
$i25VarAttributeData = import-csv 'C:\powershell\COHConverter\i25attributes\vars.attribute' -Header id,name -Delimiter ' '
$i25BadgeAttributeData = import-csv 'C:\powershell\COHConverter\i25attributes\badges.attribute' -Header id,name -Delimiter ' '

$CharacterData = Import-COHCharacter -Character (get-content $CharacterFilePath)




Validate-COHBadgeStats -CharacterData $CharacterData -AttributeData $i24BadgeStatsAttributeData | ft
Validate-COHBadgeFlags -CharacterData $CharacterData -defFile $i24BadgeDefData  | ft 
Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'Powers' -Property 'PowerName' |ft 
Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'PowerCustomizations' -Property 'PowerName'|ft
Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'RewardTokens' -Property 'PieceName'|ft 
Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'Contacts' -Property 'id' |Ft 
Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'Tasks' -Property 'id' |ft 





$CharacterData= Validate-COHBadgeStats -CharacterData $CharacterData -AttributeData $i24BadgeStatsAttributeData -remove 
$CharacterData= Validate-COHBadgeFlags -CharacterData $CharacterData -defFile $i24BadgeDefData -remove 
$characterData= Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'Powers' -Property 'PowerName' -remove
$characterData= Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'PowerCustomizations' -Property 'PowerName' -remove
$characterData= Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'RewardTokens' -Property 'PieceName' -remove
$characterData= Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'Contacts' -Property 'id' -remove
$characterData= Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'Tasks' -Property 'id' -remove


Export-COHCharacter -CharacterData $characterdata -path "$($CharacterFilePath).Converted"

Import-CharacterFileDB -CharacterFilePath "$($CharacterFilePath).Converted" -DBQueryPath $DBQueryPath


