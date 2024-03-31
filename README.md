# Download GitHub repos ZIP
This PowerShell script allows you to download all Repositories as ZIP archives from any GitHub account.
Script will download only repositories where the owner of the repository is the same account as the owner of the GitHub account connecting to.
Script will not download forked repositories.

To proceed run the file **Download_Repos.ps1**.

You can run script without parameters when using GitHub_infos.xml in script folder:
- GitHub_Token: Token to access to your itHub account
- GitHub_OwnerName: Type your GitHub account name
- Output_Path: Specify the path where to save ZIP files

Instead of XML configuration, you can run script with parameters:
- Token: Token to access to your itHub account
- Output_Path: Specify the path where to save ZIP files
- Owner: Type your GitHub account name

More information about the script parameters is available in the script.
Examples for script parameter combinations are available in the script.
