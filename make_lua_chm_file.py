#!python3

'''Make lua.hhc, lua.hhk and lua.hhp to compile lua.chm.'''

import os, re, subprocess, urllib.request
import common


settings = common.settings

# Lua function anchors or all, which includes C functions, constants...
# True=Get anchors until eof. False=Get anchors until end of Lua functions.
settings['all_anchors'] = False


def download(link, file, outfile=None):
    '''Download a link/file to (out)file.'''

    status = True

    if not outfile:
        outfile = file

    # Return True if file already exist.
    if os.path.isfile(outfile):
        return status

    # Download file.
    print(' ', outfile)

    try:
        urllib.request.urlretrieve(link + file, outfile)
    except urllib.error.HTTPError as err_msg:
        print('   ', err_msg)
        status = False

    return status


def spider(link, file):
    '''Get css and image files. Flatten the paths to a basename.'''

    with open(file) as r:
        content = r.read()

    new_content = content

    for patterns in ((r'<LINK .+?>', r'HREF="(.+?)"', 'HREF="{}"'),
                     (r'<IMG .+?>',  r'SRC="(.+?)"',  'SRC="{}"')):

        links = re.findall(patterns[0], content, re.I)

        if links:
            for item in links:
                hrefs = re.findall(patterns[1], item, re.I)

                if hrefs:
                    for href in hrefs:
                        download(link, href)
                        basename = os.path.basename(href)

                        if href != basename:
                            href = re.escape(href)

                            new_content = re.sub(patterns[2].format(href),
                                                 patterns[2].format(basename),
                                                 new_content, 0, re.I)

    if content != new_content:
        with open(file, 'w') as w:
            w.write(new_content)


if __name__ == '__main__':

    # Set Lua version.
    lua_version = common.lua_version()

    if not lua_version:
        print('Lua version needs to be major.minor, for example 5.3')
        lua_version = input('Lua version: ').strip()

    if not re.match(r'\d+\.\d+$', lua_version):
        exit('Invalid Lua version')

    # Set output path.
    output = settings['output']
    output = os.path.join(output, 'lua_chm')

    if not os.path.isdir(output):
        os.makedirs(output)

    os.chdir(output)


    # Download Lua docs.
    link = 'https://www.lua.org/manual/{}/'.format(lua_version)

    print('download:')

    new_manual = False

    for item in (['', 'contents.html'], ['manual.html'], ['readme.html']):
        if not os.path.exists(item[-1]):
            if not download(link, *item):
                continue

            if item[-1] == 'manual.html':
                new_manual = True

            spider(link, item[-1])


    # Make hhc file.
    with open('contents.html') as r:
        content = r.read()

    pattern = r'(<UL CLASS="contents menubar">.+?)<H2>'
    matches = re.search(pattern, content.replace('&ndash;', '-'), re.I|re.S)

    if not matches:
        exit('Failed to get contents data')

    contents = matches.group(1).strip()
    contents = contents.replace('<P>\n', '')
    contents = re.sub(r'<UL\s+.+?>', r'<UL>', contents)

    contents = re.sub(r'<A HREF="(.+?)">(.+)</A>',
                      r'<OBJECT type="text/sitemap">\n'
                      r'\t<param name="Name" value="\2">\n'
                      r'\t<param name="Local" value="\1">\n'
                      r'\t</OBJECT>', contents)

    with open('lua.hhc', 'w') as w:
        w.write('<!DOCTYPE HTML>\n'
                '<HTML>\n<BODY>\n'
                '<OBJECT type="text/site properties">\n'
                '\t<param name="ImageType" value="Folder">\n'
                '</OBJECT>\n'
                '<UL>\n'
                '<LI> <OBJECT type="text/sitemap">\n'
                '\t<param name="Name" value="Welcome">\n'
                '\t<param name="Local" value="readme.html">\n'
                '\t</OBJECT>\n'
                '<LI> <OBJECT type="text/sitemap">\n'
                '\t<param name="Name" value="Contents">\n'
                '\t<param name="Local" value="contents.html">\n'
                '\t</OBJECT>\n'
                '<LI> <OBJECT type="text/sitemap">\n'
                '\t<param name="Name" value="Manual">\n'
                '\t<param name="Local" value="manual.html">\n'
                '\t<param name="ImageNumber" value="1">\n'
                '\t</OBJECT>\n')

        w.write(contents + '\n</UL>\n</BODY>\n</HTML>\n')


    # Make hhk file.
    if settings['all_anchors']:
        # Get anchors until eof.
        pattern = r'<H3><A NAME="functions">Lua functions</A></H3>(.+)'
    else:
        # Get anchors until end of Lua functions.
        pattern = r'<H3><A NAME="functions">Lua functions</A></H3>(.+?)<H3><A'

    matches = re.search(pattern, content.replace('&ndash;', '-'), re.I|re.S)

    if not matches:
        exit('Failed to get index data')

    contents = matches.group(1).strip()

    matches = re.findall(r'<A HREF="(.+?)">(.+?)</A>', contents, re.I)

    matches.sort(key=lambda x: x[1].lower())

    anchors = []

    with open('lua.hhk', 'w') as w:
        w.write('<!DOCTYPE HTML>\n'
                '<HTML>\n<BODY>\n<UL>\n')

        for items in matches:
            if items[1] in ('basic',):
                continue

            if ':' in items[0] and '#' in items[0]:
                parts = items[0].split('#')
                repl = parts[1].replace(':', '_')
                items = [parts[0] + '#' + repl, items[1]]
                anchors.append([parts[1], repl])

            w.write('\t<LI> <OBJECT type="text/sitemap">\n'
                    '\t\t<param name="Name" value="{1}">\n'
                    '\t\t<param name="Local" value="{0}">\n'
                    '\t\t</OBJECT>\n'.format(*items))

        w.write('</UL>\n</BODY>\n</HTML>\n')

    if anchors and new_manual:
        with open('manual.html') as r:
            content = r.read()

        os.rename('manual.html', 'manual.html.bak')

        pattern = '<a name="{}">'

        for item in anchors:
            find = pattern.format(item[0])
            repl = pattern.format(item[1]) + '</a>' + find
            content = content.replace(find, repl)

        with open('manual.html', 'w') as w:
            w.write(content)

        os.remove('manual.html.bak')


    # Make hhp file.
    with open('lua.hhp', 'w') as w:
        w.write('[OPTIONS]\n'
                'Binary Index=No\n'
                'Compatibility=1.1 or later\n'
                'Compiled file=..\\lua.chm\n'
                'Contents file=lua.hhc\n'
                'Default topic=contents.html\n'
                'Display compile progress=No\n'
                'Full-text search=Yes\n'
                'Index file=lua.hhk\n'
                'Title=Lua Help {}\n\n'.format(lua_version) +
                '[FILES]\n'
                'contents.html\n'
                'manual.html\n'
                'readme.html\n')


    # Compile chm file.
    if settings['compiler']:
        print('output:\n  lua.chm')

        command = [settings['compiler'], 'lua.hhp']

        try:
            with subprocess.Popen(command, stdout=subprocess.PIPE) as p:
                stdout = p.communicate()[0]
        except FileNotFoundError:
            exit('compiler path not found')

        if settings['compiler_stdout']:
            stdout = stdout.decode().replace('\r', '')
            print(stdout)

    print('done')
