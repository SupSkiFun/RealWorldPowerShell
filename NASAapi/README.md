# NASAapi
## Query a NASA API in 4 languages.

JSON data is retrieved from the 'Asteroids - NeoWs' section of api.nasa.gov, then
parsed into a flat, custom structure.  Some averaging and rounding takes place.
Examples of Raw (not processed) JSON returned from the NASA API are in the JSON folder.

Fab Four:  PowerShell, Python, Node.js & Ruby

All Languages were written to run via PowerShell 7, however other
shells can be used with little or no modification.

Specific Language Versions tested:

    Powershell:  7.0.3 and 5.1.19041
    Python: 3.8.3
    Node.js:  14.2.0
    Ruby:  2.7.1p83

Usage:

    1.  Create an API key here: https://api.nasa.gov/ ; the process is easy and free.
    2.  Make the API Key available by either a or b below:
        a.  Simple / (mostly) Secure:
            Export NASA_API_KEY='Your_Key_Goes_Here' in your shell.
            In PowerShell, at the user level:
            [System.Environment]::SetEnvironmentVariable('NASA_API_KEY','Your_Key_Goes_Here',[System.EnvironmentVariableTarget]::User)
            Other shells can use the export command to accomplish the same result.
        b.  Less Simple / Secure:
            Comment out the key from environment line, and decomment the hard-coded line.
            In get_Nasa.js, this changes lines 32 and 33 to look as follows:
            32  //let key = process.env.NASA_API_KEY ;
            33  let key = 'Your_Key_Goes_Here' ;
            Changes are similar in other languages.
    3.  For PowerShell just run the script using PowerShell 5 or 7.
        For Python install into your main or virtual env the modules in requirements.txt.  'pip install -r requirements.txt'
        For Node.js install into your directory the modules listed in package.json.  'npm install'
        For Ruby install the modules within the Gemfile.  'bundle install'
    4.  From PowerShell 7.0.3 or 5.1.19401, returning the JSON data into a PSCustomObject:
        C:\NASAapi> $ps = .\PowerShell\GetNasa.ps1
        C:\NASAapi> $py = python.exe .\Python\getNasa.py | ConvertFrom-Json
        C:\NASAapi> $nj = node.exe .\Node.js\getNasa.js | ConvertFrom-Json
        C:\NASAapi> $rb = ruby.exe .\Ruby\getNasa.rb | ConvertFrom-Json
    5.  Note that running the Python, Node.Js and Ruby scripts without ConvertFrom-JSON results in an output of 'plain' JSON.
    6.  Conversely, to obtain plain JSON from PowerShell, execute .\PowerShell\GetNasa.ps1 | ConvertTo-Json


