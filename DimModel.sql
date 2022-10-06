CREATE TABLE DimDepartments(
	DepartmentKey   NUMBER(10),
	DepartmentName  NVARCHAR2(30) NULL,
    City            NVARCHAR2(30) NULL,
	StateProvince 	NVARCHAR2(25) NULL,
	CountryName 	NVARCHAR2(40) NULL,
	RegionName      NVARCHAR2(25) NULL,
    CONSTRAINT PK_DimDepartments PRIMARY KEY ( DepartmentKey )
);

CREATE TABLE DimEmployees(
	EmployeeKey     NUMBER(10),
	FirstName 		NVARCHAR2(20) NULL,
	LastName        NVARCHAR2(25) NULL,
	Email           NVARCHAR2(25) NULL,
	PhoneNumber     NVARCHAR2(20) NULL,
    HireDate        DATE NULL,
	StartDate       DATE NOT NULL,
	EndDate         DATE NULL,
    CONSTRAINT DimEmployees PRIMARY KEY ( EmployeeKey )
);

CREATE TABLE DimJobs(
	JobKey 		NUMBER(10),
	JobTitle 	NVARCHAR2(35) NULL,
	MinSalary 	NUMBER(6) NULL,
	MaxSalary 	NUMBER(6) NULL,
	StartDate 		DATE NOT NULL,
	EndDate 		DATE NULL,
    CONSTRAINT PK_DimJobs PRIMARY KEY ( JobKey )
);

CREATE TABLE DimDate (
    DateKey    	    NUMBER(8) NOT NULL,
    DateValue  	    DATE NOT NULL,
    "Year" 	        NUMBER(10) NOT NULL,
    "Month" 	        NUMBER(2) NOT NULL,
    "Day" 	        NUMBER(2) NOT NULL,
    Quarter 	        NUMBER(1) NOT NULL,
    StartOfMonth    DATE NOT NULL,
    EndOfMonth      DATE NOT NULL,
    MonthName   	VARCHAR2(9) NOT NULL,
    DayOfWeekName   VARCHAR2(9) NOT NULL,    
    CONSTRAINT PK_DimDate PRIMARY KEY ( DateKey )
);

/* We are interested in the hiring or job change facts */
CREATE TABLE FactEmployment (
    EmployeeKey      	NUMBER(10) NOT NULL,
    DepartmentKey      	NUMBER(10) NOT NULL,
    JobKey              NUMBER(10) NOT NULL,
    DateKey 	      	NUMBER(10) NOT NULL,
    Salary              NUMBER(8,2) NOT NULL,
    CommissionPct       NUMBER(2,2) NOT NULL,
    CONSTRAINT FK_FactEmployment_DimDate FOREIGN KEY (DateKey) REFERENCES DimDate (DateKey),
    CONSTRAINT FK_FactEmployment_DimEmployees FOREIGN KEY (EmployeeKey) REFERENCES DimEmployees (EmployeeKey),
    CONSTRAINT FK_FactEmployment_DimDepartments FOREIGN KEY (DepartmentKey) REFERENCES DimDepartments (DepartmentKey),
    CONSTRAINT FK_FactEmployment_DimJobs FOREIGN KEY (JobKey) REFERENCES DimJobs (JobKey)
);

CREATE INDEX IX_FactEmployment_EmployeeKey 	ON FactEmployment(EmployeeKey);
CREATE INDEX IX_FactEmployment_DepartmentKey 	ON FactEmployment(DepartmentKey);
CREATE INDEX IX_FactEmployment_JobKey 	ON FactEmployment(JobKey);
CREATE INDEX IX_FactEmployment_DateKey 	ON FactEmployment(DateKey);
