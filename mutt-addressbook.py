#!/usr/bin/env python3

try:
    import argparse
    import configparser
    import os
    import ldap3

    p = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    p.add_argument('searchterm', help='Term to search for')
    p.add_argument('-C', '--configfile', dest='configfile',
                   default='~/.mutt-addressbook.ini',
                   help='Configuration file to read')
    p.add_argument('-p', '--pc_query', dest='pc_query',
                   default = False,
                   action  = 'store_true',
                   help='Whether to use the pc_query output format')
    args = p.parse_args()

    config = configparser.ConfigParser()
    config.read(['config.ini', os.path.expanduser(args.configfile)])

    FILTER = '(mail=*)'
    ATTRS = ['cn', 'mail']

    if not bool(args.pc_query):
        print('Searching … ', end='', flush=True)
    entries = []
    for d in config:
        if d == 'DEFAULT':
            continue
        user = None
        password = None
        auth = 'SIMPLE'
        binddn = None
        if 'Bind' in config[d]:
            binddn = config[d]['Bind']
        if 'password' in config[d]:
            password = config[d]['password']
        if 'auth' in config[d]:
            auth = config[d]['auth']
        with ldap3.Connection(config[d]['URI'], binddn, password = password, authentication = auth, auto_bind = True) as conn:
            print(''.join((d, ' … ')), end='', flush=True)
            flt = '(&{0}(|(mail={1}*)(cn={1}*)(sn={1}*)(givenName={1}*)))'.format(FILTER, args.searchterm)
            conn.search(config[d]['Base'], flt, attributes=ATTRS)
            entries.extend(conn.entries)

    if len(entries) == 0 and not bool(args.pc_query):
        print('No entries found!')
        exit(1)

    if not bool(args.pc_query):
        print('{:d} entries found!'.format(len(entries)))
        for i in entries:
            for m in i.mail.values:
                print('{}\t{}\t{}'.format(m, i.cn[0], i.entry_dn))
    if bool(args.pc_query):
        for i in entries:
            for m in i.mail.values:
                print('Name    : {}'.format(i.cn[0]))
                print('EMAIL   : {}'.format(m))

except Exception as e:
    print('Error: {}: {}'.format(type(e).__name__, e))
    exit(1)
