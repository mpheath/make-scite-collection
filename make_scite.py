#!/usr/bin/env python3

'''Build SciTE.exe and Sc1.exe from source with gcc.'''

import glob, os, subprocess


def make():
    '''Make SciTE.exe and Sc1.exe.'''

    cwd = os.getcwd()

    # SciTE 5.0 and later has a separate lexilla folder.
    if os.path.isdir('lexilla'):
        paths = [os.path.join(cwd, 'lexilla', 'src')]
    else:
        paths = [os.path.join(cwd, 'scintilla', 'lexilla', 'src')]

    # Common paths.
    paths.append(os.path.join(cwd, 'scintilla', 'win32'))
    paths.append(os.path.join(cwd, 'scite', 'win32'))

    # Compile.
    for path in paths:
        with subprocess.Popen('mingw32-make', cwd=path) as p:
            p.wait()


def clean():
    '''Delete binary files in scite and scintilla folders.'''

    cwd = os.getcwd()

    for folder in ('lexilla', 'scintilla', 'scite'):

        # Folders are optional considering lexilla may not exist < SciTE 5.0.
        if not os.path.isdir(folder):
            continue

        # Delete binary files.
        command = [os.path.join(cwd, folder, 'delbin.bat')]

        with subprocess.Popen(command, cwd=folder) as p:
            p.wait()

        # Delete property files.
        file_pattern = os.path.join(cwd, folder, 'bin', '*.properties')

        for item in glob.iglob(file_pattern):
            os.remove(item)


if __name__ == '__main__':

    # Show menu to choose and run selected function.
    print('Make SciTE\n'
          '----------\n'
          ' 0  Quit\n'
          ' 1  Make\n'
          ' 2  Clean\n')

    reply = input('Enter a number: ')

    if reply == '1':
        make()
    elif reply == '2':
        clean()

    print('done')
