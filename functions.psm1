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
  Write-Host "┌────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
  Write-Colr -Text '│', '                   Successfully Completed                   ', '│' -Colour DarkCyan, Gray, DarkCyan
  Write-Host "└────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
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

    Create-DataCollectorSet -InstanceName $global:SelectedInstance -OutputFolder $global:LogFilePath -Interval $IntervalNumber -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $global:StartCollectorCheck -MaxFileSize $global:MaxLogFileSize
                    
    If ($global:StartCollectorList -notcontains $global:SelectedInstance){ $global:StartCollectorList.Add($global:SelectedInstance) > $null }
    Write-Host "[*] Data Collector Set creating for" $global:SelectedInstance -ForegroundColor DarkYellow
   } 
  ElseIf ($global:SqlInstanceArrayList[$global:InstanceNumber - 1] -eq "MSSQLSERVER") #If default instance selected
   {
    $global:SelectedInstance = $global:SqlInstanceArrayList[$global:InstanceNumber - 1]

    Delete-BlgFile -Instance $global:SelectedInstance

    Create-DataCollectorSet -InstanceName $global:SelectedInstance -OutputFolder $global:LogFilePath -Interval $IntervalNumber -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $global:StartCollectorCheck -MaxFileSize $global:MaxLogFileSize
               
    If ($global:StartCollectorList -notcontains $global:SelectedInstance){ $global:StartCollectorList.Add($global:SelectedInstance) > $null }
    Write-Host "[*] Data Collector Set creating for" $global:SelectedInstance -ForegroundColor DarkYellow
   }
  ElseIf (($global:SqlInstanceArrayList[$global:InstanceNumber - 1] = "All") -and ($global:SingleInstanceCheck -eq "n")) #If all instances selected
   {
    $global:SingleSelection = "n"
    For ($i=0; $i -lt $global:SqlInstanceArrayList.Count-1; $i++) 
     {
      $global:SelectedInstance = "All"

      If ($global:StartCollectorList -notcontains $global:SqlInstanceArrayList[$i]){ $global:StartCollectorList.Add($global:SqlInstanceArrayList[$i]) > $null }
      Write-Host "[*] Data Collector Set creating for" $global:SqlInstanceArrayList[$i] -ForegroundColor DarkYellow

      If ($global:SqlInstanceArrayList[$i] -eq "MSSQLSERVER")
       {
        Delete-BlgFile -Instance $global:SqlInstanceArrayList[$i]

        Create-DataCollectorSet -InstanceName "MSSQLSERVER" -OutputFolder $global:LogFilePath -Interval $IntervalNumber -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $global:StartCollectorCheck -MaxFileSize $global:MaxLogFileSize
    
        If ($global:StartCollectorList -notcontains 'MSSQLSERVER'){ $global:StartCollectorList.Add("MSSQLSERVER") > $null }
       }
      Else
       {
        Delete-BlgFile -Instance $global:SqlInstanceArrayList[$i]

        Create-DataCollectorSet -InstanceName $global:SqlInstanceArrayList[$i] -OutputFolder $global:LogFilePath -Interval $IntervalNumber -Circular $true -CounterFile $PSScriptRoot"\counterset.txt" -StartCounter $global:StartCollectorCheck -MaxFileSize $global:MaxLogFileSize
             
        If ($global:StartCollectorList -notcontains $global:SqlInstanceArrayList[$i]){ $global:StartCollectorList.Add($global:SqlInstanceArrayList[$i]) > $null }
       }
      }              
     }
  AllDone
 }




Function Create-DataCollectorSet
{
 Param ([string]$InstanceName, [string]$OutputFolder, [string]$Interval, [bool]$Circular, [string]$CounterFile, [bool]$StartCounter, [string]$MaxFileSize)
 
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
         $CollectorDisplayName = $InstanceName + "_DCS" + $GenerateRandomNum
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
   $CollectorDisplayName = $InstanceName + "_DCS" + $GenerateRandomNum
   $DCName = $InstanceName + "_DCS" + $GenerateRandomNum;
   $BlgName = $env:computername + "_" + $InstanceName + "_DCS" + $GenerateRandomNum + "_perfmon_";
  }


 $DataCollectorSet.DisplayName = $CollectorDisplayName
 $DataCollectorSet.RootPath    = $OutputFolder;

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
 
 Try
  {
   $mypath = $global:LogFilePath + "\" + $BlgName + "000001.blg"

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
