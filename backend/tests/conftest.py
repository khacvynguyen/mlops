import sys
import types
import pytest

@pytest.fixture(autouse=True)
def fake_env(monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "dummy-key")
    yield

@pytest.fixture(autouse=True)
def noop_langfuse_observe(monkeypatch):
    """Provide a no-op replacement for langfuse decorator/context."""

    def _identity_decorator(*_args, **_kwargs):
        def _wrap(func):
            return func
        return _wrap

    def _noop(*_args, **_kwargs):
        return None

    fake_package = types.ModuleType("langfuse")
    decorators_mod = types.ModuleType("langfuse.decorators")

    setattr(decorators_mod, "observe", _identity_decorator)
    setattr(decorators_mod, "langfuse_context", types.SimpleNamespace(
        update_current_trace=_noop,
        update_current_observation=_noop,
    ))

    setattr(fake_package, "decorators", decorators_mod)

    monkeypatch.setitem(sys.modules, "langfuse", fake_package)
    monkeypatch.setitem(sys.modules, "langfuse.decorators", decorators_mod)
    yield
    for mod in ["langfuse", "langfuse.decorators"]:
        sys.modules.pop(mod, None)

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
    for mod in ["litellm", "langfuse", "langfuse.decorators", "requests"]:
        sys.modules.pop(mod, None)