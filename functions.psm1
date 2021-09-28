<# 
╔═════════════════════════════════════════════════════════════════════════════╗
║DEVELOPER DOES NOT WARRANT THAT THE SCRIPT WILL MEET YOUR NEEDS OR BE FREE   ║
║FROM ERRORS, OR THAT THE OPERATIONS OF THE SOFTWARE WILL BE UNINTERRUPTED.   ║
╚═════════════════════════════════════════════════════════════════════════════╝
┌─────────┬───────────────────────────────────────────────────────────────────┐
│Usage    │1) Run CMD or PowerShell as Administrator (Run as Administrator)   │
│         │2) powershell.exe -File .\create-collector.ps1                     │
├─────────┼───────────────────────────────────────────────────────────────────┤
│Developer│Yigit Aktan - yigita@microsoft.com                                 │
└─────────┴───────────────────────────────────────────────────────────────────┘
#>

Function Start-DataCollectorSet
{
 if ($StartCollectorCheck -eq "y")
  {
   if ($SingleSelection -eq "y") {Write-Host "[*] Data Collector Set starting for" $SelectedInstance -ForegroundColor Yellow}
   Start-Sleep -Seconds 5

   for ($i=0; $i -lt $StartCollectorList.Count; $i++)
    {
     if ($SingleSelection -eq "n") {Write-Host "[*] Data Collector Set starting for" $StartCollectorList[$i] -ForegroundColor Yellow}
     $logmanstartparam = "start " + $StartCollectorList[$i] + "_SfMC_Counter_Set"
     Start-Process -WindowStyle hidden -FilePath "logman.exe" -ArgumentList $logmanstartparam 
   
     Delete-CounterFile
  } 
   $(AllDone)
}
elseif ($StartCollectorCheck -eq "n")
   {
    Start-Sleep -Seconds 7
    Delete-CounterFile
    AllDone
   }
}


Function Delete-CounterFile
{
 for ($i=0; $i -lt $StartCollectorList.Count; $i++)
  {
   $FileName = $PSScriptRoot + "\" + $StartCollectorList[$i]  + ".txt" 
   if (Test-Path $FileName) {Remove-Item $FileName -recurse -force}
  }
}


Function Get-SqlInstances 
{
 Param($ServerName = $env:computername)

 $localInstances = @()
 [array]$captions = gwmi win32_service -computerName $ServerName | ?{$_.Name -match "mssql*" -and $_.PathName -match "sqlservr.exe"} | %{$_.Caption}
 foreach ($caption in $captions) 
  {
   $count += 1
   $all = $count + 1
    if ($caption -eq "MSSQLSERVER") {$localInstances += "MSSQLSERVER"} 
    else 
     {
      $temp = $caption | %{$_.split(" ")[-1]} | %{$_.trimStart("(")} | %{$_.trimEnd(")")}

      $SqlInstanceMenuArrayList.Add("$count) $ServerName\$temp") > $null
      $SqlInstanceArrayList.Add("$temp") > $null
     }
  }
  $TotalInstanceCount = $captions.Count
  if ($captions.Count -gt 1)
   {
    $global:SingleInstanceCheck = "n"
    $SqlInstanceMenuArrayList.Add("$all) All") > $null
    $SqlInstanceArrayList.Add("All") > $null
    $global:IsSQL = "yes"
   }
  if ($captions.Count -eq 1)
   {
    $global:SingleInstanceCheck = "y"
    $global:IsSQL = "yes"
   }
  if ($captions.Count -eq 0)
   {
    $global:IsSQL = "no"
   }
}


Function Write-Colr
{
    Param ([String[]]$Text,[ConsoleColor[]]$Colour,[Switch]$NoNewline=$false)
    For ([int]$i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -Foreground $Colour[$i] -NoNewLine }
    If ($NoNewline -eq $false) { Write-Host '' }
}


Function AllDone
{
 Write-Host ""
 Write-Host "┌────────────┐" -ForegroundColor DarkCyan
 Write-Colr -Text '│', ' Completed! ', '│' -Colour DarkCyan, Cyan, DarkCyan
 Write-Host "└────────────┘" -ForegroundColor DarkCyan
}


Function Delete-BlgFile([String] $Instance)
{
 If (Test-Path $LogFilePath)
  {
   $FileName = $Instance + '_sfmc_perfmon_[0-9]+\.blg'
   Get-ChildItem -Path $LogFilePath | Where-Object {$_.name -match $FileName} | Remove-Item
  }
}