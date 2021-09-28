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


Import-Module $PSScriptRoot\functions.psm1


cls

$AppVer = '09.2021.1'

$SqlInstanceMenuArrayList = New-Object -TypeName "System.Collections.ArrayList"
$SqlInstanceMenuArrayList = [System.Collections.ArrayList]@()
$SqlInstanceArrayList = New-Object -TypeName "System.Collections.ArrayList"
$SqlInstanceArrayList = [System.Collections.ArrayList]@()
$StartCollectorList = New-Object -TypeName "System.Collections.ArrayList"
$StartCollectorList = [System.Collections.ArrayList]@()

#Caption
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
Write-Host "║ Perfmon Data Collector Set Setup for SQL Server instances  ║" -ForegroundColor Gray
Write-Host "╠═════════════╦═══════════╦══════════════════════╦═══════════╣" -ForegroundColor Gray
Write-Host "║ Yigit Aktan ║ Microsoft ║ yigita@microsoft.com ║" $AppVer "║" -ForegroundColor Gray
Write-Host "╚═════════════╩═══════════╩══════════════════════╩═══════════╝" -ForegroundColor Gray
Write-Host ""

#Administrator permission check
if (-not([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
 {
  Write-Colr -Text '[x] ', 'Insufficient permissions to run this script.' -Colour Gray, Red
  Write-Colr -Text '    Open the PowerShell console as an administrator and run this script again.' -Colour Red
  exit
 }

#Counter file check
if (-not(Test-Path -Path $PSScriptRoot\counterset.txt -PathType Leaf)) 
 {
  Write-Colr -Text '[x] ', 'Could not find counter set file! (counterset.txt)' -Colour Gray, Red
  exit
 }

#List all SQL instances
Get-SqlInstances
 
#Check if there is not SQL instance
if ($global:IsSQL -eq "no")
 {
  Write-Colr -Text '[*] ', 'There is no SQL Server instance on this server!'  -Colour Gray, Red
  exit
 }

#Select SQL instance
Write-Host "Which instance you would like to create Data Collector Set for?" -ForegroundColor Yellow
Write-Host ""
$SqlInstanceMenuArrayList
Write-Host ""
$InstanceNumber = Read-Host "Enter selection number (CTRL+C to quit)"
if (($InstanceNumber -gt $SqlInstanceMenuArrayList.Count) -or (!$InstanceNumber))
{
  Write-Host ""
  Write-Host "Please enter a valid number from list above!"
  Write-Host ""
  Start-Sleep -Milliseconds 300
} else{

#Set data collection interval
Write-Host ""
Write-Host "[+]" $SqlInstanceArrayList[$InstanceNumber - 1]   -ForegroundColor Green
Write-Host ""
Write-Host "Enter data collection interval " -NoNewline
Write-Host "(default: 00:00:15)" -ForegroundColor Yellow -NoNewline
Write-Host ": " -NoNewline
$IntervalNumber  = Read-Host 
Write-Host ""
 if (!$IntervalNumber) 
  {
   Write-Host "[+]" 00:00:15 -ForegroundColor Green 
   $IntervalNumber = "00:00:15"
  }
 else 
  { 
   Write-Host "[+]" $IntervalNumber -ForegroundColor Green
  }

#Set max log file size
Write-Host ""
Write-Host "Enter maximum log file size in MB " -NoNewline
Write-Host "(default: 700)" -ForegroundColor Yellow -NoNewline
Write-Host ": " -NoNewline
$MaxLogFileSize  = Read-Host 
Write-Host ""
 if (!$MaxLogFileSize)
  {
   Write-Host "[+] 700MB" -ForegroundColor Green
   $MaxLogFileSize = "700"
  }
 else 
  { 
   Write-Host "[+]" $MaxLogFileSize "MB" -ForegroundColor Green
  }

#BLG file path
Write-Host ""
Write-Host "Enter output (*.blg) file path " -NoNewline
Write-Host "(default: C:\temp)" -ForegroundColor Yellow -NoNewline
Write-Host ": " -NoNewline
$LogFilePath  = Read-Host 
Write-Host ""
 if (!$LogFilePath)
  { 
   Write-Host "[+] C:\temp" -ForegroundColor Green 
   $LogFilePath = "C:\temp"
  }
 else 
  { 
   Write-Host "[+]" $LogFilePath -ForegroundColor Green 
  }

#Start data collector set?
Write-Host ""
$StartCollector = Read-Host "Would you like to start data collector set after created? (Y/N)"
 if ($StartCollector -eq "y" -or $StartCollector -eq "n") 	    
  {
   if (!$StartCollector -or $StartCollector -eq "y")
    {
     $StartCollectorCheck = "y"
     Write-Host ""
	 Write-Host "[+] Yes" -ForegroundColor Green
	 Write-Host ""
    }	   
   elseif ($StartCollector -eq "n")
    {
     $StartCollectorCheck = "n"
     Write-Host ""
	 Write-Host "[+] No" -ForegroundColor Green
	 Write-Host ""
    }
Write-Host ""


     if (($SqlInstanceArrayList[$InstanceNumber - 1] -ne "All") -and ($SqlInstanceArrayList[$InstanceNumber - 1] -ne "MSSQLSERVER")) #If single named instance selected   
     {
      $SelectedInstance = $SqlInstanceArrayList[$InstanceNumber - 1]
      ((Get-Content -path $PSScriptRoot\counterset.txt -Raw) -replace '\[MYINSTANCENAME]:',('MSSQL$'+$SelectedInstance+':')) | Set-Content -Path $PSScriptRoot\$SelectedInstance.txt
      
      Delete-BlgFile -Instance $SelectedInstance
                        
      $logmanparam = "CREATE COUNTER -n " + $SelectedInstance + "_SfMC_Counter_Set -s . -cf " + $PSScriptRoot + "\" + $SelectedInstance + ".txt -f bincirc -max " + $MaxLogFileSize + " -si " + $IntervalNumber + " -o " + $LogFilePath + "\" + $SelectedInstance + "_sfmc_perfmon.blg"                 
      Start-Process -WindowStyle hidden -FilePath "logman.exe" -ArgumentList $logmanparam

      $SingleSelection = "y"
                    
      if ($StartCollectorList -notcontains $SelectedInstance){ $StartCollectorList.Add($SelectedInstance) > $null }
      Write-Host "[*] Data Collector Set creating for" $SelectedInstance -ForegroundColor Green
     } 
    elseif ($SqlInstanceArrayList[$InstanceNumber - 1] -eq "MSSQLSERVER") #If default instance selected
     {
      $SelectedInstance = $SqlInstanceArrayList[$InstanceNumber - 1]
      ((Get-Content -path $PSScriptRoot\counterset.txt -Raw) -replace '\[MYINSTANCENAME]:','SQLServer:') | Set-Content -Path $PSScriptRoot\$SelectedInstance.txt

      Delete-BlgFile -Instance $SelectedInstance

      $logmanparam = "CREATE COUNTER -n " + $SelectedInstance + "_SfMC_Counter_Set -s . -cf " + $PSScriptRoot + "\" + $SelectedInstance + ".txt -f bincirc -max " + $MaxLogFileSize + " -si " + $IntervalNumber + " -o " + $LogFilePath + "\" + $SelectedInstance + "_sfmc_perfmon.blg"                              
      Start-Process -WindowStyle hidden -FilePath "logman.exe" -ArgumentList $logmanparam

      $SingleSelection = "y"
                    
      if ($StartCollectorList -notcontains $SelectedInstance){ $StartCollectorList.Add($SelectedInstance) > $null }
      Write-Host "[*] Data Collector Set creating for" $SelectedInstance -ForegroundColor Green
     }
    elseif (($SqlInstanceArrayList[$InstanceNumber - 1] = "All") -and ($SingleInstanceCheck -eq "n")) #If all instances selected
     {
      $SingleSelection = "n"
       for ($i=0; $i -lt $SqlInstanceArrayList.Count-1; $i++) 
        {
         $filename = $PSScriptRoot + "\" + $SqlInstanceArrayList[$i] + ".txt"
         $SelectedInstance = "All"

         if ($StartCollectorList -notcontains $SqlInstanceArrayList[$i]){ $StartCollectorList.Add($SqlInstanceArrayList[$i]) > $null }
         Write-Host "[*] Data Collector Set creating for" $SqlInstanceArrayList[$i] -ForegroundColor Green

          if ($SqlInstanceArrayList[$i] -eq "MSSQLSERVER")
           {
            ((Get-Content -path $PSScriptRoot\counterset.txt -Raw) -replace '\[MYINSTANCENAME]:','SQLServer:') | Set-Content -Path $filename

            Delete-BlgFile -Instance $SqlInstanceArrayList[$i]

            $logmanparam = "CREATE COUNTER -n MSSQLSERVER_SfMC_Counter_Set -s . -cf " + $PSScriptRoot + "\MSSQLSERVER.txt -f bincirc -max " + $MaxLogFileSize + " -si " + $IntervalNumber + " -o " + $LogFilePath + "\MSSQLSERVER_sfmc_perfmon.blg"                 
            Start-Process -WindowStyle hidden -FilePath "logman.exe" -ArgumentList $logmanparam
            
            if ($StartCollectorList -notcontains 'MSSQLSERVER'){ $StartCollectorList.Add("MSSQLSERVER") > $null }
           }
          else
           {
            ((Get-Content -path $PSScriptRoot\counterset.txt -Raw) -replace '\[MYINSTANCENAME]:',('MSSQL$'+$SqlInstanceArrayList[$i]+':')) | Set-Content -Path $filename

            Delete-BlgFile -Instance $SqlInstanceArrayList[$i]

            $logmanparam = "CREATE COUNTER -n " + $SqlInstanceArrayList[$i] + "_SfMC_Counter_Set -s . -cf " + $PSScriptRoot +"\" + $SqlInstanceArrayList[$i] + ".txt -f bincirc -max " + $MaxLogFileSize + " -si " + $IntervalNumber + " -o " + $LogFilePath + "\" + $SqlInstanceArrayList[$i] + "_sfmc_perfmon.blg"                 
            Start-Process -WindowStyle hidden -FilePath "logman.exe" -ArgumentList $logmanparam
                     
            if ($StartCollectorList -notcontains $SqlInstanceArrayList[$i]){ $StartCollectorList.Add($SqlInstanceArrayList[$i]) > $null }
           }
        }              
     }
        }
   Start-DataCollectorSet
  }

