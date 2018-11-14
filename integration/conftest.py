import pytest


def pytest_addoption(parser):
    parser.addoption("--domain", action="store")
    parser.addoption("--device-host", action="store")
    parser.addoption("--device-port", action="store")


@pytest.fixture(scope="session")
def domain(request):
    return request.config.getoption("--domain")


@pytest.fixture(scope="session")
def device_host(request):
    return request.config.getoption("--device-host")


@pytest.fixture(scope="session")
def device_port(request):
    return request.config.getoption("--device-port")

