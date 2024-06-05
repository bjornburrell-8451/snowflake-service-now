import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session
session = get_active_session()


# Display Title and Description
st.title("84.51 Snowflake Support Portal")
st.markdown("Enter the details of the issue below.")


# create form
with st.form(key="ticket_form"):
    short_description = st.text_input(label="Give a short summary of the issue*")
    full_description = st.text_input(label=" Describe the issue in detail*")
    
    # Mark mandatory fields
    st.markdown("**required*")

    # add submit button
    submit_button = st.form_submit_button(label="Submit Ticket ")

    # If the submit button is pressed
    if submit_button:
        
        # Check if all mandatory fields are filled
        if not short_description or not full_description:
            st.warning("Ensure all mandatory fields are filled.")
            st.stop()
 
        else:
            sql = f"CALL DATABASE.SCHEMA.CREATE_ISERVICE_TICKET('description', 'full_description', 'service_now_team', 'assignment_group', 'severity', 'impact');"
            data = session.sql(sql).collect()
            
            # TODO: Need to add logic here to parse results of sproc
            st.success("Ticket successfully submitted!")

