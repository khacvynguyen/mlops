import sys
import types
import pytest

@pytest.fixture(autouse=True)
def noop_langfuse_observe(monkeypatch):
    """Provide a no-op replacement for `langfuse.observe` decorator."""
    def _identity_decorator(*_args, **_kwargs):
        def _wrap(func):
            return func
        return _wrap

    fake_module = types.ModuleType("langfuse")
    setattr(fake_module, "observe", _identity_decorator)
    monkeypatch.setitem(sys.modules, "langfuse", fake_module)
    yield


@pytest.fixture()
def fake_litellm(monkeypatch):
    """Fixture to stub `litellm.completion`."""

    class FakeChoicesMessage:
        def __init__(self, content):
            self.content = content

    class FakeChoice:
        def __init__(self, content):
            self.message = FakeChoicesMessage(content)

    class FakeResponse:
        def __init__(self, content):
            self.choices = [FakeChoice(content)]

    def set_success_response(content="ok"):
        def _completion(**_kwargs):
            return FakeResponse(content)
        monkeypatch.setitem(sys.modules, "litellm", types.ModuleType("litellm"))
        sys.modules["litellm"].completion = _completion

    def set_error(exception: BaseException):
        def _completion(**_kwargs):
            raise exception
        monkeypatch.setitem(sys.modules, "litellm", types.ModuleType("litellm"))
        sys.modules["litellm"].completion = _completion

    return types.SimpleNamespace(
        set_success_response=set_success_response,
        set_error=set_error,
    )


@pytest.fixture()
def http_ok(monkeypatch):
    """Fixture to make `requests.get` return status_code=200."""
    class Resp:
        status_code = 200

    def _get(_url, timeout=5):
        return Resp()

    monkeypatch.setitem(sys.modules, "requests", __import__("requests"))
    monkeypatch.setattr(sys.modules["requests"], "get", _get)
    return Resp()


@pytest.fixture()
def http_fail(monkeypatch):
    """Fixture to make `requests.get` return status_code=500."""
    class Resp:
        status_code = 500

    def _get(_url, timeout=5):
        return Resp()

    monkeypatch.setitem(sys.modules, "requests", __import__("requests"))
    monkeypatch.setattr(sys.modules["requests"], "get", _get)
    return Resp()


@pytest.fixture()
def fast_sleep(monkeypatch):
    """Make time.sleep do nothing during tests."""
    monkeypatch.setattr("time.sleep", lambda _seconds: None)


@pytest.fixture(autouse=True)
def reset_imports():
    """Cleanup fake modules between tests to prevent import caching issues."""
    yield
    for mod in ["litellm", "langfuse", "requests"]:
        sys.modules.pop(mod, None)