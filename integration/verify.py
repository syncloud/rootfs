import logging
import os
import shutil
import time
from os.path import dirname, join
from subprocess import check_output

import convertible
import pytest
import requests

from integration.util.ssh import run_scp, run_ssh

logging.basicConfig(level=logging.DEBUG)

DIR = dirname(__file__)
LOG_DIR = join(DIR, 'log')
SYNCLOUD_INFO = 'syncloud.info'
DEVICE_USER = 'user'
DEVICE_PASSWORD = 'password'
DEFAULT_DEVICE_PASSWORD = 'syncloud'
LOGS_SSH_PASSWORD = DEFAULT_DEVICE_PASSWORD
APPS = ['mail', 'nextcloud', 'diaspora', 'files', 'gogs', 'rocketchat']


@pytest.fixture(scope="session")
def module_setup(request, device_host):
    request.addfinalizer(lambda: module_teardown(device_host))


def module_teardown(device_host):
    os.mkdir(LOG_DIR)

    copy_logs(device_host, 'platform')
    for app in APPS:
        copy_logs(device_host, app)

    run_ssh(device_host, 'journalctl', password=DEVICE_PASSWORD, throw=False)


def copy_logs(device_host, app):
    device_logs = '/var/snap/{0}/common/log/*'.format(app)
    log_dir = join(LOG_DIR, '{0}_log'.format(app))
    os.mkdir(log_dir)
    run_scp('root@{0}:{1} {2}'.format(device_host, device_logs, log_dir), password=LOGS_SSH_PASSWORD, throw=False)


@pytest.fixture(scope='module')
def user_domain(device_domain):
    return 'device.{0}'.format(device_domain)


@pytest.fixture(scope='module')
def device_domain(auth):
    email, password, domain, release = auth
    return '{0}.{1}'.format(domain, SYNCLOUD_INFO)


@pytest.fixture(scope='function')
def syncloud_session(device_host):
    session = requests.session()
    session.post('https://{0}/rest/login'.format(device_host), data={'name': DEVICE_USER, 'password': DEVICE_PASSWORD}, verify=False)

    return session


def test_start(module_setup):
    shutil.rmtree(LOG_DIR, ignore_errors=True)


def test_activate_device(auth, device_host):
    email, password, domain, release = auth

    response = requests.post('http://{0}:81/rest/activate'.format(device_host),
                             data={'main_domain': 'syncloud.info', 'redirect_email': email,
                                   'redirect_password': password,
                                   'user_domain': domain, 'device_username': DEVICE_USER,
                                   'device_password': DEVICE_PASSWORD})
    assert response.status_code == 200
    global LOGS_SSH_PASSWORD
    LOGS_SSH_PASSWORD = DEVICE_PASSWORD


# def wait_for_platform_web(device_host):
#     print(check_output('while ! nc -w 1 -z {0} 80; do sleep 1; done'.format(device_host), shell=True))


def wait_for_sam(device_host, syncloud_session):
    sam_running = True
    while sam_running == True:
        try:
            response = syncloud_session.get('https://{0}/rest/settings/sam_status'.format(device_host), verify=False)
            if response.status_code == 200:
                json = convertible.from_json(response.text)
                sam_running = json.is_running
                print('result: {0}'.format(sam_running))
        except Exception, e:
            pass
        print('waiting for sam to finish its work')
        time.sleep(5)


def wait_for_app(device_host, syncloud_session, predicate):
    found = False
    attempts = 10
    attempt = 0
    while not found and attempt < attempts:
        try:
            response = syncloud_session.get('http://{0}/rest/installed_apps'.format(device_host))
            if response.status_code == 200:
                print('result: {0}'.format(response.text))
                found = predicate(response.text)
        except Exception, e:
            pass
        print('waiting for app')
        attempt += 1
        time.sleep(5)


def test_login(syncloud_session, device_host):
    syncloud_session.post('https://{0}/rest/login'.format(device_host), data={'name': DEVICE_USER, 'password': DEVICE_PASSWORD}, verify=False)


@pytest.mark.parametrize("app", APPS)
def test_app_install(syncloud_session, app, device_host):
    response = syncloud_session.get('https://{0}/rest/install?app_id={1}'.format(device_host, app), allow_redirects=False, verify=False)

    assert response.status_code == 200
    wait_for_sam(device_host, syncloud_session)
    wait_for_app(device_host, syncloud_session, lambda response_text: app in response_text)


#@pytest.mark.parametrize("app", APPS)
#def test_app_upgrade(syncloud_session, app, device_host):
#    response = syncloud_session.get('https://{0}/rest/upgrade?app_id={1}'.format(device_host, app),
#                                    allow_redirects=False, verify=False)
#    assert response.status_code == 200


@pytest.mark.parametrize("app", APPS)
def test_app_remove(syncloud_session, app, device_host):
    response = syncloud_session.get('https://{0}/rest/remove?app_id={1}'.format(device_host, app),
                                    allow_redirects=False, verify=False)
    assert response.status_code == 200
    wait_for_sam(device_host, syncloud_session)
    wait_for_app(device_host, syncloud_session, lambda response_text: app not in response_text)
