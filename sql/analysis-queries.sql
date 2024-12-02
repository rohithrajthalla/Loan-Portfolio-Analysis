-- Business Analysis Queries

-- 1. Portfolio Overview
CREATE PROCEDURE GetPortfolioOverview
AS
BEGIN
    -- Total portfolio metrics
    SELECT 
        COUNT(*) as total_applications,
        SUM(loan_amount) as total_funded_amount,
        SUM(total_payment) as total_amount_received,
        AVG(int_rate) * 100 as avg_interest_rate,
        AVG(dti) * 100 as avg_dti
    FROM bank_loan_data;

    -- Good vs Bad Loans
    SELECT 
        loan_status,
        COUNT(*) as loan_count,
        SUM(loan_amount) as total_amount,
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM bank_loan_data) as percentage
    FROM bank_loan_data
    GROUP BY loan_status;
END;

-- 2. Risk Analysis
CREATE PROCEDURE GetRiskMetrics
AS
BEGIN
    -- Default rates by grade
    SELECT 
        grade,
        COUNT(*) as total_loans,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as defaults,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as default_rate,
        AVG(int_rate) * 100 as avg_interest_rate,
        AVG(dti) * 100 as avg_dti
    FROM bank_loan_data
    GROUP BY grade
    ORDER BY grade;

    -- Default rates by employment length
    SELECT 
        emp_length,
        COUNT(*) as total_loans,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as default_rate
    FROM bank_loan_data
    GROUP BY emp_length
    ORDER BY 
        CASE 
            WHEN emp_length = '< 1 year' THEN 0
            WHEN emp_length = '1 year' THEN 1
            WHEN emp_length = '2 years' THEN 2
            WHEN emp_length = '3 years' THEN 3
            WHEN emp_length = '10+ years' THEN 11
            ELSE CAST(SUBSTRING(emp_length, 1, 2) AS INT)
        END;
END;

-- 3. Monthly Trend Analysis
CREATE PROCEDURE GetMonthlyTrends
AS
BEGIN
    SELECT 
        FORMAT(issue_date, 'yyyy-MM') as month,
        COUNT(*) as total_applications,
        SUM(loan_amount) as total_funded,
        AVG(int_rate) * 100 as avg_interest_rate,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as default_rate
    FROM bank_loan_data
    GROUP BY FORMAT(issue_date, 'yyyy-MM')
    ORDER BY month;
END;

-- 4. Purpose Analysis
CREATE PROCEDURE GetLoanPurposeAnalysis
AS
BEGIN
    SELECT 
        purpose,
        COUNT(*) as total_loans,
        SUM(loan_amount) as total_funded,
        AVG(int_rate) * 100 as avg_interest_rate,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as default_rate
    FROM bank_loan_data
    GROUP BY purpose
    ORDER BY total_loans DESC;
END;

-- 5. Geography Analysis
CREATE PROCEDURE GetGeographicAnalysis
AS
BEGIN
    SELECT 
        address_state,
        COUNT(*) as total_applications,
        SUM(loan_amount) as total_funded,
        AVG(int_rate) * 100 as avg_interest_rate,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as default_rate
    FROM bank_loan_data
    GROUP BY address_state
    ORDER BY total_applications DESC;
END;

-- 6. Executive Summary
CREATE PROCEDURE GetExecutiveSummary
AS
BEGIN
    -- Portfolio Health
    SELECT 
        'Portfolio Health' as metric_type,
        COUNT(*) as total_loans,
        SUM(loan_amount) as total_funded,
        SUM(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN loan_amount ELSE 0 END) as performing_amount,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) as defaulted_amount
    FROM bank_loan_data;

    -- Top 5 Risk States
    SELECT TOP 5
        address_state,
        COUNT(*) as total_loans,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as default_rate
    FROM bank_loan_data
    GROUP BY address_state
    ORDER BY default_rate DESC;

    -- Grade Performance
    SELECT 
        grade,
        COUNT(*) as total_loans,
        AVG(int_rate) * 100 as avg_interest_rate,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as default_rate
    FROM bank_loan_data
    GROUP BY grade
    ORDER BY grade;
END;