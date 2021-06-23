#!/usr/bin/env python3

'''Remove directories and files that are not needed anymore.'''

import glob, os, shutil
import common


def clean_download():
    '''Remove files and directories from download.'''

    print('download:')

    # Files downloaded that were for temporary use.
    for item in ('luawfx.cpp',):
        if os.path.isfile(item):
            reply = input('  Remove {}? [n|y]: '.format(item))

            if reply.lower() == 'y':
                os.remove(item)


def clean_output():
    '''Remove files and directories from output.'''

    print('output:')

    # The following directories were used for creating the chm files.
    # No longer needed if the chm files were made OK.
    for item in ('lua_chm',):
        if os.path.isdir(item):
            reply = input('  Remove directory {}? [n|y]: '.format(item))

            if reply.lower() == 'y':
                shutil.rmtree(item)

    # Embedded.properties no longer needed if inserted into SciTE.exe OK.
    # iface.json no longer needed as was used as a temporary file.
    for item in ('Embedded.properties', 'iface.json'):
        if os.path.isfile(item):
            reply = input('  Remove {}? [n|y]: '.format(item))

            if reply.lower() == 'y':
                os.remove(item)


    # Log files were used for inspection.
    # No longer needed if inspection was OK.
    logs = glob.glob(os.path.join('**', '*.log'), recursive=True)

    if logs:
        reply = input('  Remove all log files? [n|y]: '.format(item))

        if reply.lower() == 'y':
            for item in logs:
                os.remove(item)


def clean_source():
    '''Remove files from lexilla, scintilla and scite.'''

    print('source:')

    items = []

    # Remove hhc, hhk and hhp files.
    # No longer needed if the chm files were made OK.
    for folder in ('lexilla', 'scintilla', 'scite'):
        for pattern in ('*.hhc', '*.hhk', '*.hhp'):
            for item in glob.iglob(os.path.join(folder, 'doc', pattern)):
                items.append(item)

    if items:
        reply = input('  Remove hhc, hhk and hhp files? [n|y]: ')

        if reply.lower() == 'y':
            for item in items:
                os.remove(item)


if __name__ == '__main__':

    # Set download and output paths.
    download = common.settings['download']
    output = common.settings['output']

    # Clean source.
    clean_source()

    # Clean download.
    if os.path.exists(download):
        os.chdir(download)
        clean_download()

    # Clean output.
    if os.path.exists(output):
        os.chdir(output)
        clean_output()

    print('done')
