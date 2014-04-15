### Startup and Security README
This directory has all files relating directly to the starting up of the server(s), also should include in here all global authentication/authorization logic.

All passwords, auth tokens etc should be stored in ./security.json. Then use require 'startup_security/security' which returns the struct defined in security.json.
Security.json is included in .gitignore so it should never be included in a repository.