Function AzureConnect {
    [cmdletbinding()]
    param([string]$EnvironmentUrl)

    ## Login interactively if not already logged in
    if ($null -eq (Get-AzTenant -ErrorAction SilentlyContinue)) {
        Connect-AzAccount | Out-Null
    }

    # Get an access token
    if($environmentUrl) {
        $secureToken = (Get-AzAccessToken -ResourceUrl $environmentUrl -AsSecureString).Token
    
        # Convert the secure token to a string
        if($PSVersionTable.PSVersion.Major -gt 5) {
            $token = ConvertFrom-SecureString -SecureString $secureToken -AsPlainText
        } else {
            $token = [System.Net.NetworkCredential]::new("", $secureToken).Password
        }
        return @{
            'Authorization'    = 'Bearer ' + $token
            'Accept'           = 'application/json'
            'OData-MaxVersion' = '4.0'
            'OData-Version'    = '4.0'
        }
    }
}