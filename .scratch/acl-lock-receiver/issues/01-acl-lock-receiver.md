# 01: acl:lock receiver 与 manifests:lockdown:apply

Status: resolved

## Checklist

- [x] `taskfile.d/receivers.yaml` 新增 `acl:lock`：kind 自验证 `acl-lock`、admin/路径守卫、powershell 固定配方（protect 清空 + S-1-5-18/S-1-5-32-544 ReadAndExecute + owner SYSTEM）、converge 读-比-跳过
- [x] `manifests/lockdown.yaml` 新建（初始空 items，含注释模板）
- [x] `taskfile.yaml` 新增 `manifests:lockdown:apply` wrapper（platforms 限 windows，`acl-lock=acl:lock`）
- [x] `fixtures/manifest-dispatch/check-receivers.sh` 补 acl:lock 拼装/守卫/kind 断言并纳入 precedence 循环
- [x] fixture 套件全绿

## Answer

receiver/manifest/wrapper/fixture 全部落地；check-receivers.sh 34 项 PASS、check-dispatch.sh 30 场景 PASS。powershell 配方经 PSParser 语法校验零错误；真实 ACL 生效（管理员 + 真实目录锁定与重复运行跳过）留作一次性手工验收。

## Comments

- code-review 后收紧：converge 校验 ACE 主体与数量（恰为 SYSTEM/Admins 两条），路径守卫 `-e` 改 `-d`。

