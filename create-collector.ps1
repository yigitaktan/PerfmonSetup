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

Import-Module -DisableNameChecking .\functions.psm1

Clear-Host

$AppVer = "09.2023.1.001"

$Global:SqlInstanceMenuArrayList = New-Object -TypeName "System.Collections.ArrayList"
$Global:SqlInstanceMenuArrayList = [System.Collections.ArrayList]@()
$Global:SqlInstanceArrayList = New-Object -TypeName "System.Collections.ArrayList"
$Global:SqlInstanceArrayList = [System.Collections.ArrayList]@()
$Global:StartCollectorList = New-Object -TypeName "System.Collections.ArrayList"
$Global:StartCollectorList = [System.Collections.ArrayList]@()
 
#Caption
Write-Host " ╔═════════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
Write-Host " ║ Setting Up Perfmon Data Collector Set for SQL Server Instances  ║" -ForegroundColor Gray
Write-Host " ╠═════════════╦═══════════╦══════════════════════╦════════════════╣" -ForegroundColor Gray
Write-Host " ║ Yigit Aktan ║ Microsoft ║ yigita@microsoft.com ║" $AppVer     " ║" -ForegroundColor Gray
Write-Host " ╚═════════════╩═══════════╩══════════════════════╩════════════════╝" -ForegroundColor Gray
Write-Host ""

#Administrator permission check
If (-not([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
 {
  Write-Colr -Text ' [x] ', 'You do not have sufficient permissions to execute this script.' -Colour Gray, Red
  Write-Colr -Text '     Please open the PowerShell console as an administrator and rerun this script.' -Colour Red
  exit
 }

#Counter file check
If (-not(Test-Path -Path $PSScriptRoot\counterset.txt -PathType Leaf)) 
 {
  Write-Colr -Text ' [x] ', 'Counter set file not found! (counterset.txt)' -Colour Gray, Red
  exit
 }

#List all SQL Server instances
Get-SqlInstances

#Check if there is no SQL instance
If ($Global:IsSQL -eq "no")
 {
  Write-Colr -Text ' [*] ', 'SQL Server instance does not exist on this server!'  -Colour Gray, Red
  exit
 }

#Select SQL instance
Write-Host " For which instance would you like to create a Data Collector Set?" -ForegroundColor Yellow
Write-Host ""
$Global:SqlInstanceMenuArrayList
Write-Host ""
Do {$Global:InstanceNumber = Read-Host " Please input the selection number (CTRL+C to quit)"}
Until (($Global:InstanceNumber -cle $Global:SqlInstanceMenuArrayList.Count) -and ($Global:InstanceNumber -match '^[1-9]{1}$' -eq "False"  ))
{}
Write-Host " [+]" $Global:SqlInstanceArrayList[$Global:InstanceNumber - 1]   -ForegroundColor Green
Write-Host ""
$IfOnlyOneSelected = $Global:SqlInstanceArrayList[$Global:InstanceNumber - 1]

#Set data collection interval
Do {$Global:IntervalNumber  = $(Write-Host " Please enter the data collection interval in seconds " -NoNewLine) + $(Write-Host "(default: 15)" -ForegroundColor yellow -NoNewLine) + $(Write-Host ": " -NoNewLine; Read-Host) }
Until (($Global:IntervalNumber -match '^[1-9][0-9]{0,3}$') -or (!$Global:IntervalNumber))
Write-Host ""
 If (!$Global:IntervalNumber) 
  {
   Write-Host " [+] 15 seconds" -ForegroundColor Green 
   $Global:IntervalNumber = "15"
  }
 Else 
  { 
   If ($Global:IntervalNumber -eq "1")
    {
     Write-Host " [+]" $Global:IntervalNumber "second" -ForegroundColor Green
    }
   Else
    {
     Write-Host " [+]" $Global:IntervalNumber "seconds" -ForegroundColor Green
    }
  }
Write-Host ""

#Set duration
Do {$Global:DurationNumber  = $(Write-Host " Please input the data collection duration in seconds " -NoNewLine) + $(Write-Host "(default: 86400)" -ForegroundColor yellow -NoNewLine) + $(Write-Host ": " -NoNewLine; Read-Host) }
Until (($Global:DurationNumber -match '^[1-9][0-9]{0,5}$') -or (!$Global:DurationNumber))
Write-Host ""
 If (!$Global:DurationNumber) 
  {
   Write-Host " [+] 86400 seconds" -ForegroundColor Green 
   $Global:DurationNumber = "86400"
  }
 Else 
  { 
   If ($Global:DurationNumber -eq "1")
    {
     Write-Host " [+]" $Global:DurationNumber "second" -ForegroundColor Green
    }
   Else
    {
     Write-Host " [+]" $Global:DurationNumber "seconds" -ForegroundColor Green
    }
  }
Write-Host ""

#Set restart time
Do {$Global:RestartTime  = $(Write-Host " Please specify the data collection restart time (12h format) " -NoNewLine) + $(Write-Host "(default: 12:01AM)" -ForegroundColor yellow -NoNewLine) + $(Write-Host ": " -NoNewLine; Read-Host) }
Until (($Global:RestartTime -match '^(1[0-2]|0?[1-9]):[0-5]?[0-9](AM|PM)$') -or (!$Global:RestartTime))
Write-Host ""
 If (!$Global:RestartTime) 
  {
   Write-Host " [+] 12:01AM" -ForegroundColor Green 
   $Global:RestartTime = "12:01AM"
  }
 Else 
  { 
   Write-Host " [+]" $Global:RestartTime.ToUpper() -ForegroundColor Green
  }
Write-Host ""

#Set max log file size
Do {$Global:MaxLogFileSize  = $(Write-Host " Please enter the maximum log file size in megabytes (MB) " -NoNewLine) + $(Write-Host "(default: 1000)" -ForegroundColor yellow -NoNewLine) + $(Write-Host ": " -NoNewLine; Read-Host) }
Until (($Global:MaxLogFileSize -match '^[1-9][0-9]{2,4}$') -or (!$Global:MaxLogFileSize))
Write-Host ""
 If (!$Global:MaxLogFileSize)
  {
   Write-Host " [+] 1000 MB" -ForegroundColor Green
   $Global:MaxLogFileSize = "1000"
  }
 Else 
  { 
   Write-Host " [+]" $Global:MaxLogFileSize "MB" -ForegroundColor Green
  }
Write-Host ""

#Set BLG file path
Do {$Global:LogFilePath  = $(Write-Host " Please enter the output (*.blg) file path " -NoNewLine) + $(Write-Host "(default: C:\perfmon_data)" -ForegroundColor yellow -NoNewLine) + $(Write-Host ": " -NoNewLine; Read-Host) }
Until (($Global:LogFilePath -match '(^([a-z]|[A-Z]):(?=\\(?![\0-\37<>:"/\\|?*])|\/(?![\0-\37<>:"/\\|?*])|$)|^\\(?=[\\\/][^\0-\37<>:"/\\|?*]+)|^(?=(\\|\/)$)|^\.(?=(\\|\/)$)|^\.\.(?=(\\|\/)$)|^(?=(\\|\/)[^\0-\37<>:"/\\|?*]+)|^\.(?=(\\|\/)[^\0-\37<>:"/\\|?*]+)|^\.\.(?=(\\|\/)[^\0-\37<>:"/\\|?*]+))((\\|\/)[^\0-\37<>:"/\\|?*]+|(\\|\/)$)*()$') -or (!$Global:LogFilePath))
Write-Host ""
 If (!$Global:LogFilePath)
  {
   $Global:LogFilePath = "C:\perfmon_data"
   If (Test-Path $Global:LogFilePath)
    {
     Write-Host " [+] C:\perfmon_data" -ForegroundColor Green      
    }
   Else
    {
     Write-Host " [+] C:\perfmon_data (Folder will be created)" -ForegroundColor Green 
    }
  }
 Else 
  { 
   If (Test-Path $Global:LogFilePath)
    {
     Write-Host " [+]" $Global:LogFilePath -ForegroundColor Green 
    }
   Else
    {
     Write-Host " [+]" $Global:LogFilePath "(Folder will be created)" -ForegroundColor Green 
    }   
  }
Write-Host ""

#Delete BLG files
Do {$Global:DeleteOlderBlgFiles  = $(Write-Host " How many days old BLG files would you like to delete? " -NoNewLine) + $(Write-Host "(default: 30, Don't delete: 0)" -ForegroundColor yellow -NoNewLine) + $(Write-Host ": " -NoNewLine; Read-Host) }
Until (($Global:DeleteOlderBlgFiles -match '^(730|[0-6]?[0-9]{1,2}|0)$') -or (!$Global:DeleteOlderBlgFiles))
Write-Host ""
 If (!$Global:DeleteOlderBlgFiles)
  {
   Write-Host " [+] 30 days" -ForegroundColor Green
   $Global:DeleteOlderBlgFiles = "30"
  }
 ElseIf ($Global:DeleteOlderBlgFiles -eq 0) 
  {
   Write-Host "Files will not be deleted" -ForegroundColor Green
  } 
 Else
  {
   If ($Global:DeleteOlderBlgFiles -eq 1) 
    {
     Write-Host " [+]" $Global:DeleteOlderBlgFiles "day" -ForegroundColor Green
    }
   Else
    {
     Write-Host " [+]" $Global:DeleteOlderBlgFiles "days" -ForegroundColor Green
    }   
  }
Write-Host ""

#Start Data Collector Set?
Do {$StartCollector = Read-Host " Would you like to start the data collector set after it's created (Y/N)"}
Until (($StartCollector -eq "y") -or ($StartCollector -eq "n")) 
Write-Host ""
   If (!$StartCollector -or $StartCollector -eq "y")
    {
     $Global:StartCollectorCheck =  1 #"y"
     Write-Host " [+] Yes" -ForegroundColor Green
    }	   
   ElseIf ($StartCollector -eq "n")
    {
     $Global:StartCollectorCheck =  0 #"n"
	  Write-Host " [+] No" -ForegroundColor Green
    }
Write-Host ""

#Start Data Collector Set automatically?
Do {$StartCollectorAutomatically = Read-Host " Would you like the Data Collector Set to start automatically in case of a server restart? (Y/N)"}
Until (($StartCollectorAutomatically -eq "y") -or ($StartCollectorAutomatically -eq "n")) 
Write-Host ""
   If (!$StartCollectorAutomatically -or $StartCollectorAutomatically -eq "y")
    {
     $Global:StartCollectorAutomaticallyCheck =  1 #"y"
     Write-Host " [+] Yes (In order to automate the process, a new task will be created within Task Scheduler)" -ForegroundColor Green
    }	   
   ElseIf ($StartCollectorAutomatically -eq "n")
    {
     $Global:StartCollectorAutomaticallyCheck =  0 #"n"
	   Write-Host " [+] No" -ForegroundColor Green
    }
Write-Host ""

#Create setup file?
Do {$CreateUnattendedSetup = Read-Host " Would you like to create a setup file for later use? [N to create immediately] (Y/N)"}
Until (($CreateUnattendedSetup -eq "y") -or ($CreateUnattendedSetup -eq "n")) 	    
   If (!$CreateUnattendedSetup -or $CreateUnattendedSetup -eq "y")
    {
      Write-Host ""
      Write-Host " [+] Yes" -ForegroundColor Green
      Write-Host ""
      
  
      $ConfigFile = $PSScriptRoot + "\config.txt"

      If (Test-Path $ConfigFile) 
       {
        Remove-Item $ConfigFile
       }

      If ($Global:SqlInstanceArrayList -contains "All")
       {
        $Global:SqlInstanceArrayList.Remove("All")
       }

      If ($IfOnlyOneSelected -eq "All")
       {
        $InstList = $Global:SqlInstanceArrayList -join ","
       }
      Else
       {
        $InstList = $IfOnlyOneSelected
       }

      New-Item $ConfigFile -ItemType File  | Out-Null

      Add-Content $ConfigFile ("instance=" + $InstList)  
      Add-Content $ConfigFile ("interval=" + $Global:IntervalNumber) 
      Add-Content $ConfigFile ("duration=" + $Global:DurationNumber)  
      Add-Content $ConfigFile ("restart=" + $Global:RestartTime)  
      Add-Content $ConfigFile ("logfilesize=" + $Global:MaxLogFileSize)  
      Add-Content $ConfigFile ("logfilepath=" + $Global:LogFilePath)  
      Add-Content $ConfigFile ("startcheck=" + $Global:StartCollectorCheck)  
      Add-Content $ConfigFile ("startautocheck=" + $Global:StartCollectorAutomaticallyCheck)
      Add-Content $ConfigFile ("deletexdaysolderblgfiles=" + $Global:DeleteOlderBlgFiles)

      $UnattendedFile = $PSScriptRoot + "\unattended-setup.ps1"
      Create-UnattendedSetupFile($UnattendedFile)

      Compress-SetupFile
    }	   
   ElseIf ($CreateUnattendedSetup -eq "n")
    {
     Write-Host ""
	   Write-Host " [+] No" -ForegroundColor Green
	   Write-Host ""
     Select-SqlInstance
    }
Write-Host ""
