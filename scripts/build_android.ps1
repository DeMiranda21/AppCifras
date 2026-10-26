param(
    [ValidateSet('debug', 'profile', 'release')]
    [string]$Mode = 'debug',
    [string]$LibraryBaseUrl = 'https://pub-7cef19f80f2849fd9474b90a55aadf2b.r2.dev',
    [string[]]$AdditionalArguments = @()
)

$commit = (& git rev-parse --short HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commit)) {
    throw 'Não foi possível obter o commit Git atual.'
}

$worktreeStatus = & git status --porcelain
if ($LASTEXITCODE -ne 0) {
    throw 'Não foi possível verificar o estado do worktree.'
}
if ($worktreeStatus) {
    $commit = "$commit-dirty"
}

& flutter build apk "--$Mode" `
    "--dart-define=APP_GIT_COMMIT=$commit" `
    "--dart-define=APPCIFRAS_LIBRARY_BASE_URL=$LibraryBaseUrl" `
    @AdditionalArguments
exit $LASTEXITCODE
