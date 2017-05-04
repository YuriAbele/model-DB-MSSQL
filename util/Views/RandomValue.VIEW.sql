CREATE VIEW util.RandomValue
AS
SELECT random_value = RAND(CHECKSUM(NEWID()))
/*
SELECT * FROM util.RandomValue;
*/
;