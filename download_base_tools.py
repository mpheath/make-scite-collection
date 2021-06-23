#!/usr/bin/env python3

'''Download and extract base tools from the zip files.'''

import os, urllib.request, zipfile
import common


if __name__ == '__main__':

    # Set base path.
    base = common.settings['base']

    if not os.path.isdir(base):
        os.makedirs(base)

    # Set download path.
    download = common.settings['download']

    if not os.path.isdir(download):
        os.makedirs(download)

    os.chdir(download)

    # Dictionary. key (folder|bit), url to download and dest as extract root.
    dic = {
        'eskil': {
            'url': 'http://eskil.tcl-lang.org/index.html/uv/htdocs/download/'
                   'eskil284.win.zip',
            'dest': os.path.join(base, 'eskil')},
        'frhed|x86': {
            'url': 'https://github.com/WinMerge/frhed/releases/download/'
                   '0.10904.2017/frhed-0.10904.2017.7-win32.zip',
            'dest': base},
        'frhed|x64': {
            'url': 'https://github.com/WinMerge/frhed/releases/download/'
                   '0.10904.2017/frhed-0.10904.2017.7-x64.zip',
            'dest': base}}

    # Check base tools folders exist.
    for key in dic:
        if not os.path.isdir(os.path.join(base, key.split('|')[0])):
            break
    else:
        print('All base tools subfolders already exist\ndone')
        exit()

    # Download and extract from the zip file.
    for key, items in dic.items():
        title, bit = key.split('|', 1) if '|' in key else (key, '')
        folder = os.path.join(base, title)
        url = items['url']
        dest = items['dest']

        if os.path.isdir(folder):
            continue
        else:
            title = title.title()

            reply = input('Download and extract {}? [n|y]: '
                          .format((title + ' ' + bit) if bit else title))

            if reply.lower() != 'y':
                continue

            os.makedirs(folder)

        file = os.path.basename(url)

        try:
            if not os.path.isfile(file):
                urllib.request.urlretrieve(url, file)
        except urllib.error.HTTPError as err_msg:
            print('   ', err_msg)
            status = False
        else:
            with zipfile.ZipFile(file) as z:
                z.extractall(dest)

    print('done')
