$source = Get-Content (Join-Path $PSScriptRoot 'bookmarklet.js') -Raw
$minified = ($source -replace '(?m)^\s+', '' -replace '\r?\n', ' ' -replace '\s{2,}', ' ').Trim()
'javascript:' + $minified
