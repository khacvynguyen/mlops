import os
import time
import requests
from langfuse.decorators import observe, langfuse_context
from litellm import completion

# ============================================================
# 🧩 1️⃣ Load biến môi trường (Gemini API key)
# ============================================================
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    raise ValueError("❌ Missing GEMINI_API_KEY in environment variables")

# ============================================================
# ⏳ 2️⃣ Kiểm tra service backend/frontend có sẵn sàng chưa
# ============================================================
def wait_for_service(url, max_retries=30, delay=2):
    """Wait for a service to be ready before sending requests."""
    for i in range(max_retries):
        try:
            response = requests.get(url, timeout=5)
            # ✅ Chấp nhận cả 200, 401, 403 như “service sẵn sàng”
            if response.status_code in (200, 401, 403):
                print(f"✅ Service at {url} is ready! (status {response.status_code})")
                return True
        except requests.exceptions.RequestException:
            pass
        print(f"⏳ Waiting for service at {url}... (attempt {i + 1}/{max_retries})")
        time.sleep(delay)
    print(f"❌ Service at {url} not ready after {max_retries} attempts.")
    return False

# ============================================================
# 🤖 3️⃣ Hàm gọi inference với LiteLLM + Langfuse tracking
# ============================================================
# ✅ Sử dụng @observe để tự động tạo trace trong Langfuse dashboard
# ✅ Đặt tên trace và type để dễ phân loại
@observe(as_type="generation", name="Gemini Inference Request")
def make_inference_request(prompt, max_tokens=50, temperature=0.8, trace_id=None):
    """
    Gửi prompt đến Gemini thông qua LiteLLM.
    Tự động log input/output/error vào Langfuse dashboard.
    """
    try:
        # 🔹 Nếu có trace_id truyền từ frontend, liên kết trace
        if trace_id:
            langfuse_context.update_current_trace(trace_id)

        # 🔹 Ghi input để hiển thị trong Langfuse dashboard
        langfuse_context.update_current_observation(input={"prompt": prompt})

        # 🔹 Gọi model Gemini qua LiteLLM
        response = completion(
            model="gemini/gemini-2.5-flash-lite",
            api_key=GEMINI_API_KEY,
            messages=[{"role": "user", "content": prompt}],
            max_tokens=max_tokens,
            temperature=temperature,
        )

        # 🔹 Parse kết quả an toàn – hỗ trợ cả dict và object của LiteLLM
        result_text = None
        try:
            if isinstance(response, dict):
                # Một số model dùng "message.content", một số dùng "text"
                choice = response.get("choices", [{}])[0]
                result_text = (
                    choice.get("message", {}).get("content")
                    or choice.get("text")
                    or None
                )
            else:
                # ModelResponse object (LiteLLM)
                msg = getattr(response.choices[0], "message", None)
                result_text = (
                    getattr(msg, "content", None)
                    or getattr(response.choices[0], "text", None)
        )
        except Exception as e:
            print("⚠️ Failed to parse model response:", e)
            result_text = None

        # 🔹 Cập nhật output cho Langfuse
        langfuse_context.update_current_observation(output=result_text)

        # ✅ Log thông tin ra console
        print(f"✅ Model response: {result_text}")
        return result_text

    except Exception as e:
        # 🔹 Ghi lỗi vào Langfuse (chỉ dùng status_message và level)
        langfuse_context.update_current_observation(
            level="ERROR",
            status_message=str(e),
            output=None,
        )
        print(f"❌ Inference failed: {e}")
        raise e

# ============================================================
# 🚀 4️⃣ Ví dụ chạy test
# ============================================================
if __name__ == "__main__":
    # URL ví dụ cho health check (frontend/backend)
    backend_url = "http://llm-backend-service.llm-app.svc.cluster.local"
    if wait_for_service(backend_url):
        print("🔹 Sending test prompt to Gemini...")
        response = make_inference_request("Giải thích ý nghĩa của học sâu trong AI là gì?")
        print("✨ Final response:", response)