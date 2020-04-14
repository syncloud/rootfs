import logging
import os
import shutil
import time
from os.path import dirname, join

import pytest

from syncloudlib.integration.installer import wait_for_installer
from syncloudlib.http import wait_for_response

logging.basicConfig(level=logging.DEBUG)

DIR = dirname(__file__)
APPS = ['mail', 'nextcloud', 'diaspora', 'files', 'gogs', 'rocketchat', 'notes']
TMP_DIR = '/tmp/syncloud'


@pytest.fixture(scope="session")
def module_setup(request, device, log_dir):
    def module_teardown():
        os.mkdir(log_dir)
        device.run_ssh('journalctl > {0}/journalctl.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /etc/hosts {0}/hosts.log'.format(TMP_DIR), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), log_dir)
        copy_logs(device, 'platform', log_dir)
        for app in APPS:
            copy_logs(device, app, log_dir)
    request.addfinalizer(module_teardown)


def copy_logs(device, app, log_dir):
    device_logs = '/var/snap/{0}/common/log/*'.format(app)
    app_log_dir = join(log_dir, '{0}_log'.format(app))
    os.mkdir(app_log_dir)
    device.scp_from_device(device_logs, app_log_dir)


def test_start(module_setup, log_dir, device):
    shutil.rmtree(log_dir, ignore_errors=True)
    device.run_ssh('mkdir {0}'.format(TMP_DIR))


def test_activate_device(device):
    response = device.activate()
    assert response.status_code == 200, response.text


def wait_for_app(device, predicate):
    attempts = 10
    attempt = 0
    while attempt < attempts:
        try:
            response = device.login().get('http://{0}/rest/installed_apps'.format(device.device_host))
            if response.status_code == 200:
                print('result: {0}'.format(response.text))
                if predicate(response.text):
                    return
        except Exception, e:
            pass
        print('waiting for app')
        attempt += 1
        time.sleep(5)

    raise Exception("timeout waiting for app event")


@pytest.mark.parametrize("app", APPS, scope="session")
def test_app_install(device, app):
    syncloud_session = device.login()
    response = syncloud_session.get('https://{0}/rest/install?app_id={1}'.format(device.device_host, app),
                                    allow_redirects=False, verify=False)

    assert response.status_code == 200
    wait_for_installer(syncloud_session, device.device_host)
    wait_for_app(device, lambda response_text: app in response_text)


@pytest.mark.parametrize("app", APPS, scope="session")
def test_app_remove(device, app):
    syncloud_session = device.login()
    response = syncloud_session.get('https://{0}/rest/remove?app_id={1}'.format(device.device_host, app),
                                    allow_redirects=False, verify=False)
    assert response.status_code == 200
    wait_for_installer(syncloud_session, device.device_host)
    wait_for_app(device, lambda response_text: app not in response_text)
