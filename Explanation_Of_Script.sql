============================== Beginning ===========================

start-dfs.sh
start-yarn.sh
nohup hive --service metastore &


tname,total_records,same records,updated records
TB1-41612,0,0
TB2-62570,20,10 -- 62601
TB3-62167,20,10 -- 62197


============================== Permissions For File ===========================

chmod +rwx Day_1.csv Day_2.csv Day_3.csv 

======================== Creating database and table ===========================
mysql --local-infile=1 -uroot -p

SET GLOBAL local_infile=1;

create database project;

use project;

create table project_sql (
	custid integer(10) primary key not null,
	username varchar(30),
	quote_count varchar(30),
	ip varchar(30),
	entry_time varchar(30),
	prp_1 varchar(30),
	prp_2 varchar(30),
	prp_3 varchar(30),
	ms varchar(30),
	http_type varchar(30),
	purchase_category varchar(30),
	total_count varchar(30),
	purchase_sub_category varchar(30),
	http_info varchar(30),
	status_code integer(10),
	curr_time bigint
);


load data local infile '/home/saif/training11/project/Day_1.csv' into table project_sql fields terminated by ',';

set sql_safe_updates = 0;


update project_sql set curr_time = CURRENT_TIMESTAMP() + 1 where curr_time IS NULL;


======================= Loading of data =============================


sqoop import --connect jdbc:mysql://localhost:3306/project?useSSL=False --username root --password Welcome@123 --query 'select custid,username,quote_count,ip,entry_time,prp_1,prp_2,prp_3,ms,http_type,purchase_category,total_count,purchase_sub_category,http_info,status_code,curr_time from project_sql where $CONDITIONS' --split-by custid --target-dir /user/saif/HFS/output/project_1;


======================================== Creating and Loading data from HDFS to Hive =========================================

nohup hive --service metastore &

create database project_hive;

use project_hive;

create table project_int (
custid int,
username string,
quote_count string,
ip string,
entry_time string,
prp_1 string,
prp_2 string,
prp_3 string,
ms string,
http_type string,
purchase_category string,
total_count string,
purchase_sub_category string,
http_info string,
status_code int,
curr_time BIGINT
)
row format delimited fields terminated by ',';


load data inpath '/user/saif/HFS/output/project_1' into table project_int;




==========================================Partition Table in Hive==============================================


set hive.exec.dynamic.partition=true;    
set hive.exec.dynamic.partition.mode=nonstrict;

create external table project_int_par(
custid int,
username string,
quote_count string,
ip string,
prp_1 string,
prp_2 string,
prp_3 string,
ms string,
http_type string,
purchase_category string,
total_count string,
purchase_sub_category string,
http_info string,
status_code int,
curr_time BIGINT
)
partitioned by(year string,month string)
row format delimited fields terminated by ',';


insert overwrite table project_int_par partition (year, month) select custid,username,quote_count,ip,prp_1,prp_2,prp_3,ms,http_type,
purchase_category,total_count,purchase_sub_category,http_info,status_code,curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year, 
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month from project_int;


=============================================================SCD=============================================================================


insert overwrite table project_int_par partition (year, month) select a.custid,a.username,a.quote_count,a.ip,a.prp_1,a.prp_2,a.prp_3,a.ms,a.http_type,
a.purchase_category,a.total_count,a.purchase_sub_category,a.http_info,a.status_code,a.curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year, 
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month from project_int a
join 
project_int_par b
on a.custid=b.custid
union
select a.custid,a.username,a.quote_count,a.ip,a.prp_1,a.prp_2,a.prp_3,a.ms,a.http_type,
a.purchase_category,a.total_count,a.purchase_sub_category,a.http_info,a.status_code,a.curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year, 
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month
from project_int a
left join 
project_int_par b
on a.custid=b.custid
where b.custid is null
union
select b.custid,b.username,b.quote_count,b.ip,b.prp_1,b.prp_2,b.prp_3,b.ms,b.http_type,
b.purchase_category,b.total_count,b.purchase_sub_category,b.http_info,b.status_code,b.curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year, 
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month
from project_int a
right join 
project_int_par b
on a.custid=b.custid
where a.custid is null
;



=============================================================SCD2=============================================================================




insert overwrite table project_int_par partition (year, month) select a.custid,a.username,a.quote_count,a.ip,a.prp_1,a.prp_2,a.prp_3,a.ms,a.http_type,
a.purchase_category,a.total_count,a.purchase_sub_category,a.http_info,a.status_code,a.curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year, 
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month from project_int a
join 
project_int_par b
on a.custid=b.custid
union
select b.custid,b.username,b.quote_count,b.ip,b.prp_1,b.prp_2,b.prp_3,b.ms,b.http_type,
b.purchase_category,b.total_count,b.purchase_sub_category,b.http_info,b.status_code,b.curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year, 
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month from project_hive.project_int a
join 
project_hive.project_int_par b
on a.custid=b.custid
union
select a.custid,a.username,a.quote_count,a.ip,a.prp_1,a.prp_2,a.prp_3,a.ms,a.http_type,
a.purchase_category,a.total_count,a.purchase_sub_category,a.http_info,a.status_code,a.curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year, 
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month
from project_int a
left join 
project_int_par b
on a.custid=b.custid
where b.custid is null
union
select b.custid,b.username,b.quote_count,b.ip,b.prp_1,b.prp_2,b.prp_3,b.ms,b.http_type,
b.purchase_category,b.total_count,b.purchase_sub_category,b.http_info,b.status_code,b.curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year, 
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month
from project_int a
right join 
project_int_par b
on a.custid=b.custid
where a.custid is null
;



=======================================================Intermediate Table for checking the data==========================================================================

create table project_inter (
custid int,
username string,
quote_count string,
ip string,
entry_time string,
prp_1 string,
prp_2 string,
prp_3 string,
ms string,
http_type string,
purchase_category string,
total_count string,
purchase_sub_category string,
http_info string,
status_code int,
year string,
month string,
curr_time BIGINT
)
row format delimited fields terminated by ',';

insert into table project_inter select *
from project_int_par t1 join
     (select max(curr_time) as max_date_time
      from project_int_par
     ) tt1
     on tt1.max_date_time = t1.curr_time;


==========================================================Creating table and Exporting======================================================================



create table project_sql_exp (
	custid integer(10),
	username varchar(30),
	quote_count varchar(30),
	ip varchar(30),
	entry_time varchar(30),
	prp_1 varchar(30),
	prp_2 varchar(30),
	prp_3 varchar(30),
	ms varchar(30),
	http_type varchar(30),
	purchase_category varchar(30),
	total_count varchar(30),
	purchase_sub_category varchar(30),
	http_info varchar(30),
	status_code integer(10),
	year varchar(100),
	month varchar(100),
	curr_time bigint
);



sqoop export --connect jdbc:mysql://localhost:3306/project?useSSL=False --table project_sql_exp --username root --password Welcome@123 --export-dir "/user/hive/warehouse/project_hive.db/project_inter" --input-fields-terminated-by ',';





