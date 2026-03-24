//
//  PersistenceManager.swift
//  huabu
//
//  Created by zjs on 2026/3/5.
//

//📂 ProjectRoot (你的项目名)
//├── 🟢 App (全局启动与配置)
//│   ├── AppDelegate.swift / SceneDelegate.swift
//│   └── AppAppearance.swift (配置全局紫色背景、导航栏样式)
//│
//├── 🔵 Modules (业务模块 - 按功能拆分)
//│   ├── Tabbar (如果未来有社区、个人中心，放在这里)
//│   └── Editor (编辑核心模块)
//│       ├── ViewController (只管 UI 切换和生命周期)
//│       │   └── EditorViewController.swift
//│       ├── ViewModel (只管数据逻辑：图片处理、贴纸列表加载)
//│       │   └── EditorViewModel.swift
//│       └── View (自定义 UI 组件)
//│           ├── StickerContainerView.swift (贴纸手势、虚线框)
//│           ├── StickerCell.swift (底部预览格子)
//│           └── CanvasView.swift (如果 mainCanvas 逻辑变复杂，单独抽离)
//│
//├── 🟡 Common (公共基础)
//│   ├── Components (通用的自定义按钮、弹窗)
//│   ├── Extensions (UIView+SnapKit简写, UIImage渲染工具)
//│   └── Protocols (手势协议等)
//│
//├── 🔴 Resources (静态资源)
//│   ├── Assets.xcassets (UI图标、系统切图)
//│   └── StickerAssets (专门存放分类好的像素贴纸图片)
//│
//└── 🟣 Services (底层服务)
//    ├── ImageManager.swift (负责：View转UIImage、保存相册)
//    └── AuthManager.swift (如果以后有登录功能)
