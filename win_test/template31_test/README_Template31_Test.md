# PdfChecker Template31（帶前綴目錄）Win11 測試說明

## 1. 測試目標

生產環境中 templateId 31/32/33 共用同一個 `reportName = CorporateActionGeneric`，
磁碟上的 report folder 格式為 `Template<templateId>_<ReferenceNo>`，例如：

```
eAdvice\20260730\CorporateActionGeneric\Template31_CA20260730001\
```

舊版 PdfChecker 只找 `CorporateActionGeneric\CA20260730001`，會報 `report folder not found`。
本測試驗證修改後的版本能：

- 正確進入 `Template31_CA20260730001` 這類帶前綴的目錄做檢查
- 找不到目錄時，錯誤訊息列出兩個嘗試過的路徑
- 不帶前綴的舊式目錄（其他 template 在用）行為不變

---

## 2. 準備工作

### 2.1 開發機 build（此步驟在 Mac 上已完成）

```bash
mvn clean package -DskipTests
```

產出（已複製到本資料夾）：
- `pdfchecker.exe`
- `PdfSplitter-1.0-pdfchecker.jar`

### 2.2 複製到 Win11 測試機

把本資料夾的以下檔案放到 Win11，例如 `C:\Test\PdfChecker\`：

```
pdfchecker.exe
PdfSplitter-1.0-pdfchecker.jar
check.bat
20260807_33_NA00945001_000923.pdf
```

另外把 `CONNECTION_LOCAL.XML` 放到 **`C:\Users\95301\Desktop\CONNECTION_LOCAL.XML`**
（目前 `AppConfig.java` 寫死讀這個路徑；請依測試 DB 調整內容）。
若之後把 `CONFIG_FILE` 改回 `C:\App\config\CONNECTION.XML` 重新 build，則改放對應路徑。

### 2.3 資料庫設定

在 BPSS 測試庫執行：

```sql
-- 首次使用 PdfChecker 才需要（注意：會 drop 重建 daily/history 兩張表）
:setup_PdfChecker_tables.sql        (位於專案根目錄)

-- 建立本次測試用 CONFIRMED instruction（31 / CA20260730001）
-- 並確保 template 31 的 reportName = CorporateActionGeneric
:setup_Template31_test_data.sql     (本資料夾)
```

### 2.4 建立測試目錄

在 Win11 上執行本資料夾的 `setup_dirs.bat`，會自動建立當天日期的測試目錄並複製測試 PDF：

```
C:\Users\95301\Desktop\UTBatch\DSB\eAdvice\<今天YYYYMMDD>\CorporateActionGeneric\Template31_CA20260730001\
  └── 20260807_33_NA00945001_000923.pdf
```

（日期資料夾用**執行當天**的日期，和 `check.bat` 一致。）

PDF 檔名第 3 段 `NA00945001` 是要檢查的帳號，PDF 內文含有該帳號。

---

## 3. 執行測試

開啟 Command Prompt：

```bat
cd C:\Test\PdfChecker
check.bat
```

或不指定日期資料夾、手動執行：

```bat
pdfchecker.exe "C:\Users\95301\Desktop\UTBatch\DSB\eAdvice\<今天YYYYMMDD>" "C:\Test\PdfChecker"
```

---

## 4. 預期結果

### 4.1 主場景（帶前綴目錄）— 成功

Console / log 出現：

```
SUCCESS Template31/CA20260730001
```

DB 驗證：

```sql
SELECT * FROM TB_eDoc_PdfCheck_Daily WHERE templateId = 'Template31';
-- 預期 Status = 'SUCCESS', ErrorDetail = NULL
```

**注意**：若 DB 內還有其他 `Status = 'CONFIRMED'` 的 instruction（例如之前測試留下的
`Template1/20250630`），而它們的目錄不在本次 baseDir 下，那些 instruction 會 FAILED，
整體 exit code 會是 `1`。這屬預期行為，只需確認 `Template31/CA20260730001` 這筆是 SUCCESS。

### 4.2 負面測試 — 目錄不存在

把 `Template31_CA20260730001` 改名（例如改成 `Template31_CA20260730001_bak`）後再執行，
預期：

```
FAILED Template31/CA20260730001: report folder not found: <baseDir>\CorporateActionGeneric\CA20260730001
    or <baseDir>\CorporateActionGeneric\Template31_CA20260730001
```

錯誤訊息會列出**兩個**嘗試過的路徑（舊式 + 帶前綴）。

### 4.3 兼容測試 — 不帶前綴的舊式目錄

改用舊式目錄結構：

```
C:\Users\95301\Desktop\UTBatch\DSB\eAdvice\<今天YYYYMMDD>\CorporateActionGeneric\CA20260730001\
  └── 20260807_33_NA00945001_000923.pdf
```

預期依然 `SUCCESS`（候選 1 優先命中，其他 template 的現有行為不受影響）。

---

## 6. 測試完成後清理

```sql
-- 刪除測試 instruction 與檢查記錄
:cleanup_Template31_test_data.sql   (本資料夾)
```

另外手動刪除 Win11 上的測試目錄：

```
C:\Users\95301\Desktop\UTBatch\DSB\eAdvice\<今天YYYYMMDD>\CorporateActionGeneric\
```

（`TB_eDoc_ReportTemplate` 中 templateId = '31' 的記錄會保留；如測試庫原本沒有這個
template，需要一併刪除的話請自行執行 `DELETE FROM TB_eDoc_ReportTemplate WHERE templateId = 'Template31'`。）
