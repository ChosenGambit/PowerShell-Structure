# for finding appx packages locally
.$PSScriptRoot\..\..\Dependencies\AppxSupport\AppxHelper.ps1

function Install-LatestVCLibs {
    
    $architecture = Get-SystemArchitecture 
    $url = "https://aka.ms/Microsoft.VCLibs.$($architecture).14.00.Desktop.appx"
    $file = "Microsoft.VCLibs_cg.appx"
    $fullPath = "$HOME\Downloads\$file"


    $found = Find-LocalAppxPackage -PackageName "VCLibs"

    if (! $found) {
        Invoke-WebRequest -Uri $url -OutFile $fullPath
        Start-Sleep -Seconds 2
        Add-AppxPackage -Path $fullPath -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $f=Find-LocalAppxPackage -PackageName "VCLibs" #prevent return output
    }
}
