function Get-ChildItemBySize {
    Get-ChildItem -Force |
        Add-Member -Force -PassThru -Type ScriptProperty -Name Length -Value {
            Get-ChildItem $this -Recurse -Force | Measure-Object -Sum Length | Select-Object -Expand Sum } |
        Sort-Object Length -Descending |
        Format-Table @{ label = "TotalSize (KB)"; expression = { [math]::Truncate($_.Length / 1KB) }; width = 14 },
        @{ label = "Mode"; expression = { $_.Mode }; width = 8 },
        Name
}


Export-ModuleMember -Function Get-ChildItemBySize