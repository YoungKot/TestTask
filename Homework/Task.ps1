try
{
    $importPath = "Insert the path of your Test_task_1.csv file"

    # Creates a directory
    function Create-Directory{
        $directories = Get-Item c:\*
        if($directories.BaseName -notcontains 'test'){
            $directory = New-Item -Path "c:\" -Name "test" -ItemType "directory"
        }
        else{
            $directory = Get-Item C:\test
            Remove-Item C:\test\*
        }
        return $directory
    }

    # Gets child items of the directory
    function Get-Children{
        [CmdletBinding()]
        param(
            [object]$directory
        )
        $files = Get-ChildItem -Path $directory
        return $files
    }

    $directoryPath = Create-Directory

    # Create files with unique ids
    $file = Import-Csv -Path $importPath -Delimiter ';'
    $fileWithUniqueValues = Import-Csv -Path $importPath -Delimiter ';' | sort person_name,id -Unique
    $fileWithDuplicateValues = compare-object $file $fileWithUniqueValues -property “person_name”, "id", "Total", "Paid", "Date", "No" | Select person_name,id,Total,Paid,Date,No

    $fileWithUniqueValues | Export-Csv "$($directoryPath)\Test_task_2.csv" -NoTypeInformation
    $fileWithDuplicateValues | Export-Csv "$($directoryPath)\Test_task_3.csv" -NoTypeInformation

    # Replace commas with dots
    $files = Get-Children -directory $directoryPath 

    foreach($file in $files){
        Import-Csv -Path $file.FullName |
            ConvertTo-Csv -Delimiter ';' | 
            ForEach-Object { $_ -replace ',',"." } | 
            ConvertFrom-Csv -Delimiter ';' | 
            ConvertTo-Csv -NoTypeInformation |
            ForEach-Object { $_ -replace '"',[String]::Empty } |
            Set-Content -Path $file.FullName.Replace(".csv", "_Commas_Replaced_By_Dots.csv")
    }

    # Change column Date value format
    $files = Get-Children -directory $directoryPath
    $culture = [Globalization.CultureInfo]::InvariantCulture

    foreach($file in $files){
        if($file -match "Commas"){
            Import-Csv -Path $file.FullName | ForEach-Object {
                $_.Date = [DateTime]::ParseExact($_.Date, 'dd\/MM\/yyyy', $culture).ToString('dd-MM-yyyy')
                $_
            } | Export-csv $file.FullName.Replace("_Commas_Replaced_By_Dots.csv", "_Date_Format_Changed.csv") -Delimiter ";" -NoTypeInformation
        }
    }

    # Change No column date format
    $files = Get-Children -directory $directoryPath

    foreach($file in $files){
        if($file -match "Date"){
            Import-Csv -Path $file.FullName -Delimiter ";" | ForEach-Object {
                if($_.No -match "/"){
                    $_.No = [DateTime]::ParseExact($_.No, 'dd\/MM\/yyyy', $culture).ToString('yyyy-MM-dd')
                    $_
                }
                else{
                    $_
                }
            }| Export-Csv $file.FullName.Replace("_Date_Format_Changed.csv", "_Complete_Changes_Applied.csv") -Delimiter ";" -NoTypeInformation
        }
    }

    # Removes all unnecessary files
    $files = Get-Children -directory $directoryPath

    foreach($file in $files){
        if($file -notmatch "Complete"){
            Remove-Item $file.FullName
        }
    }
}
catch
{
    $_.Exception.Message
}