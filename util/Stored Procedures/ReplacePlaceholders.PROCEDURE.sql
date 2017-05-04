

CREATE PROCEDURE [util].[ReplacePlaceholders] (
    @Text                NVARCHAR(MAX) OUTPUT,
    -- TABLE-Domain (User Defined Type) for placeholders dictionary
    @PlaceholderMappings [util].PlaceholderMappingType READONLY,
    -- Flag to replace in placeholder values each single apostrof with double apostrof
    @EscapeApostrofs     BIT = 1,
    -- Text to TrimLeft in each text line
    @IndentString        VARCHAR(MAX) = '',
    -- Flag to PRINT additional diagnostic information
    @Debug               BIT = 0
)
AS BEGIN
    SET NOCOUNT ON;
 
    IF (@Debug = 1)
        PRINT '-- EXEC util.ReplacePlaceholders'
 
    DECLARE
        @CRLF             CHAR(2) = CHAR(13)+CHAR(10),
        @Indent_CharIndex INT,
        @I                INT = 0,
        @Char             CHAR(1),
        @Indent           VARCHAR(MAX) = '';
 
    -- Trim rows left
    IF (CHARINDEX(@IndentString, @Text, 0) = 1)
        SET @Text = STUFF(@Text, 1, LEN(@IndentString), '');
    SET @Text = REPLACE(@Text, @CRLF + @IndentString, @CRLF);
 
    -- Declare FOREACH(placeholderRow IN @PlaceholderMappings) cursor
    DECLARE
        @Placeholder NVARCHAR(102),
        @Value       NVARCHAR(MAX);
    DECLARE Placeholders_Cursor CURSOR
    LOCAL STATIC READ_ONLY FORWARD_ONLY
    FOR
    SELECT
        Placeholder = '{' + REPLACE(REPLACE(Placeholder, '{', ''), '}', '') + '}',
        Value       = CASE @EscapeApostrofs
                          WHEN 1
                          THEN REPLACE(Value, '''', '''''')
                          ELSE Value
                      END
    FROM @PlaceholderMappings;
 
    OPEN Placeholders_Cursor;
 
    FETCH NEXT FROM Placeholders_Cursor INTO @Placeholder, @Value;
    WHILE @@FETCH_STATUS = 0 BEGIN
        
        IF (@Debug = 1) AND (CHARINDEX(@Placeholder, @Text) = 0)
            PRINT '--        ==> Could not find Placeholder ' + @Placeholder;
        SET @Text = REPLACE(@Text, @Placeholder, @Value);
 
        FETCH NEXT FROM Placeholders_Cursor INTO @Placeholder, @Value;
    END;
 
    CLOSE Placeholders_Cursor
    DEALLOCATE Placeholders_Cursor
 
    RETURN;
END
/*
DECLARE
    @SQL NVARCHAR(MAX),
    @PlaceholderMappings util.PlaceholderMappingType;
 
SET @SQL = '
        SELECT
            F1=''{aaa}'',
            F2=''{bbb}'',
            F3=''{ddd}'';';
INSERT INTO @PlaceholderMappings
VALUES
    ('aaa',   'A''A''A'),
    ('{bbb}', 'BBB'),
    ('ccc',   'CCC');
 
DECLARE @IndentString VARCHAR(MAX) = SPACE(8);
EXEC util.ReplacePlaceholders
    @SQL OUTPUT,
    @PlaceholderMappings,
    @IndentString=@IndentString,
    @Debug=1;
PRINT '>>>' + @SQL + '<<<';
*/
;