/*******************************************************************************************
 job_schedules.sql
 Lists all jobs that are configured in as SQL Agent Job and the associated schedule.
 Taken from https://www.sqlservercentral.com/forums/topic/list-all-jobs-and-their-schedules#post-2021010
 Access required: Select in MSDB
 Author: Rune Rasmussen (www.runerasmussen.dk)
 https://github.com/runerasmussen/docs/blob/master/code_snippets/sql/job_schedules.sql
********************************************************************************************/




USE [msdb]


Declare @weekDay Table 
(
mask int
, maskValue varchar(32)
);

Insert Into @weekDay
Select 1, 'Sunday' UNION ALL
Select 2, 'Monday' UNION ALL
Select 4, 'Tuesday' UNION ALL
Select 8, 'Wednesday' UNION ALL
Select 16, 'Thursday' UNION ALL
Select 32, 'Friday' UNION ALL
Select 64, 'Saturday';

With SCHED as (
Select sched.name As 'scheduleName'
, sched.schedule_id
, jobsched.job_id as job_id
, Case 
When sched.freq_type = 1 
Then 'Once' 
When sched.freq_type = 4 And sched.freq_interval = 1 
Then 'Daily'
When sched.freq_type = 4 
Then 'Every ' + Cast(sched.freq_interval As varchar(5)) + ' days'
When sched.freq_type = 8 
Then Replace( Replace( Replace(( 
Select maskValue 
From @weekDay As x 
Where sched.freq_interval & x.mask <> 0 
Order By mask For XML Raw)
, '"/><row maskValue="', ', '), '<row maskValue="', ''), '"/>', '') 
+ Case When sched.freq_recurrence_factor <> 0 
And sched.freq_recurrence_factor = 1 
Then '; weekly' 
When sched.freq_recurrence_factor <> 0 
Then '; every ' 
+ Cast(sched.freq_recurrence_factor As varchar(10)) + ' weeks' 
End
When sched.freq_type = 16 
Then 'On day ' 
+ Cast(sched.freq_interval As varchar(10)) + ' of every '
+ Cast(sched.freq_recurrence_factor As varchar(10)) + ' months' 
When sched.freq_type = 32 
Then Case 
When sched.freq_relative_interval = 1 
Then 'First'
When sched.freq_relative_interval = 2 
Then 'Second'
When sched.freq_relative_interval = 4 
Then 'Third'
When sched.freq_relative_interval = 8 
Then 'Fourth'
When sched.freq_relative_interval = 16 
Then 'Last'
End + 
Case 
When sched.freq_interval = 1 
Then ' Sunday'
When sched.freq_interval = 2 
Then ' Monday'
When sched.freq_interval = 3 
Then ' Tuesday'
When sched.freq_interval = 4 
Then ' Wednesday'
When sched.freq_interval = 5 
Then ' Thursday'
When sched.freq_interval = 6 
Then ' Friday'
When sched.freq_interval = 7 
Then ' Saturday'
When sched.freq_interval = 8 
Then ' Day'
When sched.freq_interval = 9 
Then ' Weekday'
When sched.freq_interval = 10 
Then ' Weekend'
End
+ 
Case 
When sched.freq_recurrence_factor <> 0 
And sched.freq_recurrence_factor = 1 
Then '; monthly'
When sched.freq_recurrence_factor <> 0 
Then '; every ' 
+ Cast(sched.freq_recurrence_factor As varchar(10)) + ' months' 
End
When sched.freq_type = 64 
Then 'StartUp'
When sched.freq_type = 128 
Then 'Idle'
End As 'frequency'
, IsNull('Every ' + Cast(sched.freq_subday_interval As varchar(10)) + 
Case 
When sched.freq_subday_type = 2 
Then ' seconds'
When sched.freq_subday_type = 4 
Then ' minutes'
When sched.freq_subday_type = 8 
Then ' hours'
End, 'Once') As 'subFrequency'

,[start_time] = 
CASE LEN(sched.active_start_time)
WHEN 1 THEN CAST('00:00:0' + RIGHT(sched.active_start_time, 2) AS CHAR(8))
WHEN 2 THEN CAST('00:00:' + RIGHT(sched.active_start_time, 2) AS CHAR(8))
WHEN 3 THEN CAST('00:0'
+ LEFT(RIGHT(sched.active_start_time, 3), 1)
+ ':' + RIGHT(sched.active_start_time, 2) AS CHAR(8))
WHEN 4 THEN CAST('00:'
+ LEFT(RIGHT(sched.active_start_time, 4), 2)
+ ':' + RIGHT(sched.active_start_time, 2) AS CHAR(8))
WHEN 5 THEN CAST('0'
+ LEFT(RIGHT(sched.active_start_time, 5), 1)
+ ':' + LEFT(RIGHT(sched.active_start_time, 4), 2)
+ ':' + RIGHT(sched.active_start_time, 2) AS CHAR(8))
WHEN 6 THEN CAST(LEFT(RIGHT(sched.active_start_time, 6), 2)
+ ':' + LEFT(RIGHT(sched.active_start_time, 4), 2)
+ ':' + RIGHT(sched.active_start_time, 2) AS CHAR(8))
END
,[end_time] = 
CASE LEN(sched.active_end_time)
WHEN 1 THEN CAST('00:00:0' + RIGHT(sched.active_end_time, 2) AS CHAR(8))
WHEN 2 THEN CAST('00:00:' + RIGHT(sched.active_end_time, 2) AS CHAR(8))
WHEN 3 THEN CAST('00:0'
+ LEFT(RIGHT(sched.active_end_time, 3), 1)
+ ':' + RIGHT(sched.active_end_time, 2) AS CHAR(8))
WHEN 4 THEN CAST('00:'
+ LEFT(RIGHT(sched.active_end_time, 4), 2)
+ ':' + RIGHT(sched.active_end_time, 2) AS CHAR(8))
WHEN 5 THEN CAST('0'
+ LEFT(RIGHT(sched.active_end_time, 5), 1)
+ ':' + LEFT(RIGHT(sched.active_end_time, 4), 2)
+ ':' + RIGHT(sched.active_end_time, 2) AS CHAR(8))
WHEN 6 THEN CAST(LEFT(RIGHT(sched.active_end_time, 6), 2)
+ ':' + LEFT(RIGHT(sched.active_end_time, 4), 2)
+ ':' + RIGHT(sched.active_end_time, 2) AS CHAR(8))
END
, Replicate('0', 6 - Len(jobsched.next_run_time)) 
+ Cast(jobsched.next_run_time As varchar(6)) As 'nextRunTime'
, Cast(jobsched.next_run_date As char(8)) As 'nextRunDate'
From msdb.dbo.sysschedules As sched
Join msdb.dbo.sysjobschedules As jobsched
On sched.schedule_id = jobsched.schedule_id),
JOB as (
SELECT
[job_id] = job.job_id
,[job_name] = job.name
,[job_enabled] = 
CASE job.enabled
WHEN 1 THEN 'Yes'
WHEN 0 THEN 'No'
END
,[Sched_ID] = sched.schedule_id
,[sched_enabled] = 
CASE sched.enabled
WHEN 1 THEN 'Yes'
WHEN 0 THEN 'No'
END
,[Sched_Frequency] = 
CASE sched.freq_type
WHEN 1 THEN 'Once'
WHEN 4 THEN 'Daily'
WHEN 8 THEN 'Weekly'
WHEN 16 THEN 'Monthly'
WHEN 32 THEN 'Monthly relative'
WHEN 64 THEN 'When SQLServer Agent starts'
END
,[Start_Date] = 
CASE next_run_date
WHEN 0 THEN NULL
ELSE SUBSTRING(CONVERT(VARCHAR(15), next_run_date), 1, 4) + '/' +
SUBSTRING(CONVERT(VARCHAR(15), next_run_date), 5, 2) + '/' +
SUBSTRING(CONVERT(VARCHAR(15), next_run_date), 7, 2)
END
,[Next_Run_Time] = 
CASE LEN(next_run_time)
WHEN 1 THEN CAST('00:00:0' + RIGHT(next_run_time, 2) AS CHAR(8))
WHEN 2 THEN CAST('00:00:' + RIGHT(next_run_time, 2) AS CHAR(8))
WHEN 3 THEN CAST('00:0'
+ LEFT(RIGHT(next_run_time, 3), 1)
+ ':' + RIGHT(next_run_time, 2) AS CHAR(8))
WHEN 4 THEN CAST('00:'
+ LEFT(RIGHT(next_run_time, 4), 2)
+ ':' + RIGHT(next_run_time, 2) AS CHAR(8))
WHEN 5 THEN CAST('0'
+ LEFT(RIGHT(next_run_time, 5), 1)
+ ':' + LEFT(RIGHT(next_run_time, 4), 2)
+ ':' + RIGHT(next_run_time, 2) AS CHAR(8))
WHEN 6 THEN CAST(LEFT(RIGHT(next_run_time, 6), 2)
+ ':' + LEFT(RIGHT(next_run_time, 4), 2)
+ ':' + RIGHT(next_run_time, 2) AS CHAR(8))
END
,[Max_Duration] = 
CASE LEN(max_run_duration)
WHEN 1 THEN CAST('00:00:0'
+ CAST(max_run_duration AS CHAR) AS CHAR(8))
WHEN 2 THEN CAST('00:00:'
+ CAST(max_run_duration AS CHAR) AS CHAR(8))
WHEN 3 THEN CAST('00:0'
+ LEFT(RIGHT(max_run_duration, 3), 1)
+ ':' + RIGHT(max_run_duration, 2) AS CHAR(8))
WHEN 4 THEN CAST('00:'
+ LEFT(RIGHT(max_run_duration, 4), 2)
+ ':' + RIGHT(max_run_duration, 2) AS CHAR(8))
WHEN 5 THEN CAST('0'
+ LEFT(RIGHT(max_run_duration, 5), 1)
+ ':' + LEFT(RIGHT(max_run_duration, 4), 2)
+ ':' + RIGHT(max_run_duration, 2) AS CHAR(8))
WHEN 6 THEN CAST(LEFT(RIGHT(max_run_duration, 6), 2)
+ ':' + LEFT(RIGHT(max_run_duration, 4), 2)
+ ':' + RIGHT(max_run_duration, 2) AS CHAR(8))
END
,[Min_Duration] = 
CASE LEN(min_run_duration)
WHEN 1 THEN CAST('00:00:0'
+ CAST(min_run_duration AS CHAR) AS CHAR(8))
WHEN 2 THEN CAST('00:00:'
+ CAST(min_run_duration AS CHAR) AS CHAR(8))
WHEN 3 THEN CAST('00:0'
+ LEFT(RIGHT(min_run_duration, 3), 1)
+ ':' + RIGHT(min_run_duration, 2) AS CHAR(8))
WHEN 4 THEN CAST('00:'
+ LEFT(RIGHT(min_run_duration, 4), 2)
+ ':' + RIGHT(min_run_duration, 2) AS CHAR(8))
WHEN 5 THEN CAST('0'
+ LEFT(RIGHT(min_run_duration, 5), 1)
+ ':' + LEFT(RIGHT(min_run_duration, 4), 2)
+ ':' + RIGHT(min_run_duration, 2) AS CHAR(8))
WHEN 6 THEN CAST(LEFT(RIGHT(min_run_duration, 6), 2)
+ ':' + LEFT(RIGHT(min_run_duration, 4), 2)
+ ':' + RIGHT(min_run_duration, 2) AS CHAR(8))
END
,[Avg_Duration] = 
CASE LEN(avg_run_duration)
WHEN 1 THEN CAST('00:00:0'
+ CAST(avg_run_duration AS CHAR) AS CHAR(8))
WHEN 2 THEN CAST('00:00:'
+ CAST(avg_run_duration AS CHAR) AS CHAR(8))
WHEN 3 THEN CAST('00:0'
+ LEFT(RIGHT(avg_run_duration, 3), 1)
+ ':' + RIGHT(avg_run_duration, 2) AS CHAR(8))
WHEN 4 THEN CAST('00:'
+ LEFT(RIGHT(avg_run_duration, 4), 2)
+ ':' + RIGHT(avg_run_duration, 2) AS CHAR(8))
WHEN 5 THEN CAST('0'
+ LEFT(RIGHT(avg_run_duration, 5), 1)
+ ':' + LEFT(RIGHT(avg_run_duration, 4), 2)
+ ':' + RIGHT(avg_run_duration, 2) AS CHAR(8))
WHEN 6 THEN CAST(LEFT(RIGHT(avg_run_duration, 6), 2)
+ ':' + LEFT(RIGHT(avg_run_duration, 4), 2)
+ ':' + RIGHT(avg_run_duration, 2) AS CHAR(8))
END
,[Subday_Frequency] = 
CASE (sched.freq_subday_interval)
WHEN 0 THEN 'Once'
ELSE CAST('Every '
+ RIGHT(sched.freq_subday_interval, 2)
+ ' '
+ CASE (sched.freq_subday_type)
WHEN 1 THEN 'Once'
WHEN 4 THEN 'Minutes'
WHEN 8 THEN 'Hours'
END AS CHAR(16))
END
,[Sched_End Date] = sched.active_end_date
,[Sched_End Time] = sched.active_end_time
,[Fail_Notify_Name] = 
CASE
WHEN oper.enabled = 0 THEN 'Disabled: '
ELSE ''
END + oper.name
,[Fail_Notify_Email] = oper.email_address
,server

FROM dbo.sysjobs job
LEFT JOIN (SELECT

job_schd.job_id
,sys_schd.enabled
,sys_schd.schedule_id
,sys_schd.freq_type
,sys_schd.freq_subday_type
,sys_schd.freq_subday_interval
,next_run_date = 
CASE
WHEN job_schd.next_run_date = 0 THEN sys_schd.active_start_date
ELSE job_schd.next_run_date
END
,next_run_time = 
CASE
WHEN job_schd.next_run_date = 0 THEN sys_schd.active_start_time
ELSE job_schd.next_run_time
END
,active_end_date = NULLIF(sys_schd.active_end_date, '99991231')
,active_end_time = NULLIF(sys_schd.active_end_time, '235959')

FROM dbo.sysjobschedules job_schd
LEFT JOIN dbo.sysschedules sys_schd
ON job_schd.schedule_id = sys_schd.schedule_id) sched
ON job.job_id = sched.job_id
LEFT OUTER JOIN (SELECT
job_id, server
,MAX(job_his.run_duration) AS max_run_duration
,MIN(job_his.run_duration) AS min_run_duration
,AVG(job_his.run_duration) AS avg_run_duration
FROM dbo.sysjobhistory job_his
GROUP BY job_id, server) Q1
ON job.job_id = Q1.job_id
LEFT JOIN sysoperators oper
ON job.notify_email_operator_id = oper.id)


SELECT
	isnull(b.server,convert(varchar(max),SERVERPROPERTY('ServerName'))) AS ServerName, b.job_name, b.job_enabled, isnull(b.sched_enabled,'No') as sched_enabled,
	isnull(a.scheduleName, 'None') as scheduleName, isnull(a.frequency,'Not scheduled') as frequency, 
	isnull(a.subFrequency, 'None') as subFrequency, isnull(a.start_time,'-') as start_time, isnull(a.end_time,'-') as end_time, 
	isnull(b.Start_Date, '-') as Start_Date, isnull(b.Next_Run_Time, '-') as Startdate, 
	isnull(b.Max_Duration, '-') as Max_Duration, isnull(b.Min_Duration, '-') as Min_Duration, 
	isnull(b.Avg_Duration, '-') as Avg_Duration, isnull(b.Fail_Notify_Name, 'None') as Fail_Notify_Name, 
	isnull(b.Fail_Notify_Email, 'None') as Fail_Notify_Email
FROM
	SCHED a RIGHT OUTER JOIN JOB b 
	ON a.job_id = b.job_id 
--WHERE
--	b.job_name LIKE 'abc%'
ORDER BY
	start_time, b.job_enabled DESC, a.frequency, job_name
