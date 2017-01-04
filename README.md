README

Xcode Auto Pack IPA Tool, Latest: 1.1.2
by David Wang 2016/12/26
Skywind, Inc.

簡介：
利用 xcodebuile 打包專案製作 .ipa
不需輸入任何指令或預先修改bundle id

功能：
- 偵測相關套件安裝狀態：
	xcodebuile 指令
	xcode 命令列工具
	xcpretty 套件（用於美化 xcodebuile 輸入結果）
	cocoapods 套件（ Xcode 專案的套件管理工具）
- 安裝上述相關套件
- 切換 Xcode 版本
- 拖拉方式取得專案資料夾位置
- 選擇性複製專案資料夾到桌面
- 自動偵測專案是否使用 CocoaPods 工具
- 自動取得專案內 Scheme 名稱供選擇
- 自動取得專案內 Configuration 模式供選擇
- 自動取得鑰匙圈內 iPhone 開發者憑證名稱
- 拖拉方式取得 .mobileprovisioning 位置
- 複製 .mobileprovisioning 到系統 Library 中
- 讀取 .mobileprovisioning 中的 Bundle ID
- 覆蓋 .xcodeproj 專案檔中的各種憑證設定
- 封存專案到 .archive 檔
- 輸出 .archive 檔到 .ipa 檔
- 儲存原始輸入 log 檔以及 xcpretty 輸入的 log_pretty 檔
- 儲存編譯參數到 log
- 判斷輸出結果
- 計算編譯花費時間

版本：
1.0 (2016/12/28)
	可正常編譯風行天專案
	加入自動製作選項功能，減少使用者要自行輸入的步驟

1.1 (2016/12/29)
	加入自動偵測專案是否使用 CocoaPods 工具

1.1.1 (2016/12/29)
	加入輸出結果判斷
	加入自動判斷專案是否使用 CocoaPods
	修改目錄選單
	整合偵測相關套件安裝狀態功能

1.1.2 (2016/12/30)
	修正複製 .mobileprovisioning 到系統 Library 中路徑錯誤 bug
	加入選擇是否執行 pod update 的功能

1.1.3 (2017/01/03)
	修正覆蓋 .xcodeproj 專案檔設定時，沒有覆蓋開發團隊造成的問題
	新增儲存編譯參數到 log 的功能
