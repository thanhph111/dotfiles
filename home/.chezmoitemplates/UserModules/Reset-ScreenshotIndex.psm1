function Reset-ScreenshotIndex {
    Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name ScreenshotIndex -Value 1
}


Export-ModuleMember -Function Reset-ScreenshotIndex