param(
	[Parameter(Mandatory = $true)]
	[ValidatePattern('^v[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$')]
	[string]$Tag,
	[string]$ChangelogPath = (Join-Path $PSScriptRoot '../../docs/changelog.md'),
	[string]$PluginConfigPath = (Join-Path $PSScriptRoot '../../addons/blockout_tools/plugin.cfg'),
	[Parameter(Mandatory = $true)]
	[string]$OutputPath
)
$ErrorActionPreference = 'Stop'
$plugin = Get-Content -LiteralPath $PluginConfigPath -Raw -Encoding utf8
$version = [regex]::Match($plugin, '(?m)^version="(?<version>[^"]+)"\s*$')
if (!$version.Success -or $version.Groups['version'].Value -cne $Tag.Substring(1)) {
	throw "The committed plugin version must match $Tag."
}

$changelog = (Get-Content -LiteralPath $ChangelogPath -Raw -Encoding utf8).Replace("`r`n", "`n")
# Only level-two headings delimit releases; language headings remain in the body.
$sections = [regex]::Matches($changelog, '(?m)^## (?<heading>[^\n]+)$')
$tagPattern = '^\[' + [regex]::Escape($Tag) + '\] - (?<date>[0-9]{4}-[0-9]{2}-[0-9]{2})$'
$matchingSections = @($sections | Where-Object { $_.Groups['heading'].Value -cmatch $tagPattern })
if ($matchingSections.Count -ne 1) {
	throw "Expected exactly one dated ## [$Tag] section in $ChangelogPath."
}
$section = $matchingSections[0]
$start = $section.Index + $section.Length
$end = $changelog.Length
foreach ($nextSection in $sections) {
	if ($nextSection.Index -gt $section.Index) {
		$end = $nextSection.Index
		break
	}
}
$notes = $changelog.Substring($start, $end - $start).Trim()
$languages = [regex]::Matches($notes, '(?m)^### (?<language>English|中文)[ \t]*$')
if ($languages.Count -ne 2 -or @($languages | Where-Object { $_.Groups['language'].Value -ceq 'English' }).Count -ne 1 -or @($languages | Where-Object { $_.Groups['language'].Value -ceq '中文' }).Count -ne 1) {
	throw "The $Tag summary must contain exactly one ### English and one ### 中文 section."
}
for ($index = 0; $index -lt $languages.Count; $index++) {
	$bodyStart = $languages[$index].Index + $languages[$index].Length
	$bodyEnd = if ($index + 1 -lt $languages.Count) { $languages[$index + 1].Index } else { $notes.Length }
	$body = $notes.Substring($bodyStart, $bodyEnd - $bodyStart)
	if ($body -notmatch '(?m)^- \S') {
		throw "The $Tag $($languages[$index].Groups['language'].Value) summary needs a non-empty bullet."
	}
}
[IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath), $notes + "`n", [Text.UTF8Encoding]::new($false))
Write-Host "Release notes exported for $Tag."
