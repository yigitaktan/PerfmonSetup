# Setting Up Perfmon Data Collector Set for SQL Server Instances

* **[Getting started with the script](#Getting-started-with-the-script)**
* **[Script components](#Script-components)**
* **[Preparing the counter set file](#Preparing-the-counter-set-file)**
* **[Running the script](#Running-the-script)**
* **[Unattended file creation](#Unattended-file-creation)**
* **[Execution Policy errors](#Execution-Policy-errors)**
* **[Encoding errors](#Encoding-errors)**
* **[Important considerations](#important-considerations)**

## Getting started with the script
You can easily create Performance Monitor (Perfmon) Data Collector Sets using with this script . All you need to do is answer a few questions according to your criteria. Please note that this script is designed specifically for SQL Server instances. It will not work if there is no SQL Server instance installed on the machine where it is run.
## Script components
* **[create-collector.ps1](https://github.com/yigitaktan/PerfmonSetup/blob/main/create-collector.ps1):** The primary script
* **[functions.psm1](https://github.com/yigitaktan/PerfmonSetup/blob/main/functions.psm1):** A function file utilized by the `create-collector.ps1` script.
* **[counterset.txt](https://github.com/yigitaktan/PerfmonSetup/blob/main/counterset.txt):** A list of counters necessary for creating a Data Collector Set.
## Preparing the counter set file
To begin, you need to determine the performance counters from which you want to collect performance data. Specify these counters in the `counterset.txt` file, one per line.
```
\PhysicalDisk(*)\Avg. Disk sec/Read
\PhysicalDisk(*)\Avg. Disk sec/Write
\PhysicalDisk(*)\Current Disk Queue Length
\PhysicalDisk(*)\Disk Bytes/sec
\Process(*)\% Privileged Time
\Process(*)\% Processor Time
\Process(*)\Handle Count
\Process(*)\ID Process
\Process(*)\IO Data Operations/sec
\Process(*)\IO Other Operations/sec
```

When adding counters specific to the SQL Server instance, you should format the counters in the following way.

For example, instead of writing the counter as `\MSSQL$SQL2017:Locks(*)\Lock Wait Time (ms)`, you should write it as `\[MYINSTANCENAME]:Locks(*)\Lock Wait Time (ms)`. The reason for using `[MYINSTANCENAME]` instead of `MSSQL$InstanceName` is that it can be used for servers with multiple instances and for other servers without named instances.

In this case, the sample `counterset.txt` should be prepared as follows.
```
\Processor(*)\% User Time
\Processor(*)\DPC Rate
\Server\Pool Nonpaged Failures
\Server\Pool Paged Failures
\System\Context Switches/sec
\System\Processor Queue Length
\System\System Calls/sec
\SQLAgent:Jobs\Successful jobs
\SQLAgent:JobSteps\Active steps
\SQLAgent:JobSteps\Total step retries
\[MYINSTANCENAME]:Access Methods\Forwarded Records/sec
\[MYINSTANCENAME]:Access Methods\FreeSpace Scans/sec
\[MYINSTANCENAME]:Access Methods\Full Scans/sec
\[MYINSTANCENAME]:Access Methods\Index Searches/sec
\[MYINSTANCENAME]:Access Methods\Mixed page allocations/sec
\[MYINSTANCENAME]:Access Methods\Page Splits/sec
\[MYINSTANCENAME]:Access Methods\Range scans/sec
\[MYINSTANCENAME]:Access Methods\Scan Point Revalidations/sec
\[MYINSTANCENAME]:Access Methods\Table Lock Escalations/sec
```

If you want to see a list of Perfmon counters that you can use within `counter.txt`, you can use the [Get-Counter](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-counter?view=powershell-7.1) cmdlet.

## Running the script
The script requires administrator privileges.
If you don't run Command Prompt or PowerShell IDE with administrator privileges, you will encounter the following warning message.

![ad1](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/0d6c07cc-79b8-44e2-aafe-59d495b9b760)

Ensure that all three component files are in the same directory, then execute the script using the following command.

`powershell.exe -File .\create-collector.ps1`

After running the script with administrator privileges and the appropriate execution policy setting ([click for here for Execution Policy errors section](#Execution-Policy-errors)), you should see the following screen.

![main5](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/33ba9dc0-a4cf-4fd9-bbda-0e0258e014e2)

You can easily create the Data Collector Set by answering a few questions sequentially.

![fl1](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/9612e160-926f-4322-ac06-44ef1697c466)

When you also answer the last question in the screenshot above, your Data Collector Set will be successfully created based on the criteria you selected.

![cm1](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/a2aa4b93-192c-4f39-ba23-fcd9bd1dfddd)

## Unattended file creation
If you need to deploy the Data Collector Set across multiple SQL Server environments, you don't have to manually copy the script and its components to each SQL Server instance and answer all the prompts. Instead, you can utilize the script's unattended installation feature. Once you create an unattended file, you can easily deploy Data Collector Sets across your SQL Server farm by simply modifying the values in the `config.txt` file.

To create the unattended file, you need to answer '**Y**' (Yes) to the last question (**Would you like to create a setup file for later use?**). After this step, all the criteria you previously set will be added to `config.txt`, and compressed along with the `unattended-setup.ps1` script to create a file named `perfmonfile.zip`. The location of this file, as shown in the screenshot below, will be in the same path as your existing script.

![uno1](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/a6b9154e-800c-44ab-8f36-ebbe8ce4af07)

As seen in the screenshot below, upon completion of the creation process, a ZIP file is generated. All you need to do is extract this file.

![f1](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/062ccb33-f628-4883-a727-2044764ba709)

When you extract the perfmonfile.zip file, you will encounter three files:

* **config.txt:** This file contains all the configurations, and you can modify the parameters in this file as needed.
  
* **counterset.txt:** This file holds the list of counters to be applied. Don't forget to use the **[MYINSTANCENAME]** definition, as discussed in the [Preparing the counter set file](#Preparing-the-counter-set-file) section.
  
* **unattended-setup.ps1:** This is the main PowerShell script that facilitates the unattended installation.

![d1](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/83ce460b-438e-444f-8908-25b2f610be49)

After placing these three files in the same directory, you can automatically create your Data Collector Set with the parameters you specified in config.txt using the following command.

`powershell.exe -File .\unattended-setup.ps1`
   
![son4](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/d8858580-3d9e-46cf-89cd-2c8631161291)

The **config.txt** file consists of 9 parameters:

* **instance**: Specifies the SQL Server instance.
  
* **interval**: Determines how often the Data Collector Set collects data, specified in seconds as a numerical value.
  
* **duration**: Specifies the duration for which the Data Collector Set will run, given in seconds. For example, if you want it to run for 24 hours, you should input 86400.
  
* **restart**: You may want to prevent collected data from being written to the same file and create a separate file for each day. Therefore, the Data Collector Set needs to be restarted at specific times each day. This parameter defines the time for restart in the specified format, e.g., 12:30AM, 10:00PM.
  
* **logfilesize**: Specifies the size of the BLG files to be created in MB, as a numerical value.
  
* **logfilepath**: Determines the location where BLG files will be stored.
  
* **startcheck**: If you want the Data Collector Set to start as soon as the deployment process is completed, set this parameter to 1; otherwise, set it to 0.
  
* **startautocheck**: This parameter automatically starts the Data Collector Set if it stops under any circumstances. It creates a task in Task Scheduler to check and restart it every 5 minutes.
  
* **deletexdaysolderblgfiles**: You may want to delete accumulated BLG files older than a specified number of days. For instance, if you input 15 as this parameter, it keeps the last 15 days' files and removes the older ones. This process is managed by a Task Scheduler task that checks every 5 minutes.

![con1](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/3d808c70-dd4d-4842-a3ec-2acf0205d344)
 
## Execution Policy errors
If you encounter issues with PowerShell execution policy, please refer to this link: [About Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.1)

![pol1](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/f3c3642f-2436-4cdf-8866-d6ba1e24ec4b)

## Encoding errors
If you encounter character encoding errors when running the script, it might have occurred due to character encoding corruption during download, and you have likely encountered errors similar to the screenshot below. To resolve this, open the `create-collector.ps1` and `functions.psm1` files in a text editor like Notepad++ and set the character encoding to **UTF-16**.

![hata4](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/a4799a08-fc26-49cd-8106-b7384b1e0dc3)

If you are using Notepad++, you can easily set the correct encoding setting by opening the `create-collector.ps1` and `functions.psm1` files and selecting either **Convert to UTF-16 BE BOM** or **Convert to UTF-16 LE BOM** from the Encoding menu.

![enc10](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/19a4c75f-e9a7-48d8-b8ca-acd72cf7b31e)

## Important considerations
* If you want to delete the created Data Collector Set, and a Task Scheduler task was created during its creation, you must manually delete the corresponding task from Task Scheduler after removing the Data Collector Set from Perfmon.

* If you have created a Task Scheduler task to ensure that the Data Collector Set restarts in case of any stoppage while creating it, and later you wish to change the name of the Data Collector Set created in Perfmon, be sure to apply this change within the Action of the task in the Actions tab of Task Scheduler.
        
  <pre>-Command "$name = '<b><i>SQL2019_DCS256</i></b>'; $serverName = (Get-WmiObject -Class Win32_ComputerSystem).Name; $datacollectorset = New-Object -COM Pla.DataCollectorSet; $datacollectorset.Query($name, $serverName); if ($datacollectorset.Status -eq 0) { logman start $name }"</pre>
  
* Similarly, if you change the path of the BLG files from within Perfmon and have set them to be deleted older than a certain number of days, you must also implement this path change in the other Powershell code within the Task Scheduler task.

  <pre>-Command "Get-ChildItem –Path '<b><i>C:\perfmon_data</i></b>' -Recurse -Filter *.blg | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-10))} | Remove-Item"</pre>
