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

cls

$AppVer = "10.2021.3"

$global:SqlInstanceMenuArrayList = New-Object -TypeName "System.Collections.ArrayList"
$global:SqlInstanceMenuArrayList = [System.Collections.ArrayList]@()
$global:SqlInstanceArrayList = New-Object -TypeName "System.Collections.ArrayList"
$global:SqlInstanceArrayList = [System.Collections.ArrayList]@()
$global:StartCollectorList = New-Object -TypeName "System.Collections.ArrayList"
$global:StartCollectorList = [System.Collections.ArrayList]@()

 
#Caption
Write-Host " ╔════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
Write-Host " ║ Perfmon Data Collector Set Setup for SQL Server instances  ║" -ForegroundColor Gray
Write-Host " ╠═════════════╦═══════════╦══════════════════════╦═══════════╣" -ForegroundColor Gray
Write-Host " ║ Yigit Aktan ║ Microsoft ║ yigita@microsoft.com ║" $AppVer "║" -ForegroundColor Gray
Write-Host " ╚═════════════╩═══════════╩══════════════════════╩═══════════╝" -ForegroundColor Gray
Write-Host ""


#Administrator permission check
if (-not([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
 {
  Write-Colr -Text ' [x] ', 'Insufficient permissions to run this script.' -Colour Gray, Red
  Write-Colr -Text '     Open the PowerShell console as an administrator and run this script again.' -Colour Red
  exit
 }


#Counter file check
if (-not(Test-Path -Path $PSScriptRoot\counterset.txt -PathType Leaf)) 
 {
  Write-Colr -Text ' [x] ', 'Could not find counter set file! (counterset.txt)' -Colour Gray, Red
  exit
 }

 
#List all SQL instances
Get-SqlInstances


#Check if there is no SQL instance
if ($global:IsSQL -eq "no")
 {
  Write-Colr -Text ' [*] ', 'There is no SQL Server instance on this server!'  -Colour Gray, Red
  exit
 }


#Select SQL instance
Write-Host " Which instance you would like to create Data Collector Set for?" -ForegroundColor Yellow
Write-Host ""
$global:SqlInstanceMenuArrayList
Write-Host ""
Do {$global:InstanceNumber = Read-Host " Enter selection number (CTRL+C to quit)"}
Until (($global:InstanceNumber -cle $global:SqlInstanceMenuArrayList.Count) -and ($global:InstanceNumber -match '^[1-9]{1}$' -eq "False"  ))
{} #-cle cge
Write-Host " [+]" $global:SqlInstanceArrayList[$global:InstanceNumber - 1]   -ForegroundColor Green
Write-Host ""


#Set data collection interval
Do {$global:IntervalNumber  = $(Write-Host " Enter data collection interval (sec) " -NoNewLine) + $(Write-Host "(default: 15)" -ForegroundColor yellow -NoNewLine) + $(Write-Host ": " -NoNewLine; Read-Host) }
Until (($global:IntervalNumber -match '^[1-9][0-9]{0,3}$') -or (!$global:IntervalNumber))
Write-Host ""
 If (!$global:IntervalNumber) 
  {
   Write-Host " [+] 15 seconds" -ForegroundColor Green 
   $global:IntervalNumber = "15"
  }
 Else 
  { 
   If ($global:IntervalNumber -eq "1")
    {
     Write-Host " [+]" $global:IntervalNumber "second" -ForegroundColor Green
    }
   Else
    {
     Write-Host " [+]" $global:IntervalNumber "seconds" -ForegroundColor Green
    }
  }
Write-Host ""


#Set max log file size
Do {$global:MaxLogFileSize  = $(Write-Host " Enter maximum log file size in MB " -NoNewLine) + $(Write-Host "(default: 1000)" -ForegroundColor yellow -NoNewLine) + $(Write-Host ": " -NoNewLine; Read-Host) }
Until (($global:MaxLogFileSize -match '^[1-9][0-9]{2,4}$') -or (!$global:MaxLogFileSize))
Write-Host ""
 if (!$global:MaxLogFileSize)
  {
   Write-Host " [+] 1000 MB" -ForegroundColor Green
   $global:MaxLogFileSize = "1000"
  }
 else 
  { 
   Write-Host " [+]" $global:MaxLogFileSize "MB" -ForegroundColor Green
  }
Write-Host ""


#Set BLG file path
Do {$global:LogFilePath  = $(Write-Host " Enter output (*.blg) file path " -NoNewLine) + $(Write-Host "(default: C:\perfmon_data)" -ForegroundColor yellow -NoNewLine) + $(Write-Host ": " -NoNewLine; Read-Host) }
Until (($global:LogFilePath -match '(^([a-z]|[A-Z]):(?=\\(?![\0-\37<>:"/\\|?*])|\/(?![\0-\37<>:"/\\|?*])|$)|^\\(?=[\\\/][^\0-\37<>:"/\\|?*]+)|^(?=(\\|\/)$)|^\.(?=(\\|\/)$)|^\.\.(?=(\\|\/)$)|^(?=(\\|\/)[^\0-\37<>:"/\\|?*]+)|^\.(?=(\\|\/)[^\0-\37<>:"/\\|?*]+)|^\.\.(?=(\\|\/)[^\0-\37<>:"/\\|?*]+))((\\|\/)[^\0-\37<>:"/\\|?*]+|(\\|\/)$)*()$') -or (!$global:LogFilePath))
Write-Host ""
 if (!$global:LogFilePath)
  {
   $global:LogFilePath = "C:\perfmon_data"
   If (Test-Path $global:LogFilePath)
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
   If (Test-Path $global:LogFilePath)
    {
     Write-Host " [+]" $global:LogFilePath -ForegroundColor Green 
    }
   Else
    {
     Write-Host " [+]" $global:LogFilePath "(Folder will be created)" -ForegroundColor Green 
    }   
  }
Write-Host ""


#Start data collector set?
Do {$StartCollector = Read-Host " Would you like to start data collector set after created? (Y/N)"}
Until (($StartCollector -eq "y") -or ($StartCollector -eq "n")) 	    
   if (!$StartCollector -or $StartCollector -eq "y")
    {
     $global:StartCollectorCheck =  1 #"y"
     Write-Host ""
	 Write-Host " [+] Yes" -ForegroundColor Green
	 Write-Host ""
     Select-SqlInstance
    }	   
   elseif ($StartCollector -eq "n")
    {
     $global:StartCollectorCheck =  0 #"n"
     Write-Host ""
	 Write-Host " [+] No" -ForegroundColor Green
	 Write-Host ""
     Select-SqlInstance
    }
Write-Host ""
