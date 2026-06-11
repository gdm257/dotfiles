{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "localias";
  version = "3.0.0+commit.43c3619";

  # 平台特定的下载映射 - 直接下载二进制文件
  src = fetchurl {
    url = {
      x86_64-linux = "https://github.com/peterldowns/localias/releases/download/v${lib.replaceStrings ["+"] ["%2B"] version}/localias-linux-amd64";
      aarch64-linux = "https://github.com/peterldowns/localias/releases/download/v${lib.replaceStrings ["+"] ["%2B"] version}/localias-linux-arm64";
      x86_64-darwin = "https://github.com/peterldowns/localias/releases/download/v${lib.replaceStrings ["+"] ["%2B"] version}/localias-darwin-amd64";
      aarch64-darwin = "https://github.com/peterldowns/localias/releases/download/v${lib.replaceStrings ["+"] ["%2B"] version}/localias-darwin-arm64";
    }.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

    sha256 = {
      x86_64-linux = "e7e8ae3a6cf2b1d7b637b6d871ea615b66509096f35ed8f4cc2c370a812193aa";
      aarch64-linux = "464c5cf95b9ed8fb2bfd3baed8b55554d2191d20e3fd9ac5c923c7482f475d08";
      x86_64-darwin = "da15cca479447d5466569b91a679e9fe2cdb97b2be5a3c09c912ebe75ce0de17";
      aarch64-darwin = "2ee5ae68b864a1b639a26ec042b5590764aeef3536eb2681236946eb4f3d2614";
    }.${stdenv.hostPlatform.system};

    };

  # 下载的是直接的二进制文件，不需要解压
  dontUnpack = true;

  # 安装阶段
  installPhase = ''
    runHook preInstall

    # 创建安装目录
    mkdir -p $out/bin

    # 直接安装下载的二进制文件
    cp $src $out/bin/localias
    chmod +x $out/bin/localias

    runHook postInstall
  '';

  # 元数据
  meta = with lib; {
    description = "A simple DNS server that resolves local hostnames to 127.0.0.1";
    homepage = "https://github.com/peterldowns/localias";
    changelog = "https://github.com/peterldowns/localias/releases/tag/v${version}";
    license = licenses.mit;
    mainProgram = "localias";
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
