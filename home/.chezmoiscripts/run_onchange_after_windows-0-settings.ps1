# Set XDG environment variables
[Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', "$env:USERPROFILE\.config", 'User')
[Environment]::SetEnvironmentVariable('XDG_CACHE_HOME', "$env:USERPROFILE\.cache", 'User')
[Environment]::SetEnvironmentVariable('XDG_STATE_HOME', "$env:USERPROFILE\.local\state", 'User')
[Environment]::SetEnvironmentVariable('XDG_DATA_HOME', "$env:USERPROFILE\.local\share", 'User')
[Environment]::SetEnvironmentVariable('GOPATH', "$env:USERPROFILE\.local\share\go", 'User')

# Hide files and folders starting with a dot in Home directory
Get-ChildItem -Path "$HOME" -Filter '.*' | ForEach-Object { $_.Attributes += 'Hidden' }

# Set natural scrolling for mouses
$mouseDevices = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Enum\HID\*\*\Device Parameters' FlipFlopWheel -ErrorAction SilentlyContinue

foreach ($device in $mouseDevices) {
    Set-ItemProperty $device.PSPath FlipFlopWheel 1
}

# Set up OpenSSH server and client
Add-WindowsCapability -Online -Name OpenSSH.Client;
Add-WindowsCapability -Online -Name OpenSSH.Server;
Start-Service sshd;
Set-Service -Name sshd -StartupType 'Automatic';
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force