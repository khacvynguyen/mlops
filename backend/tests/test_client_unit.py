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
    with pytest.raises(RuntimeError):
        client.make_inference_request("hi")


def test_wait_for_service_success(http_ok, fast_sleep):
    client = import_client()
    assert client.wait_for_service("http://example.com") is True

def test_wait_for_service_failure(http_fail, fast_sleep):
    client = import_client()
    assert client.wait_for_service("http://example.com", max_retries=3, delay=0.1) is False
