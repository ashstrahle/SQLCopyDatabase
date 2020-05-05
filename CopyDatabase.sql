USE [master]
GO

/****** Object:  StoredProcedure [dbo].[sp_CopyDatabase] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ==========================================================================================
--
--	This procedure restores the most recent backup of @src_database over @tgt_database.
--	It assumes the target database already exists. It attempts to kill all sessions 
--	connected to target database prior to committing the restore.
--
--  Author: Ashley Strahle - https://github.com/ashstrahle
--
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_CopyDatabase](@src_database NVARCHAR(MAX), @tgt_database NVARCHAR(MAX))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE 
	@src_latestbackupfile AS NVARCHAR(MAX),
	@src_mdb_name AS NVARCHAR(MAX),
	@tgt_mdb_path AS NVARCHAR(MAX),
	@src_log_name AS NVARCHAR(MAX),
	@tgt_log_path AS NVARCHAR(MAX);

-- Get the latest backup file of the source database
SELECT TOP 1 @src_latestbackupfile = bmf.physical_device_name FROM msdb.dbo.backupmediafamily bmf
LEFT JOIN msdb.dbo.backupset bs ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = @src_database and bmf.device_type = 2
ORDER BY bs.backup_start_date DESC;

-- Get the source database logical name
SELECT @src_mdb_name = mf.name FROM sys.master_files mf
WHERE DB_ID(@src_database) = mf.database_id and mf.type_desc = 'ROWS';

-- Get the target database path
SELECT @tgt_mdb_path = mf.physical_name FROM sys.master_files mf
WHERE mf.database_id = DB_ID(@tgt_database) and mf.type_desc = 'ROWS';

-- Get the source database log logical name
SELECT @src_log_name = mf.name FROM sys.master_files mf
WHERE mf.database_id = DB_ID(@src_database) and mf.type_desc = 'LOG';

-- Get the target database log path
SELECT @tgt_log_path = mf.physical_name FROM sys.master_files mf
WHERE mf.database_id = DB_ID(@tgt_database) and mf.type_desc = 'LOG';

-- SELECT @src_latestbackupfile, @src_mdb_name, @tgt_mdb_path, @src_log_name, @tgt_log_path

-- Kill all current connections to target database
DECLARE @kill VARCHAR(8000) = '';  
SELECT @kill = @kill + 'kill ' + CONVERT(VARCHAR(5), session_id) + ';'  
FROM sys.dm_exec_sessions
WHERE database_id  = DB_ID(@tgt_database)
EXEC(@kill);

-- Kick off restore
restore database @tgt_database FROM disk = @src_latestbackupfile
with replace,
move @src_mdb_name to @tgt_mdb_path,
move @src_log_name to @tgt_log_path;

END
GO
