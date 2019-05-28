
# https://{region}.certificate-manager.cloud.ibm.com/api
# ibmcloud resource service-instance {instance_name} --output JSON

# 1. ibmcloud iam oauth-tokens
# 2. read id from config.json
# 3. curl -H "Authorization: Bearer <IAM-token>" https://<api-endpoint>/api/v3/<URL encoded CRN-based instanceId>/certificates/
# 4. curl -X POST -H "Content-Type: application/json" -H "authorization: Bearer <IAM-token>" -d "{ "name":"<name>", "description":"<description>", "data":{ "content": "<certificate>", "priv_key": "<privateKey>", "intermediate": "<intermediate>" } }" https://<api-endpoint>/api/v3/<URL encoded CRN-based instanceId>/certificates/import
# 5. curl -H "Authorization: Bearer <IAM-token>" https://<api-endpoint>/api/v2/certificate/<URL encoded CRN-based certificateId>
# 6. curl -X DELETE -H "Authorization: Bearer <IAM-token>" https://<api-endpoint>/api/v2/certificate/<URL encoded CRN-based certificateId>
