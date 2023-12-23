#!python3

'''Make lua.api and lua.json.'''

import html, json, os, re, textwrap, urllib.request
import common


def html2json(content):
    '''Read html content and extract keywords... and save to lua.json.'''

    dic = {}

    # Get keywords.
    matches = re.findall(r'cannot\sbe\sused\sas\snames:\n+'
                         r'<pre>\s*(.+?)\s*</pre>', content, re.I|re.S)

    if len(matches) == 1:
        reserved_keywords = matches[0].split()

        for item in reserved_keywords:
            dic[item] = item

    # Get functions.
    matches = re.findall(r'<hr>(.+?)(?=<h\d>|<hr>)', content, re.I|re.S)

    if matches:
        for item in matches:

            # Remove html tags.
            item = re.sub('<.+?>', '', item)
            item = html.unescape(item)

            # Trim empty lines.
            item = item.strip()
            item = re.sub('\n{3,}', '\n\n', item)

            # Skip if starts with these.
            if item.startswith(('lua_', 'luaL_')):
                continue

            # Make newlines consistent after the signature.
            if ')\n' in item and not ')\n\n' in item:
                if item.find(')\n') < 50:
                    item = item.replace(')\n', ')\n\n', 1)

            # Get key name and add to the dictionary.
            key = re.match('[_a-zA-Z][_a-zA-Z.0-9:]+', item).group(0)
            dic[key] = item

    # Write to json file.
    with open('lua.json', 'w') as w:
        json.dump(dic, w, indent=4, sort_keys=True)


def make_api():
    '''Read from lua.json and save processed information to lua.api.'''

    def _value_cleanup(value):
        '''Get the signature and the doc.'''

        value = value.strip()

        # Split text into a list of lines.
        lines = value.split('\n')

        # Get call signature.
        signature = lines[0]

        # Prepare the list for doc processing.
        lines = lines[1:]

        while len(lines) and lines[0] == '':
            del lines[0]

        # Create the doc string.
        doc = ''

        for line in lines:
            if line.strip() == '':
                break
            else:
                doc += line + '\n'

        doc.strip()

        # Wrap doc string and add escapes.
        lines = textwrap.wrap(doc, width=75)
        doc = '\n'.join(lines)
        doc = doc.replace('\\', '\\\\')
        doc = doc.replace('\n', '\\n')

        # Add (-) to signature as not callable,
        # else the doc would need to be '' to comply.
        if '(' not in signature and doc:
            signature += ' (-)'

        return [signature, doc]


    # Uncallable calltips for these keywords.
    custom = {
        'for': ('for (-)',
               "for Name '=' exp ',' exp [',' exp] do block end\\n"
               'for namelist in explist do block end'),
        'function': ('function (-)',
                    'function funcname funcbody\\n'
                    'local function Name funcbody'),
        'goto': ('goto (-)', 'goto Name will goto the label ::Name::'),
        'if': ('if (-)',
              'if exp then block {elseif exp then block} [else block] end'),
        'repeat': ('repeat (-)', 'repeat block until exp'),
        'while': ('while (-)', 'while exp do block end')}

    # Read the json file.
    with open('lua.json') as r:
        dic = json.load(r)

    # Write the api file.
    with open('lua.api', 'w') as w:
        for key, value in dic.items():
            if key in custom:
                signature, doc = custom[key]
            else:
                signature, doc = _value_cleanup(value)

            if doc:
                w.write('{} {}\n'.format(signature, doc))
            else:
                w.write('{}\n'.format(signature))


def clean_manual(content):
    '''Clean content of manual.html suitable for the api file.'''

    def _repl(item):
        '''Replace match if not a needed html tag.'''

        item = item.group().lower()

        if item == '<hr>':
            return item
        elif re.match('</{,1}h[r0-6]>', item):
            return item
        elif re.match('</{,1}pre>', item):
            return item
        else:
            return ''

    # Clean manual.html content.
    content = re.sub('<.+?>', _repl, content)

    for item in (('&amp;', '&'),   ('&copy;', ''),
                 ('&gt;', '>'),    ('&le;', '<='),
                 ('&lt;', '<'),    ('&middot;', '.'),
                 ('&ndash;', '-'), ('&nbsp;', ' '),
                 ('&pi;', 'pi'),   ('&sect;', '#'),
                 ('&lsquo;', '"'), ('&rsquo;', '"')):

        content = content.replace(item[0], item[1])

    content = re.sub(r'\n{4,}', r'\n' * 3, content)

    content = content.strip() + '\n'

    return content


if __name__ == '__main__':

    # Set output path.
    output = common.settings['output']

    if not os.path.isdir(output):
        os.makedirs(output)

    os.chdir(output)

    # Read manual.html from file else read manual.html from lua.org.
    if os.path.isfile(os.path.join('lua_chm', 'manual.html')):
        print('read manual.html from file')

        with open(os.path.join('lua_chm', 'manual.html')) as r:
            content = r.read()
    else:
        print('read manual.html from lua.org')

        lua_version = common.lua_version()

        if not lua_version:
            print('Lua version needs to be major.minor, for example 5.3')
            lua_version = input('Lua version: ').strip()

        if not re.match(r'\d+\.\d+$', lua_version):
            exit('Invalid Lua version')

        link = 'https://www.lua.org/manual/{}/manual.html'.format(lua_version)

        with urllib.request.urlopen(link) as r:
            content = r.read().decode('latin_1')

    # Clean content of manual.html.
    content = clean_manual(content)

    print('output:')

    # Make lua.json.
    print('  lua.json')
    html2json(content)

    # Make lua.api.
    print('  lua.api')
    make_api()

    print('done')
