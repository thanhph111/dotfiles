from dataclasses import dataclass
from pathlib import Path
import subprocess

LINUX_IMAGE = "dotfiles-tests-linux:latest"
PWSH_IMAGE = "dotfiles-tests-pwsh:latest"
PWSH_PLATFORM = "linux/amd64"


@dataclass
class DockerRunner:
    repo_root: Path
    artifact_dir: Path
    verbose: bool = False

    def _run(
        self, cmd: list[str], check: bool = False, env: dict[str, str] | None = None
    ) -> subprocess.CompletedProcess[str]:
        proc = subprocess.run(
            cmd, cwd=self.repo_root, text=True, capture_output=True, check=False, env=env
        )
        if check and proc.returncode != 0:
            raise RuntimeError(
                f"Command failed ({proc.returncode}): {' '.join(cmd)}\nSTDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}"
            )
        return proc

    def require_docker(self) -> None:
        self._run(["docker", "info"], check=True)

    def ensure_image(self, image: str, dockerfile: Path) -> None:
        inspect_proc = self._run(["docker", "image", "inspect", image])
        if inspect_proc.returncode == 0:
            return

        self._run(
            ["docker", "build", "-t", image, "-f", str(dockerfile), str(self.repo_root)], check=True
        )

    def run_container(
        self,
        image: str,
        container_cmd: list[str],
        env: dict[str, str] | None = None,
        platform: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        cmd = ["docker", "run", "--rm", "-v", f"{self.repo_root}:/repo", "-w", "/repo"]

        if platform:
            cmd += ["--platform", platform]

        for key, value in (env or {}).items():
            cmd += ["-e", f"{key}={value}"]

        cmd += [image, *container_cmd]
        return self._run(cmd)

    def run_bash(
        self,
        image: str,
        script: str,
        env: dict[str, str] | None = None,
        platform: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        return self.run_container(
            image=image, container_cmd=["bash", "-lc", script], env=env, platform=platform
        )

    def run_pwsh(
        self,
        image: str,
        script: str,
        env: dict[str, str] | None = None,
        platform: str | None = PWSH_PLATFORM,
    ) -> subprocess.CompletedProcess[str]:
        return self.run_container(
            image=image,
            container_cmd=["pwsh", "-NoLogo", "-NoProfile", "-Command", script],
            env=env,
            platform=platform,
        )
