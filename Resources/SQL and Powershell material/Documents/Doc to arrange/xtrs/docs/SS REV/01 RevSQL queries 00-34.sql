
-- drop a column from the specified column
USE [pragim_ytube]
GO
ALTER TABLE [dbo].[tblPerson] DROP COLUMN [test]
GO



SELECT * FROM tblperson
SELECT * FROM tblperson2
SELECT * from tblgender



insert into tblGender(id, Gender) 
values (2, 'Female') 


--Identity defined for id field so no need to mention the id each time
select * from tblPerson where Name='rich' AND ID =1
insert into tblPerson(GenderId) VALUES (1)

-- Check constraints for email field
ALTER table tblPerson 
add constraint CK_tblPerson_Email
check(EMAIL  LIKE '%@%.%')

-- Difference between scope identity: limited to current scope and @@identity: almost global IDENT_current: even in different sessions
select SCOPE_IDENTITY()
select @@identity

insert into tblperson (id,name, email) values (17, 'bibidh', 'bista@com.com')


create table tblPerson2 (
id int identity(1,1) not null primary key,
name nvarchar(50) not null,
email nvarchar(50) not null,
GenderId nvarchar(50))

-- Trigger for insert
Create trigger trForInsert on tblPerson for insert
as
Begin
    insert into tblPerson2(name, email) VALUES ('BBB', 'email@cc.com')
end


-- Unique constraint
alter table tblperson 
add constraint UQ_tblPerson_email
UNIQUE (EMAIL)



-- select queries


-- select all
select * from tblperson


--select distinct rows
select distinct name from tblPerson
select distinct name, GenderId from tblPerson  -- distinct in both columns


-- where clause
--in, between, like, not
--wildcards % one or more, _ one char, [] specify characters, ^ not operator
select * from tblPerson where email like '%r%'


--and or operator

--sort by order by
select * from tblperson order by name, email desc

--select top 
select top 2 * from tblPerson
select top 50 percent * from tblPerson





--group by
Select name, count(genderid) as noOfMorF
from tblperson
group by name, GenderId


--joins
-- inner join or join: returns matching rows
SELECT name, email, D.GenderId, G.Gender
from tblGender G
inner join tblPerson D
on D.GenderId = G.ID

--outerJoin: left/right/full
--left returns matching rows in both and all non matching rows in left table
SELECT name, email, D.GenderId, G.Gender
from tblGender G
LEFT join tblPerson D
on D.GenderId = G.ID
--right returns matching rows in both and all non matching rows in right table
SELECT name, email, D.GenderId, G.Gender
from tblGender G
RIGHT join tblPerson D
on D.GenderId = G.ID
--full returns matching rows in both and all non matching rows in both tables
SELECT name, email, D.GenderId, G.Gender
from tblGender G
FULL join tblPerson D
on D.GenderId = G.ID
--crossjoin : prdouces cartesian product of both the tables
SELECT name, email, D.GenderId, G.Gender
from tblGender G
CROSS join tblPerson D



 --advanced joins: get non matching rows onlyyy
 --non matching rows from left table only
select name, Gender
from tblPerson
left join tblGender
on tblPerson.GenderId = tblGender.ID
where tblPerson.GenderId =3


--self join 
select g.name, g.Genderid
from tblPerson g
left join tblPerson p
on g.genderId = p.ID


--replacing null values : isnull() funct, case statement, coalesce() funct
--isnull()   if null change to given text:
SELECT ISNULL(NULL, 'bibidh') as name

SELECT P.name, P.email, ISNULL(g.Gender, 'Not specified') as Gender
from	tblperson P
left Join tblGender G
on P.GenderId=g.ID


--coalesce() funct: returns non null value
SELECT COALESCE(NULL, 'bibidh') as name
-- select Id, coalesce(first name, middle name, last name) as Name from tblEmp .........chooses middle if first is null .. last name if first and middle names are null


--case stament
SELECT P.name, P.email, CASE When P.Name='bibidh' then 'not bibidh' else p.Name END as [Changed Name]
from	tblperson P
left Join tblGender G
on P.GenderId=g.ID


--union and union all 
--union unites two select queries .. removes duplicates and sorts em
SELECT * from tblPerson
union
SELECT * from tblPerson

--Cltrl+l to see estimated execution plan
-- union all unites everything in both tables ... with duplicates and no sort
SELECT * from tblPerson
union ALL
SELECT * from tblPerson



--stored procs: for things you have to perform on a regular basis: encryption : WITH ENCRYPTION
Create PROCEDURE spGetNames --or create proc
AS
BEGIN
	SELECT name, email, D.GenderId, G.Gender
	from tblGender G
	inner join tblPerson D
	on D.GenderId = G.ID
END

--to execute the sp
spGetNames

--passing parameters INPUT
Create PROCEDURE spGetNames_genId
	@genderid int
as 
begin
	select Name, genderid, email from tblPerson where Genderid = @genderid
end

--exe
exec spGetNames_genId 3 
exec spGetNames_genId @genderid = 2 

-- sys sp.. helptext
sp_helptext spGetNames

--passing parameters OUTPUT
CREATE PROC spGetCountOfGender
	@genderid int,
	@GenderCount int OUTPUT
AS
BEGIN
	select @GenderCount = COUNT(tblPerson.ID) from tblPerson where Genderid = @genderid

end

--exec
DECLARE @TotalCount int
exec spGetCountOfGender 1, @TotalCount OUT
print @TotalCount
--help
sp_help spgetcountofgender
sp_help tblperson
sp_depends spgetcountofgender


--return values from sp // only for 1 int return value .......usually to convey success or fail
CREATE PROC spGetCountOfGender_return
	@genderid int
AS
BEGIN
	return(select COUNT(tblPerson.ID) from tblPerson where Genderid = @genderid)

end

--exec
DECLARE @TotalCount int
exec @TotalCount = spGetCountOfGender_return 2
print @TotalCount


--string fnc: charindex.. substring...replicate...space()...patindex:charindex for finding patterns...    replace funct... stuff

-- date func
Create TABLE tblDateTime
(
c_time time,
c_date date,
c_smalldatetime SMALLDATETIME,
c_datetime datetime,
c_datetime2 datetime2,
c_datetimeoffset DATETIMEOFFSET(7)
)

SELECT * from tblDateTime


------------------------------------time------date------smallDT-----DT--------DT2----DToffset
insert	into tblDateTime values (getdate(), getdate(), getdate(),getdate(),getdate(),getdate())

UPDATE tblDateTime SET c_datetimeoffset = '2016-06-16 13:28:58.9270000 +01:00'
WHERE c_datetimeoffset = '2016-06-16 13:28:58.9270000 +00:00'

select getdate(), 'getdata()' --commonlyused
select CURRENT_TIMESTAMP, 'CURRENT_TIMESTAMP()'
select SYSDATETIME(), 'SYSDATETIME()' --precision
select SYSDATETIMEOFFSET(), 'SYSDATETIMEOFFSET()'--presicision + time zone offset
select GETUTCDATE(), 'GETUTCDATE()'
select getdate(), 'getdata()'


--isdate();;;; checks to see if the given value is  a valid date, time or dt returns 0 and 1
select	isdate('bbdh') ----returns 0
select	isdate(GETDATE()) ----returns 1
select ISDATE('2016-06-16 13:28:58.9270000 +01:00') -- datetime2 and dtoffsett returns 0

--day month year			for 06/16/2016
select day(GETDATE())		--returns 16
select MONTH(GETDATE())		--returns 6
select YEAR(GETDATE())		--returns 2016


--datename day of year....... quarter.......week
select DATENAME(day, GETDATE())          -- returns 16
select DATENAME(WEEKDAY, GETDATE())		-- returns Thursday
select DATENAME(MONTH, GETDATE())		-- returns June
select DATENAME(quarter, GETDATE())     --2

-- datepart, dateadd, datediff
select DATEPART(weekday,getdate())		--returns 5 for thurs ::::::::::: int reprseentation of datename 
select DATENAME(weekday,getdate())		--thursday


--dateadd 
select dateadd(day, 10, getdate())			--10 days from current date..
select dateadd(day, -10, getdate())			--10 days before current date..

--datediff
select datediff(day, '11/30/2005', '02/17/2007')	--444days
select datediff(MONTH, '11/30/2005', '02/17/2007')  --15 months


-- can't use sp in select and where clause but can use functions in both of those
--compute age
create FUNCTION fnComputeage (@dob DATETIME)
	RETURNS NVARCHAR(50)
AS
BEGIN
	DECLARE @tempdate DATETIME, @years int, @months int, @days INT

	SELECT @tempdate = @dob
	
	SELECT @years = datediff(year, @tempdate, getdate()) - 
					CASE	
						WHEN (month(@dob) > month (getdate())) OR
						(MONTH(@dob) = MONTH(getdate()) and day(@dob) >day(GETDATE()))
						then 1 else 0
					END

	SELECT @tempdate =DATEADD(YEAR, @years, @tempdate)

	select @months = DATEDIFF (month, @tempdate, getdate()) -
					case 
						when day(@dob) >day(getdate())
						then 1 else 0
					END

	select @tempdate =dateadd(MONTH, @months, @tempdate)
	select @days =DATEDIFF(DAY,@tempdate, getdate())
	
	declare @age NVARCHAR(50)
	set @age = cast(@years as NVARCHAR(4))+'Years'+cast(@months as NVARCHAR(2))+' months' +cast(@days as NVARCHAR(2)) +' days old.'
	--select @years as YEARS, @months as MONTHS, @days as [DAYS]

	return @age
end


-- exe the funtion
SELECT dbo.fnComputeAge('11/30/2015')           --returns 0Years6 months17 days old.



SELECT id,name,email, dateOfBirth,  dbo.fnComputeAge(dateofbirth) as Age from tblperson




--cast and convert date::: convert can have different formats : 101 mm/dd/yyyy 102 yy.mm.dd 013 dd/mm/yyyy

select id, name, dateofbirth, CAST(dateofbirth as NVARCHAR) as CONVERTEDDOB, DATEname(month,dateofbirth)+' '+convert(NVARCHAR,YEAR( dateofbirth)) as DOB2 from tblPerson
select id, name, dateofbirth, CONVERT(NVARCHAR, dateofbirth) as CONVERTEDDOB from tblPerson
select id, name, dateofbirth, CONVERT(NVARCHAR, dateofbirth, 102) as CONVERTEDDOB from tblPerson   --yy.dd.yyyy


--mathematical functions
--ceiling floor
select CEILING(15.2)			--   16
select FLOOR(15.2)				--   15
select CEILING(-15.2)			--  -15
select FLOOR(-15.2)				--  -16

--power square sqrt
select POWER(2,3)
select square(9)
select sqrt (81)

--round
select round(66.6666,2)		--66.6700
select round(66.6666,2,1)	--66.6600


-- inline table valued functions: returns table ...... doesn't need begin end block ... return statement is just a select statement
create	FUNCTION fnempByGender (@genderid NVARCHAR(10))
RETURNS TABLE
AS
return (SELECT tblperson.id, name, dateofbirth, g.gender as Gender
		from	tblPerson
		left join tblGender g
		on tblPerson.GenderId = g.ID
		where	 GenderId = @genderid)

--exe
select * from fnempbygender(1) 


--multi statement table valued function:       when given a choice choose ITVF .. coz faster and records can be updated in the future
create function fnMSTVFempbygender()
RETURNS @table table (id int, name NVARCHAR(20), dob date)
as 
BEGIN
	insert into @table
	select id , name, dateofbirth from tblPerson
	return
end

--exe
select * from dbo.fnmstvfempbygender()



--withencryption				WITHSCHEMABINDING: can't change/delete underlying table from a function as it has references to table/fields    with this command


--local temp tables :#: only works until the connection is closed ... so can't be accessed from other connections
-- if a sp contains a temp table... it gets deleted after the execution of the sp
create table #persondetails(id int, name NVARCHAR(20))

insert into #persondetails values (1, 'mike')
insert into #persondetails values (2, 'john')
insert into #persondetails values (3, 'todd')

SELECT * from #persondetails


--local temp tables :##: works for other connections too..............closed when the last connection to the table is closed
create table ##EmpDetails(id int, name NVARCHAR(20))

SELECT * from ##EmpDetails
