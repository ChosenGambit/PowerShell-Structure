# Path to the install script
$prerequisites_script = "$PSScriptRoot\prerequisites.ps1"

# Path to the install script
$install_winget_script = "$PSScriptRoot\install_winget.ps1"

# installs winget apps
$install_winget_apps_script = "$PSScriptRoot\install_winget_apps.ps1"

# Path to the clean script
$clean_script = "$PSScriptRoot\clean.ps1"

# Open a new terminal window and execute the install script
$prerequisites_process = Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "& {Start-Sleep -Seconds 1; & '$prerequisites_script'; exit}" -PassThru 

# Wait for the prerequisites script to complete
$prerequisites_process | Wait-Process

# Open a new terminal window and execute the install winget script
$install_winget_script = Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "& {Start-Sleep -Seconds 1; & '$install_winget_script'; exit}" -PassThru

# Wait for the install script to complete
$install_winget_script | Wait-Process

# Open a new terminal window and execute the install apps script
$install_winget_apps_script = Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "& {Start-Sleep -Seconds 1; & '$install_winget_apps_script'; exit}" -PassThru

# Wait for the script to complete
$install_winget_apps_script | Wait-Process

# Open a new terminal window and execute the clean script, this releases the files the install process used
$clean_process = Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "& {Start-Sleep -Seconds 1; & '$clean_script'; exit }" -PassThru


