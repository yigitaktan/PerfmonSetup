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

![admin8](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/1ec39f44-38e5-4d66-a78e-1e067c614796)

Ensure that all three component files are in the same directory, then execute the script using the following command.

`powershell.exe -File .\create-collector.ps1`

After running the script with administrator privileges and the appropriate execution policy setting ([click for here for Execution Policy errors section](#Execution-Policy-errors)), you should see the following screen.

![main5](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/33ba9dc0-a4cf-4fd9-bbda-0e0258e014e2)

You can easily create the Data Collector Set by answering a few questions sequentially.

![full3](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/ccb2043e-a85e-4460-9d99-92295872b5ce)

## Unattended file creation
If you need to deploy the Data Collector Set across multiple SQL Server environments, you don't have to manually copy the script and its components to each SQL Server instance and answer all the prompts. Instead, you can utilize the script's unattended installation feature. Once you create an unattended file, you can easily deploy Data Collector Sets across your SQL Server farm by simply modifying the values in the `config.txt` file.

To create the unattended file, you need to answer '**Y**' (Yes) to the last question (**Would you like to create a setup file for later use?**). After this step, all the criteria you previously set will be added to `config.txt`, and compressed along with the `unattended-setup.ps1` script to create a file named `perfmonfile.zip`. The location of this file, as shown in the screenshot below, will be in the same path as your existing script.

![unattend2](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/2e2ffeda-2efb-4070-bca9-bd61f632c9c5)

As seen in the screenshot below, upon completion of the creation process, a 9KB ZIP file is generated. All you need to do is extract this file.

![folder2](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/0d7d0540-ef69-46c7-8079-8f4fc8a5ca16)
![aaa](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/0be09d73-16a4-4d45-a8e9-57f129192529)

## Execution Policy errors
If you encounter issues with PowerShell execution policy, please refer to this link: [About Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.1)

![policy1](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/d83ce0a7-a290-4a65-baea-ac2f289ba9e3)

## Encoding errors
If you encounter character encoding errors when running the script, it might have occurred due to character encoding corruption during download, and you have likely encountered errors similar to the screenshot below. To resolve this, open the `create-collector.ps1` and `functions.psm1` files in a text editor like Notepad++ and set the character encoding to **UTF-16**.

![hata4](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/a4799a08-fc26-49cd-8106-b7384b1e0dc3)

If you are using Notepad++, you can easily set the correct encoding setting by opening the `create-collector.ps1` and `functions.psm1` files and selecting either **Convert to UTF-16 BE BOM** or **Convert to UTF-16 LE BOM** from the Encoding menu.

![enc10](https://github.com/yigitaktan/PerfmonSetup/assets/51110247/19a4c75f-e9a7-48d8-b8ca-acd72cf7b31e)



