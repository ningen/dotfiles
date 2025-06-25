# Dotfiles

このリポジトリは、私の個人的な設定ファイル（dotfiles）を [Nix](https://nixos.org/) と [Home Manager](https://github.com/nix-community/home-manager) を使って宣言的に管理するものです。Nix Flakesを活用し、macOSとLinux (NixOS) 環境間で再現性のある環境構築を実現しています。

## ディレクトリ構成

設定ファイルは以下のように構成されています。

- `flake.nix`: すべてのホスト（マシン）の設定を定義するエントリーポイントです。
- `nix/`: すべてのNix式（設定ファイル）が格納されています。
  - `hosts/`: ホスト固有の設定です。
    - `common/`: すべてのホストで共有される設定（シェル、基本的なCLIツールなど）です。
    - `nixos/`: NixOSマシンに特化した設定（システム設定、GUIアプリケーションなど）です。
    - `ningen-mba/`: MacBook Airに特化した設定です。
  - `packages/`: インストールするパッケージのリストを、機能ごと（開発ツール、フォーマッターなど）に分けて定義しています。
- `.config/`: Neovimの設定など、頻繁に変更するためNixの管理下に置いていない設定ファイルです。これにより、Nixの再ビルドを待つことなく、素早く設定を試すことができます。

## 適用方法

### NixOSの場合

NixOSマシンでシステム全体の設定を適用するには、以下のコマンドを実行します。

```bash
sudo nixos-rebuild switch --flake .#myNixOS
```

### Home Manager（すべてのシステム共通）

NixOS、macOS、またはその他のLinuxディストリビューションで、ユーザーレベルの設定（パッケージ、シェル設定など）を適用するには、以下のコマンドを実行します。

```bash
nix run .#update
```

このコマンドは、flakeの依存関係を更新し、現在のホスト名に応じた適切なHome Managerプロファイルを適用します。
