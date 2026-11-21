$logFile = "raport_testow.txt"

Write-Host "1. The Frequency (Monobit) Test"
Write-Host "2. Frequency Test within a Block"
Write-Host "3. Runs Test"
Write-Host "4. Test for the Longest Run of Ones in a Block"
Write-Host "5. Binary Matrix Rank Test"
Write-Host "6. Discrete Fourier Transform (Spectral) Test"
Write-Host "7. Non-overlapping Template Matching Test"
Write-Host "8. Overlapping Template Matching Test"
Write-Host "9. Maurer's Universal Statistical Test"
Write-Host "10. Linear Complexity Test"
Write-Host "11. Serial Test"
Write-Host "12. Approximate Entropy Test"
Write-Host "13. Cumulative Sums (Cusum) Test"
Write-Host "14. Random Excursions Test"
Write-Host "15. Random Excursions Variant Test"


$headerLine = "Plik             |"
for ($t = 1; $t -le 15; $t++) {
    $headerLine += " " + $t.ToString().PadLeft(5).PadRight(4) + "   |"
}

$separator = "-" * $headerLine.Length
$separator | Out-File -FilePath $logFile -Encoding utf8
$headerLine | Out-File -FilePath $logFile -Append -Encoding utf8
$separator | Out-File -FilePath $logFile -Append -Encoding utf8

Write-Host $separator
Write-Host $headerLine
Write-Host $separator

$testScripts = @(
    "monobit_test.py",                 # 1
    "block_frequency_test.py",          # 2
    "runs_test.py",                     # 3
    "longest_run_ones_test.py",         # 4
    "binary_matrix_rank_test.py",       # 5
    "dft_test.py",                      # 6
    "non_overlapping_template_test.py", # 7
    "overlapping_template_test.py",     # 8
    "maurer_universal_test.py",         # 9
    "linear_complexity_test.py",        # 10
    "serial_test.py",                   # 11
    "approximate_entropy_test.py",      # 12
    "cumulative_sums_test.py",          # 13
    "random_excursions_test.py",        # 14
    "random_excursions_variant_test.py" # 15
)

for ($i = 1; $i -le 10; $i++) {
    $filename = "dane_$i.bin"
    
    if (Test-Path $filename) {
        $fileCol = $filename.PadRight(16)
        $rowLine = "$fileCol |"

        Write-Host "$fileCol |" -NoNewline
    
        for ($tIdx = 0; $tIdx -lt $testScripts.Length; $tIdx++) {
            $script = $testScripts[$tIdx]
            $val = "N/A"
        
            if (Test-Path $script) {
                $rawOutput = python $script $filename 2>$null
            
                if ($LASTEXITCODE -eq 0 -and $rawOutput) {
                    $parsedVal = 0.0
                    if ([double]::TryParse($rawOutput.Trim(), [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsedVal)) {
                        $val = $parsedVal.ToString("F5", [System.Globalization.CultureInfo]::InvariantCulture)
                    }
                }
            } else {
                $val = "Brak"
            }

            if ($val -eq "N/A" -or $val -eq "Brak") {
               $formattedVal = $val.PadLeft(7).PadRight(9)
            } else {
                $formattedVal = " " + $val + " "
            }

            $rowLine += "$formattedVal|"
            if ($val -gt 0.01){
                Write-Host "$formattedVal" -NoNewline -ForegroundColor Green
                
            }else{
                Write-Host "$formattedVal" -NoNewline -ForegroundColor Red 
            }
            Write-Host "|" -NoNewline 
        }

        Write-Host ""
    

        $rowLine | Out-File -FilePath $logFile -Append -Encoding utf8
    }
}
$separator | Out-File -FilePath $logFile -Append -Encoding utf8
Write-Host $separator