#!/bin/powershell
<#
.SYNTAX         ./update-repos.ps1 [<directory>]
.DESCRIPTION	updates all Git repositories under the current/given directory
.LINK		https://github.com/fleschutz/PowerShell
.NOTES		Author:	Markus Fleschutz / License: CC0
#>

param($Directory = "")

try {
	& git --version
} catch {
	write-error "ERROR: can't execute 'git' - make sure Git is installed and available"
	exit 1
}

try {
	if ($Directory -eq "") {
		$Directory = "$PWD"
	}
	$Files = get-childItem -path $Directory
	foreach ($File in $Files) {
		if ($File.Mode -like "d*") {
			$Filename = $File.Name
			write-host ""
			write-host -nonewline "Updating $Filename ..."
			set-location $Filename
			& git pull --recurse-submodules
			set-location ..
		} 
	}
	exit 0
} catch {
	write-error "ERROR: line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
