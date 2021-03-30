Write-host " _____ _   _           _                                              _                              _                  _ "
Write-host "|_   _| | ( )         | |                                            | |                            | |                | |"
Write-host "  | | | |_|/ ___    __| | __ _ _ __   __ _  ___ _ __ ___  _   _ ___  | |_ ___     __ _  ___     __ _| | ___  _ __   ___| |"
Write-host "  | | | __| / __|  / _' |/ _' | '_ \ / _' |/ _ | '__/ _ \| | | / __| | __/ _ \   / _' |/ _ \   / _' | |/ _ \| '_ \ / _ | |"
Write-host " _| |_| |_  \__ \ | (_| | (_| | | | | (_| |  __| | | (_) | |_| \__ \ | || (_) | | (_| | (_) | | (_| | | (_) | | | |  __|_|"
Write-host "|_____|\__| |___/  \__,_|\__,_|_|_|_|\__, |\___|_|  \___/ \__,_|___/  \__\___/   \__, |\___/   \__,_|_|\___/|_| |_|\___(_)"
Write-host "|__   __|  | |        | | | |   (_)   __/ |                                       __/ |                                   "
Write-host "   | | __ _| | _____  | |_| |__  _ __|___/                                       |___/                                    "
Write-host "   | |/ _' | |/ / _ \ | __| '_ \| / __|                                                                                   "
Write-host "   | | (_| |   |  __/ | |_| | | | \__ \                                                                                   "
Write-host "   |_|\__,_|_|\_\___|  \__|_| |_|_|___/                                                                                   "
Write-host "                                          -PoC 2021-03-30   ""you know a tool is great when it has an ascii-art header""  "
                                                                                                                          

$results = @()

$events= Get-WinEvent -FilterHashTable @{ LogName = "Windows PowerShell"; ID = 400;} | Where-Object {$_.message -like "*.ps1*"}

foreach($event in $events) {
   if($event.Message.ToString().replace("`t", '').Trim() -match '([ ]|=)[A-Za-z]:\\.*\.ps1') {
        $values = [regex]::split($Matches[0], '(-.*[ ])')

        foreach ($value in $values) {
            if($value -match '[A-Za-z]:\\.*\.ps1') {
                $file = $Matches[0]
                $acl = $null
                $can_read = $null
                $can_write = $null

                if($results.FilePath -notcontains $file) {
                    $can_read = $true
                    $can_write = $true
                    if(Test-Path $file)
                    {
                        $acl = (Get-Acl $file).AccessToString.Replace("`n",";")
                        Try {
                            [io.file]::OpenWrite($file).close() 
                        } Catch {
                            $can_write = $false
                        } 
                    }
                    else {
                        $can_read = $false
                    }
                }
                else {
                    $can_read = $null
                    $can_write = $null
                }

                $result = [PSCustomObject]@{
                    DateTime = $event.TimeCreated
                    FilePath = $file
                    CanRead = $can_read
                    CanWrite = $can_write
                    Acl = $acl
                }
                $results += $result
            }   
        }
	}
}

$results | Format-Table
