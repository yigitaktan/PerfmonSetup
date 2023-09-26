# Setting Up Perfmon Data Collector Set for SQL Server Instances
You can easily create Performance Monitor (Perfmon) Data Collector Sets using with this script . All you need to do is answer a few questions according to your criteria. Please note that this script is designed specifically for SQL Server instances. It will not work if there is no SQL Server instance installed on the machine where it is run.
## Script Components
* **[create-collector.ps1](https://github.com/yigitaktan/PerfmonSetup/blob/main/create-collector.ps1):** The primary script
* **[functions.psm1](https://github.com/yigitaktan/PerfmonSetup/blob/main/functions.psm1):** A function file utilized by the `countersetup.ps1` script.
* **[counterset.txt](https://github.com/yigitaktan/PerfmonSetup/blob/main/counterset.txt):** A list of counters necessary for creating a Data Collector Set.
## Preparing the counter set file ([counterset.txt](https://github.com/yigitaktan/PerfmonSetup/blob/main/counterset.txt))
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

![image](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/2072056d-a32a-4b37-8005-33d3fc70e6ce)

Ensure that all three component files are in the same directory, then execute the script using the following command.

`powershell.exe -File .\create-collector.ps1`

If you encounter issues with PowerShell execution policy, please refer to this link: [About Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.1)

After running the script with administrator privileges and the appropriate execution policy setting, you should see the following screen.

![main2](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/aa20fb1a-b670-4200-9c4e-274dec1136d5)
![image](https://user-images.githubusercontent.com/51110247/135044020-561dc4a8-6ed8-4bd4-9f2c-9c6094792ae8.png)

You can easily create the Data Collector Set by answering a few questions sequentially.

![image](https://user-images.githubusercontent.com/51110247/135069078-4c366c8e-b207-4251-84e5-98e995accd44.png)

**[!]** *If you encounter character encoding errors when running the script, it might have occurred due to character encoding corruption during download. To resolve this, open the `create-collector.ps1` and `functions.psm1` files in a text editor like Notepad++ and set the character encoding to UTF-16.*





