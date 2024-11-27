# for finding appx packages locally
.$PSScriptRoot\..\..\Helpers\AppxSupport\AppxHelper.ps1

function Install-LatestVCLibs {

    param(
        $FilePath
    )
    
    $architecture = Get-SystemArchitecture 
    $url = "https://aka.ms/Microsoft.VCLibs.$($architecture).14.00.Desktop.appx"
    $file = "Microsoft.VCLibs_cg.appx"

    if ($PSBoundParameters.ContainsKey('FilePath')) {
        $fullPath = "$FilePath\$file"
    }
    else {
        $fullPath = "$HOME\Downloads\$file"
    }    

    $found = Find-LocalAppxPackage -PackageName "VCLibs"

    if (! $found) {

        # check local before downloading
        if (Test-Path -Path $fullPath) {
            Write-Info "Found $fullPath"
            Add-AppxPackage -Path $fullPath -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        } 
        else {
            # download
            Write-Info "Downloading VCLibs"
            Invoke-WebRequest -Uri $url -OutFile $fullPath
            Start-Sleep -Seconds 2
            Add-AppxPackage -Path $fullPath -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            $f=Find-LocalAppxPackage -PackageName "VCLibs" #prevent return output
        }
    }
}





