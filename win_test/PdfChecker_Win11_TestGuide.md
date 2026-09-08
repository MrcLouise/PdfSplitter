# PdfChecker Win11 測試說明

## 1. 測試目標
驗證 `pdfchecker.exe` 在 Windows 11 環境下能否：
- 讀取 `TB_eDoc_Instr` 內 `Status = 'CONFIRMED'` 的 instruction
- 把昨日 `TB_eDoc_PdfCheck_Daily` 記錄搬去 `TB_eDoc_PdfCheck_History` 並 truncate
- 把 CONFIRMED instructions 寫入 `TB_eDoc_PdfCheck_Daily`，狀態設為 `PENDING`
- 掃描 report folder 內的 `*.pdf`，從檔名提取 UT portfolio no
- 檢查 PDF 內文是否包含該 portfolio no 的數字部分（例如 `0094500001`）
- 把每條 instruction 更新為 `SUCCESS` 或 `FAILED`，並在 `ErrorDetail` 寫入錯誤詳情
- 發生錯誤時在 `logfile.txt` 寫入 `ERROR` 行，並回傳 exit code `1`

### 1.1 Report folder 定位規則

對每條 CONFIRMED instruction，依序嘗試以下兩種目錄：

1. `eAdvice\{date}\{reportName}\{ReferenceNo}\`（ReferenceNo 為空時用 templateId）
2. `eAdvice\{date}\{reportName}\Template{templateId}_{ReferenceNo}\`（多個 template 共用同一個 reportName 時的格式，例如 template 31/32/33 → `CorporateActionGeneric\Template31_CA20260730001`；templateId 本身以 "Template" 開頭時不會重複加前綴；**僅在 ReferenceNo 非空時才會嘗試這種格式**）

ReferenceNo 為空時只查第 1 種（folder 直接用 templateId），不會去查 `Template{templateId}_{templateId}` 這類實際不存在的名稱。

兩個都找不到則 FAILED，錯誤訊息會同時列出兩個嘗試過的路徑。

第 2 種格式的完整測試流程見 `win_test/template31_test/README_Template31_Test.md`。

---

## 2. 準備工作

### 2.1 開發機 build
```bash
mvn clean package -DskipTests
```
產出：
- `target/pdfchecker.exe`
- `target/PdfSplitter-1.0-pdfchecker.jar`

### 2.2 複製到 Win11 測試機
把以下檔案放到 Win11 的同一個資料夾，例如 `C:\Test\PdfChecker\`：
```
pdfchecker.exe
PdfSplitter-1.0-pdfchecker.jar
CONNECTION.XML                (可複製 win_test\CONNECTION.XML 並改成測試 DB)
check.bat                     (可選)
```

`pdfchecker.exe` 會到 `C:\App\config\CONNECTION.XML` 讀取 DB 連線。測試時建議把 `AppConfig.java` 內的 `CONFIG_FILE` 改為本地路徑再重新 build，或把 `CONNECTION.XML` 放到對應位置。

### 2.3 資料庫設定
在 BPSS 執行：
```sql
-- 建立 PdfChecker 專用 table 與 stored procedures
:setup_PdfChecker_tables.sql (位於專案 db 資料夾)

-- 建立測試用 CONFIRMED instruction
:win_test\setup_PdfChecker_test_data.sql
```

注意：PdfChecker 目前只需要 `TB_eDoc_Instr` 有一筆 `Status = 'CONFIRMED'` 的記錄即可，不需要 `TB_eDoc_ReportData`。

---

## 3. 測試 PDF 檔案

本專案不再內建測試 PDF。測試時請自行準備 PDF 並放到以下路徑：

```
D:\UTBatch\DSB\eAdvice\20250630\DSBCouponPaymentAdvice\20250630\
  └── 20260529_31_UT0094500001_SGN000001_000010.pdf
```

PDF 內文需要包含：
```
0094500001
```
（即 portfolio no `UT0094500001` 去掉 `UT` 後的數字部分。）

### 3.1 成功測試
`DSBCouponPaymentAdvice\20250630` 資料夾內放置正確的 PDF：
```
20260529_31_UT0094500001_SGN000001_000010.pdf
```
內含 `0094500001`。

### 3.2 失敗測試（portfolio no 不在 PDF 內）
把 `20260529_31_UT0094500001_SGN000001_000010.pdf` 換成不含 `0094500001` 的版本。

預期錯誤：
```
ERROR Template1/20250630 - 20260529_31_UT0094500001_SGN000001_000010.pdf: portfolio number 0094500001 not found in PDF content
```

### 3.3 失敗測試（portfolio no 不對）
在 `DSBCouponPaymentAdvice\20250630` 內只放：
```
20260529_31_UT0094500002_SGN000001_000010.pdf
```

預期錯誤：
```
20260529_31_UT0094500002_SGN000001_000010.pdf: portfolio number 0094500002 not found in PDF content
```
（因為 PDF 檔名提取的 portfolio no 是 UT0094500002，但 PDF 內文沒有 `0094500002`。）

---

## 4. 執行測試

開啟 Command Prompt，切到 pdfchecker.exe 所在目錄：
```bat
cd C:\Test\PdfChecker
pdfchecker.exe "D:\UTBatch\DSB\eAdvice\20250630" "C:\Test\PdfChecker"
```

或執行 batch：
```bat
check.bat
```

---

## 5. 預期結果

### 5.1 全部成功
Console 顯示：
```
[SUCCESS] All PDF checks passed!
```
Exit code: `0`

資料庫 `TB_eDoc_PdfCheck_Daily`：
- 出現 `Template1 / 20250630`，`Status = 'SUCCESS'`，`ErrorDetail = NULL`

### 5.2 有錯誤
Console 顯示：
```
[FAILED] Some PDF checks failed. Exit code: 1
```
Exit code: `1`

`logfile.txt` 會新增類似：
```
2026-07-07 10:30:15 ERROR Template1/20250630 - 20260529_31_UT0094500001_SGN000001_000010.pdf:
portfolio number 0094500001 not found in PDF content
```

資料庫 `TB_eDoc_PdfCheck_Daily`：
- `Template1 / 20250630`，`Status = 'FAILED'`，`ErrorDetail` 寫入詳細錯誤

---

## 6. 驗證 SQL

```sql
USE BPSS
GO

-- 查看今日檢查結果
SELECT * FROM TB_eDoc_PdfCheck_Daily;

-- 查看歷史記錄
SELECT * FROM TB_eDoc_PdfCheck_History ORDER BY ArchiveDate DESC;

-- 查看 CONFIRMED instruction 是否仍在原表
SELECT * FROM TB_eDoc_Instr WHERE Status = 'CONFIRMED';
```

---

## 7. 多次執行 / 跨日測試

第二次執行時，前一次的 `TB_eDoc_PdfCheck_Daily` 記錄會被搬到 `TB_eDoc_PdfCheck_History`，並重新從 `TB_eDoc_Instr` 載入 CONFIRMED 記錄。

若把 `logfile.txt` 的修改日期改成昨天，再次執行時會看到它被 rename 成 `logfile.txt20250705`（假設昨天是 20250705），然後產生新的 `logfile.txt`。

---

## 8. 常見問題

| 問題 | 檢查點 |
|------|--------|
| 找不到 CONFIRMED instruction | `TB_eDoc_Instr.Status` 是否為 `'CONFIRMED'`，`ReferenceNo` 是否純數字 |
| PDF 找不到 | `eAdvice\20250630\DSBCouponPaymentAdvice\20250630\20260529_31_UT0094500001_SGN000001_000010.pdf` 路徑是否正確；共用 reportName 的 template（31/32/33）目錄為 `Template{templateId}_{ReferenceNo}` 格式，見 1.1 |
| 地址比對失敗 | 目前已不使用地址比對；只檢查 PDF 內文是否包含 portfolio no 數字部分 |
| 無法連線 | `CONNECTION.XML` 路徑與內容是否正確；Win11 能否連到 DB server |
| 中文亂碼 | PDF 內文與 DB 地址編碼是否一致；建議用 UTF-8 或 Big5 產生 PDF |

---

## 9. 測試完成後清理

```sql
USE BPSS
GO
DELETE FROM TB_eDoc_Instr WHERE templateId = 'Template1' AND ReferenceNo = '20250630';
DELETE FROM TB_eDoc_PdfCheck_Daily WHERE templateId = 'Template1' AND ReferenceNo = '20250630';
DELETE FROM TB_eDoc_PdfCheck_History WHERE templateId = 'Template1' AND ReferenceNo = '20250630';
GO
```
