$DbName = ""
$BackupPath = ""

function CheckParms() {
	$result = !([string]::IsNullOrEmpty($script:BackupPath) -Or [string]::IsNullOrEmpty($script:DbName))
	#Write-Host "Check Parms"
	#Write-Host "BackupPath: " $script:BackupPath
	#Write-Host "DbName: " $script:DbName
	return $result
}

function GetSettings() {
	#Write-Host "Getting Settings"
	if (Test-Path git_db_settings.xml) {
		[xml]$settings = Get-Content git_db_settings.xml
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

function Retore-GitBranchDb($BackupPath, $DbName) {
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
	$toRun = 'SqlCmd -E -Q "RESTORE DATABASE [' + $script:DbName + '] FROM DISK='''+ $script:BackupPath + $gitBranch + '.bak''"'
	iex $toRun
	#Write-Host $toRun
}

function Save-GitBranchDbSettings($DbName, $BackupPath) {
	Write-Host "Saving Settings"
	$output = "git_db_settings.xml";
	$xml = New-Object System.Xml.XmlTextWriter($output, $Null);
	$xml.Formatting = "Indented"
	$xml.IndentChar = " ";
	$xml.Indentation = "1";

	# Start writing
	$xml.WriteStartDocument();
	$xml.WriteStartElement("settings");
	$xml.WriteAttributeString("DbName", $DbName);
	$xml.WriteAttributeString("BackupPath", $BackupPath);
	$xml.Close();
}

Export-ModuleMember Backup-GitBranchDb
Export-ModuleMember Retore-GitBranchDb
Export-ModuleMember Save-GitBranchDbSettings