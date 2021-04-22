# qualtricks
Packaged convenience functions for Qualtrics Site Intercept (Website/App Feedback) API and Survey API functions not in ropensci/qualtRics, e.g.,

listUsers
getUserAPIToken
createUserAPIToken
listSurveys (allowing parameters)

WIP

## Tips 

### Brand Admin utilities

1. List Qualtrics User Type Permissions from Admin Panel

```{javascript}
rules = document.querySelectorAll("td[class*=Col_PermissionName]")

table = [];

for(i = 0; i < rules.length; i++) {
    tab = rules[i].parentNode.parentNode.parentNode.parentNode.parentNode.parentElement.parentElement.parentElement.parentElement.id
    table[i] = tab + ": " + rules[i].id.replace("PermissionLabel-", "") + ": " + rules[i].innerText.replace(/\r?\n|\r/g, "").replace(/\s\s+/g, "")
}

table.join("\n"); // generates the profiles.xlsx
```

### Version control intercepts as code (Chrome)

1. Go to any intercept project's editor (doesn't matter which, you'll get all projects within the zone)
1. Open browser developer tools
1. Reload page
1. In developer tools: Network tab, filter results to GetZoneIntercept → Preview
1. Right click → Store object as global variable (the raw response is also available under Response but is slower/buggier to copy)
1. In console, run copy(temp1)
1. Paste into a text editor and save file. Name file after intercept ID, e.g., SI_abc123.json. 
1. Optionally: print the editor page as a PDF (landscape), e.g., SI_abc123.pdf

![getZoneIntercept screenshot](https://i.imgur.com/2zL1bbe.png)

You can also push this payload via fetch in the console

1. From the intercept editor UI, save an arbitrary change and capture the Network Request "SaveIntercept" as a fetch request
2. Paste copied request in text editor, it'll look something like this:
  ```
  fetch("https://hbp.az1.qualtrics.com/DX/InterceptsSection/EditIntercept/Ajax/SaveIntercept", {
  "headers": {
    "accept": "text/javascript, text/html, application/xml, text/xml, */*",
    "accept-language": "en-US,en;q=0.9,es;q=0.8",
    "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
    "sec-ch-ua": "\" Not A;Brand\";v=\"99\", \"Chromium\";v=\"90\", \"Google Chrome\";v=\"90\"",
    "sec-ch-ua-mobile": "?0",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-prototype-version": "1.7.3",
    "x-requested-with": "XMLHttpRequest",
    "x-xsrf-token": "XSRF_abc123"
  },
  "referrer": "https://abc.az1.qualtrics.com/DX/InterceptsSection/EditIntercept?ContextIntercept=SI_abc123&ContextZone=ZN_abc123",
  "referrerPolicy": "strict-origin-when-cross-origin",
  "body": "Definition=%7B%22Status%22%3A%22Active%22%2C%22Edited%22%3Atrue%2C%22ZoneID%22%3A%abc123..."
  "method": "POST",
  "mode": "cors",
  "credentials": "include"
});
  ```
  3. Replace everything after "Definition=" in the body value with the relevant intercept payload from above and run in the browser console.

![saveIntercept screenshot](https://i.imgur.com/eSSO6ES.png)
