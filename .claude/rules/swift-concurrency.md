---
paths:
  - "**/*.swift"
---

# Swift Concurrency 規約

推奨する前提：**Swift 5 言語モード + `SWIFT_APPROACHABLE_CONCURRENCY = YES` +
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`。** UI 中心のアプリでは Swift 6 の
完全データ分離より、この構成のほうが移行コストと安全性のバランスが良い
（採用したらその経緯を ADR に残す。切り替え判断は実機検証体制と相談）。

## この構成で前提になる挙動

- 注釈の無い型・関数は **MainActor 隔離がデフォルト**。UI コードに `@MainActor` を
  書く必要はほぼ無い。逆に、MainActor から外したいものだけ `nonisolated` を明示する。
- `nonisolated` な **async 関数は呼び出し側の actor で走る**（SE-0461 が既定）。
  「async にすれば勝手にバックグラウンドへ行く」は誤り。重い CPU 処理を off-main に
  したいなら actor に置くか `@concurrent` を明示する（`@concurrent` は引数・戻り値に
  Sendable を要求。採用時は計測してから）。

## よく出る対処パターン

| 状況 | 対処 |
|---|---|
| Sendable 注釈待ちの SDK 型を main actor から await したい | `@preconcurrency import <Module>` |
| 非 Sendable な型（`AVAssetExportSession` 等）を Task に渡す | `Task.detached` は使わず、actor 隔離を継承する素の `Task { }` |
| `@MainActor` クラスの mutable stored property を隔離から外したい | `@ObservationIgnored` + `nonisolated(unsafe)` ＋ **直列化の根拠コメント必須** |
| `@Observable` クラスの deinit から MainActor プロパティに触りたい | 触らない。明示的に `onDisappear` で後始末を呼ぶ規約にする |
| `[weak self]` クロージャの中から Task を起こす | Task 側にも `[weak self]` を明示（self 再キャプチャが Swift 6 で error になる） |
| 同期コールバックが main 到着保証ありの場合 | `MainActor.assumeIsolated`（KVO / time observer 等） |

## 禁止・要注意

- **`Task.detached` を使わない**。例外はブロッキング I/O を utility 優先度で逃がす等の
  限定ケースのみ（必ずコメントで理由を説明する）。
- **新規の `nonisolated(unsafe)` / `@unchecked Sendable` は理由コメント必須**。
  「直列キューで保護」「生成後イミュータブル」など安全性の根拠を書く。
  既存の意図的な使用箇所を一覧化しておき、`/audit-conventions` で増分を検知する。
- **セマフォで async を待たない**。橋渡しは `withCheckedContinuation`
  （continuation は必ず一度だけ resume。タイムアウトを付けるなら id 方式）。
- AVFoundation 等のプロパティは **async ロード**（`load(.duration)` 等）。同期アクセサは
  deprecated。
- 50ms 級の高頻度ループ（録画 ticker・カスタム compositor 等）は Timer /
  DispatchQueue のままで良い。構造化並行性への置換はリズム保証が無いので慎重に。
