{ lib, stdenv, fetchzip, unzip, file, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "yazi";
  version = "26.5.6";

  # 平台特定的下载映射
  src = fetchzip {
    url = {
      x86_64-linux = "https://github.com/sxyazi/yazi/releases/download/v${version}/yazi-x86_64-unknown-linux-gnu.zip";
      aarch64-linux = "https://github.com/sxyazi/yazi/releases/download/v${version}/yazi-aarch64-unknown-linux-gnu.zip";
      x86_64-darwin = "https://github.com/sxyazi/yazi/releases/download/v${version}/yazi-x86_64-apple-darwin.zip";
      aarch64-darwin = "https://github.com/sxyazi/yazi/releases/download/v${version}/yazi-aarch64-apple-darwin.zip";
    }.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

    sha256 = {
      x86_64-linux = "0phv9pjlda09w8y6z46v2j997i4z02wz1igj26glhrk5gz6k0s8s";
      aarch64-linux = "17jhp7l1an120cl9wjzpw9rlcf5ds7g6f3arxbf7qvxk720r13i9";
      x86_64-darwin = "17flq8mxm3pa9l22a09m8nc38jc4zw0d1a57jkfj3nv1f1zbs6py";
      aarch64-darwin = "01v6hc2nv1mkri4yi9l38msrx9q2ly5smml1m3jpv61hm8vdb5ca";
    }.${stdenv.hostPlatform.system};

    stripRoot = false;  # ZIP 文件包含版本号目录
  };

  nativeBuildInputs = [ unzip makeWrapper ];
  buildInputs = [ file ];

  # 安装阶段
  installPhase = ''
    runHook preInstall

    # 创建安装目录
    mkdir -p $out/bin
    mkdir -p $out/share/yazi

    # 查找并安装主程序（在版本号目录中）
    YAZI_DIR=$(find . -maxdepth 1 -type d -name "*yazi*" | head -n 1)
    if [ -z "$YAZI_DIR" ]; then
      YAZI_DIR="."
    fi

    # 安装主程序
    if [ -f "$YAZI_DIR/yazi" ]; then
      cp "$YAZI_DIR/yazi" $out/bin/
      chmod +x $out/bin/yazi
    fi

    # 安装 ya (可选的 CLI 工具)
    if [ -f "$YAZI_DIR/ya" ]; then
      cp "$YAZI_DIR/ya" $out/bin/
      chmod +x $out/bin/ya
    fi

    # 复制其他必要文件
    if [ -d "$YAZI_DIR/plugins" ]; then
      cp -r "$YAZI_DIR/plugins" $out/share/yazi/
    fi
    if [ -d "$YAZI_DIR/presets" ]; then
      cp -r "$YAZI_DIR/presets" $out/share/yazi/
    fi

    runHook postInstall
    wrapProgram $out/bin/yazi --prefix PATH : ${lib.makeBinPath [ file ]}
  '';

  # 元数据
  meta = with lib; {
    description = "Blazing fast terminal file manager written in Rust, based on async I/O";
    homepage = "https://github.com/sxyazi/yazi";
    changelog = "https://github.com/sxyazi/yazi/releases/tag/v${version}";
    license = licenses.mit;
    mainProgram = "yazi";
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}