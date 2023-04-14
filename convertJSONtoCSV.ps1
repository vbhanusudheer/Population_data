# Define the API URL and query parameters
function GetAllFactors([System.Numerics.BigInteger]$n) {
    $factors = New-Object System.Collections.ArrayList
    $i = 2
    while ($i * $i -le $n) {
        if ($n % $i -eq 0) {
            $factors.Add($i) | Out-Null
            $n /= $i
        }
        else {
            $i++
        }
    }
    if ($n -gt 1) {
        $factors.Add($n) | Out-Null
    }
    return ,$factors.ToArray()
}
$url = "https://datausa.io/api/data?drilldowns=State&measures=Population"
$params = @{
    Headers = @{ "accept" = "application/json" }
}

# Invoke the API and convert the response to a PowerShell object
$response = Invoke-RestMethod -Uri $url @params
$data = $response.data

# Group the data by state and calculate population change
$groups = $data | Group-Object -Property 'State'
$results = foreach ($group in $groups) {
    $state = $group.Name
    $populations = $group.Group | Sort-Object -Property 'Year' | Select-Object -ExpandProperty 'Population'
    $bigInteger = [System.Numerics.BigInteger]::Parse($populations[-1])
    $factors = New-Object System.Collections.ArrayList
    $factors = GetAllFactors($bigInteger) 
    $populationsPercentage = $populations | ForEach-Object { "{0:N2}%" -f ((($_ - $populations[0]) / $populations[0]) * 100) }
    $populationsDelta = $populations | ForEach-Object { $_ - $populations[0] }
    [PSCustomObject]@{
        'State Name' = $state
        '2013' = $populations[0]
        '2014' = $populations[1]
        '2015' = $populations[2]
        '2016' = $populations[3]
        '2017' = $populations[4]
        '2018' = $populations[5]
        '2019' = $populations[6]
        '2019 Factors' = "$($factors)"
        'Population Delta' = [string]::Join(',', $populationsDelta)
        'Population Percentage' = [string]::Join(',', $populationsPercentage)
    }
}

$results | Export-Csv -Path 'population_change.csv' -NoTypeInformation
