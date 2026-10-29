# Pokémon Red RL: Command Cheat Sheet

Run everything from the `PokemonRedExperiments` folder in PowerShell. `PokemonRed.gb` must be in that folder.
On Linux/Azure, replace `${PWD}` with `$(pwd)`.

Container names: **`pokemon-train`** = training, **`pokemon`** = viewer.
Images: **`pokemon-red-gpu`** (GPU) or **`pokemon-red`** (CPU). Drop `--gpus all` when using the CPU image.

## 1. Setup and update

| Label | Command | When to use |
|---|---|---|
| UPDATE-CODE | `git pull` | Get the latest code from GitHub (branch `Pokemon-ML-Docker`) |
| BUILD-GPU | `docker build --build-arg DEVICE=gpu -t pokemon-red-gpu .` | First time, and after any code or requirements change |
| BUILD-CPU | `docker build -t pokemon-red .` | CPU-only image (smaller) |
| GPU-CHECK | `docker run --rm --gpus all --entrypoint python pokemon-red-gpu -c "import torch; print(torch.cuda.is_available())"` | Should print `True` |
| MAKE-OUTPUT | `New-Item -ItemType Directory -Force training-output` | Once, before the first training run |

## 2. Training (headless, no VNC)

| Label | Command | When to use |
|---|---|---|
| TRAIN-START | `docker run -d --name pokemon-train --gpus all -e NUM_CPU=8 -v "${PWD}/PokemonRed.gb:/app/PokemonRed.gb:ro" -v "${PWD}/training-output:/app/baselines/sessions" pokemon-red-gpu python run_baseline_parallel_fast.py` | Start training. Set `NUM_CPU` to at most your CPU core count |
| TRAIN-LOGS | `docker logs -f pokemon-train` | Watch progress (Ctrl+C stops following, not training) |
| TRAIN-STOP | `docker stop pokemon-train` | Stop training once you have a checkpoint |
| TRAIN-REMOVE | `docker rm -f pokemon-train` | Required before running TRAIN-START again |

Checkpoints are saved to `training-output\session_<id>\poke_<steps>_steps.zip`.

## 3. Viewing the agent through VNC

Open <http://localhost:6080/vnc.html> and click **Connect**.

| Label | Command | When to use |
|---|---|---|
| FIND-CKPT | `Get-ChildItem training-output -Recurse -Filter poke_*_steps.zip \| Sort-Object LastWriteTime -Descending \| Select-Object -First 1 FullName` | Find your newest checkpoint |
| SET-CKPT | `$ckpt = "training-output/session_<id>/poke_<steps>_steps.zip"` | Put the path from FIND-CKPT here (use forward slashes) |
| AGENT-OFF | `Set-Content baselines\agent_enabled.txt no` | Before starting the viewer, and to take over play yourself |
| WATCH-MINE | `docker run -d --name pokemon --gpus all -p 127.0.0.1:6080:6080 -v "${PWD}/PokemonRed.gb:/app/PokemonRed.gb:ro" -v "${PWD}/baselines/agent_enabled.txt:/app/baselines/agent_enabled.txt" -v "${PWD}/${ckpt}:/app/baselines/session_4da05e87_main_good/poke_439746560_steps.zip:ro" pokemon-red-gpu` | View **your** trained checkpoint (run SET-CKPT first) |
| WATCH-PRETRAINED | `docker run -d --name pokemon --gpus all -p 127.0.0.1:6080:6080 -v "${PWD}/PokemonRed.gb:/app/PokemonRed.gb:ro" -v "${PWD}/baselines/agent_enabled.txt:/app/baselines/agent_enabled.txt" pokemon-red-gpu` | View the pretrained model that ships with the repo |
| AGENT-ON | `Set-Content baselines\agent_enabled.txt yes` | Let the agent play |
| WATCH-LOGS | `docker logs pokemon` | Check for `loading checkpoint` and no traceback |
| WATCH-STOP | `docker stop pokemon` | Stop the viewer |
| WATCH-REMOVE | `docker rm -f pokemon` | Required before WATCH-MINE or WATCH-PRETRAINED again |

If your training output is on another drive, change `${PWD}/${ckpt}` to the full path, for example `D:/pokemon/training-output/session_<id>/poke_<steps>_steps.zip`.

## 4. Monitoring

| Label | Command | When to use |
|---|---|---|
| CONTAINERS | `docker ps -a` | See what's running or stopped |
| CPU-MEM | `docker stats` | Live CPU and memory use per container |
| GPU-USE | `nvidia-smi` | Check the GPU is in use |
| DISK-DOCKER | `docker system df` | Space used by images, containers and cache |
| DISK-OUTPUT | `"{0:N2} GB" -f ((Get-ChildItem training-output -Recurse -File \| Measure-Object Length -Sum).Sum / 1GB)` | Size of the training output folder |
| DISK-FREE | `Get-PSDrive C` | Free space on the C: drive |

## 5. Cleanup

| Label | Command | When to use |
|---|---|---|
| PRUNE | `docker system prune` | Remove unused containers, networks and dangling images |
| PRUNE-CACHE | `docker builder prune` | Clear the image build cache |
| DELETE-OLD-CKPT | Delete old `poke_*_steps.zip` files in `training-output\` | Keep the newest few; training never deletes them |

## Typical workflows

**Train, then watch:** UPDATE-CODE → BUILD-GPU → MAKE-OUTPUT → TRAIN-START → TRAIN-LOGS → TRAIN-STOP → FIND-CKPT → SET-CKPT → AGENT-OFF → WATCH-REMOVE → WATCH-MINE → open the URL → AGENT-ON

**Retrain after a code change:** UPDATE-CODE → BUILD-GPU → TRAIN-REMOVE → TRAIN-START
