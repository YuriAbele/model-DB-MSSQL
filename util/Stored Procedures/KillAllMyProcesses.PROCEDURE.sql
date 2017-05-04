CREATE PROCEDURE util.KillAllMyProcesses
AS
BEGIN
	DECLARE @sql VARCHAR(MAX) = '-- Kill all my processes (except current: '
							  + CAST(@@SPID AS VARCHAR(20)) + ')';
	SELECT @sql = @sql + CHAR(13) + CHAR(10) + 'kill ' + CONVERT(varchar(5), spid) + ';'
	FROM master..sysprocesses
	WHERE sid = USER_SID() AND spid != @@SPID;
 
	RAISERROR(@sql, 0,1) WITH NOWAIT;
	--EXEC (@sql);
END
/*
EXEC util.KillAllMyProcesses;
*/
;