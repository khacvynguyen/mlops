import streamlit as st
import requests
import os

BACKEND_URL = os.getenv("BACKEND_URL", "http://llm-backend-service.llm-app.svc.cluster.local/inference")

st.set_page_config(
    page_title="LLM Inference Demo",
    page_icon="🤖",
    layout="centered"
)

st.title("🤖 LLM Inference Playground")
st.markdown(
    """
    Enter a **prompt** to send to your LLM backend (FastAPI + LiteLLM + Gemini).  
    This app will call the `/inference` API and display the model's response below.
    """
)

# Input form
with st.form("inference_form"):
    prompt = st.text_area("Enter your prompt:", height=150, placeholder="Example: Describe the Sun.")
    submitted = st.form_submit_button("Send Request")

# Call backend API
if submitted:
    if not prompt.strip():  
        st.warning("Please enter a prompt before sending.")
    else:
        try:
            with st.spinner("⏳ Sending request to backend..."): 
                response = requests.post(
                    BACKEND_URL,
                    json={"prompt": prompt.strip()},  
                    timeout=30
                )

            if response.status_code == 200:
                result = response.json()
                st.success("✅ Model response:")
                st.markdown(f"**Output:**\n\n{result.get('output', '(No response content)')}")
            else:
                st.error(f"⚠️ Backend returned error {response.status_code}: {response.text}")

        except requests.exceptions.RequestException as e:
            st.error(f"❌ Cannot connect to backend: {e}")

st.markdown("---")
st.caption("LLM Inference Service • Powered by FastAPI + Streamlit + LiteLLM")