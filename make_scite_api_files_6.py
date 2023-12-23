#!python3

'''Make sciteconstants.api file from various files.'''

import os, re
import common


def get_constants(const_id):
    '''Get constants for a constant identity.'''

    # Get the file path and the pattern for const_id.
    if const_id == 'IDM':

        file = os.path.join('scite', 'src', 'scite.h')
        re_constants = re.compile(r'^#define\s+(' + const_id + r'_\w+)', re.M)

    elif const_id in ('ANNOTATION', 'CARET', 'CARETSTYLE', 'EDGE',
                      'EOLANNOTATION', 'INDIC', 'SC', 'SCEN', 'SCFIND',
                      'SCI', 'SCK', 'SCMOD', 'SCN', 'SCTD', 'SCVS',
                      'SCWS', 'STYLE', 'UNDO'):

        file = os.path.join('scintilla', 'include', 'scintilla.h')
        re_constants = re.compile(r'^#define\s+(' + const_id + r'_\w+)', re.M)

    elif const_id == 'rluawfx':

        file = os.path.join('base', 'lua', 'rluawfx.lua')
        re_constants = re.compile(r'^([A-Z][A-Z_0-9]{3,})\s*=', re.M)

    # Read the file and find all the matching constants.
    with open(file) as r:
        content = r.read()

    constants = re_constants.findall(content)

    constants.sort()

    return constants


if __name__ == '__main__':

    # Get the output path.
    output = common.settings['output']

    # Get constants.
    constants = []

    for item in ('rluawfx',):
        constants.extend(get_constants(item))

    # Write the api file.
    if constants:
        print('output:\n  sciteconstants.api')

        file = os.path.join(output, 'sciteconstants.api')

        with open(file, 'w', encoding='utf-8') as w:
            for item in constants:
                w.write(item + '\n')

    print('done')
