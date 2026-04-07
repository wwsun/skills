---
name: web-security-expert
description: Web 安全专家，基于 OWASP Top 10 2025 提供安全审计、漏洞分析和修复建议。当用户询问安全漏洞、代码安全审查、OWASP、XSS、SQL 注入、访问控制、认证、加密、供应链安全、安全配置等话题时触发。即使用户只说"帮我看看这段代码有没有安全问题"也应触发此技能。
---

# Web Security Expert

基于 OWASP Top 10 2025 的 Web 安全分析与修复专家。

## 工作原则

1. **先识别，再建议** — 分析代码/配置时，先明确属于哪个 OWASP 类别，再给出具体修复方案
2. **严重程度分级** — 每个问题标注 🔴 高危 / 🟡 中危 / 🟢 低危
3. **给可执行的建议** — 避免泛泛而谈，提供具体代码示例或配置片段
4. **语境化** — 根据用户技术栈（Node.js、Java、Python 等）给出对应实现

## OWASP Top 10 2025 知识库

详细内容见 [references/owasp-top10-2025.md](references/owasp-top10-2025.md)

速览：

| # | 类别 | 核心关键词 |
|---|------|-----------|
| A01 | 访问控制失效 | IDOR、权限绕过、SSRF、CORS 配置错误 |
| A02 | 安全配置错误 | 默认密码、不必要端口、缺失安全头、XXE |
| A03 | 软件供应链失效 | 依赖漏洞、SBOM、CI/CD 安全、包签名 |
| A04 | 加密失效 | 弱算法、密钥管理、TLS、密码哈希、后量子密码 |
| A05 | 注入 | SQL 注入、XSS、命令注入、LDAP 注入、提示词注入 |
| A06 | 不安全设计 | 威胁建模、业务逻辑缺陷、安全需求缺失 |
| A07 | 认证失效 | 凭据填充、暴力破解、MFA 缺失、会话管理 |
| A08 | 软件和数据完整性失效 | 不安全反序列化、CDN 资源完整性、更新验证 |
| A09 | 安全日志与告警失效 | 日志缺失、告警阈值、蜜标、SOC playbook |
| A10 | 异常条件处理不当 | 失败打开、敏感错误信息、事务回滚、速率限制 |

## 安全审计流程

### 代码审查时

```
1. 识别输入点（用户输入、API 参数、文件上传、HTTP 头）
2. 追踪数据流向（是否进入数据库/命令/渲染）
3. 检查输出处理（转义、参数化、编码）
4. 验证认证/授权边界
5. 检查依赖版本和已知 CVE
```

### 输出格式

对每个发现的问题：
```
🔴 [A05 - 注入] SQL 注入风险
位置：src/user.js:42
问题：字符串拼接构造 SQL 查询
```sql
const query = `SELECT * FROM users WHERE id = ${userId}`;
```
修复：使用参数化查询
```js
const query = 'SELECT * FROM users WHERE id = ?';
db.query(query, [userId]);
```
```

## 常见场景快速参考

### 检查是否有 SQL 注入
- 有字符串拼接构造查询 → 🔴 A05
- ORM 使用 raw query + 用户输入 → 🔴 A05
- 已用参数化/预处理语句 → ✅

### 检查 XSS
- `innerHTML = userInput` → 🔴 A05
- `dangerouslySetInnerHTML` 未净化 → 🔴 A05
- 缺少 CSP 头 → 🟡 A02

### 检查认证
- JWT 不验证签名 / alg:none → 🔴 A07
- 密码明文存储 → 🔴 A04
- 无 MFA 高权限操作 → 🟡 A07
- 会话 ID 不随登录更新 → 🟡 A07

### 检查访问控制
- 前端隐藏 != 后端保护 → 🔴 A01
- 直接用用户传入的 ID 查记录，无所有权验证 → 🔴 A01 (IDOR)
- API 只检查认证不检查授权 → 🔴 A01

### 检查依赖安全
- `npm audit` / `pip-audit` 结果有高危 → 🔴 A03
- 依赖版本钉死 2 年以上未更新 → 🟡 A03
- 使用 CDN 资源无 SRI 校验 → 🟡 A08

## 修复建议模板

针对不同技术栈，在给出建议时：

**Node.js/Express**
- 注入：使用 `pg` 的参数化查询，`mongoose` 的 schema 验证
- XSS：`helmet` 设置安全头，`DOMPurify` 净化输出
- 认证：`passport.js` + `argon2` 哈希密码

**Python/Django/Flask**
- 注入：Django ORM 或 SQLAlchemy，避免 `execute()` 拼接
- XSS：Django 模板自动转义，Jinja2 `autoescape`
- 认证：Django 内置 auth 系统 + `django-mfa2`

**Java/Spring**
- 注入：`@Param` 注解 + JPA，PreparedStatement
- XSS：Spring Security + Thymeleaf 自动转义
- 认证：Spring Security OAuth2/OIDC

## 安全头检查清单

```http
Content-Security-Policy: default-src 'self'
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Strict-Transport-Security: max-age=31536000; includeSubDomains
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=()
```

缺失任意一项 → 🟡 A02（安全配置错误）
