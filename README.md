# Pokémon Red Reinforcement Learning in Docker

Train a reinforcement learning agent to play Pokémon Red, and watch it play from your browser. This is a containerized version of the open-source [PokemonRedExperiments](https://github.com/PWhiddy/PokemonRedExperiments) project by Peter Whidden.

<!-- TODO: add a screenshot or short clip of your own run, e.g. ![Agent playing](assets/my-run.gif) -->

## What this adds

The original project is a research codebase that has to be set up by hand on each machine. This version packages it so it runs the same way anywhere Docker runs:

- **Dockerfile** with CPU and GPU builds, selected by a build argument (`DEVICE=cpu` or `DEVICE=gpu`).
- **Browser-based viewer.** The emulator runs on a virtual display (Xvfb) and is streamed to a web page with x11vnc and noVNC, so no desktop is needed on the host. This works over an SSH tunnel to a remote server.
- **Agent/human switch.** A toggle file lets you hand control between the trained agent and the keyboard while the game is running.
- **Persistent training output.** Checkpoints and logs are written to a mounted volume so they survive container removal.
- **Configurable parallelism.** The number of parallel emulators is set with the `NUM_CPU` environment variable.
- **Fixes** for the training script, which no longer crashed on startup, and a clean restart of the display after `docker start`.

## How it works

Training runs many Game Boy emulators in parallel ([PyBoy](https://github.com/Baekalfen/PyBoy)) and optimizes a policy with PPO from [Stable Baselines 3](https://github.com/DLR-RM/stable-baselines3). The agent sees the game screen plus a few memory-derived values, and is rewarded for exploring new areas and for in-game progress. Emulation is CPU-bound, so core count sets training speed. A GPU speeds up the PPO update step.

Two entry points matter:

| Script | What it does |
|---|---|
| `baselines/run_baseline_parallel_fast.py` | Headless training with many emulators. Writes checkpoints to `sessions/`. |
| `baselines/run_pretrained_interactive.py` | Loads a checkpoint and plays one visible game, shown through the browser viewer. |

## Quick start

You need Docker, and your own legally obtained copy of Pokémon Red named `PokemonRed.gb` in the repository root. **The ROM is not included and is excluded by `.gitignore`.** The commands below are for PowerShell; use `$(pwd)` instead of `${PWD}` on Linux.

```powershell
git clone https://github.com/tdevers619/PokemonRedExperiments.git
cd PokemonRedExperiments
# copy PokemonRed.gb into this folder, then:
docker build --build-arg DEVICE=gpu -t pokemon-red-gpu .    # or: docker build -t pokemon-red .
```

### Train

```powershell
New-Item -ItemType Directory -Force training-output
docker run -d --name pokemon-train --gpus all -e NUM_CPU=8 `
  -v "${PWD}/PokemonRed.gb:/app/PokemonRed.gb:ro" `
  -v "${PWD}/training-output:/app/baselines/sessions" `
  pokemon-red-gpu python run_baseline_parallel_fast.py
docker logs -f pokemon-train
```

Set `NUM_CPU` to no more than your number of CPU cores. Checkpoints appear in `training-output/session_<id>/`.

### Watch the agent play

```powershell
Set-Content baselines\agent_enabled.txt no
docker run -d --name pokemon --gpus all -p 127.0.0.1:6080:6080 `
  -v "${PWD}/PokemonRed.gb:/app/PokemonRed.gb:ro" `
  -v "${PWD}/baselines/agent_enabled.txt:/app/baselines/agent_enabled.txt" `
  pokemon-red-gpu
```

Open <http://localhost:6080/vnc.html> and click **Connect**. Switch control with `Set-Content baselines\agent_enabled.txt yes` (agent plays) or `no` (you play). Omit `--gpus all` if you built the CPU image.

Full instructions, including loading your own checkpoint, SSH tunneling and troubleshooting, are in [README-docker.md](README-docker.md).

## Repository layout

| Path | Contents |
|---|---|
| `Dockerfile`, `docker-entrypoint.sh`, `requirements-docker.txt` | Container build and startup |
| `README-docker.md` | Detailed Docker guide and troubleshooting |
| `baselines/` | Training and playback scripts used by the Docker image |
| `v2/` | Newer training script from the upstream project (not yet supported in the Docker image) |
| `visualization/` | Map visualization code from upstream |

## Results

<!-- TODO: add what you trained and what the agent achieved, e.g. hardware used, training time, how far the agent got, and a TensorBoard screenshot. -->

## Credits and license

This project is built on [PWhiddy/PokemonRedExperiments](https://github.com/PWhiddy/PokemonRedExperiments) by Peter Whidden and contributors, released under the MIT license (see [LICENSE](LICENSE)). The reinforcement learning code, environments and pretrained model come from that project. The Docker packaging, viewer setup and related fixes in this repository are my additions.

Pokémon is a trademark of Nintendo, Game Freak and Creatures Inc. This project is not affiliated with them and does not distribute any game files.
