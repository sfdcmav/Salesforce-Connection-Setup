/*Usage Guide for UniversalQueryService

1. Endpoint URL

Once deployed, your custom REST endpoint will be available at:
https://<your-domain>.my.salesforce.com/services/apexrest/UniversalQuery

2. Request Format

The service uses the POST method. This allows for longer query strings than a standard GET request.

Method: POST

Headers:

Authorization: Bearer <YOUR_ACCESS_TOKEN>

Content-Type: application/json

Body (JSON):

{
    "queryStr": "SELECT Id, Name, Industry, (SELECT LastName FROM Contacts) FROM Account LIMIT 5"
}


3. Example Response

The Apex class automatically serializes the QueryResponse wrapper into this JSON format:

Success Response:

{
    "success": true,
    "message": "Query executed successfully.",
    "recordCount": 5,
    "records": [
        {
            "attributes": {
                "type": "Account",
                "url": "/services/data/v60.0/sobjects/Account/001..."
            },
            "Id": "0015g00000S4...",
            "Name": "Edge Communications",
            "Industry": "Electronics",
            "Contacts": {
                "totalSize": 1,
                "done": true,
                "records": [
                    {
                        "attributes": {
                            "type": "Contact",
                            "url": "..."
                        },
                        "LastName": "Forbes"
                    }
                ]
            }
        },
        ...
    ]
}


Error Response (e.g., Invalid Field):

{
    "success": false,
    "message": "SOQL Error: No such column 'BadField' on entity 'Account'...",
    "recordCount": 0,
    "records": null
}

*/


@RestResource(urlMapping='/UniversalQuery/*')
global with sharing class UniversalQueryService {

    /**
     * Wrapper class to define the structure of the JSON response.
     * Salesforce automatically serializes this into JSON when returned.
     */
    global class QueryResponse {
        public Boolean success;
        public String message;
        public Integer recordCount;
        public List<SObject> records;

        public QueryResponse() {
            this.success = true;
            this.message = 'Query executed successfully.';
            this.records = new List<SObject>();
            this.recordCount = 0;
        }
    }

    /**
     * HTTP POST method to accept a query string in the body.
     * Using POST is recommended over GET for queries to handle 
     * long query strings and complex characters better.
     * * Payload expected: { "queryStr": "SELECT Id, Name FROM Account LIMIT 5" }
     */
    @HttpPost
    global static QueryResponse executeDynamicQuery(String queryStr) {
        QueryResponse response = new QueryResponse();
        
        // 1. Basic Validation
        if (String.isBlank(queryStr)) {
            response.success = false;
            response.message = 'Error: Query string cannot be empty.';
            return response;
        }

        try {
            // 2. Execute the Query dynamically
            // The 'with sharing' keyword on the class ensures record-level security 
            // is respected for the user calling this API.
            List<SObject> results = Database.query(queryStr);
            
            // 3. Populate Response
            response.records = results;
            response.recordCount = results.size();
            
        } catch (QueryException qe) {
            // Handle invalid SOQL (e.g., typos, accessing non-existent fields)
            response.success = false;
            response.message = 'SOQL Error: ' + qe.getMessage();
            
        } catch (Exception e) {
            // Handle generic errors
            response.success = false;
            response.message = 'System Error: ' + e.getMessage();
        }

        return response;
    }
}