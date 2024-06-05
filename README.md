# Setup.sql

This script is used to set up a stored proc in Snowflake that uses external access to make an API call to ServiceNow, which then creates a ticket - all within Snowflake.

## Prerequisites

Before running the `setup.sql` script, make sure you have the following:

- A Snowflake account with the necessary privileges to create databases and tables.
- Snowflake CLI or a Snowflake GUI client installed on your machine.

## Usage

1. Clone the Snowflake service now repository:

    ```shell
    git clone https://github.com/your-username/snowflake-service-now.git
    ```

2. Navigate to the project directory:

    ```shell
    cd snowflake-service-now
    ```

3. Open the `setup.sql` script in your preferred SQL editor.

4. Modify the script if needed to match your specific configuration.

5. Run the `setup.sql` script to create the necessary database schema, tables, and initial data:

    ```sql
    -- Example using Snowflake CLI
    snowsql -f setup.sql
    ```

7. Verify that the setup was successful by calling the proc. Check the log table for any errors.

    ```sql
    CALL CREATE_ISERVICE_TICKET('description', 'full_description', 'service_now_team', 'assignment_group', 'severity', 'impact');
    ```
