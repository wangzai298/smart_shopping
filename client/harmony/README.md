# 鸿蒙 (HarmonyOS) 平台适配说明

> 当前状态：工程占位，待后续补全。不阻塞 Android / iOS 核心流程验证。

## 适配步骤

### 1. 安装 flutter_ohos 工具链

鸿蒙平台通过社区项目 [flutter_ohos](https://gitee.com/openharmony-sig/flutter_flutter) 提供 Flutter 运行时支持。

```bash
# 克隆 flutter_ohos 工具链
git clone https://gitee.com/openharmony-sig/flutter_flutter.git

# 配置环境变量指向 flutter_ohos
export PATH=$PATH:$(pwd)/flutter_flutter/bin

# 验证
flutter doctor --ohos
```

### 2. 创建鸿蒙原生工程

```bash
cd client/

# 使用 flutter_ohos 创建鸿蒙模块
flutter create --platforms ohos .

# 或者手动创建以下目录结构：
# harmony/
# ├── app/
# │   ├── src/
# │   │   └── main/
# │   │       ├── module.json5       # 应用配置（权限声明等）
# │   │       └── ets/
# │   │           └── entryability/
# │   │               └── EntryAbility.ets  # 入口 Ability
# │   └── build-profile.json5        # 编译配置
# ├── signing/                        # 签名文件目录
# │   └── .gitkeep
# └── oh-package.json5                # 包管理配置
```

### 3. 权限声明（module.json5）

在 `app/src/main/module.json5` 中添加：

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.CAMERA",
        "reason": "$string:camera_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      },
      {
        "name": "ohos.permission.READ_MEDIA",
        "reason": "$string:media_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      },
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:internet_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      }
    ]
  }
}
```

对应的资源字符串需在 `src/main/resources/base/element/string.json` 中定义。

### 4. 签名配置

1. 登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) 创建应用
2. 下载签名证书文件（.p12 和 .cer）
3. 将证书放入 `signing/` 目录
4. 配置 `build-profile.json5` 中的 `signingConfigs` 指向证书路径

### 5. Flutter 插件适配

部分 Flutter 插件需要鸿蒙适配版本，在 `pubspec.yaml` 中使用依赖覆盖：

```yaml
# pubspec.yaml
dependency_overrides:
  image_picker:
    git:
      url: https://gitee.com/openharmony-sig/flutter_image_picker.git
      ref: ohos
  # 其他需要适配的插件...
```

常用的纯 Dart 库（dio、riverpod、go_router、fl_chart）无需额外适配，可直接运行。

### 6. 运行验证

```bash
# 连接鸿蒙设备或启动模拟器
hdc shell

# 运行 Flutter 应用
flutter run -d ohos
```

## 当前进度

| 项目 | 状态 |
|------|------|
| 目录骨架 | ✅ 已创建 |
| 权限声明 | ⬜ 待创建 module.json5 |
| 签名配置 | ⬜ 待申请证书 |
| 插件适配 | ⬜ 待覆盖 image_picker |
| 真机验证 | ⬜ 待运行 |

## 注意事项

- Demo 阶段优先确保 Android 和 iOS 完整可跑，鸿蒙仅保留工程结构
- 鸿蒙权限模型不同于 Android：存储权限使用 `READ_MEDIA` / `WRITE_MEDIA`，无需 `READ_EXTERNAL_STORAGE`
- Flutter 代码库（lib/ 目录）无需任何修改，同一套 Dart 代码运行于三个平台
