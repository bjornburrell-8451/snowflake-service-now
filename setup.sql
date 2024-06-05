//PRE-REQUISITE: A ServiceNow API endpoint and user with permissions to create tickets (https://developer.servicenow.com/dev.do#!/reference/api/utah/rest/) or an api gateway that will forward you request to ServiceNow

// STEP 1: Create network rule to allow an endpoint to be hit. 
CREATE OR REPLACE NETWORK RULE service_now_demo_rule
MODE = EGRESS
TYPE = HOST_PORT
VALUE_LIST = ('demo.service-now.com');

// STEP 2: Create secrets that we use for API auth
CREATE SECRET service_now_demo_user
TYPE = GENERIC_STRING
SECRET_STRING = demo;

CREATE SECRET service_now_demo_pass
TYPE = GENERIC_STRING
SECRET_STRING = demo;

// STEP 3: Bundle the network rule and secrtets into an external access integration 
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION service_now_demo_integration
ALLOWED_NETWORK_RULES = (service_now_demo_rule)
ALLOWED_AUTHENTICATION_SECRETS = ('service_now_demo_user', 'service_now_demo_pass')
ENABLED = TRUE;

// STEP 4: create logging table
CREATE OR REPLACE TABLE CREATE_ISERV_TICKET_LOG (
    ticket_num INT PRIMARY KEY AUTOINCREMENT,
    event_identifier VARCHAR,
    short_description VARCHAR,
    description VARCHAR,
    assignment_group VARCHAR,
    u_business_service VARCHAR,
    urgency VARCHAR,
    impact VARCHAR,
    ticket_created BOOLEAN
);

// STEP 5: Create a python sproc and pass in the external access integration, with the requests package imported
CREATE OR REPLACE PROCEDURE CREATE_ISERVICE_TICKET("SHORTDESC" VARCHAR(16777216), "FULLDESC" VARCHAR(16777216), "ASSIGNMENTGROUP" VARCHAR(16777216), "BUSINESSSERVICE" VARCHAR(16777216), "URGENCY" VARCHAR(16777216), "IMPACT" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('snowflake-snowpark-python','requests')
HANDLER = 'handlerFunc'
EXTERNAL_ACCESS_INTEGRATIONS = (service_now_demo_integration)
SECRETS = ('credPass'=service_now_demo_user,'credUser'=service_now_demo_pass)
EXECUTE AS OWNER
AS '
import _snowflake
import requests
import json
reqSession = requests.Session()


def recordLogToTable(session, randUUID, shortDesc, fullDesc, assignmentGroup, businessService, urgency, impact, ticket_created):
        try:
            session.sql(("INSERT INTO COMMON.LOGS.CREATE_ISERV_TICKET_LOG("
                "event_identifier, "
                "short_description, "
                "description, "
                "assignment_group, "
                "u_business_service, "
                "urgency, "
                "impact, "
                "ticket_created) "
                "VALUES(?, ?, ?, ?, ?, ?, ?, ?)"), params=[str(randUUID), shortDesc, fullDesc, assignmentGroup, businessService, urgency, impact, ticket_created]).collect()
            return True
        except:
            return False

def handlerFunc(session, shortDesc, fullDesc, assignmentGroup, businessService, urgency, impact):
    import requests
    import json
    import base64
    import uuid

    # Get Username and pass from snowflake secrets
    username = _snowflake.get_generic_secret_string(''credUser'')
    password = _snowflake.get_generic_secret_string(''credPass'')
    credentials = f"{username}:{password}"

    # Generate UUID
    randUUID = str(uuid.uuid4())    
    
    # Encode the credentials in Base64 format
    encoded_credentials = base64.b64encode(credentials.encode(''utf-8'')).decode(''utf-8'')
    
    # Make Request
    url = ''https://demo.service-now.com/api/snowflake''
    headers = {
        "Authorization": f"Basic {encoded_credentials}"
    }
    
    data = {
        ''event_identifier'': f"{randUUID}",
        ''short_description'': f"{shortDesc}",
        ''description'': f"{fullDesc}",
        ''assignment_group'': f"{assignmentGroup}",
        ''u_business_service'': f"{businessService}",
        ''urgency'': f"{urgency}",
        ''impact'': f"{impact}"
    }
    reqSession = requests.Session()
    response = requests.post(url, headers=headers, data=json.dumps(data))

    # Logging and Return
    if int(response.status_code) == 200:
        if not recordLogToTable(session, randUUID, shortDesc, fullDesc, assignmentGroup, businessService, urgency, impact, True):
            return "Error during Logging"
        return "Ticket Created Successfully."
    else:
        if not recordLogToTable(session, randUUID, shortDesc, fullDesc, assignmentGroup, businessService, urgency, impact, False):
            return "Error during Logging"
        return f"Error Creating Ticket. Status code: {response.status_code}"
';

// TEST: Create a ticket by calling the sproc
CALL COMMON.PROCEDURES.CREATE_ISERVICE_TICKET('ServiceNow Summit Demo', 'SnowSummit 24 has been amazing so far', 'Database Support', 'Snowflake', 'Low', 'Low');
