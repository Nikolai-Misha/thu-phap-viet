# Thư Pháp Việt — gói website triển khai trực tuyến

## 1. Kiến trúc và nguyên tắc bảo mật

- `index.html`: giao diện website, responsive cho điện thoại, tablet và máy tính.
- `config.js`: chỉ chứa Supabase Project URL và Publishable Key (được thiết kế để dùng ở frontend).
- `supabase-schema.sql`: bảng dữ liệu, kho media và chính sách Row Level Security (RLS).
- Supabase Auth xác minh email/mật khẩu; quyền Admin được kiểm tra từ bảng `admin_users` ở máy chủ. Cấu hình mặc định không lưu phiên đăng nhập vào localStorage; Admin cần đăng nhập lại sau khi tải lại trang để giảm thời gian tồn tại của access token.
- Khách truy cập chỉ đọc danh sách tác phẩm và media công khai. Chỉ tài khoản có UID được chủ website cấp quyền Admin mới được tạo, sửa, gỡ tác phẩm hoặc upload/xóa media.

**Không có mật khẩu Admin trong HTML/JavaScript. Không đưa `secret key`, `service_role key`, database password hoặc mật khẩu người dùng vào `index.html`, `config.js` hay GitHub.** Publishable Key/anon key không phải mật khẩu; quyền thật được bảo vệ bằng RLS trên Supabase.

Media trong bucket `artworks` là công khai vì website là bộ sưu tập tác phẩm công khai. Không tải tài liệu cá nhân hoặc dữ liệu riêng tư vào bucket này.

## 2. Tạo backend Supabase

1. Tạo một project trên Supabase.
2. Mở **SQL Editor**, dán và chạy toàn bộ `supabase-schema.sql`.
3. Mở **Authentication → Providers → Email**. Giữ đăng nhập email/mật khẩu; tắt public sign-up/đăng ký tự do vì website chỉ có Admin.
4. Mở **Authentication → Users** và tạo user Admin thủ công. Dùng email do bạn kiểm soát và mật khẩu mạnh, riêng biệt; xác nhận email theo cài đặt dự án.
5. Sao chép `User UID` của tài khoản vừa tạo. Trong SQL Editor chạy câu dưới đây sau khi thay UUID thật:

```sql
insert into public.admin_users (user_id)
values ('THAY-BANG-USER-UID-THAT')
on conflict (user_id) do nothing;
```

6. Mở **Project Settings → API** (tên mục có thể thay đổi theo giao diện Supabase). Sao chép **Project URL** và **Publishable key** (hoặc legacy `anon` key). Không lấy `secret` / `service_role` key.
7. Mở `config.js`, thay hai chuỗi mẫu:

```js
window.THU_PHAP_CONFIG = Object.freeze({
  supabaseUrl: 'https://YOUR_PROJECT_REF.supabase.co',
  supabasePublishableKey: 'YOUR_SUPABASE_PUBLISHABLE_KEY'
});
```

8. Trong **Authentication → URL Configuration**, đặt Site URL và Redirect URLs theo URL GitHub Pages thực tế, ví dụ `https://TEN-GITHUB.github.io/TEN-REPOSITORY/`.

## 3. Publish miễn phí bằng GitHub Pages

1. Tạo một GitHub repository **public** mới. Với GitHub Free, GitHub Pages dùng miễn phí cho repository public.
2. Đưa `index.html` và `config.js` vào thư mục gốc repository. Có thể đưa `supabase-schema.sql` và README lên cùng repo; chúng không chứa bí mật. Không commit bản sao có service key hoặc mật khẩu.
3. Vào **Settings → Pages**.
4. Trong **Build and deployment**, chọn **Deploy from a branch**, branch `main`, folder `/ (root)`, rồi Save.
5. Đợi GitHub Pages publish và mở địa chỉ `https://TEN-GITHUB.github.io/TEN-REPOSITORY/`.
6. Bật **Enforce HTTPS** nếu tùy chọn xuất hiện.

GitHub Pages là static hosting, phù hợp với frontend của dự án này. Backend dữ liệu và đăng nhập nằm trên Supabase, không phải GitHub Pages.

### DuckDNS có cần không?

Không cần DuckDNS để có địa chỉ miễn phí. Dùng URL `github.io` là phương án ít bước nhất. DuckDNS chủ yếu là Dynamic DNS để ánh xạ hostname tới IP thay đổi của máy chủ; nó không lưu trữ website và không thay thế backend. Với GitHub Pages, cứ dùng hostname `github.io` trước; domain riêng có thể thiết lập sau theo loại bản ghi DNS mà GitHub hướng dẫn.

## 4. Cách kiểm tra bảo mật sau khi triển khai

- Mở website ở cửa sổ ẩn danh: khách xem được tác phẩm, không thấy nút thêm/sửa/gỡ.
- Thử truy cập đăng nhập bằng một tài khoản không nằm trong `admin_users`: không có quyền quản trị.
- Đăng nhập bằng tài khoản Admin đã cấp UID: thấy biểu tượng quản trị Google Material Symbols và các nút `Sửa` / `Gỡ` trên từng thẻ.
- Sửa tiêu đề/mô tả/ngày, thêm hoặc gỡ media, lưu lại rồi tải lại trang để kiểm tra dữ liệu vẫn còn.
- Thử upload ảnh và video trong giới hạn 50 MB/file.
- Không chia sẻ Publishable Key như thể đó là mật khẩu; nhưng tuyệt đối không đưa secret/service_role key ra frontend.
- Bật MFA/TOTP cho tài khoản Admin nếu có thể; giữ email khôi phục an toàn; không tạo tài khoản Admin cho người khác nếu không cần. Phiên quản trị sẽ kết thúc khi tải lại trang/đóng trang do `persistSession: false` được bật có chủ đích.

## 5. Giới hạn gói miễn phí cần biết

Supabase Free hiện có giới hạn dung lượng database, storage, egress và có thể tự pause project sau một tuần không hoạt động. Dung lượng Storage miễn phí hiện hiển thị là 1 GB và giới hạn upload tối đa 50 MB/file. Đây là giới hạn của nhà cung cấp, không phải do giao diện website. Theo dõi trang Usage của project để tránh vượt hạn mức.

## 6. Dữ liệu cũ đã lưu trên trình duyệt

Bản HTML trước lưu dữ liệu vào IndexedDB của từng trình duyệt/thiết bị. Bản cloud mới không tự đồng bộ dữ liệu cũ từ IndexedDB lên Supabase. Vì vậy, nếu đã có tác phẩm thật trong bản cũ, hãy giữ file backup và dữ liệu trình duyệt cũ trước khi thay thế; cần nhập lại media cũ vào kho Supabase để mọi thiết bị cùng xem được.

## 7. Cấu trúc thư mục

```text
thu-phap-viet/
├── index.html
├── config.js
├── supabase-schema.sql
└── README-VI.md
```
