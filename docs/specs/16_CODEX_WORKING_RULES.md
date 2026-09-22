# CODEX WORKING RULES

1. Đọc spec trước code change.
2. Chỉ làm phase được giao.
3. Không rewrite toàn app nếu migration incremental khả thi.
4. Không đổi framework/database/state management chỉ vì sở thích.
5. Ưu tiên compatibility với dữ liệu cũ cho tới khi importer/migration pass.
6. Mỗi domain mới có model/repository contract/test trước UI phức tạp.
7. Không để file mới thành god-file > khoảng 800-1000 dòng nếu có thể tách hợp lý.
8. Không thêm business rule vào painter/widget callback nếu có thể đặt ở controller/use case/domain.
9. Không hard-code display name làm business key.
10. Không dùng integer DB row ID làm cross-domain identity mới.
11. Không swallow exception trong business/data migration.
12. Không xóa legacy trước khi có replacement + migration test.
13. Mọi schema migration phải reversible/safety-aware ở mức hợp lý.
14. Completion report phải chỉ ra phần nào giữ, phần nào migrate, phần nào chưa làm.
