# Pelican Bench Homebrew Tap

在自己的电脑上测试模型接口，比较首字延迟、输出速度、容量错误和历史成绩。模型请求由用户本机发出，配置、账号凭据和成绩留在本机。

## 安装

需要先安装 [Homebrew](https://brew.sh)。然后执行：

```sh
brew install dahuaxiya/tap/pelican-bench
pelican-bench
```

Homebrew 会安装 Python 3.13，直接启动后端，不依赖 Node.js。启动命令会打开本机网页，默认地址为 http://127.0.0.1:8780。先到设置页添加自己的模型服务地址、API Key，再进入性能评测，选择模型开始测试。

0.2.0 起统一使用 pelican-bench 命令，不占用 pelican 名称。npm 入口仍保留在安装包中，两种渠道共用数据目录和实例锁；请选择一种全局安装方式。

也可以先添加 tap，再安装：

```sh
brew tap dahuaxiya/tap
brew install pelican-bench
```

## 使用和升级

```sh
pelican-bench doctor
pelican-bench --no-browser
pelican-bench --port 9000
pelican-bench start -d --no-browser
pelican-bench status
pelican-bench test performance --site my-api --model gpt-6.1-sol
brew update
brew upgrade pelican-bench
pelican-bench restart -d --no-browser
```

同一数据目录只运行一个后端。重复启动会打开已有实例。端口被其他服务占用时会报错，不会终止其他服务。

macOS 数据位于 ~/Library/Application Support/pelican-bench；Linux 默认位于 ~/.local/share/pelican-bench，设置了 XDG_DATA_HOME 时使用其下的 pelican-bench 目录。可用 --data-dir 指定其他位置。升级和卸载 Homebrew 包不删除这些数据。

HTTP 接口测速、容量检测和 SVG 评测可直接使用。其他能力按需准备：

- BBEH / ARC：停止服务后执行 pelican-bench setup-iq bbeh 或 pelican-bench setup-iq arc。
- ChatGPT / Kimi 账号渠道：安装对应官方 CLI，在页面中登录自己的账号。
- 工程测评：准备 Docker，执行 pelican-bench setup-engineering。按需使用 PELICAN_BENCH_DOCKER_CONTEXT 指定 Docker context。

这是项目自有 tap，不是 Homebrew 核心仓库。0.4.0 已通过 macOS Apple Silicon 和 Linux x86_64 CI 的安装、启动、停止及实例复用测试，并提供对应预编译包。Intel Mac、Linux ARM 和原生 Windows 尚未验证；Windows 请使用 WSL2。

发布包仅含程序和静态资源，不含开发者配置、登录态、题库或历史记录。下载采用固定版本和 SHA-256 校验。源码与安装包由 [pelican-bench](https://github.com/dahuaxiya/pelican-bench) 仓库维护，沿用该仓库的 MIT 许可证；第三方组件保留原有许可证。
