# MacViewer Design System: 3-Color Strict Palette

> **Phiên bản:** 2.0 (Redesign)  
> **Nguyên tắc:** Apple Human Interface Guidelines + Anti-Slop Discipline + Quy tắc 3 Màu Tối Giản.

---

## 1. Hệ thống 3 Màu Chuẩn (The 3-Color System)

| Tên màu | Vai trò | Giá trị Hex / Token | Ứng dụng thực tế |
|---|---|---|---|
| **Foundation Slate** | **Màu 1: Nền tảng trung tính** | Dark: `#0D1117` / Light: `#F6F8FA`<br>Card: `#161B22` / `#FFFFFF`<br>Border: `rgba(0,0,0,0.08)` / `rgba(255,255,255,0.08)` | Nền cửa sổ, nền card bề mặt, đường viền 1px, văn bản chính (`#FFFFFF` / `#1F2328`) và phụ (`#8B949E` / `#656D76`). |
| **Electric Cobalt** | **Màu 2: Điểm nhấn tương tác** | `#2563EB` (RGB: 37, 99, 235)<br>Subtle: `rgba(37, 99, 235, 0.08)` | Nút CTA chính ("Connect to Partner", "Start Sharing"), tiêu điểm focus ring, icon nhận diện thương hiệu, nút copy hành động. |
| **Sage Emerald** | **Màu 3: Trạng thái & Tín hiệu** | `#10B981` (RGB: 16, 185, 129)<br>Subtle: `rgba(16, 185, 129, 0.08)` | Trạng thái trực tuyến (Online dot), biểu tượng bảo mật và cấp quyền (Permissions Granted), phản hồi sao chép thành công. |

> **Cấm tuyệt đối:** Không pha trộn màu cam (orange), tím (purple), chàm hay dải gradient đa sắc lộn xộn. Mọi chi tiết đồ hoạ phải được quy chuẩn vào 3 nhóm màu trên.

---

## 2. Quy chuẩn UX/UI (Interaction & Layout)

### A. Định luật Hick (Hick's Law) - Giảm tải nhận thức
- Giao diện chia thành **2 cột đối xứng rõ ràng**:
  - **Cột trái:** Điều khiển máy từ xa (`MAC → WINDOWS`).
  - **Cột phải:** Cho phép máy khác truy cập (`WINDOWS → MAC`).
- Người dùng không phải băn khoăn tìm chức năng, nhìn vào là thấy ngay luồng công việc cần làm.

### B. Định luật Fitts (Fitts's Law) - Tối ưu thao tác bấm
- Nút CTA kết nối to, rõ ràng, chiếm toàn bộ chiều rộng card với chiều cao `34-38px`, bo góc `8px`.
- Nút Copy ID / Password có icon trực quan kèm phản hồi `Copied` chuyển sang màu Sage Emerald trong 1.5 giây.

### C. Độ rõ ràng typographic (Monospace ID & PIN)
- Số ID kết nối được định dạng thành cụm 3 số (`XX XXX XXX`) với font Monospaced kích thước `22px` đậm, giúp đọc to qua điện thoại hoặc đối chiếu không bị nhầm lẫn giữa số `0` và chữ `O`, số `1` và chữ `l`.
