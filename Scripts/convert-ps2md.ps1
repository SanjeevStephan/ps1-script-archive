﻿<#
.SYNOPSIS
	Converts a PowerShell script to Markdown
.DESCRIPTION
	This PowerShell script converts the comment-based help of a PowerShell script to Markdown.
.PARAMETER filename
	Specifies the path to the PowerShell script
.EXAMPLE
	PS> ./convert-ps2md myscript.ps1
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

param([string]$filename = "")

function EncodePartOfHtml { param([string]$Value)
    ($Value -replace '<', '&lt;') -replace '>', '&gt;'
}

function GetCode { param($Example)
    $codeAndRemarks = (($Example | Out-String) -replace ($Example.title), '').Trim() -split "`r`n"

    $code = New-Object "System.Collections.Generic.List[string]"
    for ($i = 0; $i -lt $codeAndRemarks.Length; $i++) {
        if ($codeAndRemarks[$i] -eq 'DESCRIPTION' -and $codeAndRemarks[$i + 1] -eq '-----------') { break }
        if ($codeAndRemarks[$i] -eq '' -and $codeAndRemarks[$i + 1] -eq '') { continue }
        if (1 -le $i -and $i -le 2) { continue }
    	$codeAndRemarks[$i] = ($codeAndRemarks[$i] | Out-String) -replace "PS>","PS> "
        $code.Add($codeAndRemarks[$i])
    }

    $code -join "`r`n"
}

function GetRemark { param($Example)
    $codeAndRemarks = (($Example | Out-String) -replace ($Example.title), '').Trim() -split "`r`n"

    $isSkipped = $false
    $remark = New-Object "System.Collections.Generic.List[string]"
    for ($i = 0; $i -lt $codeAndRemarks.Length; $i++) {
        if (!$isSkipped -and $codeAndRemarks[$i - 2] -ne 'DESCRIPTION' -and $codeAndRemarks[$i - 1] -ne '-----------') {
            continue
        }
        $isSkipped = $true
        $remark.Add($codeAndRemarks[$i])
    }

    $remark -join "`r`n"
}

try {
	if ($filename -eq "") { $filename = Read-Host "Enter path to PowerShell script" }
	$ScriptName = (Get-Item "$filename").Name

	$full = Get-Help $filename -Full 

	"## Script: *$($ScriptName)*"

	$Description = ($full.description | Out-String).Trim()
	if ($Description -ne "") {
		""
		"$Description"
	} else {
		""
		"$($full.Synopsis)"
	}
	""
	"## Parameters"
	"``````powershell"
	$Syntax = (($full.syntax | Out-String) -replace "`r`n", "`r`n").Trim()
	$Syntax = (($Syntax | Out-String) -replace "/home/mf/Repos/PowerShell/Scripts/", "")
	if ($Syntax -ne "") {
		"$Syntax"
	}

	foreach($parameter in $full.parameters.parameter) {
		"$(((($parameter | Out-String).Trim() -split "`r`n")[-5..-1] | % { $_.Trim() }) -join "`r`n")"
		""
	}
	"[<CommonParameters>]"
	"    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, "
	"    WarningVariable, OutBuffer, PipelineVariable, and OutVariable."
	"``````"

	foreach($input in $full.inputTypes.inputType) {
		""
		"## Inputs"
		"$($input.type.name)"
	}

	foreach($output in $full.outputTypes.outputType) {
		""
		"## Outputs"
		"$($output.type.name)"
	}

	foreach($example in $full.examples.example) {
		""
		"## Example"
		"``````powershell"
		"$(GetCode $example)"
		"``````"
	}

	$Notes = ($full.alertSet.alert | Out-String).Trim()
	if ($Notes -ne "") {
		""
		"## Notes"
		"$Notes"
	}

	$Links = ($full.relatedlinks | Out-String).Trim()
	if ($Links -ne "") {
		""
		"## Related Links"
		"$Links"
	}

	""
	"## Script Content"
	"``````powershell"
	$Lines = Get-Content -path "$filename"
        foreach($Line in $Lines) {
		"$Line"
	}
	"``````"
	""
	$now = [datetime]::Now
	"*(generated by convert-ps2md.ps1 using the comment-based help of $ScriptName as of $now)*"
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
        exit 1
}
