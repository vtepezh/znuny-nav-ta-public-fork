# NavTA – Router/Cluster Provisioning UI for Znuny 7.3.2 + ITSM/CMDB

Custom agent UI (separate from the ticket view) for documenting the provisioning of
customer routers/clusters. Built as a **Znuny package (OPM)**, not as a core patch,
so it survives Znuny updates and installs on production via the Package Manager.

This repository is a fork of `znuny/Znuny`. Branch `nav-ta-7.3.2` is based on tag
`rel-7_3_2`; the Znuny core files serve as reference only. All custom code lives in `NavTA/`.

## Layout

```
NavTA/
  NavTA.sopm                     package definition (version, dependencies, file list)
  Kernel/Config/Files/XML/       SysConfig: module registration, navigation
  Kernel/Modules/                frontend controller(s)   (AgentNavTA.pm)
  Kernel/Output/HTML/Templates/  templates (.tt)
  dev/navta.sh                   deploy helper (sync/build/install)
```

Every new file must be listed in `<Filelist>` of `NavTA.sopm`.

## Target environment

| Component | Version |
|---|---|
| Znuny | 7.3.2 |
| ITSM bundle | 7.3.2 (ITSMCore 7.3.4, ITSMConfigurationManagement 7.3.5, GeneralCatalog 7.3.2, ImportExport 7.3.3, ...) |

## Workflow: develop → test → production

### One-time setup on the local test instance
```bash
sudo apt install git rsync
git clone https://github.com/vtepezh/znuny-nav-ta.git --branch nav-ta-7.3.2 --depth 1 /opt/src/znuny-nav-ta
```

### Dev loop (fast, seconds)
1. Edit code (locally in your editor, or directly on the test host via VS Code Remote-SSH).
2. `git push` from your workstation, `git pull` on the test host (skip if editing via Remote-SSH).
3. `sudo /opt/src/znuny-nav-ta/NavTA/dev/navta.sh sync`
   – copies the files from the .sopm filelist into `/opt/znuny`, rebuilds SysConfig,
   clears the cache and reloads Apache.
4. Reload `index.pl?Action=AgentNavTA` in the browser.

### Release test (production-like)
1. Bump `<Version>` in `NavTA.sopm`, commit, tag (`git tag v0.2.0`).
2. On the test host: `sudo ./dev/navta.sh remove` (only if files were synced before), then
   `sudo ./dev/navta.sh install` – builds `dist/NavTA-<version>.opm` and installs/upgrades it.
3. Verify. Then install the same `.opm` on production via
   *Admin → Package Manager* or `bin/znuny.Console.pl Admin::Package::Upgrade NavTA-x.y.z.opm`.

> Don't mix both modes on the same instance: files installed by the package manager are
> tracked; files placed by `sync` are not. Use `remove`/`uninstall` when switching.

### Rollback
`sudo ./dev/navta.sh uninstall` (package) or `sudo ./dev/navta.sh remove` (synced files).
