# claude-code-statusline

Claude Code のステータスラインをカスタマイズする共有用の設定です。
入力欄の下に **モデル名 / Effort レベル / カレントディレクトリ / git ブランチ / コンテキスト使用率 / セッション使用率（リセットまでの残り時間）/ 週次使用率（リセットまでの残り時間）** を表示します。

## 表示例

```
[Sonnet 5 · xhigh] 📁 laravel-ecs-cdk ⎇ main | ctx 23% | session 12% (2h 13m) | week 41% (3d 4h)
```

| 項目 | 内容 |
|---|---|
| `[Sonnet 5 · xhigh]` | 使用中のモデル名 と Effort レベル（`.effort.level`。未設定なら `· xhigh` 部分は非表示） |
| `📁 laravel-ecs-cdk` | カレントディレクトリ名（ベース名のみ） |
| `⎇ main` | git ブランチ（git 管理外では非表示） |
| `ctx 23%` | コンテキストウィンドウの使用率 |
| `session 12% (2h 13m)` | `/usage` の Current Session（5時間ウィンドウ）使用率と、リセットまでの残り時間 |
| `week 41% (3d 4h)` | `/usage` の Current Week（7日ウィンドウ）使用率と、リセットまでの残り時間 |

値が取得できない項目は自動的に省略されます。例えば git 管理外なら `⎇` が消え、無料プランなら `session` / `week` が消え、Effort 未設定ならモデル名だけになります。リセット残り時間は `resets_at`（Unix epoch）が取得できたときのみ `( )` 内に表示されます。

## 色分け

状態に応じて文字色が変わります（ANSI 基本色を使用。対応ターミナルでのみ色が付き、非対応でも表示自体は崩れません）。

| 対象 | 色分けルール |
|---|---|
| **モデル名** | Opus 系: マゼンタ / Sonnet 系: シアン / Haiku 系: 緑 / Fable 系: 明るい青（太字） |
| **Effort** | `xhigh` / `max`: 赤（太字） / `high`: 黄 / それ以外: 通常色。高負荷設定の使いすぎに気づけます |
| **使用率**（`ctx` / `session` / `week`） | 〜50%: 緑 / 50〜79%: 黄 / 80%〜: 赤（太字）。3項目それぞれ独立して色が変わります |

ディレクトリ名・ブランチ・区切りの `\|` は色を付けず通常色のままにしています（過度に賑やかにならないよう対象を絞っています）。

## 必要なもの

| 依存 | 必須 | 備考 |
|---|---|---|
| **`jq`** | ✅ 必須 | JSON パースに使用。未インストールだと表示が崩れます。<br>macOS: `brew install jq` / Debian/Ubuntu: `sudo apt install jq` |
| **`bash`** | ✅ 必須 | ほぼ全環境に標準搭載 |
| **`git`** | 任意 | ブランチ表示に使用。無い場合はブランチ部分だけ非表示 |
| **Claude Code** | — | `ctx`（コンテキスト使用率）は比較的新しいバージョンが必要 |
| **Claude.ai Pro/Max プラン** | — | `session` / `week` はこのプランかつ最初の API 応答後にのみ表示 |

## インストール

### 1. スクリプトを配置

このリポジトリの `statusline-command.sh` を `~/.claude/` にコピーします。

```bash
mkdir -p ~/.claude
cp statusline-command.sh ~/.claude/statusline-command.sh
```

> 実行権限（chmod）は不要です。`bash` 経由で呼び出すため、そのままで動きます。

### 2. settings.json にマージ

`~/.claude/settings.json` に以下の `statusLine` キーを追加します（`settings.snippet.json` に同じ内容があります）。

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash \"$HOME/.claude/statusline-command.sh\""
  }
}
```

> ⚠️ **既存の `settings.json` を丸ごと上書きしないでください。**
> すでに `settings.json` がある場合は、`statusLine` キーだけを既存の内容にマージしてください。
> `jq` を使うなら次のコマンドで安全にマージできます。

```bash
# ~/.claude/settings.json が無ければ新規作成、あればマージ
touch ~/.claude/settings.json
[ -s ~/.claude/settings.json ] || echo '{}' > ~/.claude/settings.json
jq -s '.[0] * .[1]' ~/.claude/settings.json settings.snippet.json > ~/.claude/settings.json.tmp \
  && mv ~/.claude/settings.json.tmp ~/.claude/settings.json
```

### 3. 反映を確認

次のプロンプト以降でステータスラインに反映されます。表示されない場合は「トラブルシューティング」を参照してください。

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| 何も表示されない / `[null]` になる | `jq` がインストールされているか確認（`jq --version`） |
| `session` / `week` が出ない | Claude.ai Pro/Max プランか確認。最初の API 応答後に表示されます |
| `ctx` が出ない | Claude Code を最新版に更新 |
| `⎇ branch` が出ない | git 管理下のディレクトリか確認（仕様上、管理外では非表示） |

## ライセンス

自由に利用・改変してください。
