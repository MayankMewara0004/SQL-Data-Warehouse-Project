/*
  =========================================================================================================
  -- CREATE DATABASE AND SCHEMAS
  This script creates new database named 'DataWarehouse' and three schemas 
  1st bronze
  2nd silver
  3rd gold
  =========================================================================================================
*/
-- create new database 'Datawarehouse' -- 


use master

Create database DataWarehouse
go


use DataWarehouse
go

  -- Create SCHEMAS
create schema bronze 
go

create schema silver
go

create schema gold
go

