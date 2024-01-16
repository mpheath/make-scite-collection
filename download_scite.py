#!python3

'''Download SciTE source and executables and optionally extract the source.'''

import os, platform, shutil, urllib.request, zipfile
import common

settings = common.settings

# Try download url from sourceforge.net before trying scintilla.org.
settings['sourceforge'] = True


def is_os_64bit():
    '''Detect 64 bit OS.'''

    return platform.machine().endswith('64')


if __name__ == '__main__':

    # Get initial directory.
    initial_dir = os.getcwd()

    # Set download path.
    download = common.settings['download']

    if not os.path.isdir(download):
        os.makedirs(download)

    # Read version and print as current version.
    version = common.scite_version()

    if version:
        print('current:', version)

    # Get the version to download.
    version = input('Enter the version number to download: ')

    if version:
        version = version.replace('.', '')
        version = version.replace(' ', '')

    if not version:
        exit()

    if not version.isdigit():
        exit('Invalid version')

    # Set file patterns to download.
    file_patterns = ['scite{}.zip', 'wscite{}.zip', 'Sc{}.exe']

    if not version.startswith(('1', '2', '3')):
        if is_os_64bit():
            print('64 bit OS detected.')
            reply = input('Download SciTE 32 bit files? [n|y]: ')
        else:
            reply = 'y'

        if reply.lower() == 'y':
            file_patterns.extend(['wscite32_{}.zip', 'Sc32_{}.exe'])

    # Change directory to download.
    os.chdir(download)

    # Get the download url.
    if settings['sourceforge']:
        print('Get download url from sourceforge.net')

        url = ('https://sourceforge.net/projects/scintilla/files/SciTE/'
               '{}/scite{}.zip/download').format('.'.join(version), version)

        try:
            with urllib.request.urlopen(url) as r:
                download_url = r.geturl()
        except urllib.error.HTTPError as err_msg:
            print(err_msg)
            print('Switching to scintilla.org')
            url = 'https://www.scintilla.org/{}'
        else:
            download_url = download_url.split('/')
            url = '/'.join(download_url[:-1]) + '/{}'
    else:
        url = 'https://www.scintilla.org/{}'

    # Download the files.
    print('download:')

    for file_pattern in file_patterns:
        file = file_pattern.format(version)

        print(' ', file)

        if os.path.isfile(file):
            print('   ', 'os.path.isfile: True')
            continue

        try:
            urllib.request.urlretrieve(url.format(file), file)
        except urllib.error.HTTPError as err_msg:
            print('   ', err_msg)

    # Extract the source zipfile.
    required_name = 'scite/src/SciTE.h'
    source_dirs = ('lexilla', 'scintilla', 'scite')
    source_zipfile = None
    repo_found = False

    for file_pattern in file_patterns:
        if file_pattern.startswith('scite'):
            source_zipfile = os.path.join(download, file_pattern.format(version))
            break

    if os.path.isfile(source_zipfile):

        # Warn if a source folder is a repository.
        for item in source_dirs:
            for subdir in ('.git', '.hg'):
                if os.path.isdir(os.path.join(initial_dir, item, subdir)):
                    print('warning: {} recognized as a repository'.format(item))
                    repo_found = True

        if repo_found:
            # Do not extract to replace repositories.
            print('Extract option not available to replace repositories.')
            reply = 'n'
        else:
            # Warn if a source folder already exist.
            for item in source_dirs:
                if os.path.exists(os.path.join(initial_dir, item)):
                    print('warning: This may remove current lexilla, scintilla and scite '
                          'directories and then extract the source from the zipfile.')
                    break

            # Get permission to extract.
            reply = input('Extract {} to current directory [n|y]: '
                          .format(os.path.basename(source_zipfile)))

        if reply.lower() == 'y':

            # Change directory to initial.
            os.chdir(initial_dir)

            with zipfile.ZipFile(source_zipfile) as r:

                # Confirm is source file.
                if required_name in r.namelist():

                    # Remove current source directories.
                    for item in source_dirs:
                        if os.path.isdir(item):
                            print('remove', item)
                            shutil.rmtree(item)

                    # Extract all source content.
                    print('extracting')
                    r.extractall()

                    # Remove place holder file for empty bin directory.
                    for item in source_dirs:
                        file = os.path.join(item, 'bin', 'empty.txt')

                        if os.path.isfile(file):
                            os.remove(file)
                else:
                    print('no extraction as ' + required_name + ' not found.')

    print('done')
