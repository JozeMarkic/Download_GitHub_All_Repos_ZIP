<#
.SYNOPSIS
    Script downloads all repositories in selected GitHub account (owner).
  
.NOTES
    Name: Download_Repos.ps1
    Author: Damien Van Robaeys  GitHub: DamienVanRobaeys
    Updated by: Joze Markic     GitHub: JozeMarkic
    Version: 1.0
    DateCreated: 2020-07
    DateUpdated: 2024-03
    
.EXAMPLE
    To download files in specific folder, run:
    .\Download_Repos.ps1 -Token ... -Owner damienvanrobaeys -Output_Path C:\TMP\damienvanrobaeys
    
.EXAMPLE
    To download files in script sub-folder folder, run:
    .\Download_Repos.ps1 -Token ... -Owner DeploymentBunny -Output_Path DeploymentBunny
    
.EXAMPLE
    To download files in script folder, run:
    .\Download_Repos.ps1 -Token ... -Owner DeploymentBunny
    
.EXAMPLE
    To download files based on XML configuration:
    .\Download_Repos.ps1 
    
.LINK
    https://github.com/JozeMarkic/Download_GitHub_All_Repos_ZIP
#>

[CmdletBinding()]
Param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 2
            )]
        [string]$Token,            
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1
            )]
        [string]$Output_Path,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
            )]
        [string]$Owner    
    )    

Function Write_Info {
        param(
        $Message_Type,    
        $Message
        )
        
        $MyDate = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date) 
        if ($Message_Type -eq "ERROR") {
            write-host "$MyDate - $Message_Type : $Message" -ForegroundColor Red -BackgroundColor Black  
        } else {
            write-host "$MyDate - $Message_Type : $Message"    
        }
    }

If (!(Get-Module -Name "*PowerShellForGitHub*" -ListAvailable)) {
    Try {
        # Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force 
        Install-Module -Name PowerShellForGitHub -force -confirm:$false -ErrorAction SilentlyContinue
        Write_Info -Message_Type "SUCCESS" -Message "GitHub module has been successfully installed"    
        $GitHub_Module_Status = "OK"
    }
    Catch {
        Write_Info -Message_Type "ERROR" -Message "An issue occured while installing module"    
        $GitHub_Module_Status = "KO"        
    }            
} Else {
    if (Get-Module -Name PowerShellForGitHub) {Remove-Module -Name PowerShellForGitHub}
    (Get-Module -Name "*PowerShellForGitHub*" -ListAvailable) | Sort-Object -Property Version -Descending | Select-Object -First 1 | Import-Module -ErrorAction SilentlyContinue     
    Write_Info -Message_Type "INFO" -Message "The PowerShellForGitHub module already exists"        
    $GitHub_Module_Status = "OK"                
}    

$Current_Folder = split-path $MyInvocation.MyCommand.Path
if (-not $Output_Path) {$Output_Path = $Current_Folder}

$xml = "$Current_Folder\GitHub_Infos.xml"
if (Test-Path -Path $xml) {
    $my_xml = [xml] (Get-Content $xml)
    $GitHub_Token = $my_xml.Configuration.GitHub_Token
    $GitHub_Output_Path = $my_xml.Configuration.Output_Path
    $GitHub_Owner = $my_xml.Configuration.GitHub_OwnerName
}

If(($Token -eq "") -AND ($GitHub_Token -eq $null)) {
    Write_Info -Message_Type "ERROR" -Message "Please type a GitHub token"
    break        
}

If(($Token -ne "") -or ($GitHub_Token -ne $null)) {
    If($Token -ne "") {
        $Get_Token = $Token            
    }
    Else {
        $Get_Token = $GitHub_Token            
    }            
}
if ($Get_Token -eq "" -or $Get_Token -eq $null) {
    Write_Info -Message_Type "ERROR" -Message "Please type a GitHub token"
    break        
}

If(($Owner -eq "") -AND ($GitHub_Owner -eq $null)) {
    Write_Info -Message_Type "ERROR" -Message "Please type a GitHub owner name"         
    break
}
    
If(($Owner -ne "") -or ($GitHub_Owner -ne $null)) {
    If($Owner -ne "") {
        $Get_OwnerName = $Owner            
    }
    Else {
        $Get_OwnerName = $GitHub_Owner            
    }            
}
Else {
    Write_Info -Message_Type "ERROR" -Message "Please type a GitHub owner name"         
    break
}

if ($Get_OwnerName -eq "" -or $Get_OwnerName -eq $Null) {
    Write_Info -Message_Type "ERROR" -Message "Please type a GitHub owner name"         
    break
}

If(($Output_Path -ne "") -or ($GitHub_Output_Path -ne "")) {
    If($Output_Path -ne "") {
        $Get_Output_Path = $Output_Path
    }
    Else {
        $Get_Output_Path = $GitHub_Output_Path
    }
}
Else {
    Write_Info -Message_Type "ERROR" -Message "Please type an output path where to save ZIP"
}

if ($Get_Output_Path.Contains("\")) {
    if ($Get_Output_Path.StartsWith(".\")) {
        $CheckPath = Join-Path -Path $Current_Folder -ChildPath $Owner
    } else {
        $CheckPath = $Get_Output_Path
    }
} else {
    $CheckPath = Join-Path -Path $Current_Folder -ChildPath $Owner
}

if (-not (Test-Path -Path $CheckPath)) {
    $Get_Output_Path = (New-Item -ItemType Directory -Path $CheckPath).FullName
}

Write_Info -Message_Type "INFO" -Message "The script will download all repos from $Get_OwnerName"        
Write_Info -Message_Type "INFO" -Message "The script will download all repos in $Get_Output_Path"        
write-host ""

$GitHub_SecureToken = ConvertTo-SecureString $Get_Token -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential "Ownername is ignored", $GitHub_SecureToken
Try {
    Set-GitHubConfiguration -DisableLogging
    Set-GitHubConfiguration -SuppressTelemetryReminder
    Set-GitHubAuthentication -Credential $cred -SessionOnly | out-null        
    Write_Info -Message_Type "SUCCESS" -Message "Successfully connected to GitHub"        
    $GitHub_IsConnected = $True
}
Catch {
    Write_Info -Message_Type "ERROR" -Message "An error occured while connecting to GitHub"        
    $GitHub_IsConnected = $False        
}
write-host ""

If($GitHub_IsConnected -eq $True) {
    $List_My_Repos = (Get-GitHubRepository -OwnerName $Get_OwnerName | select name, html_url, owner, updated_at, default_branch) | where {(($_.owner.login -like "*$Get_OwnerName*"))}
    if ($List_My_Repos.Count) {
        $Total = $List_My_Repos.Count
    } else {
        $Total = 1
    }
    $i = 1
    ForEach ($Repo in $List_My_Repos) {
        $PComplete = "{0:N0}" -f $($i/$Total*100)
        $i++
        $Repo_Name = $Repo.name
        Write-Progress -Activity "Downloading $Repo_Name" -Status "$PComplete% Complete:" -PercentComplete $PComplete;
        
        $Repo_URL = $Repo.html_url
        $Repo_Branch = $Repo.default_branch
        $Repo_Update = $Repo.updated_at
        $Repo_Output_Path = "$Get_Output_Path\$Repo_Name.zip"        
        $Repo_Archive = "$Repo_URL\archive\$Repo_Branch.zip"
        write-host "Check the repository $Repo_Name" 
        try {
            $HTTP_Request = Invoke-WebRequest -Uri $Repo_Archive -TimeoutSec 1 -Method Head
        } Catch {
            write-host ""
        }
        if ($HTTP_Request) {
            if (Test-Path -Path $Repo_Output_Path) {
            if ($Repo_Update -gt (Get-Item $Repo_Output_Path).LastWriteTime) {
                [bool]$download = 1
            } else {
                [bool]$download = 0
                Write_Info -Message_Type "INFO" -Message "Repository $Repo_Name already up-to-date."
                write-host ""
            }
        } else {
            [bool]$download = 1
        }
        if ($download) {
            write-host "Downloading the repository $Repo_Name"    
            Write_Info -Message_Type "INFO" -Message "Downloading the repository $Repo_Name"    
            $Download_EXE = new-object -typename system.net.webclient
            Try {
                $Download_EXE.Downloadfile($Repo_Archive,$Repo_Output_Path)    
                Write_Info -Message_Type "SUCCESS" -Message "$Repo_Name has been successfully downloaded"        
            }
            Catch {
                Write_Info -Message_Type "ERROR" -Message "An issue occurred while downloading $Repo_Name"        
            }
            write-host ""
        }
        } else {
            Write_Info -Message_Type "ERROR" -Message "ZIP not found for $Repo_Name"  
        }
    }
}
