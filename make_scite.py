#!python3

'''Build SciTE.exe and Sc1.exe from source with gcc.'''

import glob, os, subprocess


def make_scite():
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


def make_testlexers():
    '''Make TestLexers.exe for testing Lexilla lexers.'''

    cwd = os.getcwd()

    # SciTE 5.0 and later has a separate lexilla folder.
    if os.path.isdir('lexilla'):
        paths = [os.path.join(cwd, 'lexilla', 'test')]
    else:
        paths = [os.path.join(cwd, 'scintilla', 'lexilla', 'test')]

    # Compile.
    for path in paths:
        with subprocess.Popen('mingw32-make', cwd=path) as p:
            p.wait()


def make_unittest():
    '''Make unitTest.exe for unit testing Lexilla and Scintilla.'''

    cwd = os.getcwd()

    # SciTE 5.0 and later has a separate lexilla folder.
    if os.path.isdir('lexilla'):
        paths = [os.path.join(cwd, 'lexilla', 'test', 'unit')]
    else:
        paths = []

    paths.append(os.path.join(cwd, 'scintilla', 'test', 'unit'))

    # Compile.
    for path in paths:
        with subprocess.Popen('mingw32-make', cwd=path) as p:
            p.wait()


def clean():
    '''Delete files in lexilla, scintilla and scite folders.'''

    # Ask for confirmation to avoid accidental deletions.
    print('Clean files in lexilla, scintilla and scite folders.')
    reply = input('Are you sure? [n|y]: ')

    if reply.lower() != 'y':
        return

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
          ' 1  Make SciTE\n'
          ' 2  Make TestLexers\n'
          ' 3  Make UnitTest\n'
          ' 4  Clean\n')

    reply = input('Enter numbers: ').strip()

    if reply:
        for item in reply.split():
            if item == '0':
                break
            elif item == '1':
                make_scite()
            elif item == '2':
                make_testlexers()
            elif item == '3':
                make_unittest()
            elif item == '4':
                clean()
            else:
                print(item, 'is an invalid number')

    print('done')
