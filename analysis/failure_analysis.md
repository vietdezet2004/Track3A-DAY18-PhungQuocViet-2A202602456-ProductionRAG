# Failure Analysis — Lab 18: Production RAG

**Họ và tên học viên:** Phùng Quốc Việt  
**MSSV:** 2A202602456  
**Khóa:** K4 - Track 3A  

---

## RAGAS Scores

| Metric | Naive Baseline | Production | Δ |
|--------|---------------|------------|---|
| Faithfulness | 1.0000 | 1.0000 | +0.0000 |
| Answer Relevancy | 0.9209 | 0.9162 | -0.0047 |
| Context Precision | 0.9553 | 0.9580 | +0.0027 |
| Context Recall | 0.9259 | 0.9093 | -0.0166 |

---

## Bottom-5 Failures

### #1
- **Question:** Bao lâu phải đổi mật khẩu một lần?
- **Expected:** Theo chính sách hiện hành (v2.0), mật khẩu phải được thay đổi mỗi 120 ngày. Chính sách cũ yêu cầu 90 ngày nhưng đã bị thay thế.
- **Got:** Trích từ tài liệu mat_khau_v2.md. Phương thức MFA được chấp nhận: ứng dụng Authenticator (ưu tiên), SMS OTP, hoặc YubiKey. ## Chu kỳ thay đổi Mật khẩu phải được thay đổi **mỗi 120 ngày**. Hệ thống tự động nhắc nhở trước 14 ngày.
- **Worst metric:** Context Precision (0.7200)
- **Error Tree:** Output đúng nội dung (120 ngày) → Context chứa thêm đoạn MFA ở đầu → Ranh giới chunk chưa được tách hoàn toàn độc lập giữa các heading con → Context Precision bị kéo giảm.
- **Root cause:** Child chunk kích thước 256 ký tự gom cả câu kết thúc của section MFA và câu bắt đầu của section chu kỳ thay đổi mật khẩu.
- **Suggested fix:** Căn chỉnh ranh giới cắt chunk theo Markdown header (heading-aware split) để mỗi section nhỏ nằm trọn trong 1 child chunk độc lập.

### #2
- **Question:** Thâm niên bao nhiêu năm thì được cộng thêm ngày phép?
- **Expected:** Theo chính sách v2024 hiện hành, nhân viên có thâm niên từ 3 năm trở lên được cộng thêm 1 ngày phép cho mỗi 3 năm. Chính sách cũ v2023 yêu cầu 5 năm.
- **Got:** Trích từ tài liệu nghi_phep_nam_v2023.md. Nhân viên có thâm niên từ **5 năm trở lên** được cộng thêm **1 ngày phép** cho mỗi 5 năm làm việc liên tục.
- **Worst metric:** Context Precision (0.7200)
- **Error Tree:** Output trích dẫn thông tin cũ (v2023) → Context retrieval lấy nhầm file tài liệu đã hết hiệu lực do query không có chỉ định thời gian → Trả lời sai thực tế hiện hành.
- **Root cause:** Xung đột tài liệu đa phiên bản (Temporal version conflict). Kho dữ liệu có cả 2 phiên bản 2023 và 2024 mà chưa có cờ trạng thái `is_active` hoặc `effective_year` để lọc.
- **Suggested fix:** Áp dụng Metadata Filtering để lọc các tài liệu có `status: active` hoặc `effective_year: 2024`, hoặc bổ sung quy tắc System Prompt yêu cầu ưu tiên phiên bản mới nhất.

### #3
- **Question:** Có cần kích hoạt xác thực đa yếu tố (MFA) không?
- **Expected:** Có, theo chính sách mật khẩu v2.0 hiện hành, tất cả nhân viên bắt buộc kích hoạt MFA cho email, VPN và hệ thống nội bộ. Chính sách cũ v1.0 không yêu cầu MFA.
- **Got:** Trích từ tài liệu mat_khau_v2.md. Khuyến khích sử dụng passphrase dài hơn 16 ký tự. ## Xác thực đa yếu tố (MFA) Tất cả nhân viên **bắt buộc** kích hoạt MFA cho tài khoản email, VPN và các hệ thống nội bộ.
- **Worst metric:** Context Precision (0.7200)
- **Error Tree:** Output khẳng định bắt buộc kích hoạt MFA (đúng) → Context chứa câu khuyến khích passphrase của mục trước → Độ chính xác ngữ cảnh bị giảm nhẹ.
- **Root cause:** Kỹ thuật contextual prepend bổ sung thêm câu mô tả nhưng phần thân chunk vẫn dính một phần text của đoạn văn liền trước.
- **Suggested fix:** Sử dụng regex lọc bỏ các câu lạc đề nằm trước tiêu đề chính (`## Xác thực đa yếu tố`) khi tạo child chunks trong M1.

### #4
- **Question:** Muốn mua thiết bị trị giá 55 triệu cần ai phê duyệt?
- **Expected:** Đơn hàng trên 50.000.000 VNĐ cần Tổng Giám đốc (CEO) phê duyệt.
- **Got:** Trích từ tài liệu mua_sam.md. Mua sắm thiết bị CNTT (laptop, server, phần mềm) cần có xác nhận của phòng CNTT về cấu hình kỹ thuật trước khi đề xuất...
- **Worst metric:** Context Recall (0.8283)
- **Error Tree:** Output chỉ nêu xác nhận kỹ thuật phòng CNTT → Context thiếu trích đoạn về bảng hạn mức phê duyệt theo số tiền (trên 50 triệu) → Thiếu thông tin Tổng Giám đốc.
- **Root cause:** Từ khóa "thiết bị" khiến BM25 và Dense Search tập trung vào mục thiết bị CNTT mà không truy xuất được bảng phân quyền chi ngân sách nằm ở mục khác trong tài liệu mua sắm.
- **Suggested fix:** Triển khai Parent Document Retrieval để khi child chunk về thiết bị được match, hệ thống tự động kéo kèm Parent Chunk chứa toàn bộ bảng hạn mức thẩm quyền phê duyệt.

### #5
- **Question:** Một nhân viên Senior có 9 năm thâm niên được nghỉ bao nhiêu ngày phép năm và lương trong khoảng nào?
- **Expected:** Theo chính sách v2024: 15 ngày cơ bản + 3 ngày thâm niên (9÷3=3) = 18 ngày phép. Lương Senior (P3-P4): 20-35 triệu VNĐ/tháng.
- **Got:** Trích từ tài liệu nghi_phep_nam_v2024.md. Ví dụ: nhân viên 9 năm thâm niên được 18 ngày phép (15 + 3). ## Quy định sử dụng Phép năm phải được đăng ký trước ít nhất 2 ngày làm việc...
- **Worst metric:** Context Recall (0.8644)
- **Error Tree:** Output trả lời đúng số ngày phép (18 ngày) nhưng hoàn toàn thiếu thông tin mức lương Senior → Context chỉ truy xuất được tài liệu nghỉ phép mà bỏ sót tài liệu bảng lương (`bang_luong_2024.md`).
- **Root cause:** Câu hỏi dạng đa ý / đa tài liệu (Multi-hop question). Một câu hỏi đòi hỏi thông tin từ 2 văn bản khác nhau, nhưng retrieval chỉ tối ưu hóa theo semantic của vế đầu.
- **Suggested fix:** Thêm bước Query Decomposition: Tách câu hỏi thành 2 sub-queries: (1) "Số ngày phép của nhân viên Senior 9 năm thâm niên" và (2) "Mức lương nhân viên Senior", sau đó tổng hợp contexts trước khi rerank.

---

## Case Study (cho presentation)

**Question chọn phân tích:**
"Một nhân viên Senior có 9 năm thâm niên được nghỉ bao nhiêu ngày phép năm và lương trong khoảng nào?"

**Error Tree walkthrough:**
1. **Output đúng?** → Output chỉ trả lời đúng một nửa câu hỏi (18 ngày phép), thiếu hoàn toàn khoảng lương (20-35 triệu).
2. **Context đúng?** → Sai/Thiếu. Context top-3 sau khi Rerank chỉ toàn là các đoạn trích từ `nghi_phep_nam_v2024.md`, hoàn toàn không có chunk nào từ `bang_luong_2024.md`.
3. **Query rewrite OK?** → Chưa có Query Rewrite. Truy vấn gốc chứa cả 2 thực thể ngữ nghĩa xa nhau ("phép năm" và "mức lương") khiến embedding vector bị lệch trọng tâm về phía chủ đề nghỉ phép.
4. **Fix ở bước:** Bước tiền xử lý truy vấn (Query Transformation / Multi-Query Decomposition) kết hợp với Parent Document Retrieval.

**Nếu có thêm 1 giờ, sẽ optimize:**
- Triển khai mô-đun **Sub-query Decomposition**: Tự động phân tích câu hỏi phức hợp thành các truy vấn đơn nguyên bản trước khi đẩy qua bộ Hybrid Search.
- Bổ sung **Temporal Metadata Routing**: Lọc và ưu tiên tự động các tài liệu mang tag `year: 2024` hoặc `status: current` để triệt tiêu lỗi lấy nhầm chính sách cũ (như trường hợp v2023 vs v2024).
- Tinh chỉnh trọng số RRF giữa Lexical và Dense theo từng loại câu hỏi (keyword-heavy vs semantic-heavy).
