# charter: 目的地与边界

Type: grilling
Status: resolved

## Question

这张图的终点交付物是什么、范围边界在哪？

## Answer

（建图会话与用户两轮 grilling 定稿）

- 交付物：一份 openspec change，schema 用 matt-pocock；图只产出决策，实现由后续 apply 会话执行。
- 「维护」与「开箱即用」共用同一套体系（manifest/模块复用），重装只是触发点之一。
- `reinstall/` 是临时名，与整条流水线一起更名为 `system/`（最终名在 01 号票定稿）。
- 单机；目标系统 Win10 + Win11 双版本。
- dotfiles 自身（D:/home 布局）落地不进图；flyoobe 集成不进图（前一会话已查明无交集）。
- 自封装镜像的保鲜（定期重打）算范围内，先记入 fog。
