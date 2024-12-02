# Bank Loan Data Validation Documentation

## Overview
This documentation outlines the data validation process for the Bank Loan Analysis project, which processes and analyzes a $435.8M loan portfolio containing 38.6K applications.

## Table of Contents
1. [Data Pipeline](#data-pipeline)
2. [Validation Process](#validation-process)
3. [SQL Database](#sql-database)
4. [Python Validation Script](#python-validation-script)
5. [Error Handling](#error-handling)
6. [Reporting](#reporting)

## Data Pipeline
### Input Data Format
```python
Required Fields:
- id: Unique identifier
- loan_amount: Decimal (10,2)
- funded_amount: Decimal (10,2)
- total_payment: Decimal (10,2)
- int_rate: Decimal (5,4)
- dti: Decimal (5,4)
- loan_status: VARCHAR(20)
```

### Data Flow
1. Raw CSV Import → SQL Database
2. Data Cleaning Procedures
3. Validation Checks
4. Business Analysis
5. Report Generation

## Validation Process

### 1. Data Quality Checks
```sql
Key Validations:
- Loan Status: Must be ['Fully Paid', 'Current', 'Charged Off']
- DTI Range: 0 to 1 (0% to 100%)
- Interest Rate: 0 to 1 (0% to 100%)
- Dates: Valid format and logical sequence
```

### 2. Business Rule Validation
```python
Business Rules:
1. funded_amount <= loan_amount
2. total_payment <= loan_amount * 2
3. issue_date <= last_payment_date
4. All monetary values > 0
```

### 3. Field-Specific Validation
| Field | Validation Rules | Error Handling |
|-------|-----------------|----------------|
| loan_status | Enumerated values | Standardize case |
| dti | 0-1 range | Null invalid values |
| dates | Valid format | Convert to standard |
| amounts | Positive values | Flag negatives |

## SQL Database

### Schema Overview
```sql
Main Tables:
1. bank_loan_data (Primary data)
2. loan_status_lookup (Reference)
3. data_cleaning_log (Audit)
```

### Key Indexes
```sql
- idx_loan_status
- idx_grade
- idx_issue_date
- idx_emp_length
```

## Python Validation Script

### Setup Instructions
1. Install requirements:
```bash
pip install -r requirements.txt
```

2. Configure database:
```json
{
    "server": "localhost",
    "database": "bank_loan_analysis"
}
```

3. Run validation:
```bash
python data_validator.py
```

### Key Features
1. **Comprehensive Validation**
   - Status checks
   - Numeric range validation
   - Date format verification
   - Relationship validation

2. **Automated Fixes**
   - Case standardization
   - Date format correction
   - Range adjustments

3. **Reporting**
   - Detailed logs
   - JSON reports
   - Error summaries

## Error Handling

### Common Issues and Solutions
1. **Invalid Loan Status**
   ```python
   Solution: Automatic standardization to ['Fully Paid', 'Current', 'Charged Off']
   ```

2. **DTI Out of Range**
   ```python
   Solution: Null invalid values, log for review
   ```

3. **Date Format Issues**
   ```python
   Solution: Convert to YYYY-MM-DD format
   ```

## Reporting

### Validation Report Format
```json
{
    "validation_date": "2024-12-02",
    "validation_results": {
        "loan_status": true,
        "dti_values": true,
        "date_formats": true
    },
    "statistics": {
        "total_records": 38600,
        "valid_status_count": 38600,
        "valid_dti_count": 38450
    }
}
```

### Key Metrics Tracked
1. **Portfolio Health**
   - Good Loans: 86.2% ($370.2M)
   - Bad Loans: 13.8% ($65.5M)

2. **Data Quality**
   - Field Completion Rate
   - Validation Pass Rate
   - Error Resolution Time

## Best Practices

### Data Cleaning
1. Never modify raw data
2. Log all changes
3. Use transaction management
4. Maintain audit trails

### Validation
1. Check before and after cleaning
2. Validate relationships
3. Monitor trends
4. Document exceptions

## Troubleshooting

### Common Issues
1. **Connection Errors**
   ```python
   Solution: Check config.json settings
   ```

2. **Invalid Data**
   ```python
   Solution: Review data_cleaning_log table
   ```

3. **Performance Issues**
   ```python
   Solution: Check index usage and query plans
   ```

## Future Enhancements
1. Real-time validation
2. Machine learning for anomaly detection
3. Advanced reporting dashboard
4. Automated data quality scoring
