import tempfile
import os
import ssl
import sys

# Init logging
import logging
log = logging.getLogger('kafka')
log.addHandler(logging.StreamHandler(sys.stdout))
log.setLevel(logging.INFO)


def generate_ssl_context(ssl_check_hostname,
                         ssl_cafile,
                         ssl_certfile,
                         ssl_keyfile,
                         ssl_password,
                         ssl_crlfile,
                         ssl_supported_protocols,
                         ssl_ciphers):
    """
    Generate SSLContext for kafka client.
    """
    log.debug('Configuring default SSL Context')
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_SSLv23)
    ssl_context.options |= ssl.OP_NO_SSLv2
    ssl_context.options |= ssl.OP_NO_SSLv3
    ssl_context.verify_mode = ssl.CERT_OPTIONAL
    if ssl_supported_protocols:
        if 'TLSv1' not in ssl_supported_protocols:
            ssl_context.options |= ssl.OP_NO_TLSv1
        if 'TLSv1.1' not in ssl_supported_protocols:
            ssl_context.options |= ssl.OP_NO_TLSv1_1
        if 'TLSv1.2' not in ssl_supported_protocols:
            ssl_context.options |= ssl.OP_NO_TLSv1_2
    if ssl_check_hostname:
        ssl_context.check_hostname = True
    if ssl_cafile:
        log.info('Loading SSL CA from %s', ssl_cafile)
        ssl_context.load_verify_locations(ssl_cafile)
        ssl_context.verify_mode = ssl.CERT_REQUIRED
    else:
        log.info('Loading system default SSL CAs from %s',
                 ssl.get_default_verify_paths())
        ssl_context.load_default_certs()
    if ssl_certfile and ssl_keyfile:
        log.info('Loading SSL Cert from %s', ssl_certfile)
        log.info('Loading SSL Key from %s', ssl_keyfile)
        ssl_context.load_cert_chain(
            certfile=ssl_certfile,
            keyfile=ssl_keyfile,
            password=ssl_password)
    if ssl_crlfile:
        if not hasattr(ssl, 'VERIFY_CRL_CHECK_LEAF'):
            raise RuntimeError('This version of Python does not'
                               ' support ssl_crlfile!')
        log.info('Loading SSL CRL from %s', ssl_crlfile)
        ssl_context.load_verify_locations(ssl_crlfile)
        ssl_context.verify_flags |= ssl.VERIFY_CRL_CHECK_LEAF
    if ssl_ciphers:
        log.info('Setting SSL Ciphers: %s', ssl_ciphers)
        ssl_context.set_ciphers(ssl_ciphers)
    return ssl_context


def generate_ssl_object(module, ssl_cafile, ssl_certfile, ssl_keyfile,
                        ssl_crlfile=None):
    """
    Generates a dict object that is used when dealing with ssl connection.
    When values given are file content, it takes care of temp file creation.
    """

    ssl_files = {
        'cafile': {'path': ssl_cafile, 'is_temp': False},
        'certfile': {'path': ssl_certfile, 'is_temp': False},
        'keyfile': {'path': ssl_keyfile, 'is_temp': False},
        'crlfile': {'path': ssl_crlfile, 'is_temp': False}
    }

    for key, value in ssl_files.items():
        if value['path'] is not None:
            # TODO is that condition sufficient?
            if value['path'].startswith("-----BEGIN"):
                # value is a content, need to create a tempfile
                fd, path = tempfile.mkstemp(prefix=key)
                with os.fdopen(fd, 'w') as tmp:
                    tmp.write(value['path'])
                ssl_files[key]['path'] = path
                ssl_files[key]['is_temp'] = True
            elif not os.path.exists(os.path.dirname(value['path'])):
                # value is not a content, but path does not exist,
                # fails the module
                module.fail_json(
                    msg='\'%s\' is not a content and provided path does not '
                        'exist, please check your SSL configuration.' % key
                )

    return ssl_files
