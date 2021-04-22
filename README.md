# qualtricks
Packaged convenience functions for Qualtrics Site Intercept (Website/App Feedback) API and Survey API functions not in ropensci/qualtRics, e.g.,

listUsers
getUserAPIToken
createUserAPIToken
listSurveys (allowing parameters)

WIP

## Tips 

### How to version control intercept logic as code (Chrome)

1. Go to intercept editor
1. Open browser developer tools
1. Reload page
1. In developer tools: Network tab, filter results to GetZoneIntercept → Preview
1. Right click → Store object as global variable (the raw response is also available under Response but is slower/buggier to copy)
1. In console, run copy(temp1)
1. Paste into a text editor and save file, save file to Git repo. Name file after intercept ID, e.g., SI_abc123.json
1. Optionally: print the editor page as a PDF (landscape), e.g., SI_abc123.pdf

![]("https://imgur.com/a/2reQK9D")
