import pandas as pd
import numpy as np
import pyodbc
import logging
from datetime import datetime
import json
from pathlib import Path

class LoanDataValidator:
    def __init__(self, config_path='config.json'):
        """Initialize the validator with database configuration."""
        # Set up logging
        self.setup_logging()
        
        # Load configuration
        self.config = self.load_config(config_path)
        
        # Connect to database
        self.conn = self.connect_to_db()

    def setup_logging(self):
        """Configure logging settings."""
        logging.basicConfig(
            filename=f'logs/validation_{datetime.now().strftime("%Y%m%d")}.log',
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)

    def load_config(self, config_path):
        """Load database configuration from JSON file."""
        try:
            with open(config_path) as f:
                return json.load(f)
        except FileNotFoundError:
            self.logger.error(f"Configuration file not found: {config_path}")
            raise

    def connect_to_db(self):
        """Establish database connection."""
        try:
            conn_str = (
                f'DRIVER={{SQL Server}};'
                f'SERVER={self.config["server"]};'
                f'DATABASE={self.config["database"]};'
                f'Trusted_Connection=yes;'
            )
            return pyodbc.connect(conn_str)
        except Exception as e:
            self.logger.error(f"Database connection failed: {str(e)}")
            raise

    def validate_loan_status(self):
        """Validate loan status values."""
        query = """
        SELECT DISTINCT loan_status
        FROM bank_loan_data
        WHERE loan_status NOT IN ('Fully Paid', 'Current', 'Charged Off')
        """
        invalid_statuses = pd.read_sql(query, self.conn)
        
        if not invalid_statuses.empty:
            self.logger.warning(f"Found invalid loan statuses: {invalid_statuses['loan_status'].tolist()}")
            return False
        return True

    def validate_dti_values(self):
        """Validate DTI (Debt-to-Income) ratios."""
        query = """
        SELECT id, dti
        FROM bank_loan_data
        WHERE dti < 0 OR dti > 1 OR dti IS NULL
        """
        invalid_dti = pd.read_sql(query, self.conn)
        
        if not invalid_dti.empty:
            self.logger.warning(f"Found {len(invalid_dti)} invalid DTI values")
            return False
        return True

    def validate_date_formats(self):
        """Validate date fields."""
        query = """
        SELECT id, issue_date, last_payment_date, next_payment_date
        FROM bank_loan_data
        WHERE 
            TRY_CONVERT(DATE, issue_date) IS NULL
            OR TRY_CONVERT(DATE, last_payment_date) IS NULL
            OR TRY_CONVERT(DATE, next_payment_date) IS NULL
        """
        invalid_dates = pd.read_sql(query, self.conn)
        
        if not invalid_dates.empty:
            self.logger.warning(f"Found {len(invalid_dates)} records with invalid dates")
            return False
        return True

    def validate_numeric_fields(self):
        """Validate numeric fields for ranges and nulls."""
        query = """
        SELECT id,
               loan_amount,
               funded_amount,
               total_payment,
               int_rate
        FROM bank_loan_data
        WHERE 
            loan_amount <= 0 OR loan_amount IS NULL
            OR funded_amount <= 0 OR funded_amount IS NULL
            OR total_payment < 0 OR total_payment IS NULL
            OR int_rate < 0 OR int_rate > 1 OR int_rate IS NULL
        """
        invalid_numerics = pd.read_sql(query, self.conn)
        
        if not invalid_numerics.empty:
            self.logger.warning(f"Found {len(invalid_numerics)} records with invalid numeric values")
            return False
        return True

    def validate_relationships(self):
        """Validate relationships between related fields."""
        query = """
        SELECT id,
               loan_amount,
               funded_amount,
               total_payment
        FROM bank_loan_data
        WHERE 
            funded_amount > loan_amount
            OR total_payment > loan_amount * 2  -- Assuming max payment is double the loan with interest
        """
        invalid_relationships = pd.read_sql(query, self.conn)
        
        if not invalid_relationships.empty:
            self.logger.warning(f"Found {len(invalid_relationships)} records with invalid relationships")
            return False
        return True

    def generate_validation_report(self):
        """Generate a comprehensive validation report."""
        validation_results = {
            "loan_status": self.validate_loan_status(),
            "dti_values": self.validate_dti_values(),
            "date_formats": self.validate_date_formats(),
            "numeric_fields": self.validate_numeric_fields(),
            "relationships": self.validate_relationships()
        }
        
        # Calculate overall stats
        query = """
        SELECT 
            COUNT(*) as total_records,
            SUM(CASE WHEN loan_status IN ('Fully Paid', 'Current', 'Charged Off') THEN 1 ELSE 0 END) as valid_status_count,
            SUM(CASE WHEN dti BETWEEN 0 AND 1 THEN 1 ELSE 0 END) as valid_dti_count,
            AVG(dti) as avg_dti,
            AVG(int_rate) as avg_interest_rate
        FROM bank_loan_data
        """
        stats = pd.read_sql(query, self.conn)
        
        # Generate report
        report = {
            "validation_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "validation_results": validation_results,
            "statistics": stats.to_dict('records')[0]
        }
        
        # Save report
        report_path = Path('reports') / f'validation_report_{datetime.now().strftime("%Y%m%d")}.json'
        with open(report_path, 'w') as f:
            json.dump(report, f, indent=4)
        
        self.logger.info(f"Validation report generated: {report_path}")
        return report

    def fix_common_issues(self):
        """Fix common data issues automatically."""
        try:
            # Start transaction
            with self.conn.cursor() as cursor:
                # Fix loan status capitalization
                cursor.execute("""
                UPDATE bank_loan_data
                SET loan_status = 
                    CASE 
                        WHEN LOWER(loan_status) LIKE '%fully%paid%' THEN 'Fully Paid'
                        WHEN LOWER(loan_status) LIKE '%current%' THEN 'Current'
                        WHEN LOWER(loan_status) LIKE '%charged%off%' THEN 'Charged Off'
                    END
                WHERE loan_status NOT IN ('Fully Paid', 'Current', 'Charged Off')
                """)
                
                # Fix DTI values
                cursor.execute("""
                UPDATE bank_loan_data
                SET dti = NULL
                WHERE dti < 0 OR dti > 1
                """)
                
                self.conn.commit()
                self.logger.info("Common issues fixed successfully")
                
        except Exception as e:
            self.conn.rollback()
            self.logger.error(f"Error fixing common issues: {str(e)}")
            raise

if __name__ == "__main__":
    # Initialize validator
    validator = LoanDataValidator()
    
    # Run validation
    validation_report = validator.generate_validation_report()
    
    # Fix common issues if needed
    if not all(validation_report['validation_results'].values()):
        validator.fix_common_issues()
        # Re-run validation
        validation_report = validator.generate_validation_report()
    
    # Print summary
    print("\nValidation Summary:")
    print("-" * 50)
    for check, result in validation_report['validation_results'].items():
        print(f"{check}: {'PASSED' if result else 'FAILED'}")
    print("-" * 50)
    print("Statistics:")
    for key, value in validation_report['statistics'].items():
        print(f"{key}: {value}")
