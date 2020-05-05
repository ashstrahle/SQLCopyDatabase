# SQLCopyDatabase
This script creates a stored procedure `sp_CopyDatabase` that restores the most recent backup of `@src_database` over `@tgt_database`. It attempts to kill all sessions connected to target  database prior to committing the restore. It assumes the target database already exists. 

Useful for refreshing, say, test or training databases from production instances.

## Execute
You can execute the procedure using the following:

```
USE [master]
GO

DECLARE @RC int
DECLARE @src_database nvarchar(max) = '<my source database name>'
DECLARE @tgt_database nvarchar(max) = '<my target database name>'

-- TODO: Set parameter values here.

EXECUTE @RC = [dbo].[sp_CopyDatabase] 
   @src_database
  ,@tgt_database
GO
```
