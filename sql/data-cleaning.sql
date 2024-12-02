-- Data Cleaning and Validation Procedures

-- 1. Clean and standardize loan status
CREATE PROCEDURE CleanLoanStatus
AS
BEGIN
    -- Standardize loan status values
    UPDATE bank_loan_data
    SET loan_status = CASE 
        WHEN LOWER(loan_status) LIKE '%fully%paid%' THEN 'Fully Paid'
        WHEN LOWER(loan_status) LIKE '%current%' THEN 'Current'
        WHEN LOWER(loan_status) LIKE '%charged%off%' THEN 'Charged Off'
        ELSE loan_status
    END;

    -- Log the changes
    INSERT INTO data_cleaning_log (table_name, field_name, cleaning_type)
    VALUES ('bank_loan_data', 'loan_status', 'Standardization');
END;

-- 2. Clean and validate DTI (Debt-to-Income ratio)
CREATE PROCEDURE CleanDTI
AS
BEGIN
    -- Flag suspicious DTI values
    INSERT INTO data_cleaning_log (table_name, field_name, old_value, cleaning_type)
    SELECT 'bank_loan_data', 'dti', CAST(dti AS VARCHAR), 'Invalid DTI'
    FROM bank_loan_data
    WHERE dti < 0 OR dti > 1;

    -- Update invalid DTI values
    UPDATE bank_loan_data
    SET dti = NULL
    WHERE dti < 0 OR dti > 1;
END;

-- 3. Date format standardization
CREATE PROCEDURE CleanDates
AS
BEGIN
    -- Convert string dates to proper date format
    UPDATE bank_loan_data
    SET 
        issue_date = TRY_CONVERT(DATE, issue_date),
        last_payment_date = TRY_CONVERT(DATE, last_payment_date),
        next_payment_date = TRY_CONVERT(DATE, next_payment_date);

    -- Log invalid dates
    INSERT INTO data_cleaning_log (table_name, field_name, cleaning_type)
    SELECT 'bank_loan_data', 'date_fields', 'Date Standardization';
END;

-- 4. Master cleaning procedure
CREATE PROCEDURE ExecuteMasterCleaning
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            
            -- Execute all cleaning procedures
            EXEC CleanLoanStatus;
            EXEC CleanDTI;
            EXEC CleanDates;
            
            -- Validate results
            SELECT 
                'Cleaning Complete' as Status,
                COUNT(*) as TotalRecords,
                SUM(CASE WHEN loan_status IN ('Fully Paid', 'Current', 'Charged Off') THEN 1 ELSE 0 END) as ValidStatusCount,
                SUM(CASE WHEN dti BETWEEN 0 AND 1 THEN 1 ELSE 0 END) as ValidDTICount,
                SUM(CASE WHEN TRY_CONVERT(DATE, issue_date) IS NOT NULL THEN 1 ELSE 0 END) as ValidDateCount
            FROM bank_loan_data;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        INSERT INTO data_cleaning_log (table_name, field_name, cleaning_type)
        VALUES ('bank_loan_data', 'ALL', 'ERROR: ' + ERROR_MESSAGE());
    END CATCH;
END;