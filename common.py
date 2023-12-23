#!python3

'''Make SciTE scripts shared library.'''

import os, re


def lua_version():
    '''Read version from lua.h.'''

    file = os.path.join(initial_dir, 'scite', 'lua', 'src', 'lua.h')
    version = ''

    # Read version.
    if os.path.isfile(file):
        with open(file) as r:
            content = r.read()
            matches = re.findall(r'^#define\s+LUA_VERSION_M(?:AJOR|INOR)'
                                 r'\s+"{0,1}(\d+)"{0,1}', content, re.M)

            if len(matches) == 2:
                version = '{}.{}'.format(*matches)

    return version


def scite_version(sep=None, folder='scite'):
    '''Read version from folder/version.txt else scintilla/version.txt.'''

    # Read folder/version.txt with v5.0 and later, else scintilla/version.txt.
    file = os.path.join(initial_dir, folder, 'version.txt')

    if not os.path.isfile(file):
        file = os.path.join(initial_dir, 'scintilla', 'version.txt')

    version = ''

    # Read version.
    if os.path.isfile(file):
        with open(file) as r:
            version = r.read().strip()

    # Add separator.
    if version and sep:
        version = sep.join(version)

    return version


initial_dir = os.getcwd()

settings = {}

# Path to base folder for scite setup.
settings['base'] = os.path.join(initial_dir, 'base')

# Path to bin folder for binary files.
settings['bin'] = os.path.join(initial_dir, 'bin')

# Set path to the chm compiler.
if 'ProgramFiles(x86)' in os.environ:
    settings['compiler'] = os.path.join(os.environ['ProgramFiles(x86)'],
                                        'HTML Help Workshop', 'hhc.exe')
elif 'ProgramFiles' in os.environ:
    settings['compiler'] = os.path.join(os.environ['ProgramFiles'],
                                        'HTML Help Workshop', 'hhc.exe')
else:
    settings['compiler'] = ''

# Show stdout from the compiler. True or False.
settings['compiler_stdout'] = False

# Path to download folder for downloaded files.
settings['download'] = os.path.join(initial_dir, 'output', 'download')

# Path to the output folder where files are saved.
settings['output'] = os.path.join(initial_dir, 'output')
