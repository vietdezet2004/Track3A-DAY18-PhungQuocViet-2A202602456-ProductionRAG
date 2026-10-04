# Checklist Lab 18: Production RAG Pipeline

Theo dõi các checkpoint theo thứ tự. Mỗi checkpoint có hướng dẫn chi tiết trong thư mục [checkpoints](checkpoints/).

## CP1 — Setup và baseline
- [x] Tạo môi trường Python 3.11+ và cài dependencies.
- [x] Khởi động Qdrant bằng Docker Compose.
- [x] Tạo `.env`, cấu hình `OPENAI_API_KEY` khi dùng các bước cần LLM.
- [x] Chạy baseline và xác nhận báo cáo được tạo.
- [x] Xem [hướng dẫn CP1](checkpoints/CP01-setup-baseline.md).

## CP2 — M1: Advanced Chunking
- [x] Hoàn thành semantic, hierarchical và structure-aware chunking.
- [x] Kiểm tra parent-child, `parent_id`, headers và `section` metadata.
- [x] Chạy test M1.
- [x] Xem [hướng dẫn CP2](checkpoints/CP02-m1-chunking.md).

## CP3 — M2: Hybrid Search
- [x] Hoàn thành tiếng Việt segmentation, BM25, Dense Search và RRF.
- [x] Xác nhận kết quả có đúng `method` và truy vấn nghỉ phép có liên quan.
- [x] Chạy test M2.
- [x] Xem [hướng dẫn CP3](checkpoints/CP03-m2-hybrid-search.md).

## CP4 — M3: Reranking
- [x] Nạp CrossEncoder `BAAI/bge-reranker-v2-m3` và rerank candidate documents.
- [x] Xác nhận giới hạn kết quả, thứ tự điểm giảm dần và thứ hạng truy vấn nghỉ phép.
- [x] Chạy test M3.
- [x] Xem [hướng dẫn CP4](checkpoints/CP04-m3-reranking.md).

## CP5 — M4: RAGAS Evaluation
- [x] Tính đủ 4 metric: Faithfulness, Answer Relevancy, Context Precision, Context Recall.
- [x] Bắt lỗi evaluation có kiểm soát.
- [x] Sinh Bottom-N failure có diagnosis và suggested fix.
- [x] Chạy test M4.
- [x] Xem [hướng dẫn CP5](checkpoints/CP05-m4-evaluation.md).

## CP6 — M5: Enrichment
- [x] Chọn combined single-call hoặc các technique riêng.
- [x] Hoàn thành `enrich_chunks()` trả về `list[EnrichedChunk]`.
- [x] Kiểm tra enriched text và fallback khi thiếu API key.
- [x] Chạy test M5.
- [x] Xem [hướng dẫn CP6](checkpoints/CP06-m5-enrichment.md).

## CP7 — Pipeline và kết quả đánh giá
- [x] Chạy pipeline end-to-end thành công.
- [x] Tạo/kiểm tra `reports/ragas_report.json` và báo cáo baseline.
- [x] Điền bảng so sánh 4 metrics và mức thay đổi.
- [x] Xem [hướng dẫn CP7](checkpoints/CP07-pipeline-evaluation.md).

## CP8 — Failure analysis
- [x] Chọn 5 câu hỏi có kết quả tệ nhất từ báo cáo.
- [x] Ghi expected, actual, metric yếu nhất, Error Tree, root cause và suggested fix.
- [x] Hoàn thiện `analysis/failure_analysis.md`.
- [x] Xem [hướng dẫn CP8](checkpoints/CP08-failure-analysis.md).

## CP9 — Reflection
- [x] Tạo `analysis/reflections/reflection_[HoTen].md` từ template.
- [x] Map đủ concept của 5 modules vào hàm/code cụ thể và observation.
- [x] Ghi exact error, cách debug, kiến thức còn thiếu và kế hoạch áp dụng.
- [x] Có timeline hành động cho project cá nhân.
- [x] Xem [hướng dẫn CP9](checkpoints/CP09-reflection.md).

## CP10 — Kiểm tra và nộp bài
- [x] Chạy toàn bộ tests và `python check_lab.py`; xử lý TODO còn lại.
- [x] Xác nhận pipeline exit code 0 và đủ deliverables trong repo.
- [ ] Đặt tên repo đúng `K4-Track3A-DAY18-<HoVaTen>-<MSSV>-ProductionRAG`.
- [ ] Push repo Public và nộp link lên VLearn LMS / Codelab trước deadline.
- [x] Xem [hướng dẫn CP10](checkpoints/CP10-final-submission.md).