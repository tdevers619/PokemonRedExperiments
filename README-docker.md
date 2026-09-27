# Running in Docker

Runs the pretrained agent (`baselines/run_pretrained_interactive.py`) in a container. The game window is shown in your browser through noVNC, and you can switch between the agent playing and you playing.

Commands below are for PowerShell on the Windows server, run from the `PokemonRedExperiments` folder.

## 1. Prerequisites

- **Docker Desktop** with the WSL 2 based engine turned on (Settings → General).
- **GPU only:** an NVIDIA driver installed on Windows. Check with `nvidia-smi`. Docker Desktop passes the GPU through WSL 2, so nothing else is needed.
- **The ROM:** your own copy of Pokémon Red, placed in this folder and named exactly `PokemonRed.gb`:

  ```powershell
  Rename-Item "Pokemon - Red Version (USA, Europe) (SGB Enhanced).gb" PokemonRed.gb
  ```

- **The toggle file:** `baselines\agent_enabled.txt` must exist before you start the container:

  ```powershell
  Set-Content baselines\agent_enabled.txt no
  ```

## 2. Build the image

Pick one. Rebuild whenever you change anything in `baselines\`, `requirements-docker.txt` or the `Dockerfile`.

```powershell
# CPU only (smaller image)
docker build -t pokemon-red .

# With GPU support (about 2 GB larger)
docker build --build-arg DEVICE=gpu -t pokemon-red-gpu .
```

To check that the GPU image can see the GPU:

```powershell
docker run --rm --gpus all --entrypoint python pokemon-red-gpu -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

It should print `True NVIDIA GeForce GTX 1070`.

## 3. Start the container

```powershell
# CPU
docker run -d --name pokemon -p 127.0.0.1:6080:6080 -v "${PWD}/PokemonRed.gb:/app/PokemonRed.gb:ro" -v "${PWD}/baselines/agent_enabled.txt:/app/baselines/agent_enabled.txt" pokemon-red

# GPU
docker run -d --name pokemon --gpus all -p 127.0.0.1:6080:6080 -v "${PWD}/PokemonRed.gb:/app/PokemonRed.gb:ro" -v "${PWD}/baselines/agent_enabled.txt:/app/baselines/agent_enabled.txt" pokemon-red-gpu
```

Check that it started. You should see `loading checkpoint` and then reward output, with no traceback:

```powershell
docker logs -f pokemon
```

Press Ctrl+C to stop following the log. The container keeps running.

## 4. Watch and play

**On the server:** open <http://localhost:6080/vnc.html> and click **Connect**.

**From another PC:** the viewer has no password, so it only listens on the server itself. Reach it through an SSH tunnel. This needs the OpenSSH Server feature enabled on the Windows server.

```powershell
ssh -L 6080:localhost:6080 you@your-server
```

Leave that window open, then browse to <http://localhost:6080/vnc.html> on your PC.

**Switch between the agent and you:**

```powershell
Set-Content baselines\agent_enabled.txt yes   # agent plays
Set-Content baselines\agent_enabled.txt no    # you play (click in the game window, use the keyboard)
```

Use `Set-Content` rather than `echo yes > ...`. In Windows PowerShell, `>` writes UTF-16, and the script won't read it as `yes`.

## 5. Stop, restart, clean up

```powershell
docker stop pokemon          # stop
docker start pokemon         # start again
docker rm -f pokemon         # remove (needed before running step 3 again)
```

## Training (optional)

To run a training script instead, put the script name at the end of the command:

```powershell
docker run -d --name pokemon-train --gpus all -v "${PWD}/PokemonRed.gb:/app/PokemonRed.gb:ro" pokemon-red-gpu python run_baseline_parallel_fast.py
```

Checkpoints are saved inside the container and are lost when it is removed. Copy them out before running `docker rm`:

```powershell
docker cp pokemon-train:/app/baselines/. .\training-output
```

Each parallel emulator (`num_cpu` in the script) uses one CPU core.

## Troubleshooting

| Error | Fix |
|---|---|
| `load metadata for docker.io/library/python` | Docker can't reach Docker Hub. Run `docker pull python:3.10-slim` to see the full error. |
| `ROM file ../PokemonRed.gb was not found` | The ROM isn't named `PokemonRed.gb`, or you ran `docker run` from a different folder. If Docker created an empty `PokemonRed.gb` folder, delete it and rename the ROM. |
| `The container name "/pokemon" is already in use` | `docker rm -f pokemon`, then run again. |
| `ModuleNotFoundError` when loading the checkpoint | Add the package to `requirements-docker.txt` and rebuild. |
| GPU check prints `False` | Make sure Docker Desktop uses the WSL 2 engine, you built with `DEVICE=gpu`, and you passed `--gpus all`. |
