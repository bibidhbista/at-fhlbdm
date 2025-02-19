

	



	

CREATE PROCEDURE [dbo].[Admin_ChangeSPOwner]

-- Don - This stored procedure will change the ownership for all Stored Procedures associated with one owner to a new owner.

-- Parameters to be passed in are the object owner name to change and the new object owner name.

 

 @ObjectOwner varchar(20),

 @SpecificObject varchar(500) = Null,

 @SecurityObject varchar(1000),

 @Count int output

AS

Declare @ObjectName  varchar(128), @sql varchar (500), @FullObjectName varchar(148), @OldObjectOwner varchar(128)

 --Create list of object names which are owned by the object owner passed in as parameter

	

If @SpecificObject is null

	begin

	DECLARE ObjectsCursor CURSOR FOR

	SELECT sysobjects.name 

	FROM sysusers INNER JOIN sysobjects ON sysusers.uid = sysobjects.uid

	WHERE sysusers.name = @ObjectOwner and sysobjects.type = 'p'

	end

else

	begin

	DECLARE ObjectsCursor CURSOR FOR

	SELECT sysobjects.name 

	FROM sysusers INNER JOIN sysobjects ON sysusers.uid = sysobjects.uid

	WHERE sysusers.name = @ObjectOwner and sysobjects.type = 'p' and sysobjects.name = @specificObject

	end



set @count = 0



OPEN ObjectsCursor

 --Get the first object name to be changed



FETCH NEXT FROM ObjectsCursor

 Into @ObjectName



 --Loop through all objects for the owner name

WHILE (@@FETCH_STATUS = 0)

	 begin

		     Set @FullObjectName = '[' + @ObjectOwner + '].[' + @ObjectName + ']'

		     Set @OldObjectOwner = 'dbo.' + @ObjectName



			if exists (SELECT sysobjects.name  FROM sysusers INNER JOIN sysobjects ON sysusers.uid = sysobjects.uid  and OBJECTPROPERTY(id, N'IsProcedure') = 1 and sysusers.name = 'dbo' and sysobjects.name = @objectname)

				begin

				    execute ('drop procedure ' + @OldObjectOwner) 

				end



		   

		    --Call standard SQL stored procedure to change ownership one object at a time

		     --Execute sp_ChangeObjectOwner @FullObjectName, 'dbo'

			SET @SQL = 'ALTER SCHEMA dbo TRANSFER ' + @FullObjectName

			Exec (@SQL)



			Set @SQL = 'Grant execute on ' + @ObjectName + ' to ' + @SecurityObject

			Exec (@SQL)



		   --Call sp to add sp and text to table to create scripts

		    Execute Admin_i_SPHistory  @ObjectName



			--Get the next object name 

		     FETCH NEXT FROM ObjectsCursor

		  Into @ObjectName

		set @count = @count + 1

	 end



CLOSE ObjectsCursor

DEALLOCATE ObjectsCursor







	



	
