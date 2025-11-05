from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
import asyncio
import importlib

def get_client_module():
    return importlib.import_module("client")

app = FastAPI(title="Inference Service", version="1.0")

class InferenceRequest(BaseModel):
    prompt: str

class InferenceResponse(BaseModel):
    output: str

@app.post("/inference", response_model=InferenceResponse)
async def run_inference(request: Request, body: InferenceRequest):
    """
    API nhận prompt, chuyển tiếp tới client và ghi trace Langfuse
    """
    try:
        client = get_client_module()

        # 👇 Lấy trace_id từ header nếu có
        trace_id = request.headers.get("x-trace-id")

        # 👇 Gọi client và truyền trace_id
        result = await asyncio.wait_for(
            asyncio.to_thread(client.make_inference_request, body.prompt, trace_id=trace_id),
            timeout=30
        )

        if not result:
            raise HTTPException(status_code=500, detail="Failed to get inference output")

        return InferenceResponse(output=result)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    return {"status": "ok"}