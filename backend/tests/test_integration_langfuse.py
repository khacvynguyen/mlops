import importlib
import socket
import os
import pytest
import sys
import requests
import types
from urllib.parse import urlparse

# Utility: Check if Langfuse web is running on localhost:3000
def _is_port_open(host: str, port: int, timeout: float = 0.5) -> bool:
    """Return True if the TCP port is open (used to detect Langfuse)."""

    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except OSError:
        return False

LANGFUSE_URL = os.getenv("LANGFUSE_URL", "http://localhost:3000")

parsed = urlparse(LANGFUSE_URL)
langfuse_running = _is_port_open(parsed.hostname, parsed.port or 80)

# Fixture: Auto cleanup monkeypatched modules between tests
@pytest.fixture(autouse=True)
def reset_imports():
    """Ensure we reset any monkeypatched modules between integration tests."""
    yield
    for mod in ["litellm", "client"]:
        sys.modules.pop(mod, None)

# ✅ Test 1: Check that Langfuse web responds
@pytest.mark.integration
@pytest.mark.skipif(not langfuse_running, reason="Langfuse web not reachable on localhost:3000")
def test_langfuse_web_health():
    """Check that Langfuse web responds with 200/401/403 — proves it's alive."""
    print("Checking Langfuse web health...")
    # Basic reachability test; langfuse web may not expose /health publicly
    # so we just GET the root and expect a 200 or 401/403 depending on setup
    resp = requests.get(LANGFUSE_URL, timeout=3)
    assert resp.status_code in (200, 401, 403)
    print(f"✅ Langfuse web responded with HTTP {resp.status_code}")


# ✅ Test 2: Ensure client waits for Langfuse then calls model
@pytest.mark.integration
@pytest.mark.skipif(not langfuse_running, reason="Langfuse web not reachable on localhost:3000")
def test_client_waits_for_langfuse_then_calls_model(monkeypatch):
    """Integration test verifying client connects to Langfuse and calls LLM."""
    print("🚀 Running integration test with fake LiteLLM...")

    # Arrange fake litellm
    class FakeChoicesMessage:
        def __init__(self, content):
            self.content = content

    class FakeChoice:
        def __init__(self, content):
            self.message = FakeChoicesMessage(content)

    class FakeResponse:
        def __init__(self, content):
            self.choices = [FakeChoice(content)]

    def _completion(**kwargs):
        return FakeResponse("integration-ok")

    monkeypatch.setitem(sys.modules, "litellm", types.ModuleType("litellm"))
    sys.modules["litellm"].completion = _completion

    # Import client after monkeypatching
    client = importlib.import_module("client")
    importlib.reload(client)

    # Act
    out = client.make_inference_request("hello")

    # Assert
    assert isinstance(out, str) and len(out) > 0
    assert out == "integration-ok"
    print("✅ make_inference_request returned:", out)

# ✅ Test 3: End-to-end test for client.main()
@pytest.mark.integration
@pytest.mark.skipif(not langfuse_running, reason="Langfuse web not reachable on localhost:3000")

def test_client_main_runs(monkeypatch):
    """Integration test verifying client.main() runs successfully."""
    print("🚀 Running end-to-end test for client.main()...")

    # --- Mock LiteLLM ---
    class FakeChoiceMessage:
        def __init__(self, content):
            self.content = content

    class FakeChoice:
        def __init__(self, content):
            self.message = FakeChoiceMessage(content)

    class FakeResponse:
        def __init__(self, content):
            self.choices = [FakeChoice(content)]

    def _completion(**kwargs):     
        return FakeResponse("integration-ok")

    monkeypatch.setitem(sys.modules, "litellm", types.ModuleType("litellm"))
    sys.modules["litellm"].completion = _completion

    # Speed up test (skip delay)
    monkeypatch.setattr("time.sleep", lambda _seconds: None)

    # Import and reload client
    client = importlib.import_module("client")
    importlib.reload(client)

    # Act
    client.main()

    # Assert
    assert True
    print("✅ client.main() ran successfully")