using namespace System.Collections.Generic
using namespace System.Collections
class CharacterData {
    [list[CharacterAttribute]] $CharacterAttributes
    [list[CharacterProperty]] $CharacterProperties
    CharacterData($Character) {
        $this.CharacterAttributes = Import-COHCharacterAttribute $Character
        $this.CharacterProperties = Import-COHCharacterProperty $Character
    }
}

class CharacterAttribute {
    [int] $ID
    [string]$Attribute
    [string]$Property
    [string]$Value 
    CharacterAttribute($AttributeString) {
     
        $Regex = '(.+)\[(\d.*)\]\.([^\s]*) (.+)'
        $AttributeString -match $regex
        $this.ID = $matches[2]
        $this.Attribute = $matches[1]
        $this.Property = $matches[3]
        $this.Value = $matches[4].replace('"', '')
        #get badgestats in format OK for joining (int)
        if ($this.attribute -like 'badges*' -and $this.property -like 'c*') {
            $this.Property = $this.Property.replace('c', '')
            $this.property = $this.property -replace '^0+', '' 
        }
          
    }
 
    [string] toString() {
        #I KNOW THIS MODIFIED THE DATA AND THATS BAD, HELP. Please fucking fix this brett      
        if (($this.attribute -like 'badges*') -and ($this.property -ne 'owned') -and !$this.property.contains('c') ) {  #handle badgestats format (pad 3)
            if (($this.property.Length -lt 3)) {
                $this.property = $this.property.padleft(3, '0')
            }
            $this.property = "c$($this.Property)"
            
        }
        
        if ($this.value -match '[a-zA-Z]' -and (!$this.value.Contains('"'))) {#requote strings
       
            $this.value = """$($this.value)"""
       
        }

        return "$($this.Attribute)[$($this.ID)].$($this.Property) $($this.Value)"

    }

}


class CharacterProperty {
    [string] $Name
    [string] $Value 

    CharacterProperty($PropertyString) {
        $regex = '([^\s]*) (.+)'
        $propertyString -match $regex
        $this.Name = $matches[1]
        $this.Value = $matches[2].replace('"', '')
    }
    [string] toString() {
     
        if ($this.value -match '[a-zA-Z]' -and (!$this.value.Contains('"'))) {
       
            $this.value = """$($this.value)"""
       
        }
        return "$($this.name) $($this.value)"

    }


}


$convertbadge = 
@"

 namespace Util
{
    public static class StringExtensions
    {
        public static byte[] FromHexToByteArray( string hexString)
        {
            var arr = new byte[hexString.Length / 2];
            for (var i = 0; i < hexString.Length; i += 2)
                arr[i / 2] = System.Convert.ToByte(hexString.Substring(i, 2), 16);
            return arr;
        }
            public static byte[] BitArrayToByteArray(System.Collections.BitArray bits)
        {
            byte[] ret = new byte[(bits.Length - 1) / 8 + 1];
            bits.CopyTo(ret, 0);
            return ret;
        }
        public static readonly uint[] _lookup32 = CreateLookup32();

        public static uint[] CreateLookup32()
        {
            var result = new uint[256];
            for (int i = 0; i < 256; i++)
            {
                string s=i.ToString("X2");
                result[i] = ((uint)s[0]) + ((uint)s[1] << 16);
            }
            return result;
        }

        public static string ByteArrayToHexViaLookup32(byte[] bytes)
        {
            var lookup32 = _lookup32;
            var result = new char[bytes.Length * 2];
            for (int i = 0; i < bytes.Length; i++)
            {
                var val = lookup32[bytes[i]];
                result[2*i] = (char)val;
                result[2*i + 1] = (char) (val >> 16);
            }
            return new string(result);
        }
    }
    
}
"@

Add-Type -TypeDefinition $Convertbadge -Language CSharp


function Import-COHCharacterAttribute {
    #accepts dbquery.exe dump, skips general properties (use ContainerAttribute)
    param([Parameter(Mandatory = $true)]$Container)
    $pastHeader = $false
    $returnList = new-object List[CharacterAttribute]

    foreach ($Attribute in $Container) {
        
        if (!$pastHeader) {
            #skip until we find [ character
            if ($Attribute.Contains('[')) {
                $PastHeader = $true

                $Attribute = [CharacterAttribute]::New($Attribute)
        
                $returnList.add( $Attribute)
            }    
        }
        else {

            $attribute = [CharacterAttribute]::New($Attribute)
            $returnList.add($Attribute)       
        }
    }
    return $returnList
}

function Import-COHCharacterProperty {
    param([Parameter(Mandatory = $true)]$Container)
    $ReturnList = new-object List[CharacterProperty]

    foreach ($property in $container) {
            
        if ($property.contains('[')) {
            break
        }
        $prop = [CharacterProperty]::new($property)

        $ReturnList.Add($prop) 
    }
    return $ReturnList
}

function Import-COHCharacter {
    param([Parameter(Mandatory = $true)]$CharacterFilePath)
    try {
        $character = get-content $CharacterFilePath
    }
    catch {
        throw $_.exception
    }
    return [CharacterData]::New($Character)

}

function Export-COHCharacter {
    param([Parameter(Mandatory = $true)]$CharacterData, [Parameter(Mandatory = $true)]$path)

    $out = new-object List[string]

    $Auth = $CharacterData.CharacterProperties.where( { $_.name -eq 'AuthName' })
    $Character = $CharacterData.CharacterProperties.where( { $_.name -eq 'Name' })

    foreach ($property in $CharacterData.CharacterProperties) {
        $out.add($property.tostring())
    }
    foreach ($attribute in $CharacterData.CharacterAttributes) {
        $out.add($attribute.tostring())
    }

    $out | out-file -FilePath $path -Encoding ascii
    write-host "Auth: $($auth.value) Character: $($character.value) written to $($path)"
    return 
}



function Import-COHDefFile {
    param( [Parameter(Mandatory = $true)]$DefFilePath)
    $text = get-content $DefFilePath
    $names = $text.where( { $_ -like 'Badge*' }).Replace('Badge ', '')
    $index = $text.where( { $_ -like '	Index*' }).replace('	Index ', '')
    $BadgeDefs = [list[PSObject]]::new()
    $i = 0
    foreach ($name in $names) {
        $BadgeDefs.add([pscustomobject]@{
                ID    = $i 
                Name  = $name
                Index = [int]$index[$i]
            })
        $i++
    }
    return $BadgeDefs
}
function Prune-COHCharacterData {
    param ($characterData)


    $CharacterData = Validate-COHBadgeStats -CharacterData $CharacterData -AttributeData $i24BadgeStatsAttributeData -remove 
    $CharacterData = Validate-COHBadgeFlags -CharacterData $CharacterData -defFile $i24BadgeDefData -remove 
    $characterData = Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'Powers' -Property 'PowerName' -remove
    $characterData = Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'PowerCustomizations' -Property 'PowerName' -remove
    $characterData = Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'RewardTokens' -Property 'PieceName' -remove
    $characterData = Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'Contacts' -Property 'id' -remove
    $characterData = Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'Tasks' -Property 'id' -remove


    return $characterData

}

function Validate-COHCharcterData {
    param($characterdata)

    try {
        Validate-COHBadgeStats -CharacterData $CharacterData -AttributeData $i24BadgeStatsAttributeData |ft
        Validate-COHBadgeFlags -CharacterData $CharacterData -defFile $i24BadgeDefData | ft 
        Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'Powers' -Property 'PowerName' | ft 
        Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'PowerCustomizations' -Property 'PowerName' | ft
        Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'RewardTokens' -Property 'PieceName' | ft 
        Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'Contacts' -Property 'id' | Ft 
        Validate-COHAttributeProperty -CharacterData $characterdata -AttributeData $i24VarAttributeData -Attribute 'Tasks' -Property 'id' | ft 
    }
    catch {
        throw $_.Exception
    }

}

function Validate-COHAttributeProperty {
    param([Parameter(Mandatory = $true)]$CharacterData, $AttributeData, [Parameter(Mandatory = $true)]$Attribute, [Parameter(Mandatory = $true)]$Property, [switch]$remove)


    $AttributeProperty = $CharacterData.CharacterAttributes.Where( { $_.Attribute -eq "$($Attribute)" -and $_.property -eq "$($Property)" })

    if (!$AttributeProperty) {
        write-host "No elements found for $($Attribute) $($Property)"
        return $CharacterData
    }

    [list[pscustomobject]]$ret = join-object -Left $AttributeProperty -Right $AttributeData -LeftJoinProperty value -RightJoinProperty name -RightProperties id, name  -Prefix 'AttFile_'
    [list[pscustomobject]]$MissingAttributes = $ret.where( { $_.AttFile_id -eq $null })

    if ($remove -and $MissingAttributes) {
        foreach ($MissingAttribute in $MissingAttributes) {
            write-host "Removing $($missingAttribute.Value) from $($Attribute).$($property)"
            $CharacterData.CharacterAttributes.RemoveAll( { param($m) ($m.Attribute.equals($Attribute) -and $m.ID.equals($MissingAttribute.ID)) }) | out-null
        }
        return $CharacterData
            
    }
    else {
        if ($remove) {
            write-host "No items found to remove for $($Attribute) $($Property)"
            return $CharacterData
        }
    }
    write-host "$($missingattributes.count) Missing Attributes for Attributes $($Attribute) $($Property)"
    return  $MissingAttributes 
}

function Get-COHBadgeBitListFromHex {
    param($Hex)

    $bitfield = Convert-HextoBitArray $hex
    $I = 0
    write-host "$($bitfield.where({$_ -eq 1}).count) badges found in character"
    $bitlist = [list[pscustomobject]]::new()
    foreach ($bit in $bitfield) {
        $bitlist.add([pscustomobject]@{
                id       = [int]$i
                HasBadge = [boolean]$bit
            })
        $I++
    }
    return $bitlist

}


function Validate-COHBadgeFlags {
    param([Parameter(Mandatory = $true)]$CharacterData, [Parameter(Mandatory = $true)]$DefFile, [switch]$remove)
    $hex = $CharacterData.CharacterAttributes.where( { ($_.attribute -eq 'badges') -and ($_.property -eq 'owned') })[0].Value
    #write-host $hex    
    $bitlist = Get-COHBadgeBitListFromHex $hex    
    $badges = [list[pscustomobject]]::new()
    $badges = join-object -Left $bitlist -Right $DefFile -LeftJoinProperty id -RightJoinProperty index -Type AllInLeft -Prefix 'Def' | sort id  
    $MissingBadges = $badges.where( { $_.hasbadge -eq $true -and $_.defindex -eq $null })   
    write-host "$($MissingBadges.where({$_.hasbadge -eq 1}).count) missing badges"   
     
    if (!$remove) {
        return $badges
      
    }
    
    if ($MissingBadges) {

        foreach ($missingBadge in $MissingBadges) {
            write-host "Setting BadgeID $($missingBadge.ID) $($missingbadge.hasbadge) to false"
            $badges[$missingBadge.Id].HasBadge = $false 
              
        }  
        write-host "$($MissingBadges.count) Badges Removed"
        $PostRemoveCount = $badges.where( { $_.hasbadge -eq $true }).count
        write-host "$($PostRemoveCount) in bit list" 
        $hex = Convert-BitArrayToHex $badges.HasBadge      
        $CharacterData.CharacterAttributes.where( { ($_.attribute -eq 'badges') -and ($_.property -eq 'owned') })[0].Value = $hex
        return $CharacterData
    }
    else {
        write-host "No Missing Badges" 
        return $CharacterData
    }
}

        




function Validate-COHBadgeStats {
    param([Parameter(Mandatory = $true)]$CharacterData, [Parameter(Mandatory = $true)]$AttributeData, [switch]$remove)

    $BadgeStats = $CharacterData.CharacterAttributes.Where( { $_.Attribute -like "badges*" -and $_.property -ne "owned" })
  
    if (!$Badgestats) {
        write-host "No badge stats found, this really shouldn't happen!!"
        return $CharacterData
    }

    [list[pscustomobject]]$ret = join-object -Left $BadgeStats -Right $AttributeData -leftjoinproperty property -RightJoinProperty id -RightProperties id, name  -Prefix 'AttFile_'
    [list[pscustomobject]]$MissingAttributes = $ret.where( { $_.AttFile_id -eq $null })

    if ($remove -and $MissingAttributes) {

        write-host "Removing $($MissingAttributes.count) badge stats"
        foreach ($MissingAttribute in $MissingAttributes) {
            write-host "Removing badge stat : $($MissingAttribute.Attribute) $($MissingAttribute.Property)"
            $Removed = $CharacterData.CharacterAttributes.RemoveAll( { param($m) ($m.Attribute.equals($MissingAttribute.Attribute) -and $m.Property.equals($MissingAttribute.Property)) }) | out-null
            $removedTotal = $removed + $removedTotal
        }
        return $CharacterData
    }
    else {
        if ($remove) {
            write-host "No badge stats found to remove"
            return $CharacterData
        }        
    }
    write-host "$($missingattributes.count) missing badge stats"
    return $MissingAttributes 
}



function Convert-HextoBitArray() {
    param([Parameter(Mandatory = $true)]$hex)
    
    $ByteArray = [util.StringExtensions]::FromHexToByteArray($hex)
    [int[]]$bitfield = [bitarray]::new($ByteArray)
    return $bitfield
}


function Convert-BitArrayToHex {
    param([Parameter(Mandatory = $true)]$BitArray)    
    [bitarray] $bitarray = [bitarray]::new($BitArray)
    $ByteArray = [Util.StringExtensions]::BitArrayToByteArray($bitarray)
    $hex = [Util.StringExtensions]::ByteArrayToHexViaLookup32($ByteArray)
    return $hex 
}


function Import-CharacterFileDB {
    param([Parameter(Mandatory = $true)]$CharacterFilePath, [Parameter(Mandatory = $true)]$DBQueryPath)
    push-location c:\cohsource\bin
    .\dbquery.exe -putcharacter $CharacterFilePath
}

function Join-Object {
    <#
    .LINK
        http://ramblingcookiemonster.github.io/Join-Object/

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeLine = $true)]
        [object[]] $Left,

        # List to join with $Left
        [Parameter(Mandatory = $true)]
        [object[]] $Right,

        [Parameter(Mandatory = $true)]
        [string] $LeftJoinProperty,

        [Parameter(Mandatory = $true)]
        [string] $RightJoinProperty,

        [object[]]$LeftProperties = '*',

        # Properties from $Right we want in the output.
        # Like LeftProperties, each can be a plain name, wildcard or hashtable. See the LeftProperties comments.
        [object[]]$RightProperties = '*',

        [validateset( 'AllInLeft', 'OnlyIfInBoth', 'AllInBoth', 'AllInRight')]
        [Parameter(Mandatory = $false)]
        [string]$Type = 'AllInLeft',

        [string]$Prefix,
        [string]$Suffix
    )
    Begin {
        function AddItemProperties($item, $properties, $hash) {
            if ($null -eq $item) {
                return
            }

            foreach ($property in $properties) {
                $propertyHash = $property -as [hashtable]
                if ($null -ne $propertyHash) {
                    $hashName = $propertyHash["name"] -as [string]         
                    $expression = $propertyHash["expression"] -as [scriptblock]

                    $expressionValue = $expression.Invoke($item)[0]
            
                    $hash[$hashName] = $expressionValue
                }
                else {
                    foreach ($itemProperty in $item.psobject.Properties) {
                        if ($itemProperty.Name -like $property) {
                            $hash[$itemProperty.Name] = $itemProperty.Value
                        }
                    }
                }
            }
        }

        function TranslateProperties {
            [cmdletbinding()]
            param(
                [object[]]$Properties,
                [psobject]$RealObject,
                [string]$Side)

            foreach ($Prop in $Properties) {
                $propertyHash = $Prop -as [hashtable]
                if ($null -ne $propertyHash) {
                    $hashName = $propertyHash["name"] -as [string]         
                    $expression = $propertyHash["expression"] -as [scriptblock]

                    $ScriptString = $expression.tostring()
                    if ($ScriptString -notmatch 'param\(') {
                        Write-Verbose "Property '$HashName'`: Adding param(`$_) to scriptblock '$ScriptString'"
                        $Expression = [ScriptBlock]::Create("param(`$_)`n $ScriptString")
                    }
                
                    $Output = @{Name = $HashName; Expression = $Expression }
                    Write-Verbose "Found $Side property hash with name $($Output.Name), expression:`n$($Output.Expression | out-string)"
                    $Output
                }
                else {
                    foreach ($ThisProp in $RealObject.psobject.Properties) {
                        if ($ThisProp.Name -like $Prop) {
                            Write-Verbose "Found $Side property '$($ThisProp.Name)'"
                            $ThisProp.Name
                        }
                    }
                }
            }
        }

        function WriteJoinObjectOutput($leftItem, $rightItem, $leftProperties, $rightProperties) {
            $properties = @{ }

            AddItemProperties $leftItem $leftProperties $properties
            AddItemProperties $rightItem $rightProperties $properties

            New-Object psobject -Property $properties
        }

        #Translate variations on calculated properties.  Doing this once shouldn't affect perf too much.
        foreach ($Prop in @($LeftProperties + $RightProperties)) {
            if ($Prop -as [hashtable]) {
                foreach ($variation in ('n', 'label', 'l')) {
                    if (-not $Prop.ContainsKey('Name') ) {
                        if ($Prop.ContainsKey($variation) ) {
                            $Prop.Add('Name', $Prop[$Variation])
                        }
                    }
                }
                if (-not $Prop.ContainsKey('Name') -or $Prop['Name'] -like $null ) {
                    Throw "Property is missing a name`n. This should be in calculated property format, with a Name and an Expression:`n@{Name='Something';Expression={`$_.Something}}`nAffected property:`n$($Prop | out-string)"
                }


                if (-not $Prop.ContainsKey('Expression') ) {
                    if ($Prop.ContainsKey('E') ) {
                        $Prop.Add('Expression', $Prop['E'])
                    }
                }
            
                if (-not $Prop.ContainsKey('Expression') -or $Prop['Expression'] -like $null ) {
                    Throw "Property is missing an expression`n. This should be in calculated property format, with a Name and an Expression:`n@{Name='Something';Expression={`$_.Something}}`nAffected property:`n$($Prop | out-string)"
                }
            }        
        }

        $leftHash = @{ }
        $rightHash = @{ }

        # Hashtable keys can't be null; we'll use any old object reference as a placeholder if needed.
        $nullKey = New-Object psobject
        
        $bound = $PSBoundParameters.keys -contains "InputObject"
        if (-not $bound) {
            [System.Collections.ArrayList]$LeftData = @()
        }
    }
    Process {
        #We pull all the data for comparison later, no streaming
        if ($bound) {
            $LeftData = $Left
        }
        Else {
            foreach ($Object in $Left) {
                [void]$LeftData.add($Object)
            }
        }
    }
    End {
        foreach ($item in $Right) {
            $key = $item.$RightJoinProperty

            if ($null -eq $key) {
                $key = $nullKey
            }

            $bucket = $rightHash[$key]

            if ($null -eq $bucket) {
                $bucket = New-Object System.Collections.ArrayList
                $rightHash.Add($key, $bucket)
            }

            $null = $bucket.Add($item)
        }

        foreach ($item in $LeftData) {
            $key = $item.$LeftJoinProperty

            if ($null -eq $key) {
                $key = $nullKey
            }

            $bucket = $leftHash[$key]

            if ($null -eq $bucket) {
                $bucket = New-Object System.Collections.ArrayList
                $leftHash.Add($key, $bucket)
            }

            $null = $bucket.Add($item)
        }

        $LeftProperties = TranslateProperties -Properties $LeftProperties -Side 'Left' -RealObject $LeftData[0]
        $RightProperties = TranslateProperties -Properties $RightProperties -Side 'Right' -RealObject $Right[0]

        #I prefer ordered output. Left properties first.
        [string[]]$AllProps = $LeftProperties

        #Handle prefixes, suffixes, and building AllProps with Name only
        $RightProperties = foreach ($RightProp in $RightProperties) {
            if (-not ($RightProp -as [Hashtable])) {
                Write-Verbose "Transforming property $RightProp to $Prefix$RightProp$Suffix"
                @{
                    Name       = "$Prefix$RightProp$Suffix"
                    Expression = [scriptblock]::create("param(`$_) `$_.'$RightProp'")
                }
                $AllProps += "$Prefix$RightProp$Suffix"
            }
            else {
                Write-Verbose "Skipping transformation of calculated property with name $($RightProp.Name), expression:`n$($RightProp.Expression | out-string)"
                $AllProps += [string]$RightProp["Name"]
                $RightProp
            }
        }

        $AllProps = $AllProps | Select -Unique

        Write-Verbose "Combined set of properties: $($AllProps -join ', ')"

        foreach ( $entry in $leftHash.GetEnumerator() ) {
            $key = $entry.Key
            $leftBucket = $entry.Value

            $rightBucket = $rightHash[$key]

            if ($null -eq $rightBucket) {
                if ($Type -eq 'AllInLeft' -or $Type -eq 'AllInBoth') {
                    foreach ($leftItem in $leftBucket) {
                        WriteJoinObjectOutput $leftItem $null $LeftProperties $RightProperties | Select $AllProps
                    }
                }
            }
            else {
                foreach ($leftItem in $leftBucket) {
                    foreach ($rightItem in $rightBucket) {
                        WriteJoinObjectOutput $leftItem $rightItem $LeftProperties $RightProperties | Select $AllProps
                    }
                }
            }
        }

        if ($Type -eq 'AllInRight' -or $Type -eq 'AllInBoth') {
            foreach ($entry in $rightHash.GetEnumerator()) {
                $key = $entry.Key
                $rightBucket = $entry.Value

                $leftBucket = $leftHash[$key]

                if ($null -eq $leftBucket) {
                    foreach ($rightItem in $rightBucket) {
                        WriteJoinObjectOutput $null $rightItem $LeftProperties $RightProperties | Select $AllProps
                    }
                }
            }
        }
    }
}

