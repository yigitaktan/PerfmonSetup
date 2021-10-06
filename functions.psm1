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
 If ($StartCollectorCheck -eq "y")
  {
   If ($SingleSelection -eq "y") {Write-Host "[*] Data Collector Set starting for" $SelectedInstance -ForegroundColor Yellow}
   Start-Sleep -Seconds 5

   For ($i=0; $i -lt $StartCollectorList.Count; $i++)
    {
     If ($SingleSelection -eq "n") {Write-Host "[*] Data Collector Set starting for" $StartCollectorList[$i] -ForegroundColor Yellow}
     $logmanstartparam = "start " + $StartCollectorList[$i] + "_SfMC_Counter_Set"
     Start-Process -WindowStyle hidden -FilePath "logman.exe" -ArgumentList $logmanstartparam 
   
     Delete-CounterFile 
    } 
   $(AllDone)
  }
 ElseIf ($StartCollectorCheck -eq "n")
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

      $global:SqlInstanceMenuArrayList.Add("$count) $ServerName\$temp") > $null
      $global:SqlInstanceArrayList.Add("$temp") > $null
     }
  }
  $TotalInstanceCount = $captions.Count
  if ($captions.Count -gt 1)
   {
    $global:SingleInstanceCheck = "n"
    $global:SqlInstanceMenuArrayList.Add("$all) All") > $null
    $global:SqlInstanceArrayList.Add("All") > $null
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


Function Create-DataCollectorSet
 {
  If (($global:SqlInstanceArrayList[$global:InstanceNumber - 1] -ne "All") -and ($global:SqlInstanceArrayList[$global:InstanceNumber - 1] -ne "MSSQLSERVER")) #If single named instance selected   
   {
    $global:SelectedInstance = $global:SqlInstanceArrayList[$global:InstanceNumber - 1]
    ((Get-Content -path $PSScriptRoot\counterset.txt -Raw) -replace '\[MYINSTANCENAME]:',('MSSQL$'+$global:SelectedInstance+':')) | Set-Content -Path $PSScriptRoot\$global:SelectedInstance.txt
 
    Delete-BlgFile -Instance $global:SelectedInstance
                        
    $logmanparam = "CREATE COUNTER -n " + $global:SelectedInstance + "_SfMC_Counter_Set -s . -cf " + $PSScriptRoot + "\" + $global:SelectedInstance + ".txt -f bincirc -max " + $MaxLogFileSize + " -si " + $IntervalNumber + " -o " + $global:LogFilePath + "\" + $global:SelectedInstance + "_sfmc_perfmon.blg"                 
    Start-Process -WindowStyle hidden -FilePath "logman.exe" -ArgumentList $logmanparam

    $global:SingleSelection = "y"
                    
    If ($global:StartCollectorList -notcontains $global:SelectedInstance){ $global:StartCollectorList.Add($global:SelectedInstance) > $null }
    Write-Host "[*] Data Collector Set creating for" $global:SelectedInstance -ForegroundColor DarkYellow
   } 
  ElseIf ($global:SqlInstanceArrayList[$global:InstanceNumber - 1] -eq "MSSQLSERVER") #If default instance selected
   {
    $global:SelectedInstance = $global:SqlInstanceArrayList[$global:InstanceNumber - 1]
    ((Get-Content -path $PSScriptRoot\counterset.txt -Raw) -replace '\[MYINSTANCENAME]:','SQLServer:') | Set-Content -Path $PSScriptRoot\$global:SelectedInstance.txt

    Delete-BlgFile -Instance $global:SelectedInstance

    $logmanparam = "CREATE COUNTER -n " + $global:SelectedInstance + "_SfMC_Counter_Set -s . -cf " + $PSScriptRoot + "\" + $global:SelectedInstance + ".txt -f bincirc -max " + $MaxLogFileSize + " -si " + $IntervalNumber + " -o " + $global:LogFilePath + "\" + $global:SelectedInstance + "_sfmc_perfmon.blg"                              
    Start-Process -WindowStyle hidden -FilePath "logman.exe" -ArgumentList $logmanparam

    $global:SingleSelection = "y"
                    
    If ($global:StartCollectorList -notcontains $global:SelectedInstance){ $global:StartCollectorList.Add($global:SelectedInstance) > $null }
    Write-Host "[*] Data Collector Set creating for" $global:SelectedInstance -ForegroundColor DarkYellow
   }
  ElseIf (($global:SqlInstanceArrayList[$global:InstanceNumber - 1] = "All") -and ($SingleInstanceCheck -eq "n")) #If all instances selected
   {
    $global:SingleSelection = "n"
    For ($i=0; $i -lt $global:SqlInstanceArrayList.Count-1; $i++) 
     {
      $filename = $PSScriptRoot + "\" + $global:SqlInstanceArrayList[$i] + ".txt"
      $global:SelectedInstance = "All"

      If ($global:StartCollectorList -notcontains $global:SqlInstanceArrayList[$i]){ $global:StartCollectorList.Add($global:SqlInstanceArrayList[$i]) > $null }
      Write-Host "[*] Data Collector Set creating for" $global:SqlInstanceArrayList[$i] -ForegroundColor DarkYellow

      If ($global:SqlInstanceArrayList[$i] -eq "MSSQLSERVER")
       {
        ((Get-Content -path $PSScriptRoot\counterset.txt -Raw) -replace '\[MYINSTANCENAME]:','SQLServer:') | Set-Content -Path $filename

        Delete-BlgFile -Instance $global:SqlInstanceArrayList[$i]

        $logmanparam = "CREATE COUNTER -n MSSQLSERVER_SfMC_Counter_Set -s . -cf " + $PSScriptRoot + "\MSSQLSERVER.txt -f bincirc -max " + $MaxLogFileSize + " -si " + $IntervalNumber + " -o " + $global:LogFilePath + "\MSSQLSERVER_sfmc_perfmon.blg"                 
        Start-Process -WindowStyle hidden -FilePath "logman.exe" -ArgumentList $logmanparam
            
        If ($global:StartCollectorList -notcontains 'MSSQLSERVER'){ $global:StartCollectorList.Add("MSSQLSERVER") > $null }
       }
      Else
       {
        ((Get-Content -path $PSScriptRoot\counterset.txt -Raw) -replace '\[MYINSTANCENAME]:',('MSSQL$'+$global:SqlInstanceArrayList[$i]+':')) | Set-Content -Path $filename

        Delete-BlgFile -Instance $global:SqlInstanceArrayList[$i]

        $logmanparam = "CREATE COUNTER -n " + $global:SqlInstanceArrayList[$i] + "_SfMC_Counter_Set -s . -cf " + $PSScriptRoot +"\" + $global:SqlInstanceArrayList[$i] + ".txt -f bincirc -max " + $MaxLogFileSize + " -si " + $IntervalNumber + " -o " + $global:LogFilePath + "\" + $global:SqlInstanceArrayList[$i] + "_sfmc_perfmon.blg"                 
        Start-Process -WindowStyle hidden -FilePath "logman.exe" -ArgumentList $logmanparam
                     
        If ($global:StartCollectorList -notcontains $global:SqlInstanceArrayList[$i]){ $global:StartCollectorList.Add($global:SqlInstanceArrayList[$i]) > $null }
       }
      }              
     }
  Start-DataCollectorSet
 }
