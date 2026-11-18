/*
 * CẤU HÌNH CÔNG KHAI CHO GIAO DIỆN.
 * Hai giá trị dưới đây được phép xuất hiện ở frontend:
 * - Project URL
 * - Publishable key (sb_publishable_...) hoặc legacy anon key
 * TUYỆT ĐỐI KHÔNG điền secret key / service_role key / mật khẩu Admin vào file này.
 */
window.THU_PHAP_CONFIG = Object.freeze({
  supabaseUrl: 'https://YOUR_PROJECT_REF.supabase.co',
  supabasePublishableKey: 'YOUR_SUPABASE_PUBLISHABLE_KEY'
});
