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


Function Delete-CounterFile
 {
  for ($i=0; $i -lt $StartCollectorList.Count; $i++)
   {
    $FileName = $PSScriptRoot + "\" + $StartCollectorList[$i]  + ".txt" 
    if (Test-Path $FileName) {Remove-Item $FileName -recurse -force}
   }
 }

Function Compress-SetupFile
 {
  $ConfigFileSetup = $PSScriptRoot + "\config.txt"
  $CountersetFileSetup = $PSScriptRoot + "\counterset.txt"
  $UnattendedSetupFile = $PSScriptRoot + "\unattended-setup.ps1"
  $CompressedFile = $PSScriptRoot + "\perfmonfile.zip"

  $compress = @{
  LiteralPath = $ConfigFileSetup,  $CountersetFileSetup, $UnattendedSetupFile
  CompressionLevel = "Fastest"
  DestinationPath =  $CompressedFile}

 Compress-Archive @compress
 Write-Host " [*] Created: " $CompressedFile -ForegroundColor DarkYellow

 If (Test-Path $ConfigFileSetup) 
  {
   Remove-Item $ConfigFileSetup
  }

 If (Test-Path $UnattendedSetupFile) 
  {
   Remove-Item $UnattendedSetupFile
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

       $global:SqlInstanceMenuArrayList.Add(" $count) $ServerName\$temp") > $null
       $global:SqlInstanceArrayList.Add("$temp") > $null
      }
   }
   $TotalInstanceCount = $captions.Count
   if ($captions.Count -gt 1)
    {
     $global:SingleInstanceCheck = "n"
     $global:SqlInstanceMenuArrayList.Add(" $all) All") > $null
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
  Write-Host " ┌────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
  Write-Colr -Text ' │', '                   Successfully Completed                   ', '│' -Colour DarkCyan, Gray, DarkCyan
  Write-Host " └────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
 }


Function Delete-BlgFile([String] $Instance)
 {
  If (Test-Path $LogFilePath)
   {
    $FileName = $Instance + '_sfmc_perfmon_[0-9]+\.blg'
    Get-ChildItem -Path $LogFilePath | Where-Object {$_.name -match $FileName} | Remove-Item
   }
 }


Function Select-SqlInstance
 {
  If (($global:SqlInstanceArrayList[$global:InstanceNumber - 1] -ne "All") -and ($global:SqlInstanceArrayList[$global:InstanceNumber - 1] -ne "MSSQLSERVER")) #If single named instance selected   
   {
    $global:SelectedInstance = $global:SqlInstanceArrayList[$global:InstanceNumber - 1]

    Delete-BlgFile -Instance $global:SelectedInstance

    Create-DataCollectorSet -InstanceName $global:SelectedInstance -OutputFolder $global:LogFilePath -Interval $global:IntervalNumber -Duration $global:DurationNumber -Restart $global:RestartTime -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $global:StartCollectorCheck -MaxFileSize $global:MaxLogFileSize
                    
    If ($global:StartCollectorList -notcontains $global:SelectedInstance){ $global:StartCollectorList.Add($global:SelectedInstance) > $null }
    Write-Host " [*] Data Collector Set creating for" $global:SelectedInstance -ForegroundColor DarkYellow
    Write-Host " [*]" $global:CollectorDisplayName "is created" -ForegroundColor DarkYellow
   } 
  ElseIf ($global:SqlInstanceArrayList[$global:InstanceNumber - 1] -eq "MSSQLSERVER") #If default instance selected
   {
    $global:SelectedInstance = $global:SqlInstanceArrayList[$global:InstanceNumber - 1]

    Delete-BlgFile -Instance $global:SelectedInstance

    Create-DataCollectorSet -InstanceName $global:SelectedInstance -OutputFolder $global:LogFilePath -Interval $global:IntervalNumber -Duration $global:DurationNumber -Restart $global:RestartTime -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $global:StartCollectorCheck -MaxFileSize $global:MaxLogFileSize
               
    If ($global:StartCollectorList -notcontains $global:SelectedInstance){ $global:StartCollectorList.Add($global:SelectedInstance) > $null }
    Write-Host " [*] Data Collector Set creating for" $global:SelectedInstance -ForegroundColor DarkYellow
    Write-Host " [*]" $global:CollectorDisplayName "is created" -ForegroundColor DarkYellow
   }
  ElseIf (($global:SqlInstanceArrayList[$global:InstanceNumber - 1] = "All") -and ($global:SingleInstanceCheck -eq "n")) #If all instances selected
   {
    $global:SingleSelection = "n"
    For ($i=0; $i -lt $global:SqlInstanceArrayList.Count-1; $i++) 
     {
      $global:SelectedInstance = "All"

      If ($global:StartCollectorList -notcontains $global:SqlInstanceArrayList[$i]){ $global:StartCollectorList.Add($global:SqlInstanceArrayList[$i]) > $null }
      Write-Host " [*] Data Collector Set creating for" $global:SqlInstanceArrayList[$i] -ForegroundColor DarkYellow

      If ($global:SqlInstanceArrayList[$i] -eq "MSSQLSERVER")
       {
        Delete-BlgFile -Instance $global:SqlInstanceArrayList[$i]

        Create-DataCollectorSet -InstanceName "MSSQLSERVER" -OutputFolder $global:LogFilePath -Interval $global:IntervalNumber -Duration $global:DurationNumber -Restart $global:RestartTime -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $global:StartCollectorCheck -MaxFileSize $global:MaxLogFileSize
    
        If ($global:StartCollectorList -notcontains 'MSSQLSERVER'){ $global:StartCollectorList.Add("MSSQLSERVER") > $null }
        Write-Host " [*]" $global:CollectorDisplayName "is created" -ForegroundColor DarkYellow
       }
      Else
       {
        Delete-BlgFile -Instance $global:SqlInstanceArrayList[$i]

        Create-DataCollectorSet -InstanceName $global:SqlInstanceArrayList[$i] -OutputFolder $global:LogFilePath -Interval $global:IntervalNumber -Duration $global:DurationNumber -Restart $global:RestartTime -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $global:StartCollectorCheck -MaxFileSize $global:MaxLogFileSize
             
        If ($global:StartCollectorList -notcontains $global:SqlInstanceArrayList[$i]){ $global:StartCollectorList.Add($global:SqlInstanceArrayList[$i]) > $null }
        Write-Host " [*]" $global:CollectorDisplayName "is created" -ForegroundColor DarkYellow
       }
      }              
     }
  AllDone
 }



Function Create-UnattendedSetupFile
{
Param ([String[]]$UnattendedSetupFile)


 If (Test-Path $UnattendedSetupFile) 
  {
   Remove-Item $UnattendedSetupFile
  }


$PSDefaultParameterValues = @{ '*:Encoding' = 'unicode'}

$UnattendedSetupFileContent = '<# 
╔═════════════════════════════════════════════════════════════════════════════╗
║DEVELOPER DOES NOT WARRANT THAT THE SCRIPT WILL MEET YOUR NEEDS OR BE FREE   ║
║FROM ERRORS, OR THAT THE OPERATIONS OF THE SOFTWARE WILL BE UNINTERRUPTED.   ║
╚═════════════════════════════════════════════════════════════════════════════╝
┌─────────┬───────────────────────────────────────────────────────────────────┐
│Usage    │1) Run CMD or PowerShell as Administrator (Run as Administrator)   │
│         │2) powershell.exe -File .\unattended-setup.ps1                     │
├─────────┼───────────────────────────────────────────────────────────────────┤
│Developer│Yigit Aktan - yigita@microsoft.com                                 │
└─────────┴───────────────────────────────────────────────────────────────────┘
#>

cls

$AppVer = "12.2022.2"

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


#Make multi-color lines
Function Write-Colr
{
    Param ([String[]]$Text,[ConsoleColor[]]$Colour,[Switch]$NoNewline=$false)
    For ([int]$i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -Foreground $Colour[$i] -NoNewLine }
    If ($NoNewline -eq $false) { Write-Host '''' }
}


#Administrator permission check
if (-not([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
 {
  Write-Colr -Text '' [x] '', ''Insufficient permissions to run this script.'' -Colour Gray, Red
  Write-Colr -Text ''     Open the PowerShell console as an administrator and run this script again.'' -Colour Red
  exit
 }


#Counter file check
if (-not(Test-Path -Path $PSScriptRoot\counterset.txt -PathType Leaf)) 
 {
  Write-Colr -Text '' [x] '', ''Could not find counter set file! (counterset.txt)'' -Colour Gray, Red
  exit
 }


#Config file check
if (-not(Test-Path -Path $PSScriptRoot\config.txt -PathType Leaf)) 
 {
  Write-Colr -Text '' [x] '', ''Could not find config file! (config.txt)'' -Colour Gray, Red
  exit
 }


#Completion text
Function AllDone
 {
  Write-Host ""
  Write-Host " ┌────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
  Write-Colr -Text '' │'', ''                   Successfully Completed                   '', ''│'' -Colour DarkCyan, Gray, DarkCyan
  Write-Host " └────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
 }


#Delete BLG if exists
Function Delete-BlgFile([String] $Instance)
 {
  If (Test-Path $LogFilePath)
   {
    $FileName = $Instance + ''_sfmc_perfmon_[0-9]+\.blg''
    Get-ChildItem -Path $LogFilePath | Where-Object {$_.name -match $FileName} | Remove-Item
   }
 }


#Create Data Collector Set
Function Create-DataCollectorSet
{
 Param ([string]$InstanceName, [string]$OutputFolder, [string]$Interval, [string]$Duration, [string]$Restart, [bool]$Circular, [string]$CounterFile, [int]$StartCounter, [string]$MaxFileSize)
 $GenerateRandomNum = (Get-Random -Minimum 100 -Maximum 1000)
 $DataCollectorSet = New-Object -COM Pla.DataCollectorSet
 Try 
  {
   $DataCollectorSet.Query($InstanceName + "_DCS" , $null)
    Do {$SameNameGoOrNot = $(Write-Host "Data Collector Set already exists!") + $(Write-Host "Would you like to go through with a new name (" -NoNewLine) + $(Write-Host $InstanceName"_DCS"$GenerateRandomNum -ForegroundColor yellow -NoNewLine) + $(Write-Host ")? (Y/N): " -NoNewLine; Read-Host)}
      Until (($SameNameGoOrNot -eq "y") -or ($SameNameGoOrNot -eq "n")) 	    
       If (!$SameNameGoOrNot -or $SameNameGoOrNot -eq "y")
        {
         Write-Host ""
         Write-Host "[+] Yes" -ForegroundColor Green 
	       Write-Host ""
         $global:CollectorDisplayName = $InstanceName + "_DCS" + $GenerateRandomNum
         $global:CollectorDcsPattern = "_DCS" + $GenerateRandomNum
         $DCName = $InstanceName + "_DCS" + $GenerateRandomNum;
         $BlgName = $env:computername + "_" + $InstanceName + "_DCS" + $GenerateRandomNum + "_perfmon_";
        }	   
       Else
        {
         Write-Host ""
         Write-Host "[+] No" -ForegroundColor Green 
	       Write-Host ""
         Exit
        }
  }
 Catch
  {
   $global:CollectorDisplayName = $InstanceName + "_DCS" + $GenerateRandomNum
   $global:CollectorDcsPattern = "_DCS" + $GenerateRandomNum
   $DCName = $InstanceName + "_DCS" + $GenerateRandomNum;
   $BlgName = $env:computername + "_" + $InstanceName + "_DCS" + $GenerateRandomNum + "_perfmon_";
  }
 $DataCollectorSet.DisplayName = $global:CollectorDisplayName
 $DataCollectorSet.RootPath    = $OutputFolder;
 $DataCollectorSet.Duration    = $Duration;
 $Collector = $DataCollectorSet.DataCollectors.CreateDataCollector(0) 
 $Collector.FileName              = $BlgName;
 $Collector.FileNameFormat        = 0x1 ;
 $Collector.FileNameFormatPattern = "NNNNNN";
 $Collector.SampleInterval        = $Interval;
 $Collector.LogAppend             = $false;
 $Collector.LogCircular           = $Circular;
 $Collector.Name = "Collector" + $GenerateRandomNum
 $CounterList = @()
 ForEach($line in Get-Content $CounterFile) 
  {
   If($line -match $regex)
    {
     If($line.Contains(''[MYINSTANCENAME]''))
      {
       If($InstanceName -eq "MSSQLSERVER")
        {
         $ReplacedLines = $line.Replace(''\[MYINSTANCENAME]:'', ''\SQLServer:'')
         $CounterList += $ReplacedLines         
        }
       Else
        {
         $ReplacedLines = $line.Replace(''\[MYINSTANCENAME]:'', ''\MSSQL$''+$InstanceName+'':'')
         $CounterList += $ReplacedLines        
        }
      }
     Else
      {
       $CounterList += $line
      }  
    }
  }
 $Collector.PerformanceCounters = [string[]]$CounterList
 $Today = Get-Date -Format "MM/dd/yyyy"
 $StartDate = [DateTime]($Today + '' '' + $Restart);
 $NewSchedule = $DataCollectorSet.Schedules.CreateSchedule()
 $NewSchedule.Days = 127
 $NewSchedule.StartDate = $StartDate
 $NewSchedule.StartTime = $StartDate
 Try
  {
   $mypath = $global:LogFilePath + "\" + $BlgName + "000001.blg"
   $DataCollectorSet.Schedules.Add($NewSchedule)
   $DataCollectorSet.DataCollectors.Add($Collector) 
   $DataCollectorSet.Segment = -1
   $DataCollectorSet.SegmentMaxSize = $MaxFileSize
   $DataCollectorSet.Commit($DCName , $null , 0x0003) | Out-Null 
    If($StartCounter -eq 1)
     {
      $DataCollectorSet.Start($true);
     }
    Else
     {
      $DataCollectorSet.Stop($true);
     } 
  }
 Catch [Exception] 
  { 
   return 
  }
}




$global:FileSqlArrayList = New-Object -TypeName "System.Collections.ArrayList"
$global:FileSqlArrayList = [System.Collections.ArrayList]@()

#Parse config file
$ConfigFile = $PSScriptRoot + "\config.txt"
$interval_raw = (Get-Content $ConfigFile) |  Select-String -Pattern "interval=" | Select -ExpandProperty line
$interval = $interval_raw.Substring($interval_raw.IndexOf("=") +1)  
$duration_raw = (Get-Content $ConfigFile) |  Select-String -Pattern "duration=" | Select -ExpandProperty line
$duration = $duration_raw.Substring($duration_raw.IndexOf("=") +1)  
$restart_raw = (Get-Content $ConfigFile) |  Select-String -Pattern "restart=" | Select -ExpandProperty line
$restart = $restart_raw.Substring($restart_raw.IndexOf("=") +1) 
$logfilesize_raw = (Get-Content $ConfigFile) |  Select-String -Pattern "logfilesize=" | Select -ExpandProperty line
$logfilesize = $logfilesize_raw.Substring($logfilesize_raw.IndexOf("=") +1) 
$logfilepath_raw = (Get-Content $ConfigFile) |  Select-String -Pattern "logfilepath=" | Select -ExpandProperty line
$logfilepath = $logfilepath_raw.Substring($logfilepath_raw.IndexOf("=") +1)  
$startcheck_raw = (Get-Content $ConfigFile) |  Select-String -Pattern "startcheck=" | Select -ExpandProperty line 
$startcheck = $startcheck_raw.Substring($startcheck_raw.IndexOf("=") +1)  
$instance = (Get-Content $ConfigFile) |  Select-String -Pattern "instance=" | Select -ExpandProperty line 

If ($instance.Substring($instance.Substring($instance.IndexOf("=") +1) -contains ","))
{ 
 For ($i=0; $i -lt $instance.Substring($instance.IndexOf("=") +1).Split(",").Count; $i++) 
 {
  Write-Host " [*] Data Collector Set creating for" $instance.Substring($instance.IndexOf("=") +1).Split(",")[$i] -ForegroundColor DarkYellow
  Delete-BlgFile -Instance $global:SelectedInstance
  Create-DataCollectorSet -InstanceName $instance.Substring($instance.IndexOf("=") +1).Split(",")[$i] -OutputFolder $logfilepath -Interval $interval -Duration $duration -Restart $restart -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $startcheck -MaxFileSize $logfilesize         
  $DcsFullName = $instance.Substring($instance.IndexOf("=") +1).Split(",")[$i] + $global:CollectorDcsPattern
  Write-Host " [+]" $DcsFullName "is created" -ForegroundColor DarkYellow
 }
 AllDone
}
Else
{
 Write-Host " [*] Data Collector Set creating for" $instance.Substring($instance.IndexOf("=") +1)  -ForegroundColor DarkYellow
 Delete-BlgFile -Instance $global:SelectedInstance
 Create-DataCollectorSet -InstanceName $instance.Substring($instance.IndexOf("=") +1) -OutputFolder $logfilepath -Interval $interval -Duration $duration -Restart $restart -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $startcheck -MaxFileSize $logfilesize
 $DcsFullName = $instance.Substring($instance.IndexOf("=") +1).Split(",")[$i] + $global:CollectorDcsPattern
 Write-Host " [+]" $DcsFullName  "is created" -ForegroundColor DarkYellow 
 AllDone       
}'

New-Item $UnattendedSetupFile -ItemType File  | Out-Null  
Add-Content $UnattendedSetupFile ($UnattendedSetupFileContent)
}



Function Create-DataCollectorSet
{
 Param ([string]$InstanceName, [string]$OutputFolder, [string]$Interval, [string]$Duration, [string]$Restart, [bool]$Circular, [string]$CounterFile, [bool]$StartCounter, [string]$MaxFileSize)
 
 $GenerateRandomNum = (Get-Random -Minimum 100 -Maximum 1000)
 $DataCollectorSet = New-Object -COM Pla.DataCollectorSet

 Try 
  {
   $DataCollectorSet.Query($InstanceName + "_DCS" , $null)

    Do {$SameNameGoOrNot = $(Write-Host "Data Collector Set already exists!") + $(Write-Host "Would you like to go through with a new name (" -NoNewLine) + $(Write-Host $InstanceName"_DCS"$GenerateRandomNum -ForegroundColor yellow -NoNewLine) + $(Write-Host ")? (Y/N): " -NoNewLine; Read-Host)}
      Until (($SameNameGoOrNot -eq "y") -or ($SameNameGoOrNot -eq "n")) 	    
       If (!$SameNameGoOrNot -or $SameNameGoOrNot -eq "y")
        {
         Write-Host ""
         Write-Host "[+] Yes" -ForegroundColor Green 
	     Write-Host ""
         $global:CollectorDisplayName = $InstanceName + "_DCS" + $GenerateRandomNum
         $DCName = $InstanceName + "_DCS" + $GenerateRandomNum;
         $BlgName = $env:computername + "_" + $InstanceName + "_DCS" + $GenerateRandomNum + "_perfmon_";
        }	   
       Else
        {
         Write-Host ""
         Write-Host "[+] No" -ForegroundColor Green 
	     Write-Host ""
         Exit
        }

  }
 Catch
  {
   $global:CollectorDisplayName = $InstanceName + "_DCS" + $GenerateRandomNum
   $DCName = $InstanceName + "_DCS" + $GenerateRandomNum;
   $BlgName = $env:computername + "_" + $InstanceName + "_DCS" + $GenerateRandomNum + "_perfmon_";
  }


 $DataCollectorSet.DisplayName = $global:CollectorDisplayName
 $DataCollectorSet.RootPath    = $OutputFolder;
 $DataCollectorSet.Duration    = $Duration;

 $Collector = $DataCollectorSet.DataCollectors.CreateDataCollector(0) 
 $Collector.FileName              = $BlgName;
 $Collector.FileNameFormat        = 0x1 ;
 $Collector.FileNameFormatPattern = "NNNNNN";
 $Collector.SampleInterval        = $Interval;
 $Collector.LogAppend             = $false;
 $Collector.LogCircular           = $Circular;
 $Collector.Name = "Collector" + $GenerateRandomNum

 $CounterList = @()

 ForEach($line in Get-Content $CounterFile) 
  {
   If($line -match $regex)
    {
     If($line.Contains('[MYINSTANCENAME]'))
      {
       If($InstanceName -eq "MSSQLSERVER")
        {
         $ReplacedLines = $line.Replace('\[MYINSTANCENAME]:', '\SQLServer:')
         $CounterList += $ReplacedLines         
        }
       Else
        {
         $ReplacedLines = $line.Replace('\[MYINSTANCENAME]:', '\MSSQL$'+$InstanceName+':')
         $CounterList += $ReplacedLines        
        }
      }
     Else
      {
       $CounterList += $line
      }  
    }
  }
 
 $Collector.PerformanceCounters = [string[]]$CounterList
 
 $Today = Get-Date -Format "MM/dd/yyyy"
 $StartDate = [DateTime]($Today + ' ' + $Restart);

 $NewSchedule = $DataCollectorSet.Schedules.CreateSchedule()
 $NewSchedule.Days = 127
 $NewSchedule.StartDate = $StartDate
 $NewSchedule.StartTime = $StartDate



 Try
  {
   $mypath = $global:LogFilePath + "\" + $BlgName + "000001.blg"

   $DataCollectorSet.Schedules.Add($NewSchedule)
   $DataCollectorSet.DataCollectors.Add($Collector) 

   $DataCollectorSet.Segment = -1
   $DataCollectorSet.SegmentMaxSize = $MaxFileSize

   $DataCollectorSet.Commit($DCName , $null , 0x0003) | Out-Null
    
    If($StartCounter -eq 1)
     {
      $DataCollectorSet.Start($true);
     }
    Else
     {
      $DataCollectorSet.Stop($true);
     }
   
   
  }
 Catch [Exception] 
  { 
   return 
  }
}
