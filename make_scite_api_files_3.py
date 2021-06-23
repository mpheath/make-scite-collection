#!/usr/bin/env python3

'''Make scitestyles.api file from SciTEGlobal.properties and others.properties.'''

import os, re
import common


settings = common.settings

# Access which SciTEGlobal.properties and others.properties.
# True=From modified files, False=From scite\src files.
settings['use_output_files'] = False


if __name__ == '__main__':

    # Set output path.
    output = settings['output']

    if not os.path.isdir(output):
        os.makedirs(output)

    # Set paths of SciTEGlobal.properties and others.properties.
    if settings['use_output_files']:
        global_file = os.path.join(output, 'external_properties', 'SciTEGlobal.properties')
        others_file = os.path.join(output, 'external_properties', 'others.properties')
    else:
        global_file = ''
        others_file = ''

    if not os.path.isfile(global_file) or not os.path.isfile(others_file):
        print('read from the source files')
        global_file = os.path.join('scite', 'src', 'SciTEGlobal.properties')
        others_file = os.path.join('scite', 'src', 'others.properties')
    else:
        print('read from the output files')

    # Exclude these known property names.
    exclude = ['font.locale', 'font.monospace', 'font.override', 'font.quality']

    # Get property names.
    scitestyles = set()

    for file in (global_file, others_file):
        with open(file) as r:
            content = r.read()

        matches = re.findall(r'^\s*((?:colour|font)\..+?)=', content, re.M)

        if matches:
            for item in matches:
                if item not in exclude:
                    scitestyles.add(item)

    scitestyles = sorted(scitestyles)

    print('output:')

    # Write to scitestyles.api.
    if scitestyles:
        print('  scitestyles.api')

        with open(os.path.join(output, 'scitestyles.api'), 'w', encoding='utf-8') as w:
            for item in scitestyles:
                if item.startswith('colour.'):
                    w.write(item + ' (-) [style]\\n Colour style.\n')
                else:
                    w.write(item + ' (-) [style]\\n Font style.\n')

    print('done')
