-- Bank Loan Analysis Database Schema
CREATE DATABASE bank_loan_analysis;
USE bank_loan_analysis;

-- Main loan data table
CREATE TABLE bank_loan_data (
    id INT PRIMARY KEY,
    member_id VARCHAR(50),
    loan_amount DECIMAL(10,2),
    funded_amount DECIMAL(10,2),
    total_payment DECIMAL(10,2),
    int_rate DECIMAL(5,4),
    dti DECIMAL(5,4),
    loan_status VARCHAR(20),
    issue_date DATE,
    last_payment_date DATE,
    next_payment_date DATE,
    grade VARCHAR(1),
    sub_grade VARCHAR(2),
    emp_length VARCHAR(20),
    home_ownership VARCHAR(20),
    purpose VARCHAR(50),
    address_state CHAR(2),
    verification_status VARCHAR(20),
    application_type VARCHAR(20)
);

-- Create lookup tables for better data organization
CREATE TABLE loan_status_lookup (
    status_id INT PRIMARY KEY IDENTITY(1,1),
    loan_status VARCHAR(20) UNIQUE
);

CREATE TABLE grade_lookup (
    grade_id INT PRIMARY KEY IDENTITY(1,1),
    grade VARCHAR(1) UNIQUE,
    description VARCHAR(100)
);

-- Create table for data cleaning logs
CREATE TABLE data_cleaning_log (
    log_id INT PRIMARY KEY IDENTITY(1,1),
    cleaning_date DATETIME DEFAULT GETDATE(),
    table_name VARCHAR(50),
    field_name VARCHAR(50),
    old_value VARCHAR(MAX),
    new_value VARCHAR(MAX),
    cleaning_type VARCHAR(50)
);

-- Create indexes for better query performance
CREATE INDEX idx_loan_status ON bank_loan_data(loan_status);
CREATE INDEX idx_grade ON bank_loan_data(grade);
CREATE INDEX idx_issue_date ON bank_loan_data(issue_date);
CREATE INDEX idx_emp_length ON bank_loan_data(emp_length);