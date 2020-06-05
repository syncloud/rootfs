import logging
import os
import shutil
import time
from os.path import dirname, join

import pytest
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning

from subprocess import check_output
from syncloudlib.integration.installer import wait_for_installer

logging.basicConfig(level=logging.DEBUG)
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


DIR = dirname(__file__)
APPS =  ['mail', 'nextcloud', 'diaspora', 'files', 'gogs', 'rocketchat', 'notes',  'wordpress', 'pihole', 'syncthing', 'users', 'openvpn']
TMP_DIR = '/tmp/syncloud'


@pytest.fixture(scope="session")
def module_setup(request, device, log_dir):
    def module_teardown():
        device.run_ssh('journalctl > {0}/journalctl.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /etc/hosts {0}/hosts.log'.format(TMP_DIR), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), log_dir)
        copy_logs(device, 'platform', log_dir)
        check_output('chmod -R a+r {0}'.format(log_dir), shell=True)

    request.addfinalizer(module_teardown)


def copy_logs(device, app, log_dir):
    device_logs = '/var/snap/{0}/common/log/*'.format(app)
    app_log_dir = join(log_dir, '{0}_log'.format(app))
    os.mkdir(app_log_dir)
    device.scp_from_device(device_logs, app_log_dir)


def test_start(module_setup, log_dir, device):
    shutil.rmtree(log_dir, ignore_errors=True)
    os.mkdir(log_dir)
    device.run_ssh('mkdir {0}'.format(TMP_DIR))


def test_activate_device(device):
    response = device.activate()
    assert response.status_code == 200, response.text


def wait_for_app(device, app, predicate):
    attempts = 100
    attempt = 0
    while attempt < attempts:
        try:
            response = device.login().get('https://{0}/rest/installed_apps'.format(device.device_host), verify=False)
            if response.status_code == 200:
                print('result {0}: {1}'.format(attempt, response.text))
                if predicate(response.text):
                    return
        except Exception as e:
            pass
        print('waiting for {0} {1}/{2}'.format(app, attempt, attempts))
        attempt += 1
        time.sleep(5)

    raise Exception("timeout waiting for {0} event".format(app))


def test_apps(device, log_dir):
    for app in APPS:
        _test_app(device, app, log_dir)


def _test_app(device, app, log_dir):
    syncloud_session = device.login()
    response = syncloud_session.get('https://{0}/rest/install?app_id={1}'.format(device.device_host, app),
                                    allow_redirects=False, verify=False)

    assert response.status_code == 200
    wait_for_installer(syncloud_session, device.device_host)
    wait_for_app(device, app, lambda response_text: app in response_text)
    copy_logs(device, app, log_dir)
    response = syncloud_session.get('https://{0}/rest/remove?app_id={1}'.format(device.device_host, app),
                                    allow_redirects=False, verify=False)
    assert response.status_code == 200
    wait_for_installer(syncloud_session, device.device_host)
    wait_for_app(device, app, lambda response_text: app not in response_text)
