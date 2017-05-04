CREATE VIEW util.[TableStat]
AS
SELECT TOP(100) PERCENT
    Database_Name = DB_NAME(),
    Schema_Name   = CAST(a3.name AS SYSNAME),
    Table_Name    = CAST(a2.name AS SYSNAME),
    Records       = a1.records,
    Reserved_KB   = (a1.reserved + ISNULL(a4.reserved,0))* 8, 
    Data_KB       = a1.data * 8,
    Indexes_KB    = CASE
                        WHEN (a1.used + ISNULL(a4.used,0)) > a1.data
                        THEN (a1.used + ISNULL(a4.used,0)) - a1.data
                        ELSE 0
                    END * 8,
    Unused_KB     = CASE
                        WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used
                        THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used
                        ELSE 0
                    END * 8
FROM
    (
        SELECT 
            ps.object_id,
            records = SUM(
                        CASE
                            WHEN (ps.index_id < 2)
                            THEN row_count
                            ELSE 0
                        END
                    ),
            reserved = SUM(ps.reserved_page_count),
            data = SUM(
                        CASE
                            WHEN ps.index_id < 2
                            THEN ps.in_row_data_page_count
                               + ps.lob_used_page_count
                               + ps.row_overflow_used_page_count
                            ELSE ps.lob_used_page_count
                               + ps.row_overflow_used_page_count
                        END
                    ),
            used = SUM(ps.used_page_count)
        FROM sys.dm_db_partition_stats ps
        GROUP BY ps.object_id
    ) AS a1
    INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id ) 
    INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)
    LEFT OUTER JOIN (
        SELECT 
            it.parent_id,
            SUM(ps.reserved_page_count) AS reserved,
            SUM(ps.used_page_count) AS used
        FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id)
        WHERE it.internal_type IN (202,204)
        GROUP BY it.parent_id
    ) AS a4 ON (a4.parent_id = a1.object_id)
WHERE a2.type <> N'S' and a2.type <> N'IT'
ORDER BY Table_Name;