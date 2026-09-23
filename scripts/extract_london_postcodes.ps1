Add-Type -AssemblyName Microsoft.VisualBasic

$repoRoot = Split-Path $PSScriptRoot -Parent

$source = Join-Path $repoRoot "data\raw\ons-postcodes\ONSPD_AUG_2026\Data\ONSPD_AUG_2026_UK.csv"
$outputDir = Join-Path $repoRoot "data\interim"
$output = Join-Path $outputDir "ons_postcodes_london.csv"

if (-not (Test-Path $source)) {
    throw "Source CSV not found: $source"
}

New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

$wantedColumns = @(
    "pcds",
    "dointr",
    "doterm",
    "lad26cd",
    "east1m",
    "north1m",
    "rgn26cd",
    "lat",
    "long",
    "lsoa21cd",
    "msoa21cd"
)

function ConvertTo-CsvField {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        $Value = ""
    }

    return '"' + $Value.Replace('"', '""') + '"'
}

$parser = [Microsoft.VisualBasic.FileIO.TextFieldParser]::new($source)
$parser.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
$parser.SetDelimiters(",")
$parser.HasFieldsEnclosedInQuotes = $true

$writer = [System.IO.StreamWriter]::new(
    $output,
    $false,
    [System.Text.UTF8Encoding]::new($false)
)

$checked = 0
$kept = 0

try {
    $header = $parser.ReadFields()
    $columnIndexes = @{}

    for ($i = 0; $i -lt $header.Count; $i++) {
        $columnIndexes[$header[$i]] = $i
    }

    foreach ($column in $wantedColumns) {
        if (-not $columnIndexes.ContainsKey($column)) {
            throw "Required column not found: $column"
        }
    }

    $writer.WriteLine(($wantedColumns -join ","))

    while (-not $parser.EndOfData) {
        $fields = $parser.ReadFields()
        $checked++

        if ($fields[$columnIndexes["rgn26cd"]] -eq "E12000007") {
            $outputFields = foreach ($column in $wantedColumns) {
                ConvertTo-CsvField $fields[$columnIndexes[$column]]
            }

            $writer.WriteLine(($outputFields -join ","))
            $kept++
        }

        if (($checked % 250000) -eq 0) {
            Write-Progress `
                -Activity "Extracting London postcodes" `
                -Status "$checked rows checked; $kept London rows retained"
        }
    }
}
finally {
    $parser.Close()
    $writer.Close()
    Write-Progress -Activity "Extracting London postcodes" -Completed
}

Write-Host ""
Write-Host "Finished successfully." -ForegroundColor Green
Write-Host "Rows checked: $checked"
Write-Host "London rows retained: $kept"
Write-Host "Output: $output"
