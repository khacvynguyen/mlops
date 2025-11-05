import importlib
import types
import pytest


def import_client():
    # Import lazily to ensure fixtures (monkeypatching) are applied first
    module = importlib.import_module("client")
    importlib.reload(module)
    return module


def test_make_inference_request_success(fake_litellm):
    fake_litellm.set_success_response(content="hello world")
    client = import_client()
    output = client.make_inference_request("hi", max_tokens=5, temperature=0.1)
    assert output == "hello world"


def test_make_inference_request_error(fake_litellm):
    fake_litellm.set_error(RuntimeError("api down"))
    client = import_client()
    output = client.make_inference_request("hi")
    assert output is None


def test_story_uses_helper(monkeypatch):
    calls = {}

    def _stub(prompt, max_tokens, temperature):
        calls.update(locals())
        return "story out"

    client = import_client()
    monkeypatch.setattr(client, "make_inference_request", _stub)

    out = client.story()
    assert out == "story out"
    assert calls["max_tokens"] == 80
    assert isinstance(calls["prompt"], str) and len(calls["prompt"]) > 0


def test_programming_advice_uses_helper(monkeypatch):
    calls = {}

    def _stub(prompt, max_tokens, temperature):
        calls.update(locals())
        return "advice out"

    client = import_client()
    monkeypatch.setattr(client, "make_inference_request", _stub)

    out = client.programming_advice()
    assert out == "advice out"
    assert calls["max_tokens"] == 60
    assert isinstance(calls["prompt"], str) and len(calls["prompt"]) > 0


def test_wait_for_service_success(http_ok, fast_sleep):
    client = import_client()
    assert client.wait_for_service("http://example.com") is True

def test_wait_for_service_failure(http_fail, fast_sleep):
    client = import_client()
    assert client.wait_for_service("http://example.com", max_retries=3, delay=0.1) is False



