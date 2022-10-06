/* Date Dimension & Stored Procedure to load it */
CREATE OR REPLACE PROCEDURE DimDate_Load ( DateValue IN DATE )
IS
BEGIN
 INSERT INTO DimDate
 SELECT  
    EXTRACT(YEAR FROM DateValue) * 10000 + EXTRACT(Month FROM DateValue) * 100 + EXTRACT(Day FROM DateValue) DateKey
    ,DateValue DateValue
    ,EXTRACT(YEAR FROM DateValue) "Year"
    ,EXTRACT(Month FROM DateValue) "Month"
    ,EXTRACT(Day FROM DateValue) "Day"
    ,CAST(TO_CHAR(DateValue, 'Q') AS INT) Quarter
    ,TRUNC(DateValue) - (TO_NUMBER (TO_CHAR(DateValue,'DD')) - 1) StartOfMonth
    ,ADD_Months(TRUNC(DateValue) - (TO_NUMBER(TO_CHAR(DateValue,'DD')) - 1), 1) -1 EndOfMonth
    ,TO_CHAR(DateValue, 'MONTH') MonthName 
    ,TO_CHAR(DateValue, 'DY') DayOfWeekName
 FROM dual; 
END;
/



/* Extracts */
CREATE TABLE Employees_Stage (
    FirstName       NVARCHAR2(20),
    LastName        NVARCHAR2(25),
	Email           NVARCHAR2(25),
	PhoneNumber     NVARCHAR2(20),
    HireDate        DATE,
    JobID           NVARCHAR2(10),
    DepartmentID    NUMBER(4)
);

CREATE OR REPLACE PROCEDURE Employees_Extract
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE Employees_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO Employees_Stage
    SELECT first_name,
           last_name,
           email,
           phone_number,
           hire_date,
           job_id,
           department_id
    FROM employees;
    RowCt := SQL%ROWCOUNT;
    IF sql%notfound THEN
        dbms_output.put_line('No records found. Check with source system.');
    ELSIF sql%found then
        dbms_output.put_line(RowCt ||' Rows have been inserted!');
    END IF;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(SQLERRM);
    dbms_output.put_line(v_sql);
END;
/

CREATE TABLE JobHistorys_Stage (
    EmployeeFirstName   NVARCHAR2(20),
    EmployeeLastName    NVARCHAR2(25),
    StartDate           DATE,
    JobTitle            NVARCHAR2(10),
    DepartmentName      NVARCHAR2(30),
    Salary              NUMBER(8,2),
    CommissionPct       NUMBER(2,2)
);

CREATE OR REPLACE PROCEDURE JobHistorys_Extract (s_date IN DATE)
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE JobHistorys_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO JobHistorys_Stage
    SELECT e.first_name,
           e.last_name,
           j.start_date,
           jobs.job_title,
           d.department_name,
           e.salary,
           e.commission_pct
    FROM job_history j
    JOIN employees e
        ON j.employee_id = e.employee_id
    JOIN departments d
        ON j.department_id = d.department_id
    JOIN jobs
        ON j.job_id = jobs.job_id
    WHERE start_date = s_date;
    RowCt := SQL%ROWCOUNT;
    IF sql%notfound THEN
        dbms_output.put_line('No records found. Check with source system.');
    ELSIF sql%found then
        dbms_output.put_line(RowCt ||' Rows have been inserted!');
    END IF;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(SQLERRM);
    dbms_output.put_line(v_sql);
END;
/

CREATE TABLE Jobs_Stage (
    JobID NVARCHAR2(10),
    JobTitle NVARCHAR2(35),
    MinSalary NUMBER(6),
    MaxSalary NUMBER(6)
);

CREATE OR REPLACE PROCEDURE Jobs_Extract
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE Jobs_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO Jobs_Stage
    SELECT job_id,
           job_title,
           min_salary,
           max_salary
    FROM jobs;
    RowCt := SQL%ROWCOUNT;
    IF sql%notfound THEN
        dbms_output.put_line('No records found. Check with source system.');
    ELSIF sql%found then
        dbms_output.put_line(RowCt ||' Rows have been inserted!');
    END IF;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(SQLERRM);
    dbms_output.put_line(v_sql);
END;
/

CREATE TABLE Departments_Stage (
    DepartmentID    NUMBER(4),
    DepartmentName  NVARCHAR2(30),
    StreetAddr      NVARCHAR2(40),
    PostalCode      NVARCHAR2(30),
    City            NVARCHAR2(30),
    StateProvince   NVARCHAR2(30),
    CountryName     NVARCHAR2(40),
    RegionName      NVARCHAR2(25)
);

CREATE OR REPLACE PROCEDURE Departments_Extract
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE Departments_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO Departments_Stage
    SELECT department_id,
           department_name,
           street_address,
           postal_code,
           city,
           state_province,
           country_name,
           region_name
    FROM departments d
    JOIN locations l
        ON d.location_id = l.location_id
    JOIN countries c
        ON l.country_id = c.country_id
    JOIN regions r
        ON c.region_id = r.region_id;
    RowCt := SQL%ROWCOUNT;
    IF sql%notfound THEN
        dbms_output.put_line('No records found. Check with source system.');
    ELSIF sql%found then
        dbms_output.put_line(RowCt ||' Rows have been inserted!');
    END IF;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(SQLERRM);
    dbms_output.put_line(v_sql);
END;
/



/* Transforms */
CREATE TABLE Departments_Preload (
    DepartmentKey   NUMBER(10),
    DepartmentName  NVARCHAR2(30) NULL,
    City            NVARCHAR2(30) NULL,
    StateProvince 	NVARCHAR2(25) NULL,
    CountryName     NVARCHAR2(40) NULL,
    RegionName      NVARCHAR2(25) NULL,
    CONSTRAINT PK_Departments_Preload PRIMARY KEY ( DepartmentKey )
);

CREATE SEQUENCE DepartmentKey START WITH 1;

CREATE OR REPLACE PROCEDURE Departments_Transform
AS
    RowCt NUMBER(10) := 0;
    v_sql VARCHAR(255) := 'TRUNCATE TABLE Departments_Preload DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    INSERT INTO Departments_Preload
    SELECT DepartmentKey.NEXTVAL AS DepartmentKey,
        stage.DepartmentName,
        stage.City,
        stage.StateProvince,
        stage.CountryName,
        stage.RegionName
    FROM Departments_Stage stage
    WHERE NOT EXISTS
        ( SELECT 1
          FROM DimDepartments dim
          WHERE stage.DepartmentName = dim.DepartmentName );
    RowCt := SQL%ROWCOUNT;
    INSERT INTO Departments_Preload
    SELECT dim.DepartmentKey,
           stage.DepartmentName,
           stage.City,
           stage.StateProvince,
           stage.CountryName,
           stage.RegionName
    FROM Departments_Stage stage
    JOIN DimDepartments dim
        ON stage.DepartmentName = dim.DepartmentName;
    RowCt := RowCt+SQL%ROWCOUNT;
    IF RowCt=0 THEN
        dbms_output.put_line('No records found. Check with source system.');
    ELSE
        dbms_output.put_line(RowCt ||' Rows have been inserted!');
    END IF;
EXCEPTION
      WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
            dbms_output.put_line(v_sql);
END;
/

CREATE TABLE Employees_Preload (
    EmployeeKey     NUMBER(10),
    FirstName       NVARCHAR2(20) NULL,
    LastName        NVARCHAR2(25) NULL,
    Email           NVARCHAR2(25) NULL,
    PhoneNumber     NVARCHAR2(20) NULL,
    HireDate        DATE NULL,
    StartDate       DATE NOT NULL,
    EndDate         DATE NULL,
    CONSTRAINT PK_Employees_Preload PRIMARY KEY ( EmployeeKey )
);

CREATE SEQUENCE EmployeeKey START WITH 1;

CREATE OR REPLACE PROCEDURE Employees_Transform
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE Employees_Preload DROP STORAGE';
    SDate DATE := SYSDATE; EDate DATE := SYSDATE - 1;
BEGIN
    EXECUTE IMMEDIATE v_sql;
    -- Add updated records
    INSERT INTO Employees_Preload
    SELECT EmployeeKey.NEXTVAL AS EmployeeKey,
        stage.FirstName,
        stage.LastName,
        stage.Email,
        stage.PhoneNumber,
        stage.HireDate,
        SDate,
        NULL
    FROM Employees_Stage stage
    JOIN DimEmployees dim
        ON stage.FirstName = dim.FirstName
        AND stage.LastName = dim.LastName
        AND stage.HireDate = dim.HireDate
        AND dim.EndDate IS NULL
    WHERE stage.Email <> dim.Email
        OR stage.PhoneNumber <> dim.PhoneNumber;
    RowCt := SQL%ROWCOUNT;
    -- Add existing records, and expire as necessary
    INSERT INTO Employees_Preload
    SELECT dim.EmployeeKey,
           dim.FirstName,
           dim.LastName,
           dim.Email,
           dim.PhoneNumber,
           dim.HireDate,
           dim.StartDate,
           CASE
                WHEN pl.FirstName IS NULL AND pl.LastName IS NULL THEN NULL
                ELSE EDate
           END AS EndDate
    FROM DimEmployees dim
    LEFT JOIN Employees_Preload pl
        ON pl.FirstName = dim.FirstName
        AND pl.LastName = dim.LastName
        AND dim.EndDate IS NULL;
    RowCt := RowCt+SQL%ROWCOUNT;
    -- Create new records
    INSERT INTO Employees_Preload
    SELECT EmployeeKey.NEXTVAL AS EmployeeKey,
        stage.FirstName,
        stage.LastName,
        stage.Email,
        stage.PhoneNumber,
        stage.HireDate,
        SDate,
        NULL
    FROM Employees_Stage stage
    WHERE NOT EXISTS ( SELECT 1 FROM DimEmployees dim WHERE stage.FirstName = dim.FirstName AND stage.LastName = dim.LastName );
    RowCt := RowCt+SQL%ROWCOUNT;
    -- Expire missing records
    INSERT INTO Employees_Preload
    SELECT dim.EmployeeKey,
           dim.FirstName,
           dim.LastName,
           dim.Email,
           dim.PhoneNumber,
           dim.HireDate,
           dim.StartDate,
           EDate
    FROM DimEmployees dim
    WHERE NOT EXISTS ( SELECT 1 FROM Employees_Stage stage WHERE stage.FirstName = dim.FirstName AND stage.LastName = dim.LastName )
        AND dim.EndDate IS NULL;
    RowCt := RowCt+SQL%ROWCOUNT;
    IF RowCt=0 THEN
        dbms_output.put_line('No records found. Check with source system.');
    ELSE
        dbms_output.put_line(RowCt ||' Rows have been inserted!');
    END IF;
EXCEPTION
      WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
            dbms_output.put_line(v_sql);
END;
/

CREATE TABLE Jobs_Preload (
    JobKey      NUMBER(10),
    JobTitle    NVARCHAR2(35) NULL,
    MinSalary 	NUMBER(6) NULL,
    MaxSalary 	NUMBER(6) NULL,
    StartDate   DATE NOT NULL,
    EndDate 		DATE NULL,
    CONSTRAINT PK_Jobs_Preload PRIMARY KEY ( JobKey )
);

CREATE SEQUENCE JobKey START WITH 1;

CREATE OR REPLACE PROCEDURE Jobs_Transform
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE Jobs_Preload DROP STORAGE';
    SDate DATE := SYSDATE; EDate DATE := SYSDATE - 1;
BEGIN
    EXECUTE IMMEDIATE v_sql;
    -- Add updated records
    INSERT INTO Jobs_Preload
    SELECT JobKey.NEXTVAL AS JobKey,
        stage.JobTitle,
        stage.MinSalary,
        stage.MaxSalary,
        SDate,
        NULL
    FROM Jobs_Stage stage
    JOIN DimJobs dim
        ON stage.JobTitle = dim.JobTitle
        AND dim.EndDate IS NULL
    WHERE stage.MinSalary <> dim.MinSalary
        OR stage.MaxSalary <> dim.MaxSalary;
    RowCt := SQL%ROWCOUNT;
    -- Add existing records, and expire as necessary
    INSERT INTO Jobs_Preload
    SELECT dim.JobKey,
           dim.JobTitle,
           dim.MinSalary,
           dim.MaxSalary,
           dim.StartDate,
           CASE
                WHEN pl.JobTitle IS NULL THEN NULL
                ELSE EDate
           END AS EndDate
    FROM DimJobs dim
    LEFT JOIN Jobs_Preload pl
        ON pl.JobTitle = dim.JobTitle
        AND dim.EndDate IS NULL;
    RowCt := RowCt+SQL%ROWCOUNT;
    -- Create new records
    INSERT INTO Jobs_Preload
    SELECT JobKey.NEXTVAL AS JobKey,
        stage.JobTitle,
        stage.MinSalary,
        stage.MaxSalary,
        SDate,
        NULL
    FROM Jobs_Stage stage
    WHERE NOT EXISTS ( SELECT 1 FROM DimJobs dim WHERE stage.JobTitle = dim.JobTitle );
    RowCt := RowCt+SQL%ROWCOUNT;
    -- Expire missing records
    INSERT INTO Jobs_Preload
    SELECT dim.JobKey,
           dim.JobTitle,
           dim.MinSalary,
           dim.MaxSalary,
           dim.StartDate,
           EDate
    FROM DimJobs dim
    WHERE NOT EXISTS ( SELECT 1 FROM Jobs_Stage stage WHERE stage.JobTitle = dim.JobTitle )
        AND dim.EndDate IS NULL;
    RowCt := RowCt+SQL%ROWCOUNT;
    IF RowCt=0 THEN
        dbms_output.put_line('No records found. Check with source system.');
    ELSE
        dbms_output.put_line(RowCt ||' Rows have been inserted!');
    END IF;
EXCEPTION
      WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
            dbms_output.put_line(v_sql);
END;
/

CREATE TABLE JobHistorys_Preload (
    EmployeeKey      	NUMBER(10) NOT NULL,
    DepartmentKey      	NUMBER(10) NOT NULL,
    JobKey              NUMBER(10) NOT NULL,
    DateKey 	      	NUMBER(10) NOT NULL,
    Salary              NUMBER(8,2) NOT NULL,
    CommissionPct       NUMBER(2,2) NOT NULL
);

CREATE OR REPLACE PROCEDURE JobHistorys_Transform
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE JobHistorys_Preload DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    INSERT INTO JobHistorys_Preload
    SELECT e.EmployeeKey,
           d.DepartmentKey,
           j.JobKey,
           EXTRACT(Year FROM hist.StartDate)*10000 + EXTRACT(Month FROM hist.StartDate)*100 + EXTRACT(Day FROM hist.StartDate),
           hist.Salary AS Salary,
           hist.CommissionPct AS CommissionPct
    FROM JobHistorys_Stage hist
    JOIN Employees_Preload e
        ON hist.EmployeeFirstName = e.FirstName
        AND hist.EmployeeLastName = e.LastName
    JOIN Departments_Preload d
        ON hist.DepartmentName = d.DepartmentName
    JOIN Jobs_Preload j
        ON hist.JobTitle = j.JobTitle;
    RowCt := SQL%ROWCOUNT;
    IF RowCt=0 THEN
        dbms_output.put_line('No records found. Check with source system.');
    ELSE
        dbms_output.put_line(RowCt ||' Rows have been inserted!');
    END IF;
EXCEPTION
      WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
            dbms_output.put_line(v_sql);
END;
/

CREATE OR REPLACE PROCEDURE Departments_Load
AS
    RowCt NUMBER(10);
BEGIN
    DELETE FROM DimDepartments ci
    WHERE EXISTS(
        SELECT pl.DepartmentKey
        FROM Departments_Preload pl
        WHERE ci.DepartmentKey = pl.DepartmentKey
    );        
    INSERT INTO DimDepartments
    SELECT *
    FROM Departments_Preload;
    RowCt := SQL%ROWCOUNT;
    IF sql%notfound THEN
        dbms_output.put_line('No records found. Check with source system.');
    ELSIF sql%found then
        dbms_output.put_line(RowCt ||' Rows have been inserted!');
    END IF;
EXCEPTION
      WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE Jobs_Load
AS
    RowCt NUMBER(10);
BEGIN
    DELETE FROM DimJobs pr
    WHERE EXISTS(
        SELECT pl.JobKey
        FROM Jobs_Preload pl
        WHERE pr.JobKey = pl.JobKey
    );        
    INSERT INTO DimJobs
    SELECT *
    FROM Jobs_Preload;
    RowCt := SQL%ROWCOUNT;
    IF sql%notfound THEN
        dbms_output.put_line('No records found. Check with source system.');
    ELSIF sql%found then
        dbms_output.put_line(RowCt ||' Rows have been inserted!');
    END IF;
EXCEPTION
      WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE JobHistorys_Load
AS
    RowCt NUMBER(10);
BEGIN
    INSERT INTO FactEmployment
    SELECT *
    FROM JobHistorys_Preload;
    RowCt := SQL%ROWCOUNT;
    IF sql%notfound THEN
        dbms_output.put_line('No records found. Check with source system.');
    ELSIF sql%found then
        dbms_output.put_line(RowCt ||' Rows have been inserted!');
    END IF;
EXCEPTION
      WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
END;
/
/* Loads */
CREATE OR REPLACE PROCEDURE Employees_Load
AS
    RowCt NUMBER(10);
BEGIN
    DELETE FROM DimEmployees dim
    WHERE EXISTS(
        SELECT pl.EmployeeKey
        FROM Employees_Preload pl
        WHERE dim.EmployeeKey = pl.EmployeeKey
    );        
    INSERT INTO DimEmployees
    SELECT *
    FROM Employees_Preload;
    RowCt := SQL%ROWCOUNT;
    IF sql%notfound THEN
        dbms_output.put_line('No records found. Check with source system.');
    ELSIF sql%found then
        dbms_output.put_line(RowCt ||' Rows have been inserted!');
    END IF;
EXCEPTION
      WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
END;
/


/* Extract data */
SET SERVEROUT ON;
EXECUTE Employees_Extract;

SET SERVEROUT ON;
EXECUTE JobHistorys_Extract(TO_DATE('2006-03-24', 'YYYY-MM-DD'));

SET SERVEROUT ON;
EXECUTE Jobs_Extract;

SET SERVEROUT ON;
EXECUTE Departments_Extract;

/* Transform Data */
SET SERVEROUT ON;
EXEC Departments_Transform;

SET SERVEROUT ON;
EXEC Employees_Transform;

SET SERVEROUT ON;
EXEC Jobs_Transform;

SET SERVEROUT ON;
EXEC JobHistorys_Transform;

/* Load data to DWH and Query */
-- Load for 2006-03-24.
SET SERVEROUT ON;
EXEC Employees_Load;

SET SERVEROUT ON;
EXEC Departments_Load;

SET SERVEROUT ON;
EXEC Jobs_Load;

EXEC DimDate_Load(TO_DATE('2006-03-24', 'YYYY-MM-DD'));

SET SERVEROUT ON;
EXEC JobHistorys_Load;

-- Sample query
SELECT e.FirstName, e.LastName, e.HireDate,
       j.JobTitle,
       d.DepartmentName, d.City, d.StateProvince, d.CountryName, d.RegionName,
       f.Salary, f.CommissionPCT
FROM FactEmployment f
LEFT JOIN DimEmployees e
    ON f.EmployeeKey = e.EmployeeKey
LEFT JOIN DimDepartments d
    ON f.DepartmentKey = d.DepartmentKey
LEFT JOIN DimJobs j
    ON f.JobKey = j.JobKey
LEFT JOIN DimDate dd
    ON f.DateKey = dd.DateKey
WHERE dd."Year" = 2006;


