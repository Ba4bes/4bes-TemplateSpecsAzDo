[cmdletbinding()]
param(
    [string]$Path  ,
    [string]$ResourceGroupName  ,
    [string]$Location
)

#Create resource group if it does not exist
Try {
    Get-AzResourceGroup $ResourceGroupName -ErrorAction Stop
}
Catch{
    Write-Host "Creating ResourceGroup $ResourceGroupName"
    New-AzResourceGroup $ResourceGroupName -Location $Location
}

# Collect all JSONs
$JSONS = Get-ChildItem $Path -Recurse -Include *.json

# Create array with information on all template files.
$Templates = [System.Collections.ArrayList]@()
foreach ($JSON in $JSONs) {
    # Check if the JSON contains a Resources property, which means it is (probably) an ARM template
    $JSONContent = Get-Content $JSON | ConvertFrom-Json
    if ($JSONContent.variables.templateSpecName) {
        $TemplateObject = [PSCustomObject]@{
            TemplateFileName = $JSON.FullName
            TemplateSpecName = $JSONContent.variables.templateSpecName
            Version          = $JSONContent.variables.version
        }
        $null = $Templates.Add($TemplateObject)
    }
}

$Templates.ToArray() | ForEach-Object {
    $TemplateSpecName = $_.TemplateSpecName
    Try {
        # Check for a current version
        $ExistingSpec = Get-AzTemplateSpec -ResourceGroupName $ResourceGroupName -Name $TemplateSpecName -ErrorAction stop
        $CurrentVersion = $ExistingSpec.Versions | Sort-Object name | Select-Object -Last 1 -ExpandProperty Name
    }
    Catch {
        # If it doesn't exist, set current version to 0 so the version in the repo is always higher
        Write-Host "TemplateSpec $TemplateSpecName does not exist"
        $CurrentVersion = 0
    }
    if ($_.Version -gt $CurrentVersion) {
        Write-Host "Template $TemplateSpecName in repo is newer than in Azure. Deploying"
        $SpecParameters = @{
            Name              = $TemplateSpecName
            ResourceGroupName = $ResourceGroupName
            Location          = $Location
            TemplateFile      = $_.TemplateFileName
            Version           = $_.Version
        }
        New-AzTemplateSpec @SpecParameters
    }
    else {
        Write-Host "$TemplateSpecName doesn't have a new version"
    }
}
