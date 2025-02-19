

	

	

CREATE PROCEDURE [dbo].[Admin_ChangeFunctionOwner]

-- Don - This stored procedure will change the ownership for all Functions associated with one owner to a new owner.

-- Parameters to be passed in are the object owner name to change and the new object owner name.

 

 @ObjectOwner varchar(20),

 @SpecificObject varchar(500) = Null,

 @SecurityObject varchar(1000),

 @Count int output

AS

Declare @ObjectName  varchar(128), @sql varchar (500), @FullObjectName varchar(148), @OldObjectOwner varchar(128)

declare @FunctionType varchar(2)

 --Create list of object names which are owned by the object owner passed in as parameter



If @specificObject is null

	begin

	DECLARE ObjectsCursor CURSOR FOR

	SELECT sysobjects.name, sysobjects.type

	FROM sysusers INNER JOIN sysobjects ON sysusers.uid = sysobjects.uid

	WHERE sysusers.name = @ObjectOwner and sysobjects.type in ('FN','TF')

	end

else

	begin

	DECLARE ObjectsCursor CURSOR FOR

	SELECT sysobjects.name, sysobjects.type 

	FROM sysusers INNER JOIN sysobjects ON sysusers.uid = sysobjects.uid

	WHERE sysusers.name = @ObjectOwner and sysobjects.type in ('FN','TF')	

	and sysobjects.name = @specificobject

	end



set @count = 0

OPEN ObjectsCursor

 --Get the first object name to be changed



FETCH NEXT FROM ObjectsCursor

 Into @ObjectName,@functiontype



 --Loop through all objects for the owner name

WHILE (@@FETCH_STATUS = 0)

	 begin

		     Set @FullObjectName = '[' + @ObjectOwner + '].[' + @ObjectName + ']'

		     Set @OldObjectOwner = 'dbo.' + @ObjectName



			if exists (SELECT sysobjects.name  FROM sysusers INNER JOIN sysobjects ON sysusers.uid = sysobjects.uid  and (OBJECTPROPERTY(id, N'IsTableFunction') = 1 or OBJECTPROPERTY(id, N'IsTableFunction') = 0) and sysusers.name = 'dbo' and sysobjects.name = @obj
ectname)

				begin		

				    --drop existing stored procedure under dbo ownership

				    execute ('drop Function ' + @OldObjectOwner) 

				end



   

		    --Call standard SQL stored procedure to change ownership one object at a time

		    -- Execute sp_ChangeObjectOwner @FullObjectName, 'dbo'

			SET @SQL = 'ALTER SCHEMA dbo TRANSFER ' + @FullObjectName

			Exec (@SQL)



			If @functiontype = 'TF' 

				begin

					Set @SQL = 'Grant select on ' + @ObjectName + ' to ' + @SecurityObject

					Exec (@SQL)

				end

			else

				begin

					Set @SQL = 'Grant execute on ' + @ObjectName + ' to ' + @SecurityObject

					Exec (@SQL)

				end

	

		   --Call sp to add sp and text to table to create scripts

		    Execute Admin_i_FNHistory  @ObjectName



			--Get the next object name 

		     FETCH NEXT FROM ObjectsCursor

		  Into @ObjectName,@functiontype

		set @count = @count + 1

	 end



CLOSE ObjectsCursor

DEALLOCATE ObjectsCursor







	

	
