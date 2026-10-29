param([string]$Session, [string]$Image = "pokemon-red-gpu")

if (-not $Session) {
    $Session = (Get-ChildItem training-output -Directory -Filter "session_*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).Name
}
$ckpt = (Get-ChildItem "training-output\$Session" -Filter "poke_*_steps.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
if (-not $ckpt) { Write-Error "No checkpoint found in $Session"; exit 1 }

Set-Content baselines\agent_enabled.txt no
docker rm -f pokemon 2>$null
docker run -d --name pokemon --gpus all -p 127.0.0.1:6080:6080 -v "${PWD}/PokemonRed.gb:/app/PokemonRed.gb:ro" -v "${PWD}/baselines/agent_enabled.txt:/app/baselines/agent_enabled.txt" -v "${ckpt}:/app/baselines/session_4da05e87_main_good/poke_439746560_steps.zip:ro" $Image
Write-Host "Viewing $ckpt at http://localhost:6080/vnc.html"