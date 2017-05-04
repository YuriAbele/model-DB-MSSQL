/*=============================================
Author:
    Yuri Abele
Changes:
    11.06.2013 - Yuri Abele - initial
Description:
    Function to convert list of Values to Table
 
Usage: Get all items
    SELECT item_index, item_value = IIF(item_value = '', '---', item_value), item_rank
    FROM util.ConvertSetToTable(N';ddd;bbb;ccc;;;ccc;ddd;eee;', N';', 0);
Usage: Get all non-empty items
    SELECT * FROM util.ConvertSetToTable(N';ddd;bbb;ccc;;;ccc;ddd;eee;', N';', 1);
Usage: Get all non-empty items and filter non-unique
    SELECT * FROM util.ConvertSetToTable(N';ddd;bbb;ccc;;;ccc;ddd;eee;', N';', 1)
    WHERE item_rank=1;
=============================================*/
CREATE FUNCTION util.ConvertSetToTable
(
    @array NVARCHAR(MAX), -- List of delimited values
    @delim NCHAR(1),      -- Delimiter
    @remove_empty BIT     -- Flag to remove empty values
)
-- Container for Array Items
RETURNS @data TABLE(
    item_index INT IDENTITY(1,1), -- 1-based index of item
    item_value NVARCHAR(MAX),     -- item value
    item_rank  INT                -- item rank if items are not unique
)
AS BEGIN
    -- Container for XML
    DECLARE
        @xml_text NVARCHAR(MAX),
        @xml XML;
 
    IF @remove_empty = 1 BEGIN
        -- Remove empty inner items
        WHILE (CHARINDEX(@delim + @delim, @array, 0) > 0) BEGIN
            SET @array = REPLACE(@array, @delim + @delim, @delim);
        END;
        -- Remove empty left item
        IF(LEFT(@array, 1) = @delim) BEGIN
            SET @array = SUBSTRING(@array, 2, LEN(@array)-1)
        END;
        -- Remove empty right item
        IF(RIGHT(@array, 1) = @delim) BEGIN
            SET @array = SUBSTRING(@array, 1, LEN(@array)-1)
        END;
    END;
    
    -- Prepare XML-Text
    SET @xml_text = N'<L><I>' +
        REPLACE(@array, @delim, N'</I><I>') +
        N'</I></L>';
    
    -- Convert Array to XML
    SET @xml = CAST(@xml_text AS XML);
 
    DECLARE @temp_data TABLE(
        item_index INT IDENTITY(1,1),
        item_value NVARCHAR(MAX)
    )
    -- Extract Array Items to Table-Variable
    INSERT INTO @temp_data(item_value)
    SELECT
        item_value = item.value('.', 'NVARCHAR(MAX)')
    FROM
        @xml.nodes('//I') XMLDATA(item);
    
    -- Calculate Rank for each item (to find non-unique items)
    INSERT INTO @data(item_value, item_rank)
    SELECT
        item_value,
        item_rank=RANK() OVER(PARTITION BY item_value ORDER BY item_index, item_value)
    FROM
        @temp_data
    ORDER BY
        item_index;
    
    RETURN;
END;
/*
Usage: Get all items
    SELECT item_index, item_value = IIF(item_value = '', '---', item_value), item_rank
    FROM util.ConvertSetToTable(N';ddd;bbb;ccc;;;ccc;ddd;eee;', N';', 0);
Usage: Get all non-empty items
    SELECT * FROM util.ConvertSetToTable(N';ddd;bbb;ccc;;;ccc;ddd;eee;', N';', 1);
Usage: Get all non-empty items and filter non-unique
    SELECT * FROM util.ConvertSetToTable(N';ddd;bbb;ccc;;;ccc;ddd;eee;', N';', 1)
    WHERE item_rank=1;
*/
;