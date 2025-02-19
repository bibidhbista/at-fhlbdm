

	

CREATE PROCEDURE [dbo].[Admin_ChangeTableOwner]

-- Don - This stored procedure will change the ownership for all Tables associated with one owner to a new owner.

-- Parameters to be passed in are the object owner name to change and the new object owner name.

 

 @ObjectOwner varchar(20),

 @SpecificObject Varchar(500) = null



AS

Declare @ObjectName  varchar(128), @sql varchar (500), @FullObjectName varchar(148), @OldObjectOwner varchar(128)

 --Create list of object names which are owned by the object owner passed in as parameter



If @specificObject is null

	begin

	DECLARE ObjectsCursor CURSOR FOR

	SELECT sysobjects.name 

	FROM sysusers INNER JOIN sysobjects ON sysusers.uid = sysobjects.uid

	WHERE sysusers.name = @ObjectOwner and sysobjects.type = 'u' 

	end

else

	begin

	DECLARE ObjectsCursor CURSOR FOR

	SELECT sysobjects.name 

	FROM sysusers INNER JOIN sysobjects ON sysusers.uid = sysobjects.uid

	WHERE sysusers.name = @ObjectOwner and sysobjects.type = 'u' and sysobjects.name = @SpecificObject

	end





OPEN ObjectsCursor

 --Get the first object name to be changed



FETCH NEXT FROM ObjectsCursor

 Into @ObjectName



 --Loop through all objects for the owner name

WHILE (@@FETCH_STATUS = 0)

	 begin

		     Set @FullObjectName = @ObjectOwner + '.' + @ObjectName

		     Set @OldObjectOwner = 'dbo.' + @ObjectName



			if exists (SELECT sysobjects.name  FROM sysusers INNER JOIN sysobjects ON sysusers.uid = sysobjects.uid  and OBJECTPROPERTY(id, N'IsUserTable') = 1 and sysusers.name = 'dbo' and sysobjects.name = @objectname)

			begin

			    --drop existing stored procedure under dbo ownership

			    execute ('drop Table ' + @OldObjectOwner) 		

			end







		   

		    --Call standard SQL stored procedure to change ownership one object at a time

		     --Execute sp_ChangeObjectOwner @FullObjectName, 'dbo'

			SET @SQL = 'ALTER SCHEMA dbo TRANSFER ' + @FullObjectName

			Exec (@SQL)

		    

      			Set @SQL = 'Grant Select,Update,Insert,Delete on ' + @ObjectName + ' to devteam'

			Exec (@SQL)





			--Get the next object name 

		     FETCH NEXT FROM ObjectsCursor

		  Into @ObjectName

	 end



CLOSE ObjectsCursor

DEALLOCATE ObjectsCursor







	
