# Perfmon Data Collector Set creation for SQL Server instances
You can easily create Perfmon Data Collector Sets for multiple SQL instances at the same time with the counters you specify without being dependent on the instance name.
## Components of the script
* **[create-collector.ps1](https://github.com/yigitaktan/PerfmonSetup/blob/main/create-collector.ps1):** Main script
* **[functions.psm1](https://github.com/yigitaktan/PerfmonSetup/blob/main/functions.psm1):** Function file used by countersetup.ps1 script.
* **[counterset.txt](https://github.com/yigitaktan/PerfmonSetup/blob/main/counterset.txt):** List of counters required to create a Data Collector Set.
## Preparing counter set file ([counterset.txt](https://github.com/yigitaktan/PerfmonSetup/blob/main/counterset.txt))
First of all, you must determine the counters where you want to collect performance data from. You should specify these counters in the **counterset.txt** file, one per line.
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

When you want to add counters specific to the SQL Server instance, you should write the counters to the file differently as follows.

For example, you should write the counter named `\MSSQL$SQL2017:Locks(*)\Lock Wait Time (ms)` as `\[MYINSTANCENAME]:Locks(*)\Lock Wait Time (ms)`. The reason why it is specified as `[MYINSTANCENAME]` rather than `MSSQL$InstanceName` is that it can be used both for servers with more than one instance and for other servers regardless of the named instances.

In this case, the sample counterset.txt should be prepared as follows.
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

If you need to get the list of counters, please use [Get-Counter](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-counter?view=powershell-7.1) cmdlet.

## Running the script
Script must be run as Administrator.
If you do not run Command Prompt or PowerShell IDE with Administrator privilege, you will see the following warning message.

![image](https://user-images.githubusercontent.com/51110247/134901242-243be960-6f8f-4379-a853-4c61c9992248.png)

Make sure all 3 component files are in the same folder. Then run the script with the following command.

`powershell.exe -File .\create-collector.ps1`

If you are having problems with PowerShell execution policy, please check this link: [About Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.1)

The following screen will appear when you run the script with Administrator privilege and the right execution policy setting you need.

![image](https://user-images.githubusercontent.com/51110247/135044020-561dc4a8-6ed8-4bd4-9f2c-9c6094792ae8.png)

You can easily create the Data Collector Set after answering a few questions in order.

![image](https://user-images.githubusercontent.com/51110247/135069078-4c366c8e-b207-4251-84e5-98e995accd44.png)
