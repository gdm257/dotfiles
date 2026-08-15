# Stateless Project

| State                       | Source of Truth           | Backup                            | Is Elegant |
| --------------------------- | ------------------------- | --------------------------------- | ---------- |
| Applications (Linux)        | home-manager, pkg, x-cmd  | public registry                   | yes        |
| Applications (Windows)      | scoop, winget, chocolatey | public registry                   | yes        |
| Applications (Android)      | obtainium                 | public registry                   | yes        |
| Applications (JS)           | mise                      | npmjs.org                         | yes        |
| Applications (Python)       | mise                      | pypi                              | yes        |
| Games                       | playnite, scoop           | steam, epic, gog, itch, scoop-lfs | yes        |
| Mods                        | mo2, vortex               | nexus                             | yes        |
| Models                      | TODO                      | hugging face                      |            |
| Datasets                    | TODO                      | dolthub, hugging face             |            |
| Bangumi                     | bangumi-data, TODO        | bgm.tv                            |            |
| ACG                         | 115                       | 123, guangya                      | no         |
| Applications Configurations | dotfiles                  | -                                 | yes        |
| Applications Cache          | kopia                     | -                                 | yes        |
| Dotfiles (this repo)        | git                       | -                                 | yes        |
| Saves                       | steam, ludusavi           | kopia                             | yes        |
| Bangumi                     | online                    | TODO                              |            |
| Bilibili                    | online                    | TODO                              |            |
| Pixiv                       | online                    | TODO                              |            |
| DAVx5                       | vcard, caldav             | -                                 | yes        |
| EHentai                     | online                    | venera                            | yes        |
| Joplin                      | webdav                    | -                                 | yes        |
| Kazumi                      | webdav                    | -                                 | yes        |
| Legado                      | webdav                    | -                                 | yes        |
| MGit                        | git                       | -                                 | yes        |
| Obsidian                    | git                       | -                                 | yes        |
| Obtainium                   | s3                        | -                                 | yes        |
| PicHoro                     | TODO                      |                                   |            |
| Playnite                    | TODO                      |                                   |            |
| Kopia                       | webdav                    | -                                 | yes        |
| PureWriter                  | webdav                    | -                                 | yes        |
| Venera                      | webdav                    | -                                 | yes        |
| `caldav://`                 | disroot                   | TODO                              |            |
| `git://`                    | github                    | TODO                              |            |
| `mail://`                   | disroot                   | TODO                              |            |
| `mysql://`                  | tidb, sqlpub              | gobackup, databasement            | yes        |
| `postgres://`               | aiven, neon               | gobackup, databasement            | yes        |
| `redis://`                  | aiven                     | gobackup, databasement            | yes        |
| `s3://`                     | cloudflare                | -                                 | yes        |
| `vcard://`                  | disroot                   | github actions                    | yes        |
| `webdav://`                 | filelu, koofr, 123        | -                                 | yes        |

# Dotfiles

## Common

```
# Windows Activation
Set-ExecutionPolicy Bypass -Scope Process -Force
irm https://get.activated.win | iex

# mise (Linux)
curl https://mise.run | sh

# mise (choco)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install mise

# mise (winget)
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
winget install jdx.mise

# mise (scoop)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm get.scoop.sh | iex # scoop
scoop install mise

# mise
cd <repo>/
mise trust
mise install
mise activate
```

## Recover

```powershell
dotbot -v -c ./dotbot.registry.yaml
dotbot -v -c ./dotbot.once.lib.yaml
dotbot -v -c ./dotbot.links.yaml
```

## From Scratch

```powershell
dotbot -v -c ./dotbot.registry.yaml
dotbot -v -c ./dotbot.once.lib.yaml
dotbot -v -c ./dotbot.links.yaml
```

## Optional Installation

```powershell
powershell -c "irm bun.com/install.ps1 | iex" # bun
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex" # uv
```

# Command-line cheatsheet

There are many tools to take note for command-line:

- Blog (e.g. Medium, Wordpress, Hexo)
- Note-taking application (e.g. Notion, Obsidian, VNote)
- Code snippets (e.g. VSCode snippets, IDEA snippets, GitHub gist)
- Cheatsheet tool (e.g. navi, cheat, tldr)
- Task runner (e.g. just, task, make)

After thousands of notes, I realize **task runner** is the best choice for **CLI**. Finally I choose [task](https://taskfile.dev/), a YAML-based task runner, which has excellent cross-platform experience and powerful features.

> [!TIP]
> It's allowed to write sensitive environment variables to `.local.env` file that taskfile auto reads.
