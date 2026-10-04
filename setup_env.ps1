# Script thiết lập môi trường cho Lab 18: Production RAG Pipeline (Windows PowerShell)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " [Lab 18] Bắt đầu thiết lập môi trường & tài nguyên... " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Kiểm tra Python
$pyVersion = python --version 2>&1
Write-Host "[1/6] Kiểm tra Python: $pyVersion" -ForegroundColor Yellow

# 2. Tạo virtual environment nếu chưa có
if (-not (Test-Path ".venv")) {
    Write-Host "[2/6] Đang tạo môi trường ảo .venv..." -ForegroundColor Yellow
    python -m venv .venv
} else {
    Write-Host "[2/6] Đã tìm thấy thư mục .venv." -ForegroundColor Green
}

# 3. Kích hoạt môi trường ảo & cài đặt dependencies
Write-Host "[3/6] Cài đặt dependencies từ requirements.txt..." -ForegroundColor Yellow
& ".\.venv\Scripts\pip.exe" install --upgrade pip
& ".\.venv\Scripts\pip.exe" install -r requirements.txt

# 4. Khởi động Qdrant qua Docker Compose
Write-Host "[4/6] Khởi động Qdrant Vector DB qua Docker Compose..." -ForegroundColor Yellow
docker compose up -d

# 5. Tạo file .env từ template nếu chưa có
if (-not (Test-Path ".env")) {
    Write-Host "[5/6] Tạo file .env từ .env.example..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host "      -> Đã tạo .env. Vui lòng mở .env và điền OPENAI_API_KEY nếu cần." -ForegroundColor Green
} else {
    Write-Host "[5/6] File .env đã tồn tại." -ForegroundColor Green
}

# 6. Tải trước các mô hình HuggingFace
Write-Host "[6/6] Tải trước các mô hình embedding & reranking..." -ForegroundColor Yellow
& ".\.venv\Scripts\python.exe" -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"
& ".\.venv\Scripts\python.exe" -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('BAAI/bge-m3')"
& ".\.venv\Scripts\python.exe" -c "from sentence_transformers import CrossEncoder; CrossEncoder('BAAI/bge-reranker-v2-m3')"

Write-Host "`nSetup hoàn tất! Bạn có thể kích hoạt venv bằng lệnh: .\.venv\Scripts\Activate.ps1" -ForegroundColor Cyan
