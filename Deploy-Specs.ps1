<#
.SYNOPSIS
    This script collects JSON files and deploys them as needed to Azure Template Specs
.DESCRIPTION
    The script collects all the JSON files in the Path that is given.
    It looks for the templates that contain TemplateSpecName and TemplateSpecVersion in the Variables.
    It checks in Azure if a Template Spec with that name already exists.
    If it does, it will check if the version in the repository is newer.
    It will then deploy the template spec only if the version in the repository is newer than the one in Azure.
.EXAMPLE
    .\Deploy-Specs.ps1 -Path .\ -ResourceGroupName 'exampleResourceGroup' -Location 'WestEurope'

    ===
    Will check all JSON files in the Root path and deploy if needed to exampleResourceGroup in the region WestEurope
.PARAMETER Path
    The path that is scanned for JSON files. subfolders are included
.PARAMETER ResourceGroupName
    The resource group where the Template Specs should be stored. Will be created if it doesn't exist
.PARAMETER Location
    The Azure region where the Template Specs should be stored
.LINK
    https://4bes.nl/2021/05/09/from-bicep-to-arm-template-specs-with-azure-devops/
.NOTES
    Created by Barbara Forbes
    https://4bes.nl
    @ba4bes
#>
[cmdletbinding()]
param(
    [parameter(Mandatory = $true)]
    [string]$Path  ,
    [parameter(Mandatory = $true)]
    [string]$ResourceGroupName  ,
    [parameter(Mandatory = $true)]
    [string]$Location
)

#Create resource group if it does not exist
Try {
    $null = Get-AzResourceGroup $ResourceGroupName -ErrorAction Stop
    Write-Host "##[debug] ResourceGroup $ResourceGroupName exists and will be used"
}
Catch {
    Write-Host "##[command]Creating ResourceGroup $ResourceGroupName"
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
        Write-Host "## [debug] TemplateSpec $TemplateSpecName does not exist"
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
        Try {
            $null = New-AzTemplateSpec @SpecParameters
        }
        Catch {
            Write-Error "##[error]Something went wrong with deploying $TemplateSpecName : $_"
        }
    }
    else {
        Write-Host "##[debug] $TemplateSpecName is up to date"
    }
}
