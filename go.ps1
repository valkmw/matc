
# URL publica do MAS no GitHub
$url = "https://raw.githubusercontent.com/valkmw/matc/refs/heads/main/MAS_AIO.cmd"

$ErrorActionPreference = "Stop"

# Verificar privilegios antes de iniciar
# Evita tentar abrir uma janela UAC durante uma sessao SSH
fltmc.exe *> $null

if ($LASTEXITCODE -ne 0) {
    throw "Esta sessao precisa ter privilegios administrativos."
}

# Criar caminho temporario
$arquivo = Join-Path $env:TEMP (
    "MAS_" + [guid]::NewGuid().ToString("N") + ".cmd"
)

try {
    Write-Host "Baixando MAS..."

    Invoke-WebRequest `
        -Uri $url `
        -OutFile $arquivo `
        -UseBasicParsing

    # Exibir hash para verificacao
    $hash = (Get-FileHash $arquivo -Algorithm SHA256).Hash
    Write-Host "SHA256: $hash"

    Write-Host "Executando no terminal atual..."

    # Sem Start-Process e sem criar janela pelo iniciador
    & $arquivo

    $codigo = $LASTEXITCODE

    Write-Host "Processo encerrado. Codigo: $codigo"
}
finally {
    # Limpeza do arquivo temporario
    Remove-Item $arquivo -Force -ErrorAction SilentlyContinue
}
