# Installe (ou désinstalle) la traduction française d'Arco.
# Le texte original du jeu n'est pas redistribué : ce script le lit dans ton arco.exe,
# y ajoute le français, puis copie le résultat dans %APPDATA%\arco, que le jeu lit en priorité.
param(
    [string]$Jeu,                                         # chemin de arco.exe (sinon détecté via Steam)
    [string]$Destination = (Join-Path $env:APPDATA "arco"),
    [switch]$Desinstaller,
    [switch]$SansPause
)
$ErrorActionPreference = "Stop"
$Ici = Join-Path $PSScriptRoot "traduction"
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Sha = [System.Security.Cryptography.SHA1]::Create()

function Trouver-Jeu {
    $dossiers = @()
    $steam = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
    if ($steam) {
        $dossiers += $steam
        $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
        if (Test-Path $vdf) {
            foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $dossiers += $m.Groups[1].Value -replace '\\\\', '\'
            }
        }
    }
    foreach ($d in $dossiers) {
        $exe = Join-Path $d "steamapps\common\Arco\arco.exe"
        if (Test-Path $exe) { return $exe }
    }
    return $null
}

function Lire-Archive([string]$exe, [string[]]$noms) {
    # arco.exe = moteur LÖVE + archive zip collée à la fin. Les positions de l'archive sont
    # relatives à son propre début, ce que les outils zip de .NET refusent : lecture manuelle.
    $fs = [System.IO.File]::OpenRead($exe)
    try {
        $br = New-Object System.IO.BinaryReader($fs)
        $fin = [int][Math]::Min(65557, $fs.Length)
        $fs.Seek(-$fin, 'End') | Out-Null
        $buf = $br.ReadBytes($fin)
        $eocd = -1
        for ($i = $buf.Length - 22; $i -ge 0; $i--) {
            if ($buf[$i] -eq 0x50 -and $buf[$i + 1] -eq 0x4b -and $buf[$i + 2] -eq 5 -and $buf[$i + 3] -eq 6) { $eocd = $i; break }
        }
        if ($eocd -lt 0) { throw "archive du jeu introuvable dans $exe" }
        $posEocd = [long]$fs.Length - $fin + $eocd
        $nombre = [BitConverter]::ToUInt16($buf, $eocd + 10)
        $tailleCd = [long][BitConverter]::ToUInt32($buf, $eocd + 12)
        $debut = $posEocd - $tailleCd - [long][BitConverter]::ToUInt32($buf, $eocd + 16)
        $fs.Seek($posEocd - $tailleCd, 'Begin') | Out-Null
        $cd = $br.ReadBytes([int]$tailleCd)
        $res = @{}
        $p = 0
        for ($n = 0; $n -lt $nombre; $n++) {
            $methode = [BitConverter]::ToUInt16($cd, $p + 10)
            $taille = [BitConverter]::ToUInt32($cd, $p + 20)
            $lNom = [BitConverter]::ToUInt16($cd, $p + 28)
            $lAutres = [BitConverter]::ToUInt16($cd, $p + 30) + [BitConverter]::ToUInt16($cd, $p + 32)
            $local = [long][BitConverter]::ToUInt32($cd, $p + 42)
            $nom = [System.Text.Encoding]::UTF8.GetString($cd, $p + 46, $lNom)
            if ($noms -contains $nom) {
                $fs.Seek($debut + $local + 26, 'Begin') | Out-Null
                $saut = $br.ReadUInt16() + $br.ReadUInt16()
                $fs.Seek($saut, 'Current') | Out-Null
                $data = $br.ReadBytes([int]$taille)
                if ($methode -eq 8) {
                    $entree = New-Object System.IO.MemoryStream(, $data)
                    $deflate = New-Object System.IO.Compression.DeflateStream($entree, [System.IO.Compression.CompressionMode]::Decompress)
                    $sortie = New-Object System.IO.MemoryStream
                    $deflate.CopyTo($sortie)
                    $data = $sortie.ToArray()
                }
                $res[$nom] = $Utf8.GetString($data)
            }
            $p += 46 + $lNom + $lAutres
        }
        foreach ($nom in $noms) { if (-not $res.ContainsKey($nom)) { throw "$nom absent du jeu (version différente ?)" } }
        return $res
    } finally { $fs.Dispose() }
}

function Empreinte([string]$texte) {
    # doit rester identique à key_hash() de l'outil de traduction
    (([BitConverter]::ToString($Sha.ComputeHash($Utf8.GetBytes($texte))) -replace '-', '').Substring(0, 12)).ToLower()
}

function Lire-Tsv([string]$fichier) {
    # sensible à la casse ("Chest!" et "chest!" sont deux phrases différentes), contrairement à @{}
    $table = New-Object System.Collections.Specialized.OrderedDictionary([StringComparer]::Ordinal)
    foreach ($ligne in ([System.IO.File]::ReadAllLines($fichier, $Utf8) | Select-Object -Skip 1)) {
        if ($ligne) { $cle, $valeur = $ligne -split "`t", 2; $table[$cle] = $valeur }
    }
    return $table
}

$code = 0
try {
    $locale = Join-Path $Destination "locale"
    $image = Join-Path $Destination "assets\ui\combat\ambush.png"
    if ($Desinstaller) {
        if (Test-Path $locale) { Remove-Item $locale -Recurse -Force }
        if (Test-Path $image) { Remove-Item $image -Force }
        Write-Host "Traduction désinstallée. Tes sauvegardes n'ont pas été touchées." -ForegroundColor Green
    }
    else {
        if (-not $Jeu) { $Jeu = Trouver-Jeu }
        if (-not $Jeu -or -not (Test-Path $Jeu)) {
            $Jeu = (Read-Host "arco.exe introuvable automatiquement. Colle son chemin complet").Trim('"')
        }
        Write-Host "Jeu trouvé : $Jeu"
        $fichiers = Lire-Archive $Jeu @("locale/translations.csv", "locale/init.lua")

        $traduction = Lire-Tsv (Join-Path $Ici "traduction.tsv")
        $lignes = $fichiers["locale/translations.csv"].Split("`n")
        $entete = $lignes[0].Split("`t")
        $iEn = [Array]::IndexOf($entete, "en")
        $iFr = [Array]::IndexOf($entete, "fr")
        if ($iEn -lt 0 -or $iFr -lt 0) { throw "format de texte du jeu inattendu (mise à jour du jeu ?)" }

        $resultat = New-Object System.Collections.Generic.List[string]
        $resultat.Add($lignes[0])
        $total = 0; $traduites = 0
        for ($i = 1; $i -lt $lignes.Length; $i++) {
            if (-not $lignes[$i]) { continue }   # une ligne vide en plein fichier empêche le jeu de démarrer
            $cols = $lignes[$i].Split("`t")
            $total++
            $h = Empreinte $cols[$iEn]
            if ($traduction.Contains($h)) { $cols[$iFr] = $traduction[$h]; $traduites++ }
            $resultat.Add($cols -join "`t")
        }
        # phrases que le jeu assemble lui-même ("Pick " + nom) : ajoutées comme nouvelles lignes
        $ajouts = Lire-Tsv (Join-Path $Ici "phrases_ajoutees.tsv")
        foreach ($en in $ajouts.Keys) {
            $cols = New-Object string[] $entete.Length
            for ($k = 0; $k -lt $cols.Length; $k++) { $cols[$k] = "" }
            $cols[0] = "fr-extra"; $cols[$iEn] = $en; $cols[$iFr] = $ajouts[$en]
            $resultat.Add($cols -join "`t")
        }
        foreach ($ligne in $resultat) {
            if ($ligne.Split("`t").Length -ne $entete.Length) { throw "ligne malformée, installation annulée" }
        }

        $init = $fichiers["locale/init.lua"]
        $initFr = $init.Replace('-- "fr",', '"fr",')
        if ($initFr -eq $init) { throw "impossible d'activer le français dans le menu (mise à jour du jeu ?)" }

        New-Item -ItemType Directory -Force $locale | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $locale "translations.csv"), (($resultat -join "`n") + "`n"), $Utf8)
        [System.IO.File]::WriteAllText((Join-Path $locale "init.lua"), $initFr, $Utf8)
        Copy-Item (Join-Path $Ici "*.fr.srt") $locale -Force
        New-Item -ItemType Directory -Force (Split-Path $image) | Out-Null
        Copy-Item (Join-Path $Ici "ambush.png") $image -Force

        Write-Host "Traduction installée : $traduites lignes traduites sur $total." -ForegroundColor Green
        if ($traduites -lt $total) { Write-Host "Certaines lignes resteront en anglais (version du jeu différente de celle traduite)." -ForegroundColor Yellow }
        Write-Host "Dans le jeu : Options > Locale > French / Français."
    }
}
catch {
    Write-Host "ERREUR : $($_.Exception.Message)" -ForegroundColor Red
    $code = 1
}
if (-not $SansPause) { Read-Host "Appuie sur Entrée pour fermer" | Out-Null }
exit $code
