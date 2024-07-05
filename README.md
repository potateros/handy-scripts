# handy-scripts

## bulk-create-gitlab-vars.js

Node.js script to bulk create CI/CD variables in GitLab projects from a JSON file.

Prepare a JSON file with variables:

```json
   [
     {
       "name": "VAR_NAME",
       "value": "value",
       "protected": false,
       "environment_scope": "All"
     }
   ]
```

Run with `node bulk-create-gitlab-vars.js <gitlab_url> <project_id> <access_token> <json_file>`

Example: `node bulk-create-gitlab-vars.js https://gitlab.com 12345 access_token bulk-create-gitlab-vars.json`
