$DbName = ""
$BackupPath = ""
$SettingsPath = Join-Path $PSScriptRoot "git_db_settings.xml"

function CheckParms() {
    $result = !([string]::IsNullOrEmpty($script:BackupPath) -Or [string]::IsNullOrEmpty($script:DbName))
    #Write-Host "Check Parms"
    #Write-Host "BackupPath: " $script:BackupPath
    #Write-Host "DbName: " $script:DbName
    return $result
}

function GetSettings() {
    #Write-Host "Getting Settings"
    if (Test-Path $SettingsPath) {
        [xml]$settings = Get-Content $SettingsPath
        #write-host "have settings"
        if ([string]::IsNullOrEmpty($BackupPath)) { $script:BackupPath = $settings.settings.BackupPath }
        if ([string]::IsNullOrEmpty($DbName)) { $script:DbName = $settings.settings.DbName }
        #Write-Host "BackupPath: " $script:BackupPath
        #Write-Host "DbName: " $script:DbName
    }
}

function Backup-GitBranchDb($BackupPath, $DbName) {
    $script:BackupPath = $BackupPath
    $script:DbName = $DbName
    if (-Not (CheckParms)) {
        GetSettings
        #Write-Host "BackupPath: " $script:BackupPath
        #Write-Host "DbName: " $script:DbName
    }
    if (-Not (CheckParms)) {
        $ErrorMessage = "Must provide a -DbName and -BackupPath or create a settings file as git_db_settings.xml"
        throw [System.ArgumentException] $ErrorMessage
    }
    Write-Host "Doing backup"
    $gitBranch = git branch | grep \* | cut -d ' ' -f2-
    $toRun = 'SqlCmd -E -Q "BACKUP DATABASE [' + $script:DbName + '] TO DISK='''+ $script:BackupPath + $gitBranch + '.bak''"'
    iex $toRun
    #Write-Host $toRun
}

function Restore-GitBranchDb($BackupPath, $DbName) {
    $script:BackupPath = $BackupPath
    $script:DbName = $DbName
    if (-Not (CheckParms)) {
        GetSettings
        #Write-Host "BackupPath: " $script:BackupPath
        #Write-Host "DbName: " $script:DbName
    }
    if (-Not (CheckParms)) {
        $ErrorMessage = "Must provide a -DbName and -BackupPath or create a settings file as git_db_settings.xml"
        throw [System.ArgumentException] $ErrorMessage
    }
    Write-Host "Doing restore"
    $gitBranch = git branch | grep \* | cut -d ' ' -f2-
    iex 'SqlCmd -E -Q "ALTER DATABASE [$script:DbName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE"'
    iex 'SqlCmd -E -Q "RESTORE DATABASE [$script:DbName] FROM DISK=''$script:BackupPath$gitBranch.bak'' WITH REPLACE"'
    iex 'SqlCmd -E -Q "ALTER DATABASE [$script:DbName] SET MULTI_USER"';
    #Write-Host $toRun
}

function Save-GitBranchDbSettings($DbName, $BackupPath) {
    Write-Host "Saving Settings to $SettingsPath"
    $xml = New-Object System.Xml.XmlTextWriter($SettingsPath, $Null);
    $xml.Formatting = "Indented"
    $xml.IndentChar = " ";
    $xml.Indentation = "1";

    $xml.WriteStartDocument();
    $xml.WriteStartElement("settings");
    $xml.WriteAttributeString("DbName", $DbName);
    $xml.WriteAttributeString("BackupPath", $BackupPath);
    $xml.WriteEndElement()
    $xml.WriteEndDocument()
    $xml.Flush()
    $xml.Close()
}

Export-ModuleMember Backup-GitBranchDb
Export-ModuleMember Restore-GitBranchDb
Export-ModuleMember Save-GitBranchDbSettings