## Key Resources
- documentation: https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/use-ps-and-vscode-web-api
- https://github.com/microsoft/PowerApps-Samples/blob/master/dataverse/webapi/PS/README.md
- https://learn.microsoft.com/en-us/power-apps/developer/data-platform/discovery-service
- https://rakhesh.com/azure/well-known-client-ids/

## next steps

Leveraging the MetaData endpoint, need to cache an understanding of the table structure and relationships.
then create a function that will generate the appropriate PSCustomObjects when passed an API result and property entitySetName,
support recursions.


# for getting picklist values:
https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/query-metadata-web-api#querying-entitymetadata-attributes

should look at including this in the schema information... maybe support returning the string and translating from string to number automatically for updates?

# for setting parent columns
https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/associate-disassociate-entities-using-web-api
this uses odata.bind

# validate that SDVApp is ready
add logic in SDVApp to determine if its ready to be used -- update cmdlets to check prior to running.