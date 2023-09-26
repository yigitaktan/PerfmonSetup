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

. \create-collector.ps1

#Compress setup files
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

 Compress-Archive -Force @compress
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

#List SQL Server instances
Function Get-SqlInstances 
 {
  Param($ServerName = $env:computername)

  $localInstances = @()
  [array]$captions = gwmi win32_service -computerName $ServerName | ?{$_.Name -match "mssql*" -and $_.PathName -match "sqlservr.exe"} | %{$_.Caption}
  ForEach ($caption In $captions) 
   {
    $count += 1
    $all = $count + 1
     If ($caption -eq "MSSQLSERVER") {$localInstances += "MSSQLSERVER"} 
     Else 
      {
       $temp = $caption | %{$_.split(" ")[-1]} | %{$_.trimStart("(")} | %{$_.trimEnd(")")}

       $Global:SqlInstanceMenuArrayList.Add(" $count) $ServerName\$temp") > $null
       $Global:SqlInstanceArrayList.Add("$temp") > $null
      }
   }
   $TotalInstanceCount = $captions.Count
   If ($captions.Count -gt 1)
    {
     $Global:SingleInstanceCheck = "n"
     $Global:SqlInstanceMenuArrayList.Add(" $all) All") > $null
     $Global:SqlInstanceArrayList.Add("All") > $null
     $Global:IsSQL = "yes"
    }
   If ($captions.Count -eq 1)
    {
     $Global:SingleInstanceCheck = "y"
     $Global:IsSQL = "yes"
    }
   If ($captions.Count -eq 0)
    {
     $Global:IsSQL = "no"
    }
 }

#Make multi-color lines
Function Write-Colr
{
    Param ([String[]]$Text,[ConsoleColor[]]$Colour,[Switch]$NoNewline=$false)
    For ([int]$i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -Foreground $Colour[$i] -NoNewLine }
    If ($NoNewline -eq $false) { Write-Host '' }
}

#Completion text
Function AllDone
 {
  Write-Host ""
  Write-Host " ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
  Write-Colr -Text ' │', '                      Successfully Completed                     ', '│' -Colour DarkCyan, Gray, DarkCyan
  Write-Host " └─────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
 }

#Delete BLG if exists
Function Delete-BlgFile([String] $Instance)
 {
  If (Test-Path $LogFilePath)
   {
    $FileName = $env:computername + "_" + $Instance + "_DCS" + $Global:GenerateRandomNum + "_perfmon_[0-9]+\.blg";
    Get-ChildItem -Path $LogFilePath | Where-Object {$_.name -match $FileName} | Remove-Item
   }
 }

#Select SQL Server instance(s)
Function Select-SqlInstance
 {
  $Global:GenerateRandomNum = (Get-Random -Minimum 100 -Maximum 1000)	 
  If (($Global:SqlInstanceArrayList[$Global:InstanceNumber - 1] -ne "All") -and ($Global:SqlInstanceArrayList[$Global:InstanceNumber - 1] -ne "MSSQLSERVER")) #If single named instance selected   
   {
    $Global:SelectedInstance = $Global:SqlInstanceArrayList[$Global:InstanceNumber - 1]

    Delete-BlgFile -Instance $Global:SelectedInstance

    Create-DataCollectorSet -InstanceName $Global:SelectedInstance -OutputFolder $Global:LogFilePath -Interval $Global:IntervalNumber -Duration $Global:DurationNumber -Restart $Global:RestartTime -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $Global:StartCollectorCheck -MaxFileSize $Global:MaxLogFileSize
                    
    If ($Global:StartCollectorList -notcontains $Global:SelectedInstance){ $Global:StartCollectorList.Add($Global:SelectedInstance) > $null }
    Write-Host " [*] Data Collector Set creating for" $Global:SelectedInstance -ForegroundColor DarkYellow
    (Write-Host " [*] Data Collector Set named " -ForegroundColor DarkYellow -NoNewLine) + $(Write-Host $Global:CollectorDisplayName -ForegroundColor Yellow -NoNewLine) + $(Write-Host " has been created" -ForegroundColor DarkYellow)
	 If (($Global:StartCollectorAutomaticallyCheck -eq 1) -or ($Global:DeleteOlderBlgFiles -ge 1)) 
	  {
	   Create-ScheduledTask -DcsName $Global:CollectorDisplayName 
	  }
   } 
  ElseIf ($Global:SqlInstanceArrayList[$Global:InstanceNumber - 1] -eq "MSSQLSERVER") #If default instance selected
   {
    $Global:SelectedInstance = $Global:SqlInstanceArrayList[$Global:InstanceNumber - 1]

    Delete-BlgFile -Instance $Global:SelectedInstance

    Create-DataCollectorSet -InstanceName $Global:SelectedInstance -OutputFolder $Global:LogFilePath -Interval $Global:IntervalNumber -Duration $Global:DurationNumber -Restart $Global:RestartTime -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $Global:StartCollectorCheck -MaxFileSize $Global:MaxLogFileSize
               
    If ($Global:StartCollectorList -notcontains $Global:SelectedInstance){ $Global:StartCollectorList.Add($Global:SelectedInstance) > $null }
    Write-Host " [*] Data Collector Set creating for" $Global:SelectedInstance -ForegroundColor DarkYellow
    (Write-Host " [*] Data Collector Set named " -ForegroundColor DarkYellow -NoNewLine) + $(Write-Host $Global:CollectorDisplayName -ForegroundColor Yellow -NoNewLine) + $(Write-Host " has been created" -ForegroundColor DarkYellow)
	 If (($Global:StartCollectorAutomaticallyCheck -eq 1) -or ($Global:DeleteOlderBlgFiles -ge 1)) 
	  {
	   Create-ScheduledTask -DcsName $Global:CollectorDisplayName 
	  }
   }
  ElseIf (($Global:SqlInstanceArrayList[$Global:InstanceNumber - 1] = "All") -and ($Global:SingleInstanceCheck -eq "n")) #If all instances selected
   {
    $Global:SingleSelection = "n"
    For ($i=0; $i -lt $Global:SqlInstanceArrayList.Count-1; $i++) 
     {
      $Global:SelectedInstance = "All"

      If ($Global:StartCollectorList -notcontains $Global:SqlInstanceArrayList[$i]){ $Global:StartCollectorList.Add($Global:SqlInstanceArrayList[$i]) > $null }
      Write-Host " [*] Data Collector Set creating for" $Global:SqlInstanceArrayList[$i] -ForegroundColor DarkYellow

      If ($Global:SqlInstanceArrayList[$i] -eq "MSSQLSERVER")
       {
        Delete-BlgFile -Instance $Global:SqlInstanceArrayList[$i]

        Create-DataCollectorSet -InstanceName "MSSQLSERVER" -OutputFolder $Global:LogFilePath -Interval $Global:IntervalNumber -Duration $Global:DurationNumber -Restart $Global:RestartTime -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $Global:StartCollectorCheck -MaxFileSize $Global:MaxLogFileSize
    
        If ($Global:StartCollectorList -notcontains 'MSSQLSERVER'){ $Global:StartCollectorList.Add("MSSQLSERVER") > $null }
        (Write-Host " [*] Data Collector Set named " -ForegroundColor DarkYellow -NoNewLine) + $(Write-Host $Global:CollectorDisplayName -ForegroundColor Yellow -NoNewLine) + $(Write-Host " has been created" -ForegroundColor DarkYellow)
		 If (($Global:StartCollectorAutomaticallyCheck -eq 1) -or ($Global:DeleteOlderBlgFiles -ge 1)) 
	      {
	       Create-ScheduledTask -DcsName $Global:CollectorDisplayName 
	      }
       }
      Else
       {
        Delete-BlgFile -Instance $Global:SqlInstanceArrayList[$i]

        Create-DataCollectorSet -InstanceName $Global:SqlInstanceArrayList[$i] -OutputFolder $Global:LogFilePath -Interval $Global:IntervalNumber -Duration $Global:DurationNumber -Restart $Global:RestartTime -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $Global:StartCollectorCheck -MaxFileSize $Global:MaxLogFileSize
             
        If ($Global:StartCollectorList -notcontains $Global:SqlInstanceArrayList[$i]){ $Global:StartCollectorList.Add($Global:SqlInstanceArrayList[$i]) > $null }
        (Write-Host " [*] Data Collector Set named " -ForegroundColor DarkYellow -NoNewLine) + $(Write-Host $Global:CollectorDisplayName -ForegroundColor Yellow -NoNewLine) + $(Write-Host " has been created" -ForegroundColor DarkYellow)
	     If (($Global:StartCollectorAutomaticallyCheck -eq 1) -or ($Global:DeleteOlderBlgFiles -ge 1)) 
	      {
	       Create-ScheduledTask -DcsName $Global:CollectorDisplayName 
	      }
       }
      }              
     }
	 
  AllDone
 }

#Create Task Scheduler task
Function Create-ScheduledTask([String] $DcsName)
 {
  $DataCollecterSetName = $DcsName

  $TaskActions = @()
  If ($Global:StartCollectorAutomaticallyCheck -eq 1)
   {
    $TaskActions += New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command ""`$name = '$DataCollecterSetName'; `$serverName = (Get-WmiObject -Class Win32_ComputerSystem).Name; `$datacollectorset = New-Object -COM Pla.DataCollectorSet; `$datacollectorset.Query(`$name, `$serverName); if (`$datacollectorset.Status -eq 0) { logman start `$name }"""
   }
  If ($Global:DeleteOlderBlgFiles -ge 1)
   {
    $TaskActions += New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command ""Get-ChildItem –Path '$Global:LogFilePath' -Recurse -Filter *.blg | Where-Object {(`$_.LastWriteTime -lt (Get-Date).AddDays(-$Global:DeleteOlderBlgFiles))} | Remove-Item"""
   }

  $TaskTriggerDaily = New-ScheduledTaskTrigger -Daily -At 2pm
  $TaskTriggerStartup = New-ScheduledTaskTrigger -AtStartup
  $TaskSettings = New-ScheduledTaskSettingsSet -DontStopOnIdleEnd -ExecutionTimeLimit (New-TimeSpan -Hours 0) -Compatibility Win8 -AllowStartIfOnBatteries
  $TaskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType Password -RunLevel Highest
  $TaskName = "Run " + $DataCollecterSetName
  $TaskDescription = "Runs every 5 minutes for a duration of indefinitely, with the highest privileges and whether the user is logged on or not, and at system startup"

  If (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false }

  $Task = Register-ScheduledTask -TaskName $TaskName -Description $TaskDescription -Action $TaskActions -Trigger $TaskTriggerDaily, $TaskTriggerStartup -Settings $TaskSettings -Principal $TaskPrincipal
  $Task.Triggers[0].Repetition.Interval = "PT5M" 
  $Task | Set-ScheduledTask > $null

  $TaskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $TaskName }

  If($TaskExists)
   {
    (Write-Host " [*] Task Scheduler task named " -ForegroundColor DarkYellow -NoNewLine) + $(Write-Host $TaskName -ForegroundColor Yellow -NoNewLine) + $(Write-Host " has been created" -ForegroundColor DarkYellow)
	Write-Host " [i] Please go to Task Scheduler and change the 'When running the task, use the following user account'" -ForegroundColor Yellow
	Write-Host "     section to a user account with the necessary privileges to start the task. Additionally, check" -ForegroundColor Yellow
	Write-Host "     the 'Run whether user is logged on or not' check box." -ForegroundColor Yellow
	Write-Host " [i] If you change the name of the created Data Collector Set, the task created in Task Scheduler" -ForegroundColor Yellow
	Write-Host "     to automatically start it will not function." -ForegroundColor Yellow
   }

  #$UpdateTaskPrincipal = New-ScheduledTaskPrincipal -UserId $UserName -RunLevel Highest
  #$UpdateTaskSettings = New-ScheduledTaskSettingsSet -Compatibility Win8
  #Set-ScheduledTask -TaskName $TaskName -Principal $UpdateTaskPrincipal -Settings $UpdateTaskSettings
  #Set-ScheduledTask -TaskName $TaskName -User $UpdateTaskPrincipal.UserID -Password $Password
}

#Create Data Collector Set
Function Create-DataCollectorSet
{
 Param ([string]$InstanceName, [string]$OutputFolder, [string]$Interval, [string]$Duration, [string]$Restart, [bool]$Circular, [string]$CounterFile, [bool]$StartCounter, [string]$MaxFileSize)
 
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
         $Global:CollectorDisplayName = $InstanceName + "_DCS" + $Global:GenerateRandomNum
         $DCName = $InstanceName + "_DCS" + $Global:GenerateRandomNum;
         $BlgName = $env:computername + "_" + $InstanceName + "_DCS" + $Global:GenerateRandomNum + "_perfmon_";
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
   $Global:CollectorDisplayName = $InstanceName + "_DCS" + $Global:GenerateRandomNum
   $DCName = $InstanceName + "_DCS" + $Global:GenerateRandomNum;
   $BlgName = $env:computername + "_" + $InstanceName + "_DCS" + $Global:GenerateRandomNum + "_perfmon_";
  }

 $DataCollectorSet.DisplayName = $Global:CollectorDisplayName
 $DataCollectorSet.RootPath    = $OutputFolder;
 $DataCollectorSet.Duration    = $Duration;

 $Collector = $DataCollectorSet.DataCollectors.CreateDataCollector(0) 
 $Collector.FileName              = $BlgName;
 $Collector.FileNameFormat        = 0x1 ;
 $Collector.FileNameFormatPattern = "NNNNNN";
 $Collector.SampleInterval        = $Interval;
 $Collector.LogAppend             = $false;
 $Collector.LogCircular           = $Circular;
 $Collector.Name = "Collector" + $Global:GenerateRandomNum

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
   $mypath = $Global:LogFilePath + "\" + $BlgName + "000001.blg"

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

#Create unattended setup file
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

Clear-Host

$AppVer = "' + $AppVer + '"

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
  Write-Colr -Text '' [x] '', ''You do not have sufficient permissions to execute this script.'' -Colour Gray, Red
  Write-Colr -Text ''     Please open the PowerShell console as an administrator and rerun this script.'' -Colour Red
  exit
 }

#Counter file check
if (-not(Test-Path -Path $PSScriptRoot\counterset.txt -PathType Leaf)) 
 {
  Write-Colr -Text '' [x] '', ''Counter set file not found! (counterset.txt)'' -Colour Gray, Red
  exit
 }

#Config file check
if (-not(Test-Path -Path $PSScriptRoot\config.txt -PathType Leaf)) 
 {
  Write-Colr -Text '' [x] '', ''Could not find config file! (config.txt)'' -Colour Gray, Red
  exit
 }

#Delete BLG if exists
Function Delete-BlgFile([String] $Instance)
 {
  If (Test-Path $LogFilePath)
   {
	$FileName = $env:computername + "_" + $Instance + "_DCS" + $Global:GenerateRandomNum + "_perfmon_[0-9]+\.blg";
    #$FileName = $Instance + ''_sfmc_perfmon_[0-9]+\.blg''
    Get-ChildItem -Path $LogFilePath | Where-Object {$_.name -match $FileName} | Remove-Item
   }
 }
 
#Completion text
Function AllDone
 {
  Write-Host ""
  Write-Host " ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
  Write-Colr -Text '' │'', ''                      Successfully Completed                     '', ''│'' -Colour DarkCyan, Gray, DarkCyan
  Write-Host " └─────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
 }

#Create Data Collector Set
Function Create-DataCollectorSet
{
 Param ([string]$InstanceName, [string]$OutputFolder, [string]$Interval, [string]$Duration, [string]$Restart, [bool]$Circular, [string]$CounterFile, [int]$StartCounter, [string]$MaxFileSize)
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
         $Global:CollectorDisplayName = $InstanceName + "_DCS" + $Global:GenerateRandomNum
         $Global:CollectorDcsPattern = "_DCS" + $Global:GenerateRandomNum
         $DCName = $InstanceName + "_DCS" + $Global:GenerateRandomNum;
         $BlgName = $env:computername + "_" + $InstanceName + "_DCS" + $Global:GenerateRandomNum + "_perfmon_";
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
   $Global:CollectorDisplayName = $InstanceName + "_DCS" + $Global:GenerateRandomNum
   $Global:CollectorDcsPattern = "_DCS" + $Global:GenerateRandomNum
   $DCName = $InstanceName + "_DCS" + $Global:GenerateRandomNum;
   $BlgName = $env:computername + "_" + $InstanceName + "_DCS" + $Global:GenerateRandomNum + "_perfmon_";
  }
 $DataCollectorSet.DisplayName    = $Global:CollectorDisplayName
 $DataCollectorSet.RootPath       = $OutputFolder;
 $DataCollectorSet.Duration       = $Duration;
 $Collector                       = $DataCollectorSet.DataCollectors.CreateDataCollector(0) 
 $Collector.FileName              = $BlgName;
 $Collector.FileNameFormat        = 0x1 ;
 $Collector.FileNameFormatPattern = "NNNNNN";
 $Collector.SampleInterval        = $Interval;
 $Collector.LogAppend             = $false;
 $Collector.LogCircular           = $Circular;
 $Collector.Name                  = "Collector" + $Global:GenerateRandomNum
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
   $mypath = $LogFilePath + "\" + $BlgName + "000001.blg"
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

#Create Task Scheduler task
Function Create-ScheduledTask([String] $DcsName)
 {
  $DataCollecterSetName = $DcsName

  $TaskActions = @()
  If ($startautocheck -eq 1)
   {
    $TaskActions += New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command ""`$name = ''$DataCollecterSetName''; `$serverName = (Get-WmiObject -Class Win32_ComputerSystem).Name; `$datacollectorset = New-Object -COM Pla.DataCollectorSet; `$datacollectorset.Query(`$name, `$serverName); if (`$datacollectorset.Status -eq 0) { logman start `$name }"""
   }
  If ($deletexdaysolderblgfiles -ge 1)
   {
    $TaskActions += New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command ""Get-ChildItem –Path ''$Global:LogFilePath'' -Recurse -Filter *.blg | Where-Object {(`$_.LastWriteTime -lt (Get-Date).AddDays(-$deletexdaysolderblgfiles))} | Remove-Item"""
   }
   
  $TaskTriggerDaily = New-ScheduledTaskTrigger -Daily -At 2pm
  $TaskTriggerStartup = New-ScheduledTaskTrigger -AtStartup
  $TaskSettings = New-ScheduledTaskSettingsSet -DontStopOnIdleEnd -ExecutionTimeLimit (New-TimeSpan -Hours 0) -Compatibility Win8 -AllowStartIfOnBatteries
  $TaskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType Password -RunLevel Highest
  $TaskName = "Run " + $DataCollecterSetName
  $TaskDescription = "Runs every 5 minutes for a duration of indefinitely, with the highest privileges and whether the user is logged on or not, and at system startup"

  If (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false }

  $Task = Register-ScheduledTask -TaskName $TaskName -Description $TaskDescription -Action $TaskActions -Trigger $TaskTriggerDaily, $TaskTriggerStartup -Settings $TaskSettings -Principal $TaskPrincipal
  $Task.Triggers[0].Repetition.Interval = "PT5M" 
  $Task | Set-ScheduledTask > $null

  $TaskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $TaskName }

  If($TaskExists)
   {
    (Write-Host " [*] Task Scheduler task named " -ForegroundColor DarkYellow -NoNewLine) + $(Write-Host $TaskName -ForegroundColor Yellow -NoNewLine) + $(Write-Host " has been created" -ForegroundColor DarkYellow)
	Write-Host " [i] Please go to Task Scheduler and change the ''When running the task, use the following user account''" -ForegroundColor Yellow
	Write-Host "     section to a user account with the necessary privileges to start the task. Additionally, check" -ForegroundColor Yellow
	Write-Host "     the ''Run whether user is logged on or not'' check box." -ForegroundColor Yellow
	Write-Host " [i] If you change the name of the created Data Collector Set, the task created in Task Scheduler" -ForegroundColor Yellow
	Write-Host "     to automatically start it will not function." -ForegroundColor Yellow
   }
 }

$Global:FileSqlArrayList = New-Object -TypeName "System.Collections.ArrayList"
$Global:FileSqlArrayList = [System.Collections.ArrayList]@()

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
$startautocheck_raw = (Get-Content $ConfigFile) |  Select-String -Pattern "startautocheck=" | Select -ExpandProperty line 
$startautocheck = $startautocheck_raw.Substring($startautocheck_raw.IndexOf("=") +1)
$deletexdaysolderblgfiles_raw = (Get-Content $ConfigFile) |  Select-String -Pattern "deletexdaysolderblgfiles=" | Select -ExpandProperty line 
$deletexdaysolderblgfiles = $deletexdaysolderblgfiles_raw.Substring($deletexdaysolderblgfiles_raw.IndexOf("=") +1)
$instance = (Get-Content $ConfigFile) |  Select-String -Pattern "instance=" | Select -ExpandProperty line 

$Global:GenerateRandomNum = (Get-Random -Minimum 100 -Maximum 1000)

If ($instance.Substring($instance.Substring($instance.IndexOf("=") +1) -contains ","))
{ 
 For ($i=0; $i -lt $instance.Substring($instance.IndexOf("=") +1).Split(",").Count; $i++) 
 {
  Write-Host " [*] Data Collector Set creating for" $instance.Substring($instance.IndexOf("=") +1).Split(",")[$i] -ForegroundColor DarkYellow
  Delete-BlgFile -Instance $Global:SelectedInstance
  Create-DataCollectorSet -InstanceName $instance.Substring($instance.IndexOf("=") +1).Split(",")[$i] -OutputFolder $logfilepath -Interval $interval -Duration $duration -Restart $restart -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $startcheck -MaxFileSize $logfilesize         
  $DcsFullName = $instance.Substring($instance.IndexOf("=") +1).Split(",")[$i] + $Global:CollectorDcsPattern
  (Write-Host " [*] Data Collector Set named " -ForegroundColor DarkYellow -NoNewLine) + $(Write-Host $DcsFullName -ForegroundColor Yellow -NoNewLine) + $(Write-Host " has been created" -ForegroundColor DarkYellow) 
  If (($startautocheck -eq 1) -or ($deletexdaysolderblgfiles -ge 1)) 
   {
	Create-ScheduledTask -DcsName $DcsFullName
   }
 }
 AllDone
}
Else
{
 Write-Host " [*] Data Collector Set creating for" $instance.Substring($instance.IndexOf("=") +1)  -ForegroundColor DarkYellow
 Delete-BlgFile -Instance $Global:SelectedInstance
 Create-DataCollectorSet -InstanceName $instance.Substring($instance.IndexOf("=") +1) -OutputFolder $logfilepath -Interval $interval -Duration $duration -Restart $restart -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $startcheck -MaxFileSize $logfilesize
 $DcsFullName = $instance.Substring($instance.IndexOf("=") +1).Split(",")[$i] + $Global:CollectorDcsPattern
 (Write-Host " [*] Data Collector Set named " -ForegroundColor DarkYellow -NoNewLine) + $(Write-Host $DcsFullName -ForegroundColor Yellow -NoNewLine) + $(Write-Host " has been created" -ForegroundColor DarkYellow)
  If (($startautocheck -eq 1) -or ($deletexdaysolderblgfiles -ge 1)) 
   {
	Create-ScheduledTask -DcsName $DcsFullName
   }
   
 AllDone       
}'

New-Item $UnattendedSetupFile -ItemType File  | Out-Null  
Add-Content $UnattendedSetupFile ($UnattendedSetupFileContent)
}
