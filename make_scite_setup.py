#!/usr/bin/env python3

'''Build a new wscite or sc1 setup.'''

import glob, os, shutil, subprocess, urllib.request, zipfile, zlib
import common


def build_global_properties(bitness):
    '''Build content to use for the SciTEGlobal override file.'''

    global_content = (
        '# SciTE override file for global initialization.\n\n\n'
        '# Behaviour\n'
        'are.you.sure.on.reload=1\n'
        'clear.before.execute=1\n'
        'load.on.activate=1\n'
        'margin.width=0\n\n'
        '# Define the Lexer menu\n'
        'keyIndent=\n'
        'keyText=\n'
        'keyMake=\n'
        'keyHTML=\n'
        'keyXML=\n\n'
        '# Remove these languages from the menu\n'
        '*language.errorlist=\n'
        '*language.java=\n'
        '*language.makefile=\n'
        '*language.perl=\n'
        '*language.vb=\n'
        '*language.yaml=\n\n'
        '# Scripting\n'
        'ext.lua.startup.script=$(SciteDefaultHome)' + os.sep + 'SciTEStartup.lua\n'
        'if PLAT_WIN\n'
        '\tcreate.hidden.console=1\n')

    if bitness == 'x64':
        global_content += (
            '\n# 48 DebugPrintSelection\n'
            '#command.name.48.*=DebugPrintSelection\n'
            'command.48.*=DebugPrintSelection\n'
            'command.subsystem.48.*=3\n'
            'command.save.before.48.*=2\n\n'
            '# 49 GlobalTools\n'
            'command.name.49.*=GlobalTools\n'
            'command.49.*=GlobalTools\n'
            'command.subsystem.49.*=3\n'
            'command.save.before.49.*=2\n'
            'command.shortcut.49.*=F12\n')

    if selection == 'sc1':
        global_content += '\nimport *\n'
        return global_content

    # Read all override files and include for wscite to keep imports small.
    for item in glob.iglob(os.path.join(base, 'overrides', '*.properties')):
        with open(item) as r:
            content = r.read().strip()

        if content:
            name = os.path.basename(item)[:-11]
            length = len(name) + 6

            global_content += '\n' + ('#' * length) + '\n' \
                              '#  ' + name + '  #\n' \
                              + ('#' * length) + '\n\n' \
                              + content + '\n'

    global_content = global_content.strip('\n') + '\n'

    return global_content


def compile_au3(file, bitness):
    '''Compile au3 file to an executable.'''

    def _download_range(url, offset, length):
        '''Download a range of bytes from a url.'''

        with urllib.request.urlopen(urllib.request.Request(
                url, headers={'Range': 'bytes={}-'.format(offset)})) as r:

            content = r.read(length)

        return content

    # Check au3 file exist.
    if not os.path.isfile(file):
        return

    # Check Aut2exe.exe exist.
    for item in ('ProgramFiles', 'ProgramFiles(x86)'):
        if item in os.environ:
            compiler = os.path.join(os.environ[item], 'AutoIt3',
                                    'Aut2Exe', 'Aut2exe.exe')

            if os.path.isfile(compiler):
                break
    else:
        bin_dir = common.settings['bin']
        compiler = os.path.join(bin_dir, 'Aut2exe.exe')

    # Download Aut2exe.exe if not exist.
    if not os.path.isfile(compiler):
        reply = input('Download Aut2Exe.exe to compile "{}"? [n|y]: '.format(file))

        if reply.lower() != 'y':
            return

        if not os.path.isdir(bin_dir):
            os.makedirs(bin_dir)

        url = ('https://www.autoitscript.com/autoit3/'
               'files/archive/autoit/autoit-v3.3.14.5.zip')

        compressed = _download_range(url, 256320, 1117562)

        uncompressed = zlib.decompress(compressed, -15)

        with open(compiler, 'wb') as w:
            w.write(uncompressed)

    # Compile au3 file to executable.
    bit = '/x64' if bitness == 'x64' else '/x86'

    with subprocess.Popen([compiler, '/in', file, '/nopack', bit]) as p:
        p.wait()


def copy_base_files(bitness):
    '''Copy base files to a setup directory.'''

    rewrite = []

    for root, dirs, files in os.walk(base):
        relroot = os.path.relpath(root, base)

        # Make dirs.
        makedirs = True

        if not os.path.isdir(relroot):
            if selection == 'sc1' and relroot.lower() == 'overrides':
                makedirs = False

        if makedirs and not os.path.isdir(relroot):
            os.makedirs(relroot)

        # Copy files.
        for item in files:
            if bitness != 'x64':
                if item in ('about_global_tools.hta',
                            'rluawfx.lua',
                            'SciTEStartup.lua'):

                    rewrite.append('SciTEStartup.lua')
                    continue

            if selection == 'sc1' and relroot.lower() == 'overrides':
                relroot = '.'

            src = os.path.join(root, item)
            dst = os.path.join(relroot, item)

            shutil.copyfile(src, dst)

            print(' ', os.path.basename(dst))

    # Write global override properties.
    content = build_global_properties(bitness)

    if selection == 'sc1':
        file = 'SciTEGlobal.properties'
    else:
        file = '~overrides.properties'

    with open(file, 'w') as w:
        w.write(content)

    # Write startup script with the require calls without rluawfx.
    if 'SciTEStartup.lua' in rewrite:

        with open(os.path.join(base, 'SciTEStartup.lua')) as r, \
             open('SciTEStartup.lua', 'w') as w:

            for line in r:
                if line.startswith("require('rluawfx')"):
                    break

                w.write(line)


def copy_output_files(bitness):
    '''Copy files from output directory to a setup directory.'''

    # Copy api files.
    items = glob.glob(os.path.join(output, '*.api'))

    if items:
        if not os.path.isdir('api'):
            os.mkdir('api')

        for item in items:
            print(' ', os.path.basename(item))
            shutil.copyfile(item, os.path.join('api', os.path.basename(item)))

    # Copy files and remove some files if not x64.
    items = [(output, 'scite.chm'),
             (output, 'lua/iface.hta'),
             (output, 'lua/lua.chm'),
             (output, 'lua/lua.json'),
             (output, 'properties/modules.json')]

    if bitness == 'x64':
        items.extend([(download, 'rluawfx-en.dll'),
                     (output, 'lua/rluawfx_functions.hta')])
    else:
        for item in ('rluawfx-en.dll', 'lua/rluawfx_functions.hta'):
            if os.path.isfile(item):
                os.remove(item)

    for item in items:
        path, name = os.path.split(item[1])

        if path and not os.path.isdir(path):
            os.makedirs(path)

        infile = os.path.join(os.path.join(item[0], name))
        outfile = os.path.normpath(item[1])

        if os.path.isfile(infile):
            print(' ', name)
            shutil.copyfile(infile, outfile)


def get_exe_bitness(file):
    '''Get executable bitness as x86 or x64.'''

    with open(file, 'rb') as r:
        pos = r.read(1024).find(b'PE')
        r.seek(pos + 4, 0)
        char = r.read(1)

    if char == b'd':
        return 'x64'
    elif char == b'L':
        return 'x86'


def get_scite_to_copy(glob_pattern_list):
    '''List SciTE choices and get the one selected from input.'''

    scite = []

    for pattern in glob_pattern_list:
        scite.extend(glob.glob(pattern))

    if not scite:
        print('No files match the pattern')
        return

    if len(scite) > 1:
        print('Select file to copy or extract the SciTE executable:')

        print('  0  Quit')

        for index, item in enumerate(scite, 1):
            print('  {}  {}'.format(index, os.path.basename(item)))

        reply = input('Enter a number: ').strip()

        if reply in ('', '0'):
            return

        try:
            index = int(reply) - 1
        except ValueError as err_msg:
            print(err_msg)
            return
    else:
        index = 0

    return scite[index]


def make_sc1(output):
    '''Main function to make a sc1 setup.'''

    # Prepare sc1 dir.
    if not os.path.isdir(selection):
        os.mkdir(selection)

    os.chdir(selection)

    # Get sc1 file.
    scite_exe = get_scite_to_copy([os.path.join(output, 'sc*.exe')])

    if not scite_exe:
        return

    # Remove old SciTE executables.
    for item in glob.iglob('sc*.exe'):
        os.remove(item)

    # Copy SciTE executable.
    shutil.copyfile(scite_exe, os.path.basename(scite_exe))
    bitness = get_exe_bitness(scite_exe)

    # Copy, extract... various files.
    print('copy:')
    copy_base_files(bitness)

    copy_output_files(bitness)

    # Make a relative user directory.
    if not os.path.isdir('user'):
        os.mkdir('user')

    # Compile SciTE Launcher.
    if not os.path.isfile('SciTELauncher.exe'):
        if os.path.isfile('SciTELauncher.au3'):
            compile_au3('SciTELauncher.au3', bitness)
            os.remove('SciTELauncher.au3')

    os.chdir(initial_dir)


def make_wscite(output):
    '''Main function to make a wscite setup.'''

    # Check modified external properties exist to continue.
    output = os.path.join(output, 'external_properties')

    if not os.path.exists(output):
        exit('No external_properties dir found')

    # Prepare wscite dir.
    if not os.path.isdir(selection):
        os.mkdir(selection)

    # Get wscite zipfiles.
    scite_exe = get_scite_to_copy([os.path.join(download, 'wscite*.zip'),
                                   os.path.join('scite', 'bin', 'SciTE*.exe')])

    if not scite_exe:
        return

    # Remove old SciTE executables.
    for item in glob.iglob(os.path.join(selection, 'sc*.exe')):
        os.remove(item)

    # Unzip files from wscite zipfile.
    if scite_exe.endswith('.zip'):
        print('unzip:')

        with zipfile.ZipFile(scite_exe) as r:
            members = ('wscite/SciTE32.exe',
                       'wscite/SciTE.exe',
                       'wscite/Lexilla.dll',
                       'wscite/Scintilla.dll')

            for item in members:
                if item in r.namelist():
                    print(' ', os.path.basename(item))
                    r.extract(item)

                    if item.endswith('.exe'):
                        bitness = get_exe_bitness(item)

        print('copy:')
    else:
        print('copy:')

        scite_files = (os.path.join('scite', 'bin', 'lexilla.dll'),
                       os.path.join('scite', 'bin', 'Scintilla.dll'),
                       scite_exe)

        for item in scite_files:
            if os.path.isfile(item):
                print(' ', os.path.basename(item))

                shutil.copyfile(item, os.path.join('wscite',
                                os.path.basename(item)))

        bitness = get_exe_bitness(scite_exe)

    # Change to root of the extract dir.
    os.chdir(selection)

    # Copy, extract... various files.
    copy_base_files(bitness)

    copy_output_files(bitness)

    # Make a relative user directory.
    if not os.path.isdir('user'):
        os.mkdir('user')

    # Copy properties files.
    items = glob.glob(os.path.join(output, '*.properties'))

    if len(items) > 10:
        print('  {}\n  [...]\n  {}'.format(os.path.basename(items[0]),
                                           os.path.basename(items[-1])))
        print_items = False
    else:
        print_items = True

    for item in glob.iglob(os.path.join(output, '*.properties')):
        if print_items:
            print(' ', os.path.basename(item))

        shutil.copyfile(item, os.path.basename(item))

    # Compile SciTE Launcher.
    if not os.path.isfile('SciTELauncher.exe'):
        if os.path.isfile('SciTELauncher.au3'):
            compile_au3('SciTELauncher.au3', bitness)
            os.remove('SciTELauncher.au3')

    os.chdir(initial_dir)


if __name__ == '__main__':

    initial_dir = os.getcwd()
    base = common.settings['base']
    download = common.settings['download']
    output = common.settings['output']

    for item in ('sc1', 'wscite'):
        reply = input('Make {} setup? [n|y]: '.format(item))
        if reply.lower() == 'y':

            # Ask to remove current setup.
            if os.path.isdir(item):
                reply = input(('Delete {0} dir before '
                               'make {0} setup? [n|y]: ').format(item))

                if reply.lower() == 'y':
                    shutil.rmtree(item)

            # Make the setup.
            selection = item

            if item == 'sc1':
                make_sc1(output)
            else:
                make_wscite(output)

    print('done')
