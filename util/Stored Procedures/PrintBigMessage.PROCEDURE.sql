CREATE PROCEDURE util.PrintBigMessage
    @message NVARCHAR(MAX)
AS BEGIN
 
    -- SET NOCOUNT ON to prevent extra log messages
    SET NOCOUNT ON;
 
    DECLARE
        @CRLF            CHAR(2) = CHAR(13)+CHAR(10),
        @message_len    INT = LEN(@message),
        @i                INT,
        @part            NVARCHAR(2000),
        @part_len        INT;
 
    IF @message_len <= 2000 BEGIN
        -- Message ist enough short
        RAISERROR (@message, 0,1) WITH NOWAIT;
    END ELSE BEGIN
        -- Message is too long
        SET @i = 1;
        WHILE @i < LEN(@message) BEGIN
            -- Split to parts end send them to client immediately
            SET @part = SUBSTRING(@message, @i, 2000);
            SET @part_len = 2000 - CHARINDEX(CHAR(10) + CHAR(13), REVERSE(@part)) - 1;
            SET @part = CASE @i
                            WHEN 1
                            THEN ''
                            ELSE '/* CRLF ' + CAST(@i AS VARCHAR(20)) + ':'
                                 + CAST(@part_len AS VARCHAR(20)) + ' */' + @CRLF
                        END
                        + REPLACE(SUBSTRING(@message, @i, @part_len), '%', '%%');
            RAISERROR (@part, 0,1) WITH NOWAIT;
            SET @i = @i + @part_len + 2;
        END;
    END;
END
/*
-- Declare long message
DECLARE @LongMessage NVARCHAR(MAX) = '';
-- Fill message with test data
DECLARE @i INT = 1;
WHILE @i < 200 BEGIN
    SET @LongMessage = @LongMessage
                       + CASE @i WHEN 1 THEN '' ELSE CHAR(13) + CHAR(10) END
                       + CAST(@i AS VARCHAR(10))
                       + '. Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
    SET @i = @i + 1;
END;
 
-- Display length of generated message
DECLARE @len INT = LEN(@LongMessage);
RAISERROR('Message length: %i', 0, 1, @len) WITH NOWAIT;
 
-- Use SP to print long message
EXEC util.PrintBigMessage @LongMessage;
*/
;