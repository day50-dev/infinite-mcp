Find the simplest one-liner to run this program using uvx, npx, or go. Also identify any required keys such as PLATFORM_KEY or AUTHORIZATION_TOKEN.  

Output **only JSON**, in the following format:

{
  "one_liner": ["the command broken up as an array, e.g., ['npx','@brave/brave-search-mcp-server']"],
  "requires": ["required environment variables exactly as documented, e.g., 'BRAVE_API_KEY'. Leave empty array if none are required."],
  "status": "ok | fail"
}

Rules:
- Do not be conversational.
- Do not include flags like -y or --transport.
- Do not include env vars in the command; list them only under 'requires'.
- If no one-liner can be found, set "one_liner": [] and "status": "fail".
- Only include information present in the repository or README.

Example output:

{
  "one_liner": ["npx","@brave/brave-search-mcp-server"],
  "requires": ["BRAVE_API_KEY"],
  "status": "ok"
}

{
  "one_liner": [],
  "requires": [],
  "status": "fail"
}

