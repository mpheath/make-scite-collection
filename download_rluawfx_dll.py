#!python3

'''Download rluawfx-en.dll and luawfx.cpp. Make rluawfx_functions.hta.'''

import os, re, urllib.request
import common


def download_file(link, file):
    '''Download link/file to file.'''

    status = True

    # Return True if file already exist.
    if os.path.isfile(file):
        return status

    # Download file.
    try:
        urllib.request.urlretrieve(link + file, file)
    except urllib.error.HTTPError as err_msg:
        print('   ', err_msg)
        status = False

    return status


def get_signatures(content, translate=True):
    '''Get C function names and function signatures for use in Lua.

    translate:
      True
        Replace some parameter names in Italian to English.
      False
        Keep actual parameter names.
    '''

    def _translate(substring):
        '''Basic Italian to English replacement.'''

        for find, repl in (('Titolo', 'Title'),
                           ('titolo', 'title'),
                           ('comando', 'command'),
                           ('Elementi', 'Element'),
                           ('Filtri', 'Filter'),
                           ('messaggio', 'message'),
                           ('Opzioni', 'Option')):

            substring = substring.replace(find, repl)

        return substring

    # Get function names and signatures.
    result = []

    matches = re.findall(r'LUALIB_API \w+ (c_.*?)\n}', content, re.S)

    if matches:
        for item in matches:
            if 'showErrorMsg(' in item:
                items = []

                substring = re.sub(r'.+showErrorMsg\(".+? - (.+?)"\);.+', r'\1',
                                   item, 0, re.S)

                if '(' not in substring:
                    continue

                if translate:
                    substring = _translate(substring)

                items.append(substring)

                substring = re.sub(r'(.+?)\(.+', r'\1', item, 0, re.S)
                items.append(substring)

                result.append(items)

    result.sort(key=lambda x: x[0].lower())

    return result


def make_hta(items):
    '''Make hta file containing SciTE rluawfx function signatures.'''

    head = ('<!DOCTYPE html>\n'
            '<html>\n\n'
            '<head>\n'
            ' <meta charset="utf-8">\n'
            ' <style>\n'
            '  body {background: #383838}\n'
            '  h1 {color: lightblue; background: #444444; padding: 2px}\n'
            '  b {color: #88BBEF}\n'
            '  .s0 {color: #DDDDDD}\n'
            '  .s1 {color: #EFAAEF}\n'
            '  .s2 {color: #93E793}\n'
            ' </style>\n'
            '</head>\n\n'
            '<body>\n'
            ' <h1># SciTE rluawfx Functions</h1>\n\n'
            ' <code class="s0"><b>local</b> rwfx_NameDLL = <span class="s1">'
            "'rluawfx-en.dll'</span></code><br><br>")

    foot = '</body>\n\n</html>'

    # Write hta file.
    with open('rluawfx_functions.hta', 'w', encoding='utf-8') as w:
        w.write(head + '\n')

        for signature, func_name in items:
            lua_name = 'rwfx_' + func_name[2:]

            # Rename ListDlg to ListBox to match RSciTE name.
            if lua_name == 'rwfx_ListDlg':
                lua_name = 'rwfx_ListBox'

            # Improve spaces surrounding commas.
            for items in ((' ,', ','), (', ', ','), (',', ', ')):
                signature = signature.replace(*items)

            # Add another commented signature line and code line.
            w.write((' <code class="s2">-- {0}</code><br>\n'
                     ' <code class="s0"><b>local</b> {1} = <b>package.loadlib</b>'
                     '(rwfx_NameDLL, <span class="s1">\'{2}\'</span>)</code>'
                     '<br><br>\n')
                     .format(signature, lua_name, func_name))

        w.write(foot + '\n')


if __name__ == '__main__':

    # Set output path.
    output = common.settings['output']

    if not os.path.isdir(output):
        os.makedirs(output)

    # Set download path.
    download = common.settings['download']

    if not os.path.isdir(download):
        os.makedirs(download)

    # Change directory to download.
    os.chdir(download)

    print('download:')

    # Download dll file.
    root = 'https://github.com/robertorossi73'

    link = root + '/rscite/raw/master/sources/distro/'
    file = 'rluawfx-en.dll'

    if download_file(link, file):
        print(' ', file)

    # Download cpp file.
    link = root + '/rscite/raw/master/sources/Src-Utilities/rluawfx/source/'
    file = 'luawfx.cpp'

    if download_file(link, file):
        print(' ', file)

        # Read cpp file.
        with open(file, errors='surrogateescape') as r:
            content = r.read()

        # Change directory to output.
        os.chdir(output)

        # Make hta file.
        print('output:\n  rluawfx_functions.hta')

        items = get_signatures(content)

        make_hta(items)

    print('done')
