class SimplyDataVerseException:Exception {
    [string]$DataVerseUri
    [string]$DataVerseEndPoint
    [System.Net.HttpStatusCode]$StatusCode
    
    hidden SimplyDataVerseException([string]$message, [exception]$ex, [string]$ep):base($message, $ex) {
        
        $this.DataVerseUri = [SDVApp]::GetBaseUri()
        $this.DataVerseEndPoint = $ep
        $this.StatusCode = $ex.Response.StatusCode
    }

    static [SimplyDataVerseException] Create([System.Management.Automation.ErrorRecord]$er, [string]$ep) {
        if($er.Exception.GetType().Name -notin @("WebException","HttpResponseException")){
            $notSupported = "[SimplyDataVerseException] does not support [{0}]" -f $er.Exception.GetType().FullName
            throw [System.InvalidOperationException]::new($notSupported, $er.Exception)
        }
        $msg = $er.Exception.Message
        if($er.ErrorDetails) {
            $msg = $er.ErrorDetails |
                ConvertFrom-Json |
                Select-Object -ExpandProperty error |
                Select-Object -ExpandProperty message
            if($msg -like "Error identified in Payload provided by the user for Entity*") {
                $msg = "[{0}] {1} BECAUSE [{2}] {3}" -f (((($msg -split "---->  InnerException : ")[1]) -split "`n")[0] -split " ---> " -split ": ")
            }
        }

        return [SimplyDataVerseException]::new($msg, $er.Exception, $ep)
    }
}