# Individual Reflection — Lab 18: Production RAG

**Họ và tên:** Phùng Quốc Việt  
**MSSV:** 2A202602456  
**Khóa:** K4 - Track 3A  
**Ngày hoàn thành:** 04/10/2026  

---

## Phần 1: Mapping bài giảng (Lecture Mapping)
Map từng concept trong lecture vào code bạn vừa viết trong lab:

| Lecture Concept | Module | Hàm cụ thể | Observation & Phân tích |
|----------------|--------|-------------|--------------------------|
| Semantic chunking | M1 | `chunk_semantic()` & `chunk_hierarchical()` | Threshold 0.85 nhóm các câu có tính tương đồng ngữ nghĩa cao vào cùng một chunk. So với basic paragraph chunking (57 chunks), hierarchical chunking phân tách thành 104 child chunks (256 chars) gắn liền với parent context (2048 chars) qua `parent_id`, đồng thời structure-aware chunking trích xuất chính xác cấu trúc Markdown/tiêu đề và lưu vào metadata `section`. |
| BM25 + Dense fusion | M2 | `reciprocal_rank_fusion()` | RRF kết hợp điểm xếp hạng giữa lexical search (BM25 Okapi với từ điển tiếng Việt tách từ qua Underthesea) và dense vector search (BAAI/bge-m3 1024 chiều trong Qdrant). Công thức $RRF(d) = \sum \frac{1}{60 + r(d)}$ giải quyết bài toán vocabulary mismatch, giúp bắt chính xác các keyword kỹ thuật và số liệu (ví dụ: "PVI", "MFA", "120 ngày", "30 triệu") mà dense search đơn lẻ dễ bị trôi. |
| Cross-encoder reranking | M3 | `CrossEncoderReranker.rerank()` | Sử dụng mô hình `BAAI/bge-reranker-v2-m3` để cross-encode đồng thời cặp (query, document). Lấy top 20 candidates từ hybrid search và rerank xuống top 3 chunks có điểm tương quan cao nhất. Reranking giúp lọc bỏ các chunk gây nhiễu, tối ưu hóa Context Precision đưa thông tin đắt giá nhất lên đầu. |
| RAGAS 4 metrics | M4 | `evaluate_ragas()` & `failure_analysis()` | Đánh giá 4 chỉ số cốt lõi: Faithfulness (độ trung thực, chống ảo giác), Answer Relevancy (độ bám sát câu hỏi), Context Precision (chất lượng xếp hạng ngữ cảnh), Context Recall (độ đầy đủ thông tin so với ground truth). Tích hợp Diagnostic Tree tự động phân loại lỗi (LLM hallucination, missing chunks, irrelevant chunks) và đề xuất suggested fix tương ứng cho Bottom-5 câu hỏi kém nhất. |
| Contextual embeddings | M5 | `_enrich_single_call()` / `contextual_prepend()` | Làm giàu ngữ cảnh chunks trước khi lập chỉ mục theo kỹ thuật Contextual Retrieval của Anthropic. Gom 4 nhiệm vụ (summary, HyQA câu hỏi giả định, contextual prepend tiêu đề tài liệu, auto metadata extraction) vào một lượt xử lý duy nhất `_enrich_single_call` giúp tiết kiệm chi phí API, đồng thời có cơ chế extractive fallback cục bộ giúp chunk độc lập, không mất bối cảnh ban đầu ngay cả khi offline. |

---

## Phần 2: Khó khăn & Cách giải quyết (Challenges & Debugging)

- **Lỗi kỹ thuật gặp phải (Exact error message):**
  1. `UnicodeEncodeError: 'charmap' codec can't encode character...` trên Windows console/PowerShell khi in tiếng Việt và emoji kết quả đánh giá.
  2. `AuthenticationError: Incorrect API key provided: sk-... (Error code: 401)` khi chạy các tác vụ OpenAI/RAGAS với API key mặc định chưa được cấu hình.
  3. `qdrant_client.http.exceptions.ResponseHandlingException: Connection refused` khi Qdrant Docker container chưa khởi động.
- **Nguyên nhân gốc rễ & Cách debug:**
  1. *Unicode stdout trên Windows:* Do default encoding của PowerShell không phải UTF-8. Cách debug: Đã bổ sung cấu hình `sys.stdout.reconfigure(encoding="utf-8")` và `sys.stderr.reconfigure(encoding="utf-8")` ở đầu tất cả các script.
  2. *API Key Authentication 401:* Chuỗi placeholder `sk-...` trong file `.env` được code đọc như một API key hợp lệ nhưng bị server OpenAI từ chối. Cách debug: Chuẩn hóa kiểm tra trong `config.py` để nhận diện các key giả định/placeholder (`len < 20` hoặc chứa `...`), chuyển sang chế độ heuristic fallback an toàn mà không làm crash hay nghẽn luồng xử lý.
  3. *Qdrant Fallback:* Qdrant port 6333 không phản hồi nếu Docker daemon chưa bật. Cách debug: Bổ sung try/except timeout 2s trong `DenseSearch.__init__` để tự động fallback sang `QdrantClient(":memory:")`, bảo đảm toàn bộ pipeline chạy độc lập và ổn định trong mọi môi trường.
- **Kiến thức còn thiếu & Cách khắc phục:**
  - Hiểu sâu hơn về sự cân bằng đánh đổi (trade-off) giữa Cross-Encoder reranking (chính xác cao nhưng độ trễ tăng) và Bi-Encoder (nhanh nhưng khó bắt ngữ nghĩa phức tạp). Khắc phục bằng cách benchmark latency phân đoạn và chỉ rerank trên top 20 candidate documents thay vì toàn bộ corpus.

---

## Phần 3: Action Plan cho Project cá nhân (Application Plan)

### Project: Hệ thống Trợ lý Hỏi Đáp Quy trình & Tài liệu Kỹ thuật Nội bộ (Enterprise Docs AI Assistant)

#### 1. Hiện trạng
- **Pipeline hiện tại:** Sử dụng Naive RAG cơ bản với fixed-size character chunking (1000 ký tự), chỉ dùng Dense Search (OpenAI embeddings `text-embedding-3-small`) và prompt trực tiếp vào LLM.
- **Vấn đề / Bottlenecks đang gặp:**
  - Văn bản có cấu trúc phân tầng (tiêu đề, điều khoản hợp đồng, bảng biểu) bị cắt rời rạc, làm mất bối cảnh khi trả lời.
  - Tỉ lệ Recall thấp đối với các câu hỏi tra cứu mã quy trình, từ viết tắt nội bộ (ví dụ: "SOP-IT-04", "QĐ-72").
  - LLM thỉnh thoảng bị ảo giác (hallucination) vì top-k chunks chứa quá nhiều văn bản thừa không liên quan (Context Precision thấp).

#### 2. Kế hoạch cải tiến
1. **Chunking strategy:** Chuyển sang kết hợp Structure-aware Chunking và Hierarchical Parent-Child Chunking. Child chunks kích thước 256 tokens để match chính xác chi tiết, khi trả về context cho LLM sẽ nạp cả Parent chunk (2048 tokens) để giữ nguyên vẹn bối cảnh điều khoản.
2. **Search retrieval:** Triển khai Hybrid Search kết hợp BM25 (xử lý chính xác mã định danh, số văn bản) và Dense Search BAAI/bge-m3, hợp nhất điểm xếp hạng qua Reciprocal Rank Fusion (RRF).
3. **Reranking:** Tích hợp Cross-Encoder `BAAI/bge-reranker-v2-m3` cho top 25 candidates lấy từ Hybrid Search, chắt lọc top 4 chunks đắt giá nhất trước khi sinh phản hồi.
4. **Evaluation:** Xây dựng bộ test-set gồm 50 câu hỏi golden dataset đa dạng (factoid, multi-hop, procedural). Đánh giá định kỳ bằng 4 chỉ số RAGAS và tự động sinh Failure Report qua Diagnostic Tree.
5. **Enrichment:** Sử dụng phương pháp Contextual Prepend bổ sung nguồn tài liệu và tóm tắt vị trí section vào đầu mỗi chunk trước khi vector hóa.

#### 3. Timeline triển khai
- **Tuần 1:** Tái cấu trúc pipeline dữ liệu: Triển khai Hierarchical Chunking, Underthesea tokenizer và cấu hình Qdrant Vector Store.
- **Tuần 2:** Tích hợp Hybrid Search (BM25 + Dense) và cơ chế RRF; benchmark độ chính xác so sánh với retrieval cũ.
- **Tuần 3:** Thêm tầng Cross-Encoder Reranker; tối ưu hóa prompt template và giảm thiểu độ trễ; thiết lập hệ thống logging chi tiết.
- **Tuần 4:** Chạy evaluation toàn diện với RAGAS test suite, phân tích bottom failures, tinh chỉnh ngưỡng lọc và hoàn thiện tài liệu bàn giao sản phẩm.
