Invoke-Command -ScriptBlock {Clear-Host}




Write-host "///////////////////////////////////////////////////////////////

Hi, This script is for generating CSR and Private key.

Please enter your desired information according to the asked questions.

The CSR and Private key files will be named after your domain name without the TLD and are stored in your desktop folder with the name domain-certificate

P.S. The default hashing algorithm is SHA256.

Enjoy!

Made By Hamidreza Shadi.

///////////////////////////////////////////////////////////////////////////" -ForegroundColor Cyan

if (-not (Get-Command openssl -ErrorAction SilentlyContinue)) {
    Write-Host "OpenSSL is not installed or not available in the system PATH. Please install or configure OpenSSL." -ForegroundColor Red
    exit
}



Set-Location C:\

$pri_key = $null
$country = $null
$state = $null
$city = $null
$company = $null
$email_add = $null
$cn_name = $null


while (-not [int]::TryParse(($pri_key = Read-Host -Prompt "Please enter your key size (default is 2048)"), [ref]$null) -or $pri_key -le 0) {
    
    if (-not $pri_key) {
        # If input is blank, set default and exit the loop
        $pri_key = 2048
        break
    }
    Write-Host "Invalid input. Please enter a valid numeric key size." -ForegroundColor Red
   
}


Write-Host ("-" * 50) -ForegroundColor Yellow

$country = Read-Host -Prompt "Please enter your country name in two characters (e.g. IR, US, JP)"

while ($country -notmatch '^[A-Z]{2}$')
{ 
   Write-Host "You have entered the wrong information. Please enter again." -ForegroundColor Red
   $country = Read-Host -Prompt "Please enter your country name in two characters (e.g. IR, US, JP)"

}

$country = $country.ToUpper()
Write-Host ("-" * 50) -ForegroundColor Yellow

$state = Read-Host -Prompt "Please enter your state"
Write-Host ("-" * 50) -ForegroundColor Yellow

$city = Read-Host -Prompt "Please enter your city"
Write-Host ("-" * 50) -ForegroundColor Yellow

$company = Read-Host -Prompt "Please enter your Organization name"
Write-Host ("-" * 50) -ForegroundColor Yellow

$email_add = Read-Host -Prompt "Please enter your email address"
Write-Host ("-" * 50) -ForegroundColor Yellow

$cn_name = Read-Host -Prompt "Please enter your domain name in FQDN format (e.g. company.ir or *.company.ir)"

while (($cn_name -notmatch '^[a-zA-Z0-9-.]+\.[a-zA-Z]{2,}$') -and ($cn_name -notmatch '^\*\.[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'))

{
    Write-Host "Invalid info. Please enter the correct info." -ForegroundColor Red
    $cn_name = Read-Host -Prompt "Please enter your domain name in FQDN format (e.g. company.ir or *.company.ir)"

}


Write-Host ("-" * 50) -ForegroundColor Yellow

$new_name = $cn_name.Split(".")
$f_name = $new_name[0]

if ($f_name -eq '*')
{
    $f_name = $new_name[1]
}

# Prompt User for Wildcard or SAN Choice
Write-Host "Would you like to:" -ForegroundColor Cyan
Write-Host "1. Add a single wildcard domain (e.g., *.example.com)" -ForegroundColor Yellow
Write-Host "2. Add multiple SAN domains (e.g., www.example.com, mail.example.com)" -ForegroundColor Yellow
Write-Host "If you want to create a single domain CSR then just skip this part." -ForegroundColor Magenta
$choice = Read-Host -Prompt "Please enter 1, 2 or leave it blank"

# Validate User Input
while ($choice -ne 1 -and $choice -ne 2 -and $choice -ne "") {
    Write-Host "Invalid choice. Please enter 1 for a wildcard domain or 2 for multiple SAN domains. Or just leave it blank" -ForegroundColor Red
    $choice = Read-Host -Prompt "Please enter 1, 2 or leave it blank"
}


# Handle Wildcard Domain
if ($choice -eq 1) {
    $wildcard_domain = Read-Host -Prompt "Enter your wildcard domain (e.g., *.example.com)"

    # Validate Wildcard Domain Format
    while ($wildcard_domain -notmatch '^\*\.[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') {
        Write-Host "Invalid wildcard domain format. Please try again." -ForegroundColor Red
        $wildcard_domain = Read-Host -Prompt "Enter your wildcard domain (e.g., *.example.com)"
    }

    # Create SAN String for Wildcard Domain
    $san_string = "DNS.1:$wildcard_domain"
}

# Handle Multiple SAN Domains
elseif ($choice -eq 2) {
    $alt_names = Read-Host -Prompt "Please enter the SAN of your domain (e.g., www.example.com,mail.example.com)"
    $new_alt_names = $alt_names.Split(",")

    # Construct SAN Entries
    $san_entries = @()
    for ($i = 0; $i -lt $new_alt_names.Count; $i++) {
        $san_entries += "DNS.$($i+1):$($new_alt_names[$i])"
    }

    # Create SAN String for Multiple Domains
    $san_string = ($san_entries -join ",")
}


#Handle Single Domain request
else {
    $san_string ="DNS.1:www.$cn_name,DNS.2:$cn_name"
}

# Continue with OpenSSL Command
$cert_folder = "$env:USERPROFILE\Desktop\$f_name-certificate"
if (!(Test-Path -path $cert_folder)) {
    New-Item -ItemType Directory -Path $cert_folder | Out-Null
}

openssl req -new -newkey rsa:$pri_key -sha256 -nodes -subj "/C=$country/ST=$state/L=$city/O=$company/CN=$cn_name/emailAddress=$email_add" -addext "subjectAltName=$san_string" -keyout "$cert_folder\$f_name.key" -out "$cert_folder\$f_name.csr"

Write-Host `n
Write-Host "Your CSR and Private key are generated successfully in $cert_folder." -ForegroundColor Green

Start-Sleep -Seconds 5
Write-Host `n
cat $cert_folder\$f_name.key

Start-Sleep -Seconds 5
Write-Host `n
cat $cert_folder\$f_name.csr


Start-Sleep -Seconds 10
Write-Host `n

# Prompt for CSR Verification
$prompt1 = Read-Host "Do you want to verify your CSR which is $cert_folder\$f_name.csr (Y/N)?"
if ($prompt1 -match '^(y|yes)?$') {
    openssl req -text -in "$cert_folder\$f_name.csr" -noout -verify
}

Write-Host `n
# Prompt for Private Key Passphrase

$prompt2 = Read-Host "Do you want to set passphrase for your private key which is $cert_folder\$f_name.key (Y/N)?"
if ($prompt2 -match '^(y|yes)?$') {
    openssl rsa -in "$cert_folder\$f_name.csr" -sha256 -out "$cert_folder\$f_name-encrypted.key"
    cat "$cert_folder\$f_name-encrypted.key"
}


Read-Host "Press any key to exit..."