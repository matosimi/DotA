<#
   ========================================================================================================================
   Name         : _zx7levels.ps1
   Description  : compresses all the levels with zx7
   Created Date : 19.07.2023
   Created By   : MatoSimi
   Dependencies : 1) Windows PowerShell 5.1
                  2) zx7mini.exe

   Revision History
   Date       Release  Change By      Description
   19.7.2023  1.0      MatoSimi       Initial Release
   ========================================================================================================================
#>

for ($j = 0; $j -lt 5;$j++)
{
	for ($i = 0; $i -lt 4;$i++)
	{
		$twodigit = "{0:d2}" -f ($i+10*$j) 
		$src = "..\lev" + $twodigit + ".dat"
		$dst = "lev" + $twodigit + ".dat.zx7"
		Write-Output $dst
		..\..\tools\zx7mini.exe $src $dst
	}
}
