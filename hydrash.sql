-+-----------------------------------------+-
         SCRIPT BY KISHAN                   |
-+-----------------------------------------+-
set lines 200 pages 1000
col TIMER(s) for 9999999
col SID for 9999
col "WHO_BLOCK_WHO" for a20
col W_CHAINS for a60
col EVENT for a25
col WHO for a7
col PROGRAM for a7
col username for a7
col W_CHAINS for a50
col CHART_WAIT_CLASS for a20
col cntr for 99999999
col count(*) for 99999999999
def acol="ash.session_id as sid,to_char(ash.sample_time,'dd-mm-yy hh24:mi:ss') as TIME,regexp_substr(PROGRAM,'[^@]+') as WHO,regexp_substr(ash.PROGRAM,'\((.*?)\)',1,1,null,1) as PROGRAM,ash.SQL_ID"
def ucol="au.username"
def aview="v$active_session_history ash"
def uview="all_users au"
def aujoin="( ash.user_id = au.user_id )"
def awhere="ash.session_state like '%WAIT%' and ash.BLOCKING_SESSION is NOT NULL"
def aord="order by TIMER_sec desc"
--def astime="to_char(sample_time,'dd-mm-yy hh24:mi:ss') between '16-05-22 20:23:40' and '16-05-22 20:23:47'"
def agby="group by W_CHAINS,SQL_ID,TOTAVGACT,AVGAS"
def afilter="fetch first 5 rows only"
WITH HYDRASH as 
(
select &acol,
       &ucol,
       case when session_state = 'ON CPU' 
	   then 'BURN_CPU' 
	        when session_state = 'WAITING' 
			then 'LONG_WAIT' 
			     when session_state = 'WAITED SHORT TIME' 
				 then 'SHORT_WAIT' 
				 else 'KNOWN_WAIT' 
				 end as state,
       case when ash.BLOCKING_SESSION is NULL 
       then 'NULL'
	        when ash.BLOCKING_SESSION is NOT NULL 
		    then '|'||lag(ash.EVENT) over (order by sample_id)||' [|]<~~~ '||ash.EVENT||'|' 	
       end W_CHAINS,				
       '|'||nvl(to_char(ash.BLOCKING_SESSION),'NULL')||' blocks===> '||ash.SESSION_ID||'|' as "WHO_BLOCK_WHO"
from &aview
full outer join &uview on &aujoin
where &awhere
), AAS as 
(
select ((CAST(max(ash.sample_time) AS DATE) - CAST(min(ash.sample_time) AS DATE)) * 24 * 3600) AVGAS,
       round(count(*) / ((CAST(max(ash.sample_time) AS DATE) - CAST(min(ash.sample_time) AS DATE)) * 24 * 3600),2) TOTAVGACT
from &aview 
)
select W_CHAINS,
       count(*) TIMER_sec,
	   rpad(' ',count(*)/10,'<>') CHART_WAIT_CLASS,
	   SQL_ID,
	   TOTAVGACT,
	   round(count(*) / (AVGAS),3) * 100 as "PER%AS"
       from HYDRASH,AAS
	&agby
	&aord
	&afilter;
	