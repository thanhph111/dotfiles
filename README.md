# Dotfiles

## Windows

On _Windows_, we don't have _Git_ and _Python_ preinstalled. Fortunately, _winget_ is available to install them:

```powershell
winget install --exact --id=Python.Python.3.10
winget install --exact --id=Git.Git
```

_Windows_ also packed an _OpenSSH_ client (from _Windows Server_ 2019 or _Windows_ 10 build 1809), which is enough to set up an SSH key for _GitHub_ and clone the repository.

We also use _winget_ to install several other programs, but it needs to be run separately as the installation script need privilege elevation, which is prohibited by _winget_.

After cloning, go to the repository directory and run the command:

```powershell
winget import --import-file .\dotfiles\winget\packages.json
```

Reopen _PowerShell_ as administrator, and run the following commands from the root of the repository to install the rest of the dotfiles:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\Install-Dotfiles.ps1 -Profile windows
```
