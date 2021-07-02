#!/usr/bin/env python3

'''Copy or extract base tools from the downloaded files.'''

import os, shutil, urllib.request, zipfile
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

    # Dictionary. key 'folder|bit', url to download and dest as copy|extract root.
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
            'dest': base},
        'luacheck|x64': {
            'url': 'https://github.com/mpeterv/luacheck/releases/download'
                   '/0.23.0/luacheck.exe',
            'dest': os.path.join(base, 'lua')}}

    # Check base tools files and subfolders exist.
    for key in dic:
        if dic[key]['url'].endswith('.exe'):
            fullpath = os.path.join(dic[key]['dest'],
                                    os.path.basename(dic[key]['url']))

            if not os.path.isfile(fullpath):
                break

        elif not os.path.isdir(os.path.join(base, key.split('|')[0])):
            break
    else:
        print('All base tools files and subfolders already exist\ndone')
        exit()

    # Download, copy or extract each file as needed.
    for key, items in dic.items():
        title, bit = key.split('|', 1) if '|' in key else (key, '')
        folder = os.path.join(base, title)
        url = items['url']
        dest = items['dest']
        title = title.title()
        file = os.path.basename(url)
        prompt = '' if os.path.isfile(file) else 'Download and '

        # Ask the user if OK to do the operation.
        if url.endswith('.exe'):
            fullpath = os.path.join(dest, file)

            if os.path.isfile(fullpath):
                continue

            prompt += ('copy' if prompt else 'Copy') + ' {}? [n|y]: '
        elif os.path.isdir(folder):
            continue
        else:
            prompt += ('extract' if prompt else 'Extract') + ' {}? [n|y]: '

        reply = input(prompt.format((title + ' ' + bit) if bit else title))

        if reply.lower() != 'y':
            continue

        # Download the file.
        try:
            if not os.path.isfile(file):
                urllib.request.urlretrieve(url, file)
        except urllib.error.HTTPError as err_msg:
            print('   ', err_msg)
        else:
            # Extract if a zip file else copy the file to base.
            if file.endswith('.zip'):
                os.makedirs(folder)

                with zipfile.ZipFile(file) as z:
                    z.extractall(dest)
            else:
                if not os.path.exists(dest):
                    os.makedirs(dest)

                shutil.copyfile(file, fullpath)

    print('done')
