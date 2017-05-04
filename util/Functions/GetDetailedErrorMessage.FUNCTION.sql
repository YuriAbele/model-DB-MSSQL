/*=============================================
Author:
    Yuri Abele
Changes:
    11.06.2013 - Yuri Abele - initial
Description:
    Function to format last error as detailed message
 
Usage: Log last error
    BEGIN TRY
        DECLARE @i INT;
        PRINT 'Try division by zero'
        SET @i = 1/0;
        PRINT 'After'
    END TRY
    BEGIN CATCH
        -- Display error
        PRINT dbo.fnGetDetailedErrorMessage();
        IF @@TRANCOUNT > 0 ROLLBACK;
    END CATCH;
=============================================*/
CREATE FUNCTION util.GetDetailedErrorMessage()
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN ('ERROR:
        ErrorNumber    = ' + CAST(ERROR_NUMBER() AS VARCHAR(20)) + ',
        ErrorSeverity  = ' + CAST(ERROR_SEVERITY() AS VARCHAR(20)) + ',
        ErrorState     = ' + CAST(ERROR_STATE() AS VARCHAR(20)) + ',
        ErrorProcedure = "' + ISNULL(ERROR_PROCEDURE(), '') + ',
        ErrorLine      = ' + CAST(ERROR_LINE() AS VARCHAR(20)) + ',
        ErrorMessage   = "' + ERROR_MESSAGE() + '"' + CHAR(13) + CHAR(10));
END
/*
BEGIN TRY
    DECLARE @i INT;
    PRINT 'Try division by zero'
    SET @i = 1/0;
    PRINT 'After'
END TRY
BEGIN CATCH
    -- Display error
    PRINT util.GetDetailedErrorMessage();
    IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH
*/
;