# Luxos Web

[English](README_EN.md) | [中文](README_CN.md) | [Español](README_ES.md) | [日本語](README_JP.md)

Luxos Web は、Docker を使用して構築された最新の Web アプリケーションデプロイメントおよび管理プラットフォームで、完全な Web アプリケーション実行環境と管理ツールを提供します。

## 特徴

- 🚀 クイックデプロイ：完全な Web アプリケーション環境をワンクリックでデプロイ
- 🛡️ 安全性と信頼性：組み込みのセキュリティ設定と SSL 証明書管理
- 📊 パフォーマンス監視：システムリソースとアプリケーションステータスのリアルタイム監視
- 💾 自動バックアップ：データベースとファイルの自動バックアップをサポート
- 🔄 負荷分散：組み込みの負荷分散とリバースプロキシ
- 🎛️ ビジュアル管理：コマンドラインと Web インターフェースによる管理を提供

## 技術スタック

- Web サーバー：Caddy 2.0
- リバースプロキシ：Pingora
- データベース：PostgreSQL 15
- キャッシュ：Redis 7
- 実行環境：PHP 8.2
- コンテナ化：Docker & Docker Compose

## クイックスタート

### システム要件

- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ RAM
- 20GB+ 利用可能なディスク容量

### インストール手順

1. リポジトリのクローン：
   ```bash
   git clone https://github.com/veritaswiki/luxos-web.git
   cd luxos-web
   ```

2. 環境変数の設定：
   ```bash
   cp .env.example .env
   # .env ファイルを編集して設定を行う
   ```

3. インストールスクリプトの実行：
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

4. サービスの開始：
   ```bash
   docker-compose up -d
   ```

### 使用方法

1. サイト管理：
   ```bash
   ./scripts/menu.sh
   ```

2. 新しいサイトの追加：
   ```bash
   ./scripts/add_site.sh
   ```

3. システム最適化：
   ```bash
   ./scripts/optimize_system.sh
   ```

4. データのバックアップ：
   ```bash
   ./scripts/backup.sh
   ```

## ディレクトリ構造

```
luxos-web/
├── caddy/              # Caddy 設定ファイル
├── config/             # アプリケーション設定ファイル
├── php/               # PHP 設定と拡張機能
├── pingora/           # Pingora 設定
├── scripts/           # 管理スクリプト
├── www/               # ウェブサイトファイル
├── docker-compose.yml # Docker compose 設定
└── install.sh         # インストールスクリプト
```

## 設定

### 環境変数

- `POSTGRES_USER`: データベースユーザー名
- `POSTGRES_PASSWORD`: データベースパスワード
- `POSTGRES_DB`: データベース名
- `REDIS_PASSWORD`: Redis パスワード

### パフォーマンス最適化

システムには、ニーズに応じて調整できるプリセットの最適化がいくつか用意されています：

1. PHP-FPM 設定
2. PostgreSQL 最適化パラメータ
3. Redis キャッシュ設定
4. システムカーネルパラメータ

## よくある問題

1. システムの更新方法は？
   ```bash
   git pull
   docker-compose up -d --build
   ```

2. ログの確認方法は？
   ```bash
   ./scripts/view_logs.sh
   ```

3. データのバックアップ方法は？
   ```bash
   ./scripts/backup.sh
   ```

## セキュリティ推奨事項

1. システムと依存関係を定期的に更新
2. 強力なパスワードを使用
3. ファイアウォールを有効化
4. 定期的なデータバックアップ
5. システムログの監視

## 貢献方法

1. プロジェクトをフォーク
2. 機能ブランチを作成
3. 変更をコミット
4. ブランチにプッシュ
5. プルリクエストを作成

## ライセンス

MIT License

## 作者

- veritaswiki
- https://github.com/veritaswiki

## 謝辞

このプロジェクトに貢献してくださったすべての開発者に感謝いたします！ 