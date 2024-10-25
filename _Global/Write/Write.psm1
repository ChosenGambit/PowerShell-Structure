# Globals
$global:NeutralForegroundColor = "White"
$global:NeutralBackgroundColor = ""
$global:SuccessForegroundColor = "Green"
$global:SuccessBackgroundColor = ""
$global:ErrorForegroundColor = "Red"
$global:ErrorBackgroundColor = "Black"
$global:InfoForegroundColor = "Cyan"
$global:InfoBackgroundColor = ""
$global:AlertForegroundColor = "Yellow"
$global:AlertBackgroundColor = "DarkRed"
$global:StatusForegroundColor = "Gray"
$global:StatusBackgroundColor = "DarkMagenta"
$global:WriteOutput = $False
$global:WriteToLogFile = $False
$global:LogFilePath = "C:\"

function Write-Colored {
    param( 
        [Parameter(Mandatory=$True)]
        [String]$Str,
        [String]$FColor,
        [String]$BColor,
        [bool]$WriteOutput = $False
    )
    $params = @{      
    }

    if ($FColor -ne $null -and $FColor -ne "") {
        $params['ForegroundColor'] = $FColor
    }

    if ($BColor -ne $null -and $BColor -ne "") {
        $params['BackgroundColor'] = $BColor
    }

    if ($WriteOutput -eq $False -and $global:WriteOutput -eq $False) {
        Write-Host @params $Str 
    }
    else {
        if ($global:WriteToLogFile) {
            $str | Out-File -FilePath $(Join-Path -Path $global:LogFilePath -ChildPath "output.log") -Append
        }
        else {
            Write-Output $Str
        }        
    }
}

function Write-Neutral {
    param( 
        [Parameter(Mandatory=$True)]
        [String]$Str,
        [bool]$WriteOutput = $False
    )
    Write-Colored -WriteOutput $WriteOutput -FColor $global:NeutralForegroundColor -BColor $global:NeutralBackgroundColor $Str
}

function Write-Success {
    param( 
        [Parameter(Mandatory=$True)]
        [String]$Str,
        [bool]$WriteOutput = $False
    )
    Write-Colored -WriteOutput $WriteOutput -FColor $global:SuccessForegroundColor -BColor $global:SuccessBackgroundColor $Str
}

function Write-Error {
    param( 
        [Parameter(Mandatory=$True)]
        [String]$Str,
        [bool]$WriteOutput = $False
    )
    Write-Colored -WriteOutput $WriteOutput -FColor $global:ErrorForegroundColor -BColor $global:ErrorBackgroundColor $Str
}

function Write-Info {
    param( 
        [Parameter(Mandatory=$True)]
        [String]$Str,
        [bool]$WriteOutput = $False
    )
    Write-Colored -WriteOutput $WriteOutput -FColor $global:InfoForegroundColor -BColor $global:InfoBackgroundColor $Str
}

function Write-Alert {
    param( 
        [Parameter(Mandatory=$True)]
        [String]$Str,
        [bool]$WriteOutput = $False
    )
    Write-Colored -WriteOutput $WriteOutput -FColor $global:AlertForegroundColor -BColor $global:AlertBackgroundColor $Str
}

function Write-Status {
    param( 
        [Parameter(Mandatory=$True)]
        [String]$Str,
        [bool]$WriteOutput = $False
    )
    Write-Colored -WriteOutput $WriteOutput -FColor $global:StatusForegroundColor -BColor $global:StatusBackgroundColor $Str
}

Export-ModuleMember -Function Write-Neutral
Export-ModuleMember -Function Write-Success
Export-ModuleMember -Function Write-Error
Export-ModuleMember -Function Write-Info
Export-ModuleMember -Function Write-Alert
Export-ModuleMember -Function Write-Status
