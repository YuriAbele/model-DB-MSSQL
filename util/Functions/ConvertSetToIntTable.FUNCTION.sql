/*=============================================
Author:
    Yuri Abele
Changes:
    11.06.2013 - Yuri Abele - initial
Description:
    Function to convert list of numeric Values to Table of integers
Remark:
    Empty and non-numeric values will be ignored
 
Usage: Get all items
    SELECT * FROM util.ConvertSetToIntTable(N';444;bbb;333;;;333;444;555;', N';');
Usage: Get all non-empty items and filter non-unique
    SELECT * FROM util.ConvertSetToIntTable(N';444;bbb;333;;;333;444;555;', N';') WHERE ItemRank=1;
=============================================*/
CREATE FUNCTION util.ConvertSetToIntTable(
    @Array NVARCHAR(MAX),
    @Delim NCHAR(1)
)
-- Container for Array Items
RETURNS @Data TABLE(
    ItemIndex INT IDENTITY(1,1),
    ItemValue INT,
    ItemRank INT
)
AS BEGIN
    -- Container for XML
    DECLARE
        @XmlText NVARCHAR(MAX),
        @Xml XML;
    
    -- Remove empty inner items
    WHILE (CHARINDEX(@Delim + @Delim, @Array, 0) > 0) BEGIN
        SET @Array = REPLACE(@Array, @Delim + @Delim, @Delim);
    END;
    -- Remove empty left item
    IF(LEFT(@Array, 1) = @Delim) BEGIN
        SET @Array = SUBSTRING(@Array, 2, LEN(@Array)-1)
    END;
    -- Remove empty right item
    IF(RIGHT(@Array, 1) = @Delim) BEGIN
        SET @Array = SUBSTRING(@Array, 1, LEN(@Array)-1)
    END;
    
    -- Prepare XML-Text
    SET @XmlText = N'<List><Item>' +
        REPLACE(@Array, @Delim, N'</Item><Item>') +
        N'</Item></List>';
    
    -- Convert Array to XML
    SET @Xml = CAST(@XmlText AS XML);
    
    -- Temp Table-Variableble
    DECLARE @TempData TABLE(
        ItemIndex INT IDENTITY(1,1),
        ItemValue NVARCHAR(MAX)
    )
 
    -- Extract Array Items to temp Table-Variable
    INSERT INTO @TempData
    SELECT
        Item = item.value('.', 'INT')
    FROM
        @Xml.nodes('//Item') XMLDATA(item)
    WHERE
        -- Skeep non-numeric items
        ISNUMERIC(item.value('.', 'NVARCHAR(MAX)')) = 1;
    
    -- Calculate Rank for each item (to find non-unique items)
    INSERT INTO @Data(ItemValue, ItemRank)
    SELECT
        ItemValue,
        ItemRank=RANK() OVER(PARTITION BY ItemValue ORDER BY ItemIndex, ItemValue)
    FROM
        @TempData
    ORDER BY
        ItemIndex;
 
    RETURN;
END
/*
-- Get all non-empty and numeric items
SELECT * FROM util.ConvertSetToIntTable(N';444;bbb;333;;;333;444;555;', N';');
-- Get all non-empty and numeric items and filter non-unique
SELECT * FROM util.ConvertSetToIntTable(N';444;bbb;333;;;333;444;555;', N';') WHERE ItemRank=1;*/
;