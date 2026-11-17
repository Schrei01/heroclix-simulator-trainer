[CmdletBinding()]
param(
    [ValidateSet('debug', 'release')][string]$Mode = 'debug',
    [switch]$SkipBuild,
    [string]$FlutterExecutable
)

$ErrorActionPreference = 'Stop'
$Mode = $Mode.ToLowerInvariant()
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$buildRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot 'build'))
$releaseRoot = [IO.Path]::GetFullPath((Join-Path $buildRoot 'releases'))
if (-not $releaseRoot.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'La carpeta de APK está fuera del proyecto.'
}
foreach ($directory in @($buildRoot, $releaseRoot)) {
    if ((Test-Path -LiteralPath $directory) -and
        ((Get-Item -LiteralPath $directory -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "La carpeta de APK no puede pasar por un enlace: $directory"
    }
}

$spec = [IO.File]::ReadAllText((Join-Path $projectRoot 'pubspec.yaml'))
$version = [regex]::Match($spec, '(?m)^version:\s*(?<name>[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?)\+(?<build>[0-9]+)\s*$')
if (-not $version.Success) { throw 'No se encontró una versión válida en pubspec.yaml.' }
$properties = [IO.File]::ReadAllText((Join-Path $projectRoot 'android/gradle.properties'))
$identity = [regex]::Match($properties, '(?m)^appId=(?<id>[A-Za-z0-9_.]+)\s*$')
if (-not $identity.Success) { throw 'No se encontró appId en android/gradle.properties.' }
$versionName = $version.Groups['name'].Value
$versionCode = $version.Groups['build'].Value
$appId = $identity.Groups['id'].Value

if (-not $env:JAVA_HOME) {
    $jbr = Join-Path $env:ProgramFiles 'Android/Android Studio/jbr'
    if (Test-Path -LiteralPath $jbr) { $env:JAVA_HOME = $jbr }
}
if ($env:JAVA_HOME) { $env:Path = "$(Join-Path $env:JAVA_HOME 'bin');$env:Path" }

if (-not $SkipBuild) {
    if (-not $FlutterExecutable) {
        $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
        $FlutterExecutable = if ($flutterCommand) { $flutterCommand.Source } else {
            Join-Path $env:USERPROFILE 'develop/flutter/bin/flutter.bat'
        }
    }
    if (-not (Test-Path -LiteralPath $FlutterExecutable -PathType Leaf)) {
        throw 'No se encontró Flutter. Añádelo al PATH o usa -FlutterExecutable.'
    }
    Push-Location -LiteralPath $projectRoot
    try {
        & $FlutterExecutable --no-version-check build apk "--$Mode" --no-pub
        if ($LASTEXITCODE -ne 0) { throw 'La compilación falló. Se conservan los APK anteriores.' }
    } finally { Pop-Location }
}

$source = Join-Path $buildRoot "app/outputs/flutter-apk/app-$Mode.apk"
if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or (Get-Item -LiteralPath $source).Length -eq 0) {
    throw 'Falta el APK compilado. Se conservan las versiones anteriores.'
}
$sdkRoot = @($env:ANDROID_SDK_ROOT, $env:ANDROID_HOME, (Join-Path $env:LOCALAPPDATA 'Android/Sdk')) |
    Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ 'build-tools')) } | Select-Object -First 1
if (-not $sdkRoot) { throw 'No se encontró Android SDK para validar el APK.' }
$sdkTools = Get-ChildItem -LiteralPath (Join-Path $sdkRoot 'build-tools') -Directory |
    Where-Object { (Test-Path -LiteralPath (Join-Path $_.FullName 'aapt.exe')) -and (Test-Path -LiteralPath (Join-Path $_.FullName 'apksigner.bat')) } |
    Sort-Object { try { [version]$_.Name } catch { [version]'0.0' } } -Descending | Select-Object -First 1
if (-not $sdkTools) { throw 'Faltan aapt y apksigner en Android SDK.' }
$badging = (& (Join-Path $sdkTools.FullName 'aapt.exe') dump badging $source 2>&1) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'El APK no es válido. Se conservan los anteriores.' }
$packagePattern = "package: name='" + [regex]::Escape($appId) + "' versionCode='" + [regex]::Escape($versionCode) + "' versionName='" + [regex]::Escape($versionName) + "'"
if ($badging -notmatch $packagePattern) { throw 'Paquete o versión del APK no coinciden con el proyecto. Se conservan los anteriores.' }
$signature = & (Join-Path $sdkTools.FullName 'apksigner.bat') verify $source 2>&1
if ($LASTEXITCODE -ne 0) { throw 'La firma del APK no es válida. Se conservan los anteriores.' }

[IO.Directory]::CreateDirectory($releaseRoot) | Out-Null
$destination = [IO.Path]::GetFullPath((Join-Path $releaseRoot "teamfight-gridlab-$versionName-$Mode.apk"))
if ((Test-Path -LiteralPath $destination) -and
    ((Get-Item -LiteralPath $destination -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw 'El APK destino no puede ser un enlace.'
}
$partial = Join-Path $releaseRoot ('.apk-' + [guid]::NewGuid().ToString('N') + '.tmp')
$hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
try {
    Copy-Item -LiteralPath $source -Destination $partial
    if ((Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash -ne $hash) {
        throw 'La copia del APK no coincide. Se conservan los anteriores.'
    }
    Move-Item -LiteralPath $partial -Destination $destination -Force
} finally {
    if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force }
}

$removed = 0
$freedBytes = 0L
foreach ($previous in Get-ChildItem -LiteralPath $releaseRoot -Filter '*.apk' -File -Force) {
    $absolute = [IO.Path]::GetFullPath($previous.FullName)
    if ($absolute.Equals($destination, [StringComparison]::OrdinalIgnoreCase)) { continue }
    if (-not ([IO.Path]::GetDirectoryName($absolute).Equals($releaseRoot, [StringComparison]::OrdinalIgnoreCase))) {
        throw 'Se rechazó un archivo fuera de la carpeta de APK.'
    }
    $size = $previous.Length
    Remove-Item -LiteralPath $absolute -Force
    $removed++
    $freedBytes += $size
}
[pscustomobject]@{ Apk = $destination; Sha256 = $hash; Removed = $removed; FreedBytes = $freedBytes }
