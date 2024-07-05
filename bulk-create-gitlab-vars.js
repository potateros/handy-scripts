const fs = require('fs');
const https = require('https');
const url = require('url');

function loadVariables(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function createVariable(gitlabUrl, projectId, variable, accessToken) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      key: variable.name,
      value: variable.value,
      protected: variable.protected,
      environment_scope: variable.environment_scope
    });

    const parsedUrl = new url.URL(`${gitlabUrl}/api/v4/projects/${projectId}/variables`);

    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || 443,
      path: parsedUrl.pathname + parsedUrl.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'PRIVATE-TOKEN': accessToken,
        'Content-Length': data.length
      },
      rejectUnauthorized: false // Use this only if your GitLab instance uses a self-signed certificate
    };

    const req = https.request(options, (res) => {
      let responseBody = '';

      res.on('data', (chunk) => {
        responseBody += chunk;
      });

      res.on('end', () => {
        resolve(JSON.parse(responseBody));
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(data);
    req.end();
  });
}

async function main(gitlabUrl, projectId, accessToken, jsonFile) {
  const variables = loadVariables(jsonFile);

  for (const variable of variables) {
    console.log(`Creating variable: ${variable.name}`);
    try {
      const result = await createVariable(gitlabUrl, projectId, variable, accessToken);
      if (result.message) {
        console.log(`Error: ${result.message}`);
      } else {
        console.log(`Successfully created variable: ${variable.name}`);
      }
    } catch (error) {
      console.error(`Error creating variable ${variable.name}:`, error.message);
    }
    console.log('---');
  }
}

if (process.argv.length !== 6) {
  console.log('Usage: node script.js <gitlab_url> <project_id> <access_token> <json_file>');
  process.exit(1);
}

const gitlabUrl = process.argv[2];
const projectId = process.argv[3];
const accessToken = process.argv[4];
const jsonFile = process.argv[5];

main(gitlabUrl, projectId, accessToken, jsonFile).catch(console.error);
