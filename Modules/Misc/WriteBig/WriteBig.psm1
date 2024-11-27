function Write-CharType {

	<#
		.SYNOPSIS
		Writes a char to the terminal
	#>

    [CmdletBinding()]
    param(
        [string]$Number,
        [string]$Type = "fill_hc",
		[string]$ForegroundColor = $Host.UI.RawUI.ForegroundColor,
		[string]$BackgroundColor = $Host.UI.RawUI.BackgroundColor  
    ) 

	try {

		switch ($Type) {
			"fill_hc" {
				if ($Number -eq 1) { $char = [char]0x2588 } else { $char = [char]0x2591 }
			}
			"fill_lc" {
				if ($Number -eq 1) { $char = [char]0x2593 } else { $char = [char]0x2592 }
			}
			"love" {
				if ($Number -eq 1) { $char = [char]0x2665 } else { $char = [char]0x25CB }
			}
			"square" {
				if ($Number -eq 1) { $char = [char]0x2B1B } else { $char = [char]0x2B1C }
			}
			"circle" {
				if ($Number -eq 1) { $char = [char]0x26AB } else { $char = [char]0x26AA }
			}
			"happy" {
				if ($Number -eq 1) { $char = [char]0x1F60A } else { $char = [char]0x2764 }
			}
			"music" {
				if ($Number -eq 1) { $char = [char]0x1F3B5 } else { $char = [char]0x1F3B6 }
			}
			"hot" {
				if ($Number -eq 1) { $char = [char]0x1F525 } else { $char = [char]0x1F4A5 }
			}
			"surprise" {
				if ($Number -eq 1) { $char = [char]0x1F381 } else { $char = [char]0x1F389 }
			}
			"cold" {
				if ($Number -eq 1) { $char = [char]0x2744 } else { $char = [char]0x1F327 }
			}
			"money" {
				if ($Number -eq 1) { $char = [char]0x1F4B8 } else { $char = [char]0x1F4B0 }
			}
			"sunny" {
				if ($Number -eq 1) { $char = [char]0x1F31E } else { $char = [char]0x1F334 }
			}
			default {
				if ($Number -eq 1) { $char = [char]0x2588 } else { $char = [char]0x2591 }		
			}
		}
	}
	catch {
		# fallback
		if ($Number -eq 1) { $char = [char]0x2588 } else { $char = [char]0x2591 }
	}

	try {
		Write-Host $char -NoNewline -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
	}
	catch {
		Write-Host $char -NoNewline
	}
    
}

function Write-BigWord {

	<#
		.SYNOPSIS
			Write a big word in the terminal	
		.NOTES
			-RandomColors overwrites other set colors	
			To make terminal compatible set: [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
				
		.INPUTS	
			-Word: The word to display
			-Type can be: "fill_hc", "fill_hc", "love", "square", "circle", "happy", "music", "hot", "surprise", "cold", "money", "sunny" or "random"
			-RandomColors: turn off or on, turning this on will usually override manual color settings
				"word" the word will get random predefined colors
				"letter" each letter foreground will get a random color		
			-ForegroundColorOne foreground color of the chars that create the letter itself
			-BackgroundColorOne background color  of the chars that create the letter itself
			-ForegroundColorZero foreground color of the chars that create the background of the letter
			-BackgroundColorZero background color  of the chars that create the background of the letter
	
	#>

    [CmdletBinding()]
    param(        
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Word,
        [string]$Type = "fill_hc",
		[string]$RandomColors = "false", # overwrites other color values
		[string]$ForegroundColorOne = $Host.UI.RawUI.ForegroundColor,
		[string]$BackgroundColorOne = $Host.UI.RawUI.BackgroundColor,		
		[string]$ForegroundColorZero = $Host.UI.RawUI.ForegroundColor,
		[string]$BackgroundColorZero = $Host.UI.RawUI.BackgroundColor 
    )

	$letters = $Word.ToCharArray()
	$letterColors = New-Object -TypeName System.Collections.ArrayList

	# When type is random
	if ($Type -eq "random") {
		$allTypes = @("fill_hc","fill_hc","love","square","circle","happy","music","hot","surprise","cold","money","sunny")
		$Type = $allTypes[$(Get-Random -Minimum 0 -Maximum ($allTypes.Count -1))]
	}

	# When color is random
	$allColors = @( "Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")
	
	if ($RandomColors -eq "word") {
		$ForegroundColorOne  = $allColors[$(Get-Random -Minimum 0 -Maximum ($allColors.Count -1))]
		$ForegroundColorZero = $allColors[$(Get-Random -Minimum 0 -Maximum ($allColors.Count -1))]
		# Random background color, that always differs from foreground color
		do {
			$BackgroundColorOne  = $allColors[$(Get-Random -Minimum 0 -Maximum ($allColors.Count -1))]
			$BackgroundColorZero = $allColors[$(Get-Random -Minimum 0 -Maximum ($allColors.Count -1))]
		}
		while ($BackgroundColorOne -eq $ForegroundColorOne -or 
			$BackgroundColorOne -eq $ForegroundColorZero -or 
			$BackgroundColorZero -eq $ForegroundColorOne -or 
			$BackgroundColorZero -eq $ForegroundColorZero)		
	}
	# generate a color per letter
	elseif ($RandomColors -eq "letter") {

		foreach ($letter in $letters) {
			$letterColors.Add(
			@(
				$allColors[$(Get-Random -Minimum 0 -Maximum ($allColors.Count -1))],
				$allColors[$(Get-Random -Minimum 0 -Maximum ($allColors.Count -1))]
			)) | Out-Null
		}

		if ($BackgroundColorZero -eq $Host.UI.RawUI.BackgroundColor) {
			$BackgroundColorZero = $allColors[$(Get-Random -Minimum 0 -Maximum ($allColors.Count -1))]
		}
		if ($ForeGroundColorZero -eq $Host.UI.RawUI.BackgroundColor) {
			$ForeGroundColorZero = $allColors[$(Get-Random -Minimum 0 -Maximum ($allColors.Count -1))]
		}
	}	

    # go over each line
    for ($i = 0; $i -lt 5; $i++) {
       
		$letterNum = 0
        foreach ($letter in $letters) {
            $letter = [string]$letter
            $letter = $letter.ToLower();

			# get letter to draw from dict
            $drawLetter = $letterDict.$letter[$i]

			# color per letter if set
			if ($letterColors.Count -gt 0) {
				$ForegroundColorOne = $letterColors[$letterNum][0]
				$BackgroundColorOne = $letterColors[$letterNum][1]
			}
            
            foreach ($Number in $drawLetter) {
				if ($Number -eq 1) {
					#Write-Host "$Number $ForegroundColorOne $BackgroundColorOne"
					Write-CharType -Number $Number -Type $Type -ForegroundColor $ForegroundColorOne -BackgroundColor $BackgroundColorOne
				}
				else {
					#Write-Host "$Number $ForegroundColorZero $BackgroundColorZero"
					Write-CharType -Number $Number -Type $Type -ForegroundColor $ForegroundColorZero -BackgroundColor $BackgroundColorZero
				}                
            }

			$letterNum++
        }
        Write-Host "" # new line
    }    
}

# Letter dictionary
$letterDict = @{
" " = @(
    @(0, 0, 0),
    @(0, 0, 0),
    @(0, 0, 0),
    @(0, 0, 0),
    @(0, 0, 0)
)
a = @(
    @(0, 0, 1, 1, 0, 0),
    @(0, 1, 0, 0, 1, 0),
    @(0, 1, 1, 1, 1, 0),
    @(0, 1, 0, 0, 1, 0),
    @(0, 1, 0, 0, 1, 0)
)
b = @(
	@(0, 1, 1, 1, 0, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 1, 1, 0, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 1, 1, 0, 0)
)
c = @(
	@(0, 0, 1, 1, 1, 0),
	@(0, 1, 0, 0, 0, 0),
	@(0, 1, 0, 0, 0, 0),
	@(0, 1, 0, 0, 0, 0),
	@(0, 0, 1, 1, 1, 0)
)
d = @(
	@(0, 1, 1, 1, 0, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 1, 1, 0, 0)
)
e = @(
	@(0, 1, 1, 1, 0),
	@(0, 1, 0, 0, 0),
	@(0, 1, 1, 0, 0),
	@(0, 1, 0, 0, 0),
	@(0, 1, 1, 1, 0)
)
f = @(
	@(0, 1, 1, 1, 1, 0),
	@(0, 1, 0, 0, 0, 0),
	@(0, 1, 1, 1, 0, 0),
	@(0, 1, 0, 0, 0, 0),
	@(0, 1, 0, 0, 0, 0)
)
g = @(
	@(0, 0, 1, 1, 1, 0),
	@(0, 1, 0, 0, 0, 0),
	@(0, 1, 0, 1, 1, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 0, 1, 1, 1, 0)
)
h = @(
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 1, 1, 1, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 0, 0, 1, 0)
)
i = @(
	@(0, 1, 1, 1, 0),
	@(0, 0, 1, 0, 0),
	@(0, 0, 1, 0, 0),
	@(0, 0, 1, 0, 0),
	@(0, 1, 1, 1, 0)
)
j = @(
	@(0, 0, 1, 1, 1, 0),
	@(0, 0, 0, 0, 1, 0),
	@(0, 0, 0, 0, 1, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 0, 1, 1, 1, 0)
)
k = @(
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 0, 1, 0, 0),
	@(0, 1, 1, 0, 0, 0),
	@(0, 1, 0, 1, 0, 0),
	@(0, 1, 0, 0, 1, 0)
)
l = @(
	@(0, 1, 0, 0, 0, 0),
	@(0, 1, 0, 0, 0, 0),
	@(0, 1, 0, 0, 0, 0),
	@(0, 1, 0, 0, 0, 0),
	@(0, 1, 1, 1, 1, 0)
)
m = @(
	@(0, 1, 0, 0, 0, 1, 0),
	@(0, 1, 1, 1, 1, 1, 0),
	@(0, 1, 0, 1, 0, 1, 0),
	@(0, 1, 0, 0, 0, 1, 0),
	@(0, 1, 0, 0, 0, 1, 0)
)

n = @(
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 1, 0, 1, 0),
	@(0, 1, 0, 1, 1, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 0, 0, 1, 0)
)
o = @(
	@(0, 0, 1, 1, 0, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 0, 1, 1, 0, 0)
)
p = @(
	@(0, 1, 1, 1, 0, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 1, 1, 0, 0),
	@(0, 1, 0, 0, 0, 0),
	@(0, 1, 0, 0, 0, 0)
)
q = @(
	@(0, 0, 1, 1, 1, 0, 0),
	@(0, 1, 0, 0, 0, 1, 0),
	@(0, 1, 0, 0, 0, 1, 0),
	@(0, 1, 0, 0, 1, 0, 0),
	@(0, 0, 1, 1, 0, 1, 0)
)
r = @(
	@(0, 1, 1, 1, 0, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 1, 1, 0, 0),
	@(0, 1, 0, 1, 0, 0),
	@(0, 1, 0, 0, 1, 0)
)
s = @(
	@(0, 0, 1, 1, 1, 0),
	@(0, 1, 0, 0, 0, 0),
	@(0, 0, 1, 1, 0, 0),
	@(0, 0, 0, 0, 1, 0),
	@(0, 1, 1, 1, 0, 0)
)
t = @(
	@(0, 1, 1, 1, 1, 1, 0),
	@(0, 0, 0, 1, 0, 0, 0),
	@(0, 0, 0, 1, 0, 0, 0),
	@(0, 0, 0, 1, 0, 0, 0),
	@(0, 0, 0, 1, 0, 0, 0)
)
u = @(
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 0, 0, 1, 0),
	@(0, 1, 1, 1, 1, 0)
)
v = @(
	@(0, 1, 0, 0, 0, 1, 0),
	@(0, 1, 0, 0, 0, 1, 0),
	@(0, 1, 0, 0, 0, 1, 0),
	@(0, 0, 1, 0, 1, 0, 0),
	@(0, 0, 0, 1, 0, 0, 0)
)
w = @(
	@(0, 1, 0, 0, 0, 1, 0),
	@(0, 1, 0, 0, 0, 1, 0),
	@(0, 1, 0, 1, 0, 1, 0),
	@(0, 1, 1, 0, 1, 1, 0),
	@(0, 1, 0, 0, 0, 1, 0)
)
x = @(
	@(0, 1, 0, 0, 0, 1, 0),
	@(0, 0, 1, 1, 1, 0, 0),
	@(0, 0, 0, 1, 0, 0, 0),
	@(0, 0, 1, 1, 1, 0, 0),
	@(0, 1, 0, 0, 0, 1, 0)
)
y = @(
	@(0, 1, 0, 0, 0, 1, 0),
	@(0, 0, 1, 0, 1, 0, 0),
	@(0, 0, 0, 1, 0, 0, 0),
	@(0, 0, 0, 1, 0, 0, 0),
	@(0, 0, 0, 1, 0, 0, 0)
)
z = @(
	@(0, 1, 1, 1, 1, 1, 0),
	@(0, 0, 0, 0, 1, 0, 0),
	@(0, 0, 0, 1, 0, 0, 0),
	@(0, 0, 1, 0, 0, 0, 0),
	@(0, 1, 1, 1, 1, 1, 0)
)
'!' = @(
	@(0, 1, 1, 0),
	@(0, 1, 1, 0),
	@(0, 1, 1, 0),
	@(0, 0, 0, 0),
	@(0, 1, 1, 0)
)

}


Export-ModuleMember -Function Write-BigWord